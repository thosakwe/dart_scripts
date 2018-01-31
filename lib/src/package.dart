import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:pubspec/pubspec.dart';

class PubPackage {
  static String _pubCachePath;
  final PackageDescription description;
  final String name, source, version;

  PubPackage({this.name, this.description, this.source, this.version});

  static String get pubCachePath {
    if (_pubCachePath != null) return _pubCachePath;

    if (Platform.isWindows) {
      var appdata = Platform.environment['APPDATA'];
      return _pubCachePath = p.join(appdata, 'Pub', 'Cache');
    }

    var homeDir = Platform.environment['HOME'];
    return _pubCachePath = p.join(homeDir, '.pub-cache');
  }

  factory PubPackage.fromMap(Map data) {
    return new PubPackage(
        name: data['name'],
        description: new PackageDescription.fromMap(data['description']),
        source: data['source'],
        version: data['version']);
  }

  Directory get location {
    if (source == 'hosted') {
      return new Directory(
          p.join(pubCachePath, 'hosted', 'pub.dartlang.org', '$name-$version'));
    } else
      throw new UnsupportedError(
          'Unsupported source for package $name in pubspec.lock: $source');
  }

  Future<PubSpec> readPubspec() {
    return PubSpec.load(location);
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
