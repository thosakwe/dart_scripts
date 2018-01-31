import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:pubspec/pubspec.dart';
import 'package:scripts/scripts.dart';

main(List<String> args) async {
  final runner = new CommandRunner(
      'scripts', 'Run commands upon installing Dart packages, and more.');
  runner.addCommand(new CleanCommand());
  runner.addCommand(new GetCommand());
  runner.addCommand(new IgnoreCommand());
  runner.addCommand(new InitCommand());
  runner.addCommand(new InstallCommand());
  runner.addCommand(new LinkCommand());
  runner.addCommand(new ResetCommand());
  runner.addCommand(new UpgradeCommand());

  try {
    await runner.run(args);
  } catch (exc) {
    if (exc is UsageException) {
      final pubspec = await PubSpec.load(Directory.current);

      for (final arg in args) {
        try {
          await runScript(pubspec, arg);
        } catch (e, st) {
          stderr.writeln('ERR: $e');
          stderr.writeln(st);
          // stderr.writeln(e);
          return exit(1);
        }
      }
    } else {
      stderr.writeln(exc);
      return exit(1);
    }
  }
}
