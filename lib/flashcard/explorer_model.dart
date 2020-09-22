import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import './config.dart';
import './log.dart';
import '../whiteboard/data.dart';

File frontSvg(Directory dir) {
  return File(dir.path + '/front.svg');
}

File backSvg(Directory dir) {
  return File(dir.path + '/back.svg');
}

File configFile(Directory dir) {
  return File(dir.path + '/config.json');
}

Config config(Directory dir) {
  assert(configFile(dir).existsSync());
  final configStr = configFile(dir).readAsStringSync();
  try {
    // Put here since this issue disappeared after I tried to print
    final configJson = jsonDecode(configStr);
    return Config.fromJson(configJson);
  } on FormatException catch (_) {
    print(configStr);
    return Config.empty();
  }
}

bool isFlashcard(Directory dir) {
  final config = configFile(dir);
  if (config.existsSync()) {
    return false;
  } else {
    assert(frontSvg(dir).existsSync());
    assert(backSvg(dir).existsSync());
    assert(logFile(dir).existsSync());
    return true;
  }
}

String relativeName(Directory root, FileSystemEntity f) {
  assert(f.path.startsWith(root.path));
  final relativeName = f.path.substring(root.path.length);
  if (relativeName.startsWith('/')) {
    return relativeName.substring(1);
  } else {
    assert(relativeName.isEmpty);
    return relativeName;
  }
}

List<Directory> listFlashcards(Directory root) {
  assert(!isFlashcard(root));

  final flashcards = <Directory>[];
  for (final f in config(root).orderedContents) {
    final dir = Directory(root.path + '/$f');
    if (isFlashcard(dir)) {
      flashcards.add(dir);
    } else {
      flashcards.addAll(listFlashcards(dir));
    }
  }

  return flashcards;
}

File logFile(Directory flashcard) {
  return File(flashcard.path + '/log.txt');
}

FlashcardLog log(Directory flashcard) {
  assert(logFile(flashcard).existsSync());
  final lines = logFile(flashcard).readAsLinesSync();
  return FlashcardLog.fromLines(lines);
}

void markFlashcard(Directory flashcard) {
  final fLog = log(flashcard);
  fLog.mark();
  logFile(flashcard).writeAsStringSync(fLog.toString());
}

void unmarkFlashcard(Directory flashcard) {
  final fLog = log(flashcard);
  fLog.unMark();
  logFile(flashcard).writeAsStringSync(fLog.toString());
}


class FlashcardExplorerModel extends ChangeNotifier {
  final Directory root;

  FlashcardExplorerModel(this.root)
      : _wd = root,
        _pastDirs = [root];

  factory FlashcardExplorerModel.maybeNoConfig(Directory root) {
    final rootConfigFile = configFile(root);
    if (!rootConfigFile.existsSync()) {
      rootConfigFile.createSync();
      final configJson = Config.empty().toJson();
      rootConfigFile.writeAsStringSync(jsonEncode(configJson));
    }
    return FlashcardExplorerModel(root);
  }

  Directory _wd;

  Directory get wd => _wd;

  Directory get parentDir {
    assert(canCdUp()); // not home
    return _pastDirs[_pastDirs.length - 2];
  }

  List<Directory> _pastDirs;

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

    final wdConfig = config(_wd);
    wdConfig.orderedContents.add(relativeName(_wd, dir));
    final wdConfigFile = configFile(_wd);
    wdConfigFile.writeAsStringSync(jsonEncode(wdConfig.toJson()));
  }

  createFolder(Directory dir) {
    _createDirectory(dir);

    final newConfigFile = configFile(dir);
    assert(!newConfigFile.existsSync());

    newConfigFile.createSync();
    final newConfig = Config.empty();
    final newConfigJson = newConfig.toJson();
    newConfigFile.writeAsString(jsonEncode(newConfigJson));

    assert(newConfigFile.existsSync());
    notifyListeners();
  }

  createFlashcard(Directory dir) {
    final name = relativeName(_wd, dir);
    _createDirectory(dir);

    final front = frontSvg(dir);
    final back = backSvg(dir);
    assert(!front.existsSync());
    assert(!back.existsSync());

    final size = Size(1024, 768);

    front.createSync();
    final frontData = WhiteboardData(size, [], title: name);
    front.writeAsStringSync(frontData.svg.toXmlString(pretty: true));

    back.createSync();
    final backData = WhiteboardData(size, []);
    back.writeAsStringSync(backData.svg.toXmlString(pretty: true));

    final log = logFile(dir);
    assert(!log.existsSync());
    log.createSync();

    notifyListeners();
  }

  renameWd(String newPath) {
    assert(!Directory(newPath).existsSync());

    final renamedWd = _wd.renameSync(newPath);

    final oldName = relativeName(parentDir, _wd);
    final newName = relativeName(parentDir, renamedWd);

    _wd = renamedWd;
    _pastDirs.last = renamedWd;

    final parentConfig = config(parentDir);
    final index = parentConfig.orderedContents.indexOf(oldName);
    assert(index != -1);
    parentConfig.orderedContents[index] = newName;
    final parentConfigFile = configFile(parentDir);
    parentConfigFile.writeAsStringSync(jsonEncode(parentConfig.toJson()));

    notifyListeners();
  }

  deleteWdAndCdUp() {
    assert(canCdUp());
    final wdName = relativeName(parentDir, _wd);

    final parentConfig = config(parentDir);
    final isRemoved = parentConfig.orderedContents.remove(wdName);
    assert(isRemoved);
    final parentConfigFile = configFile(parentDir);
    parentConfigFile.writeAsStringSync(jsonEncode(parentConfig.toJson()));

    cdUp();
    notifyListeners();
  }

  reorderContents(int oldIndex, int newIndex) {
    final wdConfig = config(_wd);
    final movedEntity = wdConfig.orderedContents.removeAt(oldIndex);
    wdConfig.orderedContents.insert(newIndex, movedEntity);
    final newJsonStr = jsonEncode(wdConfig.toJson());
    configFile(_wd).writeAsStringSync(newJsonStr);
    notifyListeners();
  }
}
