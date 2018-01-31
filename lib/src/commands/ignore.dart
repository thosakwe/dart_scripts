import 'dart:async';
import 'dart:io';
import 'package:args/command_runner.dart';

class IgnoreCommand extends Command {
  static const String _contents = '.scripts-bin/';
  
  @override
  String get name => 'ignore';

  @override
  String get description => 'Adds .scripts-bin/ to your VCS ignore file.';

  IgnoreCommand() {
    argParser
      ..addOption(
        'filename',
        help: 'The name of the ignore file to write to.',
        defaultsTo: '.gitignore',
      );
  }

  @override
  Future run() async {
    var ignoreFile = new File.fromUri(Directory.current.uri.resolve(argResults['filename']));

    if (!await ignoreFile.exists()) {
      return await ignoreFile.writeAsString(_contents);
    }

    var contents = await ignoreFile.readAsString();

    if (!contents.contains(_contents)) {
      var sink = await ignoreFile.openWrite(mode: FileMode.APPEND);
      sink.writeln(_contents);
      await sink.close();
    }
  }
}
