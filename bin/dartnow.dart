import 'dart:io';
import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:dartnow/analyse/pubspec.dart';
import 'package:github/server.dart';
import 'package:prompt/prompt.dart';
import 'package:dartnow/common.dart';
import 'package:dartnow/dartnow.dart';

void main(List<String> arguments) {
  new CommandRunner('dartnow', 'Command line interface for http://dartnow.org.')
    ..addCommand(new InitCommand())
    ..addCommand(new ResetCommand())
    ..addCommand(new GetCommand())
    ..addCommand(new PublishCommand())
    ..run(arguments);
}

class InitCommand extends Command {
  final name = 'init';
  final description = 'Create dartnow.yaml with your github token.';
  final invocation = 'dartnow init';

  run() async {
    checkIfRootIsEmpty();
    createConfigFile();
    DartNow.createTemplateFiles();
    print('Template files created');
    runCmd('pub get');
    exit(0);
  }

  void checkIfRootIsEmpty() {
    List<FileSystemEntity> files = new Directory('').listSync();
    // ignore .idea and .pub files
    files.removeWhere((file) => file.path.endsWith('.idea'));
    files.removeWhere((file) => file.path.contains('.pub'));
    if (files.isNotEmpty) {
      print('You must run dartnow init in an empty directory.');
      // TODO which exit code ?
      exit(0);
    }
  }

  void createConfigFile() {
    String username = askSync(new Question('Github Username'));
    // TODO check if token works
    String token = askSync(new Question(
        'Get a token with gist access here: https://github.com/settings/tokens\n'
        'Github Token'));
    String yamlString = 'username: $username\n'
        'token: $token';
    new File('dartnow.yaml').writeAsStringSync(yamlString);
    print('dartnow.yaml created');
  }
}

class ResetCommand extends Command {
  final name = 'reset';
  final description = 'Reset the playground.';

  run() async {
    DartNow.deleteAllFiles();
    // create template playground files again
    DartNow.createTemplateFiles();
    runCmd('pub get');
    exit(0);
  }
}

class PublishCommand extends Command {
  final name = 'publish';
  final invocation = 'dartnow publish';
  final description = 'Publish the snippet to dartnow.org.';

  PublishCommand();

  Future run() async {
    DartNow dartNow = new DartNow();

    // get the id from the homepage in the pubspec
    // if there is no homepage in the pubspec, create a new gist
    String id = new PubSpec.fromString(DartNow.files['pubspec.yaml']).id;
    if (id == null) {
      id = (await dartNow.createGist()).id;
    }
    print(id);
    await dartNow.updateGist(id);
    await dartNow.addToFireBase(id);

    List<GistFile> gistFiles = (await new DartNow().getGist(await id)).files;
    DartNow.files = new Map.fromIterables(
        gistFiles.map((gistFile) => gistFile.name),
        gistFiles.map((gistFile) => gistFile.content));
    print('Playground updated');
    runCmd('pub get');
    exit(0);
  }
}

class GetCommand extends Command {
  final name = 'get';
  final invocation = 'dartnow get';

  final description = 'Get the gist selected at dartnow.org.';

  Future<String> get id async {
    return await DartNowUser.idToGet(new DartNow().username);
  }

  GetCommand();

  run() async {
    List<GistFile> gistFiles = (await new DartNow().getGist(await id)).files;
    DartNow.files = new Map.fromIterables(
        gistFiles.map((gistFile) => gistFile.name),
        gistFiles.map((gistFile) => gistFile.content));
    runCmd('pub get');
    exit(0);
  }
}
