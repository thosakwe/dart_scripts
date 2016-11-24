import 'package:args/command_runner.dart';
import 'clean.dart';
import 'get.dart';

class ResetCommand extends Command {
  @override
  String get name => 'reset';

  @override
  String get description => 'Runs `clean`, followed by `get`.';

  @override
  run() async {
    await new CleanCommand().run();
    await new GetCommand().run();
  }
}