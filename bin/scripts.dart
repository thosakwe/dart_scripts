import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:scripts/scripts.dart';
import 'package:yaml/yaml.dart';

main(List<String> args) async {
  final runner = new CommandRunner(
      'scripts', 'Run commands upon installing Dart packages, and more.');
  runner.addCommand(new LinkCommand());

  try {
    runner.run(args);
  } catch (exc) {
    for (final arg in args) {
      await runScript(arg);
    }
  }
}

loadScriptsFromPubspec() {
  
}

runScript(String script) {

}
