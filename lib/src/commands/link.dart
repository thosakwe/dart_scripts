import 'dart:io';
import 'package:args/command_runner.dart';
import '../home.dart';
import 'load_publock.dart';

final RegExp _file = new RegExp(r'^file://');
final String dartPath = Platform.executable;

class LinkCommand extends Command {
  String get name => 'link';
  String get description => 'Links installed packages to executables.';

  createBashFile(Directory bin, String name, String scriptFile) async {
    final file = new File.fromUri(bin.uri.resolve('$name'));
    await file.writeAsString('#!/usr/bin/env bash\n"$dartPath" "$scriptFile" @*');
    await Process.run('chmod', ['+x', file.path]);
  }

  createBatFile(Directory bin, String name, String scriptFile) async {
    final file = new File.fromUri(bin.uri.resolve('$name.bat'));
    await file.writeAsString('@echo off\n"$dartPath" "$scriptFile" %*');
  }

  run() async {
    final lock = await loadPublock();
    final Directory bin =
        new Directory.fromUri(Directory.current.uri.resolve('./.scripts-bin'));
    final packageRoot =
        new Directory.fromUri(bin.uri.resolve('./package-root'));

    if (!await packageRoot.exists()) await packageRoot.create(recursive: true);

    for (final pkg in lock.packages) {
      // Create symlink
      final pubspec = await pkg.readPubspec();
      final link =
          new Link.fromUri(packageRoot.uri.resolve('./${pubspec['name']}'));

      if (await link.exists()) await link.delete();

      final uri = pkg.location.absolute.uri.resolve('./lib').toString().replaceAll(_file, '');
      await link.create(uri);
    }

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

          // Generate snapshot
          final snapshot =
              new File.fromUri(pkg.location.uri.resolve('$name.snapshot.dart'));
          final result = await Process.run(Platform.executable, [
            '--snapshot=${snapshot.path}',
            '--package-root=${packageRoot.path}',
            path
          ]);

          if (result.stderr.isNotEmpty) {
            stderr.writeln(result.stderr);
            throw new Exception(
                "Could not create snapshot for package '$name'.");
          }

          // Create script files
          await createBashFile(bin, name, snapshot.absolute.path);
          await createBatFile(bin, name, snapshot.absolute.path);
          print('Successfully linked executables.');
        }
      }
    }
  }
}
