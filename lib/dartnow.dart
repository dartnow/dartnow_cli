library dartnow.dartnow;

import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:yaml/yaml.dart';
import 'package:github/server.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart';

import 'analyse/dart_snippet.dart';
import 'common.dart';

class DartNow {
  static createTemplateFiles() {
    files = {
      'pubspec.yaml': pubspecStringTemplate,
      'main.dart': dartStringTemplate,
      'index.html': htmlStringTemplate
    };
  }

  /// Delete everything except idea files and dartnow.yaml.
  static deleteAllFiles() {
    List<FileSystemEntity> rootFiles =
        new Directory('').listSync(recursive: true);
    List<FileSystemEntity> filesToDelete = rootFiles
      ..removeWhere(
          (file) => file.path.contains(new RegExp('.idea|dartnow.yaml')));
    filesToDelete.forEach(
        (file) => file.existsSync() ? file.deleteSync(recursive: true) : null);
  }

  static Map<String, String> get files {
    List<FileSystemEntity> allFiles = new Directory('web').listSync();
    allFiles.add(new File('pubspec.yaml'));
    if (new File('README.md').existsSync()) {
      allFiles.add(new File('README.md'));
    }
    allFiles.removeWhere((file) => file is Directory);

    Map<String, String> files = new Map.fromIterable(allFiles,
        key: (file) => path.basename(file.path),
        value: (file) => file.readAsStringSync());
    return files;
  }

  static set files(Map<String, String> files) {
    List<FileSystemEntity> rootFiles =
        new Directory('').listSync(recursive: true);
    List<FileSystemEntity> filesToDelete = rootFiles
      ..removeWhere(
          (file) => file.path.contains(new RegExp('.idea|dartnow.yaml')));
    filesToDelete.forEach(
        (file) => file.existsSync() ? file.deleteSync(recursive: true) : null);

    var webDir = new Directory('web');
    if (!webDir.existsSync()) {
      webDir.createSync();
    }
    for (String fileName in files.keys) {
      String newFileName;
      if (fileName != 'pubspec.yaml' && fileName != 'README.md') {
        newFileName = 'web/$fileName';
      } else {
        newFileName = fileName;
      }
      File file = new File(newFileName)..createSync();
      file.writeAsStringSync((files[fileName]));
    }
  }

  final String username;
  final GitHub gitHub;

  factory DartNow() {
    File yamlFile = new File('dartnow.yaml');
    if (!yamlFile.existsSync()) {
      print("Couldn't find dartnow.yaml. Run dartnow init first.");
      exit(1);
    }
    Map yaml = loadYaml(yamlFile.readAsStringSync());
    Authentication auth = new Authentication.withToken(yaml['token']);
    GitHub gitHub = createGitHubClient(auth: auth);
    return new DartNow._init(yaml['username'], gitHub);
  }
  DartNow._init(this.username, this.gitHub);

  /// Update a gist.
  ///
  /// Updates the readme, adds the homepage to the pubspec and updates
  /// the gist description.
  Future<Gist> updateGist(String id) async {
    print(id);
    Gist gist = await getGist(id);
    DartSnippet snippet = new DartSnippet.fromGist(gist);
    Map<String, String> gistFiles = files;
    gistFiles['pubspec.yaml'] = snippet.updatePubSpec(files['pubspec.yaml']);

    await gitHub.gists.editGist(id,
        description: snippet.shortDescription, files: gistFiles);

    gist = await getGist(id);
    snippet = new DartSnippet.fromGist(gist);
    gistFiles = files;
    gistFiles['pubspec.yaml'] = snippet.updatePubSpec(files['pubspec.yaml']);
    gistFiles['README.md'] = snippet.updateReadme();

    await gitHub.gists.editGist(id,
        description: snippet.shortDescription, files: gistFiles);

    return gist;
  }

  Future<Gist> getGist(String id) async => await gitHub.gists.getGist(id);

  Future addToFireBase(String id) async {
    await post('https://dartnow.firebaseio.com/new.json',
        body: JSON.encode(id));
    print('$id added to https://dartnow.firebaseio.com/new.json');
  }

  /// Default value of [inputDir] is `new Directory('playground')`
  Future<Gist> createGist() async {
    Gist gist = await gitHub.gists.createGist(files, public: true);
    print('Gist created at ${gist.htmlUrl}');
    return gist;
  }
}

class DartNowAdmin {
  final String username;
  final GitHub gitHub;
  final String _secret;

  Map<String, String> newIds;

  factory DartNowAdmin() {
    File yamlFile = new File('dartnow.yaml');
    if (!yamlFile.existsSync()) {
      throw "Couldn't find dartnow.yaml. Please run dartnow init.";
    }
    Map yaml = loadYaml(yamlFile.readAsStringSync());
    Authentication auth = new Authentication.withToken(yaml['token']);
    GitHub gitHub = createGitHubClient(auth: auth);
    String secret = yaml['secret'];
    return new DartNowAdmin._init(yaml['username'], gitHub, secret);
  }

  DartNowAdmin._init(this.username, this.gitHub, this._secret);

  Future<Map<String, String>> fetchNew() async {
    Response response = await get('https://dartnow.firebaseio.com/new.json');
    newIds = JSON.decode(response.body);
    return newIds;
  }

  Future updateAll() async {
    Response response = await get('https://dartnow.firebaseio.com/gists.json');
    List<String> allIds = JSON.decode(response.body).keys.toList();
    for (String id in allIds) {
      await update(id);
    }
  }

  Future updateNew() async {
    Map<String, String> newIds = await fetchNew();
    if (newIds == null || newIds.isEmpty) {
      print('No new ids to process.');
      exit(0);
    }
    for (String key in newIds.keys) {
      await update(newIds[key]);
      await deleteNew(newIds[key]);
    }
  }

  Future update(String id) async {
    Gist gist = await gitHub.gists.getGist(id);
    DartSnippet snippet = new DartSnippet.fromGist(gist);
    await patch('https://dartnow.firebaseio.com/gists.json?auth=$_secret',
        body: JSON.encode({snippet.id: snippet.toJson()}));
    print('Snippet added to https://dartnow.firebaseio.com/gists/${id}');
    print('You can view the snippet at http://dartnow.org');

    await updateUser(gist.owner.login);
  }

  Future updateUser(String username) async {
    User user = await gitHub.users.getUser(username);
    DartNowUser dartnowUser = new DartNowUser(user);
    await dartnowUser.onReady;
    await dartnowUser.updateToFirebase();
  }

  Future deleteGist(String id) async {
    await delete('https://dartnow.firebaseio.com/gists/$id.json?auth=$_secret');
    print('$id deleted from gists.json');
  }

  Future deleteNew(String id) async {
    if (newIds == null) {
      newIds = await fetchNew();
    }
    while (newIds.keys.any((key) => newIds[key] == id)) {
      String key = newIds.keys.firstWhere((key) => newIds[key] == id);
      await delete('https://dartnow.firebaseio.com/new/$key.json');
      print('$id deleted from new.json');
      newIds[key] = null;
    }
  }
}

// TODO add info for finding the gist the user want to clone/get.
class DartNowUser {
  static Future<String> idToGet(String username) async {
    return (await get('https://dartnow.firebaseio.com/get/$username.json')).body
        .replaceAll('"', '');
  }

  final User _user;

  final DartNowAdmin admin = new DartNowAdmin();

  Future onReady;

  List<String> gists;

  DartNowUser(this._user) {
    onReady = new Future(() async {
      gists = await _gists;
    });
  }

  Future<List<String>> get _gists async {
    Map<String, Map<String, String>> json = JSON
        .decode((await get('https://dartnow.firebaseio.com/gists.json')).body);
    return json.keys.toList()
      ..retainWhere((String id) => json[id]['author'] == username);
  }

  String get avatarUrl => _user.avatarUrl;

  String get name => _user.name;

  int get id => _user.id;

  String get email => _user.email;

  String get username => _user.login;

  Map toJson() => {
    'name': name,
    'avatarUrl': avatarUrl,
    'id': id,
    'username': username,
    'gists': gists,
    'gistCount': gists.length
  };

  String get _secret => admin._secret;

  Future updateToFirebase() async {
    await patch(
        'https://dartnow.firebaseio.com/users/$username/github_info.json?auth=$_secret',
        body: JSON.encode(toJson()));
    print('User added to https://dartnow.firebaseio.com/users/${username}');
    print('User gist count is ${gists.length}');
  }
}
