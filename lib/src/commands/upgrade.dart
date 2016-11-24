import 'dart:io';
import 'package:args/command_runner.dart';
import 'link.dart';
import '../run.dart';
import 'load_publock.dart';

class UpgradeCommand extends Command {
  String get name => 'upgrade';
  String get description =>
      'Runs pub upgrade, and then runs scripts of any dependencies.';
  final LinkCommand _link = new LinkCommand();

  run() async {
    final args = ['upgrade'];

    if (argResults != null) args.addAll(argResults.rest);

    await Process.run('pub', args);
    print('Now linking dependencies...');
    await _link.run();

    final publock = await loadPublock();

    for (final package in publock.packages) {
      final pubspec = await package.readPubspec();

      if (pubspec.containsKey('scripts') &&
          pubspec['scripts'].containsKey('upgrade')) {
        print('Running get hook from package "${package.name}"...');
        await runScript(pubspec, 'upgrade', workingDir: package.location);
      }
    }

    await runScript(await loadPubspec(), 'upgrade', allowFail: true);
  }
}
