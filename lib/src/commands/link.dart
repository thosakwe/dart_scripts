import 'dart:convert';
import 'dart:io';
import 'package:args/command_runner.dart';
import 'load_publock.dart';

final String dartPath = Platform.executable;

class LinkCommand extends Command {
  String get name => 'link';
  String get description => 'Links installed packages to executables.';

  createBashFile(Directory bin, String name, String scriptFile) async {
    final file = new File.fromUri(bin.uri.resolve('$name'));
    await file.writeAsString('#!/usr/bin/env/bash' + new String.fromCharCode(13) + '"$scriptFile" @*', encoding: ASCII);
    await Process.run('chmod', ['-R', '+x', bin.path]);
  }

  createBatFile(Directory bin, String name, String scriptFile) async {
    final file = new File.fromUri(bin.uri.resolve('$name.bat'));
    await file.writeAsString('@echo off\n"$scriptFile" %*');
  }

  run() async {
    final lock = await loadPublock();

    for (final pkg in lock.packages) {
      final pubspec = await pkg.readPubspec();
      final Map executables = pubspec['executables'];

      if (executables != null) {
        for (final name in executables.keys) {
          final scriptName =
              executables[name].isNotEmpty ? executables[name] : name;
          final scriptFile = new File.fromUri(
              pkg.location.uri.resolve('./bin/$scriptName.dart'));
          final path = scriptFile.absolute.path;

          // Create script files
          final Directory bin = new Directory.fromUri(Directory.current.uri.resolve('./.scripts-bin'));

          if (!await bin.exists())
            await bin.create();

          await createBashFile(bin, name, path);
          await createBatFile(bin, name, path);
          print('Successfully linked executables.');
        }
      }
    }
  }
}
