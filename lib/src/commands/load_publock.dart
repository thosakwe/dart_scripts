import 'dart:async';
import 'dart:io';
import 'package:yaml/yaml.dart';
import '../publock.dart';

final File lock = new File.fromUri(Directory.current.uri.resolve('./pubspec.lock'));

Future<Publock> loadPublock() async {
  return new Publock.fromMap(loadYaml(await lock.readAsString()));
}
