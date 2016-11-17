import 'package:yaml/yaml.dart';
import 'package.dart';

class Publock {
  final List<PubPackage> packages = [];

  Publock({List<PubPackage> packages: const []}) {
    this.packages.addAll(packages);
  }

  factory Publock.fromMap(Map data) {
    final packages = [];

    data['packages'].forEach((k, v) {
      packages.add(new PubPackage.fromMap({'name': k}..addAll(v)));
    });

    return new Publock(packages: packages);
  }
}
