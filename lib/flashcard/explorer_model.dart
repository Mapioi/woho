import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import './config.dart';
import './files_utils.dart' as files;
import '../whiteboard/data.dart';
import '../whiteboard/whiteboard.dart';

/// Mark this [flashcard] and write the changes to [files.logFile].
void markFlashcard(Directory flashcard) {
  final fLog = files.log(flashcard);
  fLog.mark();
  files.logFile(flashcard).writeAsStringSync(fLog.toString());
}

/// Unmark this [flashcard] and write the changes to [files.logFile].
void unmarkFlashcard(Directory flashcard) {
  final fLog = files.log(flashcard);
  fLog.unMark();
  files.logFile(flashcard).writeAsStringSync(fLog.toString());
}

/// Patch [root] by adding the missing [files.configFile]s and [files.logFile]s,
/// unlisting non-existent contents, and registering unlisted contents.
///
/// A directory is considered to be a flashcard when [files.frontSvg] and
/// [files.backSvg] exist.
/// When [root] is a flashcard, an empty [files.logFile] is
/// created in case it is missing.
/// When [root] is a folder, the procedure first creates a default
/// [files.configFile] in case it is missing. It then goes through
/// [Config.orderedContents], checks whether the listed directories still exist,
/// and removes the no longer existing directories from the list. Finally, it
/// lists the file entities in this folder, and adds any unlisted directories
/// to the end of [Config.orderedContents].
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
      return doesDirExist;
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
    final configString = jsonEncode(config.toJson());
    files.configFile(root).writeAsStringSync(configString);
  }
}

/// The model for a flashcard explorer.
///
/// It keeps track of the current directory in [_wd], and the list of past
/// directories in [_pastDirs].
/// It keeps a [_clipboard] for the copied contents.
/// It is responsible for making the actual changes to the file system.
class FlashcardExplorerModel extends ChangeNotifier {
  final Directory root;

  FlashcardExplorerModel(this.root)
      : _wd = root,
        _pastDirs = [root] {
    patch(root);
  }

  Directory _wd;

  /// The current working directory.
  Directory get wd => _wd;

  /// The immediate parent directory of [wd].
  ///
  /// In fact the second to last directory in [_pastDirs] is returned, but since
  /// only immediate children are listed in the explorer, this entry must be the
  /// immediate parent of [wd].
  Directory get parentDir {
    assert(canCdUp()); // not home
    return _pastDirs[_pastDirs.length - 2];
  }

  List<Directory> _pastDirs;

  _Clipboard _clipboard;

  /// Resets [wd] to [root], patches and reloads the file system.
  void reset() {
    _wd = root;
    _pastDirs = [root];
    patch(root);
    notifyListeners();
  }

  /// Change [wd] to [dir].
  ///
  /// We assume that [dir] is a direct child of [wd].
  /// This also patches the new [wd] before notifying listeners.
  void cd(Directory dir) {
    // Check _wd is the direct parent of dir.
    assert(!files.relativeName(_wd, dir).contains('/'));
    _pastDirs.add(dir);
    _wd = dir;
    patch(_wd);
    notifyListeners();
  }

  bool canCdUp() => _pastDirs.length > 1;

  /// Change [wd] to the last directory of [_pastDirs].
  ///
  /// This also patches the new [wd] before notifying listeners.
  void cdUp() {
    assert(canCdUp());
    _pastDirs.removeLast();
    _wd = _pastDirs.last;
    patch(_wd);
    notifyListeners();
  }

  /// Create [dir] in [wd], and add [dir] to [Config.orderedContents] in
  /// [wd]'s [files.configFile].
  _createDirectory(Directory dir) {
    assert(!dir.existsSync());
    dir.createSync();
    assert(dir.existsSync());

    final wdConfig = files.config(_wd);
    wdConfig.orderedContents.add(files.relativeName(_wd, dir));
    final wdConfigFile = files.configFile(_wd);
    wdConfigFile.writeAsStringSync(jsonEncode(wdConfig.toJson()));
  }

  /// Create the folder [dir] with a default [files.configFile].
  createFolder(Directory dir) {
    _createDirectory(dir);

    final newConfigFile = files.configFile(dir);
    assert(!newConfigFile.existsSync());

    newConfigFile.createSync();
    final newConfig = Config.empty();
    final newConfigJson = newConfig.toJson();
    newConfigFile.writeAsStringSync(jsonEncode(newConfigJson));

    assert(newConfigFile.existsSync());
    notifyListeners();
  }

  /// Create the flashcard [dir] with an empty [files.logFile] as well as empty
  /// 1024x768 [files.frontSvg] and [files.backSvg].
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

  /// Rename [wd] to [newPath];
  /// if [wd] is a flashcard, rename [WhiteboardData.title] of [files.frontSvg]
  /// as well;
  /// rename entry in [Config.orderedContents] of [wd]'s [files.configFile].
  ///
  /// There must not be an existing directory at [newPath].
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

  /// Delete [wd], removing the entry from [Config.orderedContents] in
  /// [parentDir]'s [files.configFile].
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

  /// Copy [wd]'s contents recursively to a temporary folder, storing the name
  /// of the copied directory and the location of the temporary folder in
  /// [_clipboard].
  copyWd() async {
    final tmp = await getTemporaryDirectory();
    final cache = Directory("${tmp.path}/clipboard");
    if (await cache.exists()) {
      await cache.delete(recursive: true);
    }
    await cache.create();

    patch(_wd);
    await for (final entity in _wd.list(recursive: true)) {
      final relativeName = files.relativeName(_wd, entity);
      final newPath = cache.path + '/$relativeName';
      if (entity is Directory) {
        await Directory(newPath).create();
      } else if (entity is File) {
        await File(newPath).create();
        await entity.copy(newPath);
      }
    }

    _clipboard = _Clipboard(
      cache: cache,
      name: files.relativeName(parentDir, _wd),
    );
    notifyListeners();
  }

  /// Check whether [_clipboard] exists to be pasted.
  bool get canPaste {
    if (_clipboard != null) {
      if (_clipboard.cache.existsSync()) {
        return true;
      } else {
        _clipboard = null;
        notifyListeners();
        return false;
      }
    } else {
      return false;
    }
  }

  /// The resulting directory when [_clipboard] is pasted into [wd].
  Directory _pastedClipboardDirectory() {
    final path = _wd.path + '/' + _clipboard.name;
    return Directory(path);
  }

  /// Checks whether the directory [_pastedClipboardDirectory] already exists.
  bool get willPasteCreateConflict => _pastedClipboardDirectory().existsSync();

  String get clipboardName => _clipboard.name;

  /// Paste [_clipboard] recursively into [wd], overwriting the old contents if
  /// [_pastedClipboardDirectory] already exists.
  ///
  /// Adds [_pastedClipboardDirectory] to [Config.orderedContents] in [wd]'s
  /// [files.configFile] if it is not already listed.
  pasteIntoWd() {
    final oldDir = _pastedClipboardDirectory();
    if (oldDir.existsSync()) {
      oldDir.deleteSync(recursive: true);
    }

    final newDir = _pastedClipboardDirectory();
    assert(!newDir.existsSync());
    newDir.createSync();

    for (final entity in _clipboard.cache.listSync(recursive: true)) {
      final relativeName = files.relativeName(_clipboard.cache, entity);
      final absoluteName = "${newDir.path}/$relativeName";
      if (entity is Directory) {
        Directory(absoluteName).createSync();
      } else if (entity is File) {
        File(absoluteName).createSync();
        entity.copySync(absoluteName);
      }
    }

    final wdConfig = files.config(_wd);
    if (!wdConfig.orderedContents.contains(_clipboard.name)) {
      wdConfig.orderedContents.add(_clipboard.name);
    }
    files.configFile(_wd).writeAsStringSync(jsonEncode(wdConfig.toJson()));

    notifyListeners();
  }

  /// Move the entry at [oldIndex] of [Config.orderedContents] in [wd]'s
  /// [files.configFile] to [newIndex], so that the entry is placed before the
  /// original entries from [newIndex] till the end.
  reorderContents(int oldIndex, int newIndex) {
    final wdConfig = files.config(_wd);
    final movedEntity = wdConfig.orderedContents.removeAt(oldIndex);
    wdConfig.orderedContents.insert(newIndex, movedEntity);
    final newJsonStr = jsonEncode(wdConfig.toJson());
    files.configFile(_wd).writeAsStringSync(newJsonStr);
    notifyListeners();
  }

  /// Changes [Config.colourValue] to the value of [newColor] in [wd]'s
  /// [files.configFile].
  setWdColour(Color newColor) {
    final wdConfig = files.config(_wd);
    wdConfig.colourValue = newColor.value;
    final newJsonStr = jsonEncode(wdConfig.toJson());
    files.configFile(_wd).writeAsStringSync(newJsonStr);
    notifyListeners();
  }
}

/// A data object holding the relative [name] of the copied directory and the
/// [cache] directory to which it is copied.
class _Clipboard {
  final String name;
  final Directory cache;

  _Clipboard({this.name, this.cache});
}
