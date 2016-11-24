import 'dart:async';
import 'dart:convert';
import 'dart:io';

runScript(Map pubspec, String script,
    {bool allowFail: false, Directory workingDir}) async {
  final scripts = pubspec['scripts'] ?? {};

  if (!scripts.containsKey(script)) {
    if (allowFail)
      return;
    else
      throw new Exception(
          'Could not find a script named "$script" in project "${pubspec['name'] ?? '<untitled>'}".');
  } else {
    final lines = scripts[script] is List ? scripts[script] : [scripts[script]];

    for (final line in lines) {
      final result = await runLine(line, workingDir ?? Directory.current);
      final String sout = result[1].trim(), serr = result[2].trim();

      if (sout.isNotEmpty) print(sout);

      if (serr.isNotEmpty) stderr.writeln(serr);

      if (result[0] != 0) {
        throw new Exception(
            'Script "$script" failed with exit code ${result[0]}.');
      }
    }
  }
}

Future<List> runLine(String line, Directory workingDir) async {
  var path = Platform.environment['PATH'];
  final scriptsBin =
      new Directory.fromUri(Directory.current.uri.resolve('./.scripts-bin'));

  if (Platform.isWindows) {
    if (await scriptsBin.exists()) path = '${scriptsBin.absolute.uri};$path';

    final cmd = await Process.start('cmd', [],
        environment: {'PATH': path},
        workingDirectory: workingDir.absolute.path);
    cmd.stdin.writeln(line);
    cmd.stdin.writeln('exit 0');
    cmd.stdin.flush();

    return [
      await cmd.exitCode,
      await cmd.stdout.transform(UTF8.decoder).join(),
      await cmd.stderr.transform(UTF8.decoder).join()
    ];
  } else {
    if (await scriptsBin.exists()) path = '"${scriptsBin.absolute.uri}":$path';

    final bash = await Process.start('bash', [],
        environment: {'PATH': path},
        workingDirectory: workingDir.absolute.path);
    bash.stdin.writeln(line);
    bash.stdin.writeln('exit 0');
    bash.stdin.flush();

    return [
      await bash.exitCode,
      await bash.stdout.transform(UTF8.decoder).join(),
      await bash.stderr.transform(UTF8.decoder).join()
    ];
  }
}
