import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:dartnow/dartnow.dart';
import 'package:github/server.dart';
import 'package:grinder/grinder.dart' as grind;

CommandRunner runner;

void main(List<String> arguments) {
  runner = new CommandRunner("dartnow", "DartNow manager.")
    ..addCommand(new InitCommand())
    ..addCommand(new CreateCommand())
    ..addCommand(new PushCommand())
    ..addCommand(new AddCommand())
    ..addCommand(new UpdateGistCommand())
    ..addCommand(new CloneCommand())
    ..addCommand(new InstallCommand())
    ..addCommand(new ResetCommand());

  runner.run(arguments);
}

class PushCommand extends Command {
  final name = "push";
  final description =
      "Commit changes from git dir, push the changes and add the gist to firebase";

  DartNow dartnow;

  String get dir => argResults.rest[0];

  PushCommand();

  run() async {
    dartnow = new DartNow();
    await dartnow.push(dir);
    exit(0);
  }
}

class InitCommand extends Command {
  final name = "init";
  final description =
      "Create a config file in the directory, and creates a playground dir.";

  InitCommand();

  run() async {
    DartNow.addConfig();
    DartNow.createPlayground();
    exit(0);
  }
}

/// Create a new gist from playground dir.
class CreateCommand extends Command {
  final name = "create";
  final description =
      "Create a new gist from playground dir. Add the gist to firebase, and saves the gist in my_gists directory.";

  DartNow dartnow;

  CreateCommand();

  run() async {
    dartnow = new DartNow();
    Gist gist = await dartnow.createGist();

    // Add command
    String id = gist.id;
    await dartnow.add(id);

    await DartNow.resetPlayground();
    await dartnow.cloneGist(id);
    exit(0);
  }
}

/// Create a new gist from playground dir.
class CloneCommand extends Command {
  final name = "clone";
  final description =
  "Clone a gist from github. Specify the id.";

  DartNow dartnow;

  String get id => argResults.rest[0];


  CloneCommand();

  run() async {
    dartnow = new DartNow();
    await dartnow.cloneGist(id);
    exit(0);
  }
}

/// Add an gist id to firebase.
class AddCommand extends Command {
  final name = "add";
  final description = "Add an gist id to firebase.";
  DartNow dartnow;

  String get id => argResults.rest[0];

  AddCommand();

  run() async {
    dartnow = new DartNow();
    await dartnow.add(id);

    exit(0);
  }
}

/// Update a gist.
class UpdateGistCommand extends Command {
  final name = "update_gist";
  final description =
      "Update a gist. The argument should be the id of the gist. Doesn't add the gist to firebase.";
  DartNow dartnow;

  String get id => argResults.rest[0];

  UpdateGistCommand();

  run() async {
    dartnow = new DartNow();
    await dartnow.updateGist(id);
    exit(0);
  }
}

class ResetCommand extends Command {
  final name = "reset";
  final description = "Reset the playground dir.";

  ResetCommand();

  run() async {
    await DartNow.resetPlayground();
    exit(0);
  }
}

class InstallCommand extends Command {
  final name = "install";
  final description = "Install a library to the gist.";

  String get package => argResults.rest[0].split(':')[0];

  String get library => argResults.rest[0].split(':')[1];

  InstallCommand();

  void run() {
    if (package != 'dart') {
      grind.run('pub', arguments: 'global run den install $package'.split(' '));
      grind.run('pub', arguments: 'get'.split(' '));
    }
    addLibray();
    String printMessage = package == 'dart'
    ? 'Added $package:$library to main.dart'
    : 'Added package:$package/$library.dart to main.dart';
    print(printMessage);
  }

  void addLibray() {
    File mainFile = new File('main.dart');
    String mainFileString = mainFile.readAsStringSync();
    String importString = package == 'dart'
    ? "import '$package:$library';"
    : "import 'package:$package/$library.dart';";
    mainFile.writeAsStringSync('$importString\n$mainFileString');
  }
}