#dartnow cli - OUTDATED, DOCS WILL BE UPDATED

To activate the package:

`pub global activate dartnow`

Create a directory where you want to manage your dartnow gists, for example:

`mkdir ~/dartnow_gists && cd ~/dartnow_gists`

Now run `dartnow init`. You will be asked your github username. And you need to create a github token. See this doc:

https://help.github.com/articles/creating-an-access-token-for-command-line-use/

The token only needs access to your gists.

If you have done this, open the `~/dartnow_gists` directory in your favourite editor. You will see a playground dir. If you want to upload the playground dir to dartnow, run:

`dartnow create`

This will save the playground dir to `~/dartnow_gists/my_gists`, generates a readme for the gist, and adds the gist to a list for me to review for dartnow.org. For now, please send me a message at https://dartlang.slack.com. Of course this will be automated in the future.

The directory name will be the name you specified in pubspec.yaml. If you want to push new changes to github and dartnow.org, run:

`dartnow push my_gists/dart.convert_JsonEncoder.withIndent`

Where `dart.convert_JsonEncoder.withIndent` would be for example the name of your directory.

### Naming convention

Make sure that the pubspec.yaml file follows the right naming convention. Here is an example:

```
name: dart.convert_JsonEncoder.withIndent
description: |
  How to pretty-print JSON using Dart.

  How to display JSON in an easy-to-read (for human readers) format.
tags: json pretty-print
```

If the main library contains an underscore, you use then double underscore to seperate the main library, from the element. For example:

```
name: route_hierarchical__Router
```

If you want to use a creative pubspec name, you can also specify the metadata in this way:

```
name: my_creative_title
main_library: intl:intl
main_elements: DateFormat DateFormat.format DateTime
tags: date
```

Note that you can also specify multiple main libraries in this way.
