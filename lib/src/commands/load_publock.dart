import 'dart:async';
import 'dart:io';
import 'package:yaml/yaml.dart';
import '../publock.dart';

final File lockFile =
    new File.fromUri(Directory.current.uri.resolve('./pubspec.lock'));
final File pubspecFile =
    new File.fromUri(Directory.current.uri.resolve('./pubspec.yaml'));

_copyVal(v) {
  if (v is YamlMap) {
    final map = {};
    v.forEach((k, v) => _copy(k, v, map));
    return map;
  } else if (v is YamlList) {
    return v.map(_copyVal).toList();
  } else
    return v;
}

_copy(String k, v, Map out) {
  out[k] = _copyVal(v);
}

Future<Publock> loadPublock() async {
  return new Publock.fromMap(loadYaml(await lockFile.readAsString()));
}