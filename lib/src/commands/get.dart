import 'package:args/command_runner.dart';
import 'link.dart';

class GetCommand extends Command {
  String get name => 'get';
  String get description => 'Runs pub get, and then runs scripts of any dependencies.';
  final LinkCommand _link = new LinkCommand();

  run() async {
    // await link.run();
  }
}
