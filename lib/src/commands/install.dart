import 'dart:io';
import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:yamlicious/yamlicious.dart';
import 'get.dart';
import 'load_publock.dart';

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
      final pubspec = await loadPubspec();
      final key = argResults['dev'] ? 'dev_dependencies' : 'dependencies';

      if (pubspec[key] is! Map) {
        pubspec[key] = {};
      }

      for (final pkg in argResults.rest) {
        // Todo: Hosted packages

        if (_gitPkg.hasMatch(pkg)) {
          final match = _gitPkg.firstMatch(pkg);
          final dep = await resolveGitDep(match);
          pubspec[key][match.group(1)] = dep;
        } else if (_pathPkg.hasMatch(pkg)) {
          final match = _pathPkg.firstMatch(pkg);
          pubspec[key][match.group(1)] = {'path': match.group(2)};
        } else {
          final dep = await resolvePubDep(pkg, pubApiRoot);
          pubspec[key][dep['name']] = dep['version'];
        }
      }

      final yaml = toYamlString(pubspec);
      _client.close();

      if (argResults['dry-run']) {
        return print(yaml);
      } else {
        await pubspecFile.writeAsString(yaml);
        print('Now installing dependencies...');
        return await _get.run();
      }
    }
  }

  resolveGitDep(Match match) {
    if (match.group(4) != null) {
      return {
        'git': {'url': 'git://${match.group(2)}', 'ref': match.group(4)}
      };
    } else {
      return {'git': match.group(2)};
    }
  }

  /// Install [pkg] from [apiRoot].
  resolvePubDep(String pkg, String apiRoot) async {
    final index = pkg.indexOf('@');

    if (index > 0 && index < pkg.length - 1) {
      final split = pkg.split('@');

      return {'name': split[0], 'version': split[1]};
    } else {
      // Try to auto-detect version...
      final response =
          await _client.get(p.join(apiRoot, 'packages', pkg));

      if (response.statusCode == HttpStatus.NOT_FOUND) {
        throw new Exception('Unable to resolve package within pub: "$pkg"');
      } else {
        final versions = resolvePackageVersions(parse(response.body));

        if (versions.isEmpty) {
          throw new Exception(
              'Could not resolve any version of pub package "$pkg".');
        } else {
          return {'name': pkg, 'version': '^${versions.first}'};
        }
      }
    }
  }

  List<String> resolvePackageVersions(Document doc) {
    final result = [];

    for (final th in doc.querySelectorAll('#versions table tbody tr th')) {
      result.add(th.text);
    }

    return result;
  }
}
