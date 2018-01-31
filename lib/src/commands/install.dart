import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:pubspec/pubspec.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:tuple/tuple.dart';
import 'package:yamlicious/yamlicious.dart';
import 'get.dart';

final RegExp _gitPkg = new RegExp(r'^([^@]+)@git://([^#]+)(#(.+))?$');
final RegExp _pathPkg = new RegExp(r'^([^@]+)@path:([^$]+)$');

const String pubApiRoot = 'https://pub.dartlang.org';

class InstallCommand extends Command {
  final http.Client _client = new http.Client();
  final GetCommand _get = new GetCommand();

  @override
  String get name => 'install';

  @override
  String get description =>
      'Adds the specified dependencies to your pubspec.yaml, then runs `scripts get`.';

  InstallCommand() {
    argParser
      ..addFlag('dev',
          help: 'Installs the package(s) into dev_dependencies.',
          defaultsTo: false,
          negatable: false)
      ..addFlag('dry-run',
          help:
              'Resolves new dependencies, and prints the new pubspec, without changing any files.',
          defaultsTo: false,
          negatable: false);
  }

  run() async {
    if (argResults.rest.isEmpty) {
      stderr.writeln('usage: scripts install [options...] [<packages>]');
      stderr.writeln();
      stderr.writeln('Options:');
      stderr.writeln(argParser.usage);
      return exit(1);
    } else {
      var pubspec = await PubSpec.load(Directory.current);
      var targetMap = <String, DependencyReference>{};

      for (final pkg in argResults.rest) {
        if (_gitPkg.hasMatch(pkg)) {
          final match = _gitPkg.firstMatch(pkg);
          final dep = await resolveGitDep(match);
          targetMap[match.group(1)] = dep;
        } else if (_pathPkg.hasMatch(pkg)) {
          final match = _pathPkg.firstMatch(pkg);
          targetMap[match.group(1)] = new PathReference(match.group(2));
        } else {
          final dep = await resolvePubDep(pkg, pubApiRoot);
          targetMap[dep.item1] = dep.item2;
        }
      }

      _client.close();

      if (!argResults['dev']) {
        var dependencies = new Map.from(pubspec.dependencies)
          ..addAll(targetMap);
        pubspec = pubspec.copy(dependencies: dependencies);
      } else {
        var devDependencies = new Map.from(pubspec.devDependencies)
          ..addAll(targetMap);
        pubspec = pubspec.copy(devDependencies: devDependencies);
      }

      if (argResults['dry-run']) {
        return print(toYamlString(pubspec.toJson()));
      } else {
        await pubspec.save(Directory.current);
        print('Now installing dependencies...');
        return await _get.run();
      }
    }
  }

  GitReference resolveGitDep(Match match) {
    if (match.group(4) != null) {
      return new GitReference(match.group(2), match.group(4));
    } else {
      return new GitReference(match.group(2), null);
    }
  }

  /// Install [pkg] from [apiRoot].
  Future<Tuple2<String, DependencyReference>> resolvePubDep(
      String pkg, String apiRoot) async {
    final index = pkg.indexOf('@');
    String name;
    VersionConstraint version;

    if (index > 0 && index < pkg.length - 1) {
      final split = pkg.split('@');
      name = split[0];
      version = new VersionConstraint.parse(split[1]);
    } else {
      // Try to auto-detect version...
      final response = await _client.get(p.join(apiRoot, 'packages', pkg));

      if (response.statusCode == HttpStatus.NOT_FOUND) {
        throw new Exception('Unable to resolve package within pub: "$pkg"');
      } else {
        final versions = resolvePackageVersions(JSON.decode(response.body));

        if (versions.isEmpty) {
          throw new Exception(
              'Could not resolve any version of pub package "$pkg".');
        } else {
          name = pkg;
          version = versions.first;
        }
      }
    }

    DependencyReference out;

    if (apiRoot == pubApiRoot)
      out = new HostedReference(version);
    else
      out = new ExternalHostedReference(name, apiRoot, version);

    return new Tuple2(name, out);
  }

  List<VersionConstraint> resolvePackageVersions(Map response) {
    return response['versions'].map((Map info) {
      String version = info['version'];
      return new VersionConstraint.parse('^$version');
    }).toList();
  }
}
