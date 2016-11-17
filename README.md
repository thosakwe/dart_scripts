# scripts
Run commands upon installing Dart packages, and more.

# Usage
```bash
$ pub global activate scripts
```

To use packages that integrate with `scripts`, you should run
`scripts get` instead of `pub get`. This will run `pub get`, and
then install package executables into a `.scripts-bin` directory.
Then, all installed packages will have their `get` scripts run.

Also replace `pub upgrade` with `scripts upgrade`. This will run `get`
scripts as well.

You can run `scripts link` to link executables into `.scripts-bin`.

# Running your own Scripts
It is very likely that you want to run your own scripts during
development, or upon package installation. Do as follows in your
`pubspec.yaml`:

```yaml
name: foo
# ...
scripts:
  build: gcc -o foo src/foo.cc
  get: dart_gyp configure && dart_gyp build
```


Then, in your project root, you can run:
```bash
$ scripts build
```
