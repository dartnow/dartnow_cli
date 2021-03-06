library dartnow.dart_snippet;

import 'package:github/server.dart';
import 'package:dartnow/analyse/pubspec.dart';
import 'package:dartnow/analyse/analyzer_util.dart';
import "package:md_proc/md_proc.dart";

class DartSnippet {
  Gist _gist;

  PubSpec get _pubspec => new PubSpec.fromString(pubspecString);
  String get name => _pubspec.name;
  String get description => _pubspec.description;
  String get shortDescription {
    if (description == null ||
        description.isEmpty) return '${mainLibrary} example';
    if (description.indexOf('\n\n') == -1) {
      return description;
    } else {
      return description.substring(0, description.indexOf('\n\n'));
    }
  }
  String get mainLibrary => _pubspec.mainLibrary;
  String get mainElements => _pubspec.mainElements;
  String get tags => _pubspec.tags;

  String get id => _gist.id;
  String get author => _gist.owner.login;
  String get updatedAt => _gist.updatedAt.toIso8601String();
  String get createdAt => _gist.updatedAt.toIso8601String();
  String get gistUrl => 'https://gist.github.com/${author}/$id';
  String get dartpadUrl => 'https://dartpad.dartlang.org/$id';

  List<GistFile> get _gistFiles => _gist.files;
  String get pubspecString => _fileString('pubspec.yaml');
  String get htmlString => _fileString('index.html');
  String get dartString => _fileString('main.dart');
  String get cssString => _fileString('styles.css');
  String get _oldReadmeString => _fileString('README.md');

  List<String> get libraries => new AnalyzerUtil().findLibraries(dartString);

  DartSnippet.fromGist(this._gist);

  Map toJson() {
    print(description);
    return {
      'name': name,
      'author': author,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'description': markdownToHtml(description),
      'shortDescription': markdownToHtml(shortDescription),
      'mainLibrary': mainLibrary,
      'mainElements': mainElements,
      'tags': tags,
      'files': {
        'pubspec': pubspecString,
        'html': htmlString,
        'css': cssString,
        'dart': dartString,
      },
      'libraries': libraries,
      'id': id,
      'gistUrl': gistUrl,
      'dartpadUrl': dartpadUrl,
      'dependencies': _pubspec.dependencies
    };
  }

  String updatePubSpec(String pubspecString) {
    List<String> pubSpecAsList = pubspecString.split('\n');
    // check if homepage is already inserted
    if (pubSpecAsList.every((s) => !s.startsWith('homepage'))) {
      var environmentIndex = pubSpecAsList.indexOf(
          pubSpecAsList.firstWhere((s) => s.startsWith('environment:')));
      pubSpecAsList.insert(environmentIndex, 'homepage: ${gistUrl}');
      print('Pubspec homepage inserted ($gistUrl)');
    }
    return pubSpecAsList.join('\n');
  }

  String updateReadme() => _newReadmeString;

  String _fileString(String fileName) {
    if (_gistFiles.any((file) => file.name == fileName)) {
      return _gistFiles.firstWhere((file) => file.name == fileName).content;
    } else {
      return null;
    }
  }

  String get _newReadmeString => '''
#${mainLibrary} example

${description}

**Main library:** ${mainLibrary}<br>
**Main element${mainElements.contains(' ') ? 's' : ''}:** ${mainElements}<br>
**Gist:** $gistUrl<br>${_displayDartPadLink ? '\n**DartPad:** $dartpadUrl<br>' : ''}
${tags.length == 0 ? "" : '**Tags:** ${_tagsWithHashTag}<br>'}
''';

  String get _tagsWithHashTag =>
      tags.trim().split(' ').map((t) => '#$t').join(' ');

  bool get _displayDartPadLink {
    return libraries.every((l) => l.startsWith('dart:'));
  }
}
