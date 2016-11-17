import 'dart:async';
import 'dart:io';
import 'package:yaml/yaml.dart';
import 'home.dart';

class PubPackage {
  final PackageDescription description;
  final String name, source, version;

  PubPackage({this.name, this.description, this.source, this.version});

  factory PubPackage.fromMap(Map data) {
    return new PubPackage(
        name: data['name'],
        description: new PackageDescription.fromMap(data['description']),
        source: data['source'],
        version: data['version']);
  }

  Directory get location {
    if (source == 'hosted') {
      return new Directory.fromUri(homeDir.uri
          .resolve('./.pub-cache/hosted/pub.dartlang.org/$name-$version'));
    } else
      return null;
  }

  Future<Map> readPubspec() async {
    final pubspec = new File.fromUri(location.uri.resolve('./pubspec.yaml'));
    return loadYaml(await pubspec.readAsString());
  }

  Map toJson() {
    return {
      'name': name,
      'description': description.toJson(),
      'source': source,
      'version': version
    };
  }
}

class PackageDescription {
  final String name, url;

  PackageDescription({this.name, this.url});

  factory PackageDescription.fromMap(Map data) {
    return new PackageDescription(name: data['name'], url: data['url']);
  }

  Map toJson() {
    return {'name': name, 'url': url};
  }
}
