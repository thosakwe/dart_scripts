# scripts
Run commands upon installing Dart packages, and more.
It would be nice if all of these features were
eventually integrated into the main `pub` executable.
Until then, this will do.

* [Usage](#usage)
* [Running your own Scripts](#running-your-own-scripts)
* [Available Commands](#available-commands)
    * [clean](#clean)
    * [get, upgrade](#get)
    * [link](#link)
    * [init](#init)
    * [install](#install)
    * [reset](#reset)

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
  get:
  - dart_gyp configure
  - dart_gyp build
```

Installed dependencies with executables will automatically be
filled in to the `PATH` during script execution.

Then, in your project root, you can run:
```bash
$ scripts build
```

# Available Commands
* [clean](#clean)
* [get, upgrade](#get)
* [link](#link)
* [init](#init)
* [install](#install)
* [reset](#reset)

## clean
Removes the `.scripts-bin` directory, if present.

## get
This script simply runs `pub get`, and then calls
[`link`](#link).

## init
Essentially an `npm init` for Dart. This command will
run you through a series of prompts, after which a `pubspec.yaml`
will be generated for you.

## install
Can be used to install dependencies without having to search
the Pub directory for the current version.

```bash
# Install the newest version, and apply caret syntax
$ scripts install my-package

# Install a specific version
$ scripts install my-package@^1.0.0
$ scripts install my-package@0.0.4+25
$ scripts install "my-package@>=2.0.0 <3.0.0"

# Install a Git dependency
$ scripts install my-package@git://path/to/repo.git

# Specify a commit or ref
$ scripts install my-package@git://path/to/repo.git#bleeding-edge

# Install a local package
$ scripts install my-package@path:/Users/john/Source/Dart/pkg

# Install multiple packages
$ scripts install my-package my-other-package yet-another-package

# Install to dev_dependencies
$ scripts install --dev http test my-package@git://repo#dev

# Preview new `pubspec.yaml`, without actually installing dependencies,
# or modifying the file.
$ scripts install --dry-run my-experimental-package
```

## link
Creates symlinks to each dependency (in future versions, I
will eliminate symlink use), and also creates executable files
linked to any dependencies that export executables.

## reset
Runs `clean`, followed by `get`.