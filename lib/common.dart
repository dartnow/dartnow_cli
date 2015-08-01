library dartnow.common;

import 'package:grinder/grinder.dart' as grind;

void runCmd(String command) {
  grind.RunOptions options = new grind.RunOptions(runInShell: true);

  List<String> commandAsList = command.split(' ');
  String executable = commandAsList.first;
  List<String> arguments = commandAsList..removeAt(0);

  grind.run(executable, arguments: arguments, runOptions: options);
}

String get htmlStringTemplate => '''
<!doctype html>
<html>
  <head>
  </head>
  <body>
    <script type="application/dart" src="main.dart"></script>
  </body>
</html>
''';

String get dartStringTemplate => '''
main() {
${'  '}
}
''';

String get pubspecStringTemplate => '''
name: playground
description: |
${'  '}
environment:
  sdk: '>=1.11.0 <2.0.0'
''';
