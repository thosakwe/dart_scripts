import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:pubspec/pubspec.dart';
import 'link.dart';
import '../run.dart';
import 'load_publock.dart';

class GetCommand extends Command {
  String get name => 'get';
  String get description =>
      'Runs pub get, and then runs scripts of any dependencies.';
  final LinkCommand _link = new LinkCommand();

  run() async {
    final args = ['get'];

    if (argResults != null) args.addAll(argResults.rest);

    await Process.run('pub', args);
    print('Now linking dependencies...');
    await _link.run();

    final publock = await loadPublock();

    for (final package in publock.packages) {
      final pubspec = await package.readPubspec();

      if (pubspec.containsKey('scripts') &&
          pubspec['scripts'].containsKey('get')) {
        print('Running get hook from package "${package.name}"...');
        await runScript(pubspec, 'get', workingDir: package.location);
      }
    }

    await runScript(await PubSpec.load(Directory.current), 'get', allowFail: true);
  }
}
