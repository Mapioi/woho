/// Utility functions that don't modify the file system.

import 'dart:io';
import 'dart:convert';
import './log.dart';
import './config.dart';

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
  } on FormatException catch (e) {
    print("Error reading config of $dir: $configStr");
    print(e);
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
