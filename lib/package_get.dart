library pget;

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:logger/logger.dart';
import 'package:yaml/yaml.dart' as yaml;

import 'package:yaml_edit/yaml_edit.dart';

part 'constants.dart';

final _logger = Logger(
  filter: ProductionFilter(),
  printer: PrettyPrinter(
    lineLength: 80,
    methodCount: 0,
    noBoxingByDefault: true,
    printEmojis: false,
  ),
);
String? pubspecContent;
final pgetFileName = 'pget.yaml';
final pubspecFileName = 'pubspec.yaml';

Future<void> set(List<String> args) async {
  try {
    _logger.w(_majorTaskDoneLine);

    if (!_configFileExists()) throw "File 'pubspec.yaml' not found";

    // Create args parser to get flavor flag and its value
    final parser = ArgParser()
      ..addFlag(
        'init',
        negatable: false,
        help: 'Initialize Package get',
      )
      ..addFlag(
        'remove',
        negatable: false,
        help: 'Remove pget.yaml file from this project and from .gitignore',
      )
      ..addFlag(
        'help',
        abbr: 'h',
        negatable: false,
        help: 'Prints out available command usages',
      );

    final results = parser.parse(args);

    if (results.wasParsed('help')) {
      _logger..i(parser.usage);
    }
    if (results.wasParsed('init')) {
      await _initializePackageGet();
      _logger.w(_minorTaskDoneLine);
      _logger.i('File pget.yaml created and added to .gitignore');
    }
    if (results.wasParsed('remove')) {
      await _removePackageGet();
      _logger.w(_minorTaskDoneLine);
      _logger.i('File pget.yaml deleted and removed to .gitignore');
    }

    if (results.arguments.isEmpty) {
      _logger..i('Finding pget.yaml file...');
      await _findAndReplacePackagesPath();
      _logger.i('All Packages Are updated with pget.yaml file');
    }
  } catch (e) {
    _logger.f(e.toString());
    exit(255);
  } finally {
    _logger.close();
  }
}

Future<void> _findAndReplacePackagesPath() async {
  // Load package paths and versions from pget.yaml
  Map pgetData = {};
  try {
    final pgetFile = File(pgetFileName);
    if (await pgetFile.exists()) {
      final pgetContent = await pgetFile.readAsString();
      var d = yaml.loadYaml(pgetContent);
      if (d != null) pgetData = d as Map;
    } else {
      print('$pgetFileName does not exist.');
      return;
    }
  } catch (e) {
    print('Failed to read or parse $pgetFileName: $e');
    return;
  }
  if (pgetData.isEmpty) {
    await _runFlutterPubGet();
    return;
  }

  // Load pubspec.yaml content

  Map pubspecData = await getPubspecMap();
  if (pubspecData.isEmpty) {
    return;
  }
  await _replaceDependencies(
    pubspecData: pubspecData,
    pgetData: pgetData,
  );
  // await _replaceDependencies(
  //     pubspecData: pubspecData, pgetData: pgetData, key: 'dev_dependencies');
  // await _replaceDependencies(
  //     pubspecData: pubspecData,
  //     pgetData: pgetData,
  //     key: 'dependency_overrides');

  await _runFlutterPubGet();

  // if (updated) {
  //   try {
  //     final updatedContent = YamlWriter().write(pubspecData);
  //     final pubspecFile = File(pubspecFileName);
  //     await pubspecFile.writeAsString(updatedContent);
  //     print('Updated $pubspecFileName with package data from $pgetFileName.');
  //   } catch (e) {
  //     print('Failed to write updated $pubspecFileName: $e');
  //   }
  // } else {
  //   print('No updates needed for $pubspecFileName.');
  // }
}

Future<Map> getPubspecMap() async {
  Map pubspecData = Map();
  try {
    final pubspecFile = File(pubspecFileName);

    if (await pubspecFile.exists()) {
      pubspecContent = await pubspecFile.readAsString();
      var d = yaml.loadYaml(pubspecContent!);
      if (d != null) {
        pubspecData = Map.from(d as Map);
      }
    } else {
      print('$pubspecFileName does not exist.');
      return pubspecData;
    }
  } catch (e) {
    _logger.e('Failed to read or parse $pubspecFileName: $e');
  }
  return pubspecData;
}

Future<void> _replaceDependencies({
  required Map pubspecData,
  required Map pgetData,
}) async {
  Completer completer = Completer();
  //adding and replacing..
  if (pubspecData.isNotEmpty && pgetData.isNotEmpty) {
    int i = 0;
    // it will parent key like dependency, dev_dependency etc, value should always a map
    pgetData.forEach((key, val) {
      i++;
      (pgetData[key] as Map).forEach((e, v) async {
        if ((pubspecData[key] as Map).containsKey(e)) {
          _logger.i('Updated $e to ${pgetData[key][e]} at $key');
        } else {
          _logger.i('Added $e : ${pgetData[key][e]} at $key');
        }
        await _replacePackageWithPubGet(
            parentKey: key,
            key: e,
            value: pgetData[key][e],
            pubspecData: pubspecData);
      });
      if (i == pgetData.length) {
        completer.complete();
      }
    });
  } else {
    completer.complete();
  }
  await completer.future;
  final pubspecFile = File(pubspecFileName);

  if (pubspecContent != null) {
    await pubspecFile.writeAsString(pubspecContent!);
  }
}

Future<void> _replacePackageWithPubGet({
  required key,
  required value,
  required Map pubspecData,
  required String parentKey,
}) async {
  Completer completer = Completer();

  if ((pubspecData[parentKey] as Map).containsKey(key)) {
    //if package is already there it should rewrite this
    YamlEditor d = YamlEditor(pubspecContent!);
    d.update([parentKey, key], value);
    pubspecContent = d.toString();
    completer.complete();
  } else {
    completer.complete();
  }
  await completer.future;
}

Future<void> _runFlutterPubGet() async {
  try {
    // Running the command
    final result = await Process.run('flutter', ['pub', 'get']);

    // Handling the output
    if (result.exitCode == 0) {
      print('Command executed successfully:\n${result.stdout}');
    } else {
      print('Error executing command:\n${result.stderr}');
    }
  } catch (e) {
    print('Failed to execute command: $e');
  }
}

Future<void> _removePackageGet() async {
  final fileName = 'pget.yaml';
  final gitignorePath = '.gitignore';

  // Remove pget.yaml
  File pgetFile = File(fileName);
  if (await pgetFile.exists()) {
    await pgetFile.delete();
    _logger.i('Deleted $fileName.');
  } else {
    _logger.i('$fileName does not exist.');
  }

  // Remove pget.yaml from .gitignore
  File gitignoreFile = File(gitignorePath);
  if (await gitignoreFile.exists()) {
    List<String> gitignoreLines = await gitignoreFile.readAsLines();
    List<String> updatedLines =
        gitignoreLines.where((line) => line.trim() != fileName).toList();
    if (updatedLines.length < gitignoreLines.length) {
      await gitignoreFile.writeAsString(updatedLines.join('\n'));
      _logger.i('Removed $fileName from $gitignorePath.');
    } else {
      _logger.i('$fileName is not in $gitignorePath.');
    }
  } else {
    _logger.i('$gitignorePath does not exist.');
  }
}

Future<void> _initializePackageGet() async {
  final fileName = 'pget.yaml';
  final gitignorePath = '.gitignore';

  // Create pget.yaml
  File pgetFile = File(fileName);
  Map pubspecData = await getPubspecMap();
  final yamlEditor = YamlEditor('');

  if (!(await pgetFile.exists())) {
    if (pubspecData.isNotEmpty) {
      Map<String, dynamic> list = {
        'dependencies': {},
        'dev_dependencies': {},
        'dependency_overrides': {}
      };
      list.forEach((e, value) {
        (pubspecData[e] as Map).forEach((key, v) {
          if ((v is Map) && v.containsKey('path')) {
            list[e][key] = v;
          }
        });
      });

      list.removeWhere((s, d) {
        if ((d as Map).isEmpty) {
          return true;
        } else {
          return false;
        }
      });
      yamlEditor.update([], list);
    }
    String insertString = yamlEditor.toString();
    insertString = '''
# Created By @Bikramaditya with ❤
# Now run 'Flutter pub run pget' or 'dart run pget'
$insertString
    ''';

    await pgetFile.writeAsString(insertString);
  }
  // Add pget.yaml to .gitignore if not already present
  File gitignoreFile = File(gitignorePath);
  if (gitignoreFile.existsSync()) {
    List<String> gitignoreLines = gitignoreFile.readAsLinesSync();
    if (!gitignoreLines.contains(fileName)) {
      gitignoreFile.writeAsStringSync('\n$fileName', mode: FileMode.append);
      _logger.i('Added $fileName to $gitignorePath.');
    } else {
      _logger.i('$fileName is already in $gitignorePath.');
    }
  } else {
    _logger.i('$gitignorePath does not exist.');
  }
}

bool _configFileExists() {
  final pubspecFile = File('pubspec.yaml');
  return pubspecFile.existsSync();
}
