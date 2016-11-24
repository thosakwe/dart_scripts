import 'dart:io';
import 'package:args/command_runner.dart';

class CleanCommand extends Command {
  @override
  String get name => 'clean';

  @override
  String get description => 'Removes the .scripts-bin directory, if it exists.';

  @override
  run() async {
    final scriptsBin = new Directory.fromUri(Directory.current.uri.resolve('./.scripts-bin'));

    if (await scriptsBin.exists()) {
      await scriptsBin.delete(recursive: true);
    }
  }
}