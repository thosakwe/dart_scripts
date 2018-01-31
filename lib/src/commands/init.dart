import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:console/console.dart';
import 'package:id/id.dart';
import 'package:path/path.dart' as path;
import 'package:pubspec/pubspec.dart';
import 'get.dart';
import 'load_publock.dart';

class InitCommand extends Command {
  final GetCommand _get = new GetCommand();

  @override
  String get name => 'init';

  @override
  String get description =>
      'Generates a `pubspec.yaml` file in the current directory, after a series of prompts.';

  @override
  run() async {
    if (await pubspecFile.exists()) {
      throw new Exception(
          '`pubspec.yaml` already exists in ${Directory.current.absolute
              .uri}.');
    }

    print('This utility will walk you through creating a pubspec.yaml file.');
    print(
        ' It only covers the most common items, and tries to guess sensible defaults.');
    print('');
    print('Use `scripts install <pkg>` afterwards to install a package and');
    print('save it as a dependency in the pubspec.yaml file.');

    final pubspec = {};

    pubspec['name'] = await promptForName();
    pubspec['version'] = await promptForVersion();

    await promptField(pubspec, 'description');
    await promptField(pubspec, 'author', defaultValue: Platform.localHostname);

    var gitUrl = null;

    try {
      final result = await Process.run('git', ['remote', 'get-url', 'origin']);

      if (result.exitCode == 0) {
        final stdout = await result.stdout.trim();

        if (stdout.isNotEmpty) gitUrl = stdout;
      }
    } catch (e) {}

    await promptField(pubspec, 'homepage', defaultValue: gitUrl);

    print('About to write to ${pubspecFile.absolute.path}:');

    final result = await readInput('Is this ok? (yes) ');

    if (result.toLowerCase().startsWith('y') || result.trim().isEmpty) {
      var ps = new PubSpec.fromJson(pubspec);
      await ps.save(Directory.current);
    }

    await Process.run('pub', ['get']);
    await _get.run();
  }

  promptField(Map pubspec, String field,
      {String as, String defaultValue}) async {
    final value = await readInput(
        defaultValue != null ? '$field ($defaultValue): ' : '$field: ');

    if (value.isNotEmpty)
      pubspec[as ?? field] = value;
    else if (defaultValue != null) pubspec[as ?? field] = defaultValue;
  }

  promptForName() async {
    final id = idFromString(
        path.basename(Directory.current.path).replaceAll('-', '_'));
    final defaultName = id.snake;
    final name = await readInput('name: ($defaultName) ');
    return name.isNotEmpty ? name : defaultName;
  }

  promptForVersion() async {
    final version = await readInput('version: (1.0.0) ');
    return version.isNotEmpty ? version : '1.0.0';
  }
}
