import 'dart:io';

import 'package:args/command_runner.dart';

import 'package:dartnow/dartnow.dart';

void main(List<String> arguments) {
  new CommandRunner("dartnow_admin", "DartNow admin manager.")
    ..addCommand(new UpdateCommand())
    ..addCommand(new UpdateNew())
    ..addCommand(new UpdateAll())
    ..addCommand(new DeleteGistCommand())
    ..addCommand(new UpdateUserCommand())
    ..run(arguments);
}

class UpdateCommand extends Command {
  final name = "update";
  final description = "Update info from gist to firebase, and update user info";

  DartNowAdmin dartnow;

  String get id => argResults.rest[0];

  UpdateCommand();

  run() async {
    dartnow = new DartNowAdmin();
    await dartnow.update(id);
    exit(0);
  }
}


class UpdateNew extends Command {
  final name = "update_new";
  final description = "Fetch all new ids, and update them";

  DartNowAdmin dartnow;

  String get id => argResults.rest[0];

  UpdateNew();

  run() async {
    dartnow = new DartNowAdmin();
    await dartnow.updateNew();
    exit(0);
  }
}

class UpdateAll extends Command {
  final name = "update_all";
  final description = "Fetch all gists, and update them";

  DartNowAdmin dartnow;

  UpdateAll();

  run() async {
    dartnow = new DartNowAdmin();
    await dartnow.updateAll();
    exit(0);
  }
}



class DeleteGistCommand extends Command {
  final name = "delete";
  final description = "Delete an id from dartnow.org";

  DartNowAdmin dartnow;

  String get id => argResults.rest[0];

  DeleteGistCommand();

  run() async {
    dartnow = new DartNowAdmin();
    await dartnow.deleteGist(id);
    exit(0);
  }
}


class UpdateUserCommand extends Command {
  final name = "update_user";
  final description = "Update the user info from the given username";

  DartNowAdmin dartnow;

  String get username => argResults.rest[0];

  UpdateUserCommand();

  run() async {
    dartnow = new DartNowAdmin();
    await dartnow.updateUser(username);
    exit(0);
  }
}

