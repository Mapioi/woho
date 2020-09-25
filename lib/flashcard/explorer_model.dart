import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import './config.dart';
import './files_utils.dart' as files;
import '../whiteboard/data.dart';
import '../whiteboard/whiteboard.dart';

void markFlashcard(Directory flashcard) {
  final fLog = files.log(flashcard);
  fLog.mark();
  files.logFile(flashcard).writeAsStringSync(fLog.toString());
}

void unmarkFlashcard(Directory flashcard) {
  final fLog = files.log(flashcard);
  fLog.unMark();
  files.logFile(flashcard).writeAsStringSync(fLog.toString());
}

void patch(Directory root) {
  if (files.frontSvg(root).existsSync() && files.backSvg(root).existsSync()) {
    // The root directory is a flashcard (directory).
    if (!files.logFile(root).existsSync()) {
      // Create an empty (literally) log file if it doesn't exist.
      files.logFile(root).createSync();
      print("Created the missing log file for $root.");
    }
  } else {
    // The root directory is a folder.
    if (!files.configFile(root).existsSync()) {
      final configFile = files.configFile(root);
      configFile.createSync();
      configFile.writeAsStringSync(
        jsonEncode(Config.empty().toJson()),
      );
      print("Created the missing config file for $root.");
    }

    final config = files.config(root);
    config.orderedContents = config.orderedContents.where((name) {
      final dir = Directory("${root.path}/$name");
      final doesDirExist = dir.existsSync();
      if (!doesDirExist) {
        print("Removed no longer existing $name from config");
      }
      return !doesDirExist;
    }).toList();

    for (final entity in root.listSync()) {
      if (entity is Directory) {
        final name = files.relativeName(root, entity);
        if (!config.orderedContents.contains(name)) {
          config.orderedContents.add(name);
          print("Registered unlisted $entity in config.");
        }
        patch(entity); // TODO maybe limit recursion depth
      }
    }
  }
}

class FlashcardExplorerModel extends ChangeNotifier {
  final Directory root;

  FlashcardExplorerModel(this.root)
      : _wd = root,
        _pastDirs = [root] {
    patch(root);
  }

  Directory _wd;

  Directory get wd => _wd;

  Directory get parentDir {
    assert(canCdUp()); // not home
    return _pastDirs[_pastDirs.length - 2];
  }

  List<Directory> _pastDirs;

  _Clipboard _clipboard;

  void cd(Directory dir) {
    _pastDirs.add(dir);
    _wd = dir;
    notifyListeners();
  }

  bool canCdUp() => _pastDirs.length > 1;

  void cdUp() {
    assert(canCdUp());
    _pastDirs.removeLast();
    _wd = _pastDirs.last;
    notifyListeners();
  }

  _createDirectory(Directory dir) {
    assert(!dir.existsSync());
    dir.createSync();
    assert(dir.existsSync());

    final wdConfig = files.config(_wd);
    wdConfig.orderedContents.add(files.relativeName(_wd, dir));
    final wdConfigFile = files.configFile(_wd);
    wdConfigFile.writeAsStringSync(jsonEncode(wdConfig.toJson()));
  }

  createFolder(Directory dir) {
    _createDirectory(dir);

    final newConfigFile = files.configFile(dir);
    assert(!newConfigFile.existsSync());

    newConfigFile.createSync();
    final newConfig = Config.empty();
    final newConfigJson = newConfig.toJson();
    newConfigFile.writeAsString(jsonEncode(newConfigJson));

    assert(newConfigFile.existsSync());
    notifyListeners();
  }

  createFlashcard(Directory dir) {
    final name = files.relativeName(_wd, dir);
    _createDirectory(dir);

    final front = files.frontSvg(dir);
    final back = files.backSvg(dir);
    assert(!front.existsSync());
    assert(!back.existsSync());

    final size = Size(1024, 768);

    front.createSync();
    final frontData = WhiteboardData(size, [], title: name);
    front.writeAsStringSync(frontData.svg.toXmlString(pretty: true));

    back.createSync();
    final backData = WhiteboardData(size, []);
    back.writeAsStringSync(backData.svg.toXmlString(pretty: true));

    final log = files.logFile(dir);
    assert(!log.existsSync());
    log.createSync();

    notifyListeners();
  }

  renameWd(String newPath) {
    assert(!Directory(newPath).existsSync());

    if (files.isFlashcard(_wd)) {
      final data = svgData(files.frontSvg(_wd));
      data.title = files.relativeName(parentDir, Directory(newPath));
      files.frontSvg(_wd).writeAsStringSync(data.svg.toXmlString(pretty: true));
    }

    final renamedWd = _wd.renameSync(newPath);

    final oldName = files.relativeName(parentDir, _wd);
    final newName = files.relativeName(parentDir, renamedWd);

    _wd = renamedWd;
    _pastDirs.last = renamedWd;

    final parentConfig = files.config(parentDir);
    final index = parentConfig.orderedContents.indexOf(oldName);
    assert(index != -1);
    parentConfig.orderedContents[index] = newName;
    final parentConfigFile = files.configFile(parentDir);
    parentConfigFile.writeAsStringSync(jsonEncode(parentConfig.toJson()));

    notifyListeners();
  }

  deleteWdAndCdUp() {
    assert(canCdUp());
    final wdName = files.relativeName(parentDir, _wd);

    final parentConfig = files.config(parentDir);
    final isRemoved = parentConfig.orderedContents.remove(wdName);
    assert(isRemoved);
    final parentConfigFile = files.configFile(parentDir);
    parentConfigFile.writeAsStringSync(jsonEncode(parentConfig.toJson()));

    wd.deleteSync(recursive: true);

    cdUp();
    notifyListeners();
  }

  copyWd() {
    assert(files.isFlashcard(_wd));
    _clipboard = _Clipboard(
      flashcardName: _wd.path.split('/').last,
      frontContents: files.frontSvg(_wd).readAsStringSync(),
      backContents: files.frontSvg(_wd).readAsStringSync(),
      logContents: files.logFile(_wd).readAsStringSync(),
    );
  }

  Directory _pastedClipboardDirectory() {
    assert(_clipboard != null);
    final path = _wd.path + '/' + _clipboard.flashcardName;
    return Directory(path);
  }

  bool get willPasteCreateConflict => _pastedClipboardDirectory().existsSync();

  bool get canPaste => _clipboard != null;

  String get clipboardName => _clipboard.flashcardName;

  pasteIntoWd() {
    assert(_clipboard != null);
    final oldDir = _pastedClipboardDirectory();
    if (oldDir.existsSync()) {
      oldDir.deleteSync(recursive: true);
    }

    final newDir = _pastedClipboardDirectory();
    assert(!newDir.existsSync());
    newDir.createSync();
    files.frontSvg(newDir).createSync();
    files.frontSvg(newDir).writeAsStringSync(_clipboard.frontContents);
    files.backSvg(newDir).createSync();
    files.backSvg(newDir).writeAsStringSync(_clipboard.backContents);
    files.logFile(newDir).createSync();
    files.logFile(newDir).writeAsStringSync(_clipboard.logContents);

    final wdConfig = files.config(_wd);
    if (!wdConfig.orderedContents.contains(_clipboard.flashcardName)) {
      wdConfig.orderedContents.add(_clipboard.flashcardName);
    }
    files.configFile(_wd).writeAsStringSync(jsonEncode(wdConfig.toJson()));

    notifyListeners();
  }

  reorderContents(int oldIndex, int newIndex) {
    final wdConfig = files.config(_wd);
    final movedEntity = wdConfig.orderedContents.removeAt(oldIndex);
    wdConfig.orderedContents.insert(newIndex, movedEntity);
    final newJsonStr = jsonEncode(wdConfig.toJson());
    files.configFile(_wd).writeAsStringSync(newJsonStr);
    notifyListeners();
  }

  setWdColour(Color newColor) {
    final wdConfig = files.config(_wd);
    wdConfig.colourValue = newColor.value;
    final newJsonStr = jsonEncode(wdConfig.toJson());
    files.configFile(_wd).writeAsStringSync(newJsonStr);
    notifyListeners();
  }
}

class _Clipboard {
  final String flashcardName;
  final String frontContents;
  final String backContents;
  final String logContents;

  _Clipboard({
    @required this.flashcardName,
    @required this.frontContents,
    @required this.backContents,
    @required this.logContents,
  });
}
