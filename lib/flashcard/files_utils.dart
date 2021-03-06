/// Utility functions that don't modify the file system.
///
/// Concretely, the file system consists of [File] and [Directory] entities.
/// In the scope of this app, the system consists of flashcards and folders.
/// Both are directories: flashcards contain only a [frontSvg], a [backSvg], and
/// a [logFile]; folders contain [configFile], flashcards, and other folders.

import 'dart:io';
import 'dart:convert';
import './flashcard_log.dart';
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

/// Parse the json in the [configFile] of this [dir] into a [Config] object.
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

/// Check whether this [dir] is a flashcard.
///
/// We assume and make sure that [dir] is either a flashcard or a folder.
/// If [dir] contains a [configFile], then we consider it to be a folder;
/// otherwise it must be a flashcard and must contain a [frontSvg], a [backSvg],
/// and a [logFile].
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

/// The name of [f] relative to [root].
///
/// ```
///   relativeName(Directory('/tmp'), Directory('/tmp/folder/1')) == 'folder/1'
/// ```
///
/// ```
///   relativeName(Directory('/tmp'), Directory('/tmp')) == ''
/// ```
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

/// List all flashcards contained in [root], by traversing through the contents
/// in the order given by [configFile] in DFS order.
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

/// Parse the [logFile] of this [flashcard] into a [FlashcardLog] object.
FlashcardLog log(Directory flashcard) {
  assert(logFile(flashcard).existsSync());
  final lines = logFile(flashcard).readAsLinesSync();
  return FlashcardLog.fromLines(lines);
}
