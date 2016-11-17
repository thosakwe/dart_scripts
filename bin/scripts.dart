import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:scripts/scripts.dart';
import 'package:yaml/yaml.dart';

main(List<String> args) async {
  final runner = new CommandRunner(
      'scripts', 'Run commands upon installing Dart packages, and more.');
  runner.addCommand(new LinkCommand());

  try {
    await runner.run(args);
  } catch (exc) {
    if (exc is UsageException) {
      for (final arg in args) {
        await runScript(arg);
      }
    } else {
      stderr.writeln(exc.message);
      exitCode = 1;
    }
  }
}

loadScriptsFromPubspec() {}

runScript(String script) {}
