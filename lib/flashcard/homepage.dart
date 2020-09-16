import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import './config.dart';
import './popups.dart';

class FlashcardsHomepage extends StatefulWidget {
  @override
  _FlashcardsHomepageState createState() => _FlashcardsHomepageState();
}

class _FlashcardsHomepageState extends State<FlashcardsHomepage> {
  @override
  void initState() {
    getApplicationDocumentsDirectory().then(
      (dir) {
        final configFile = File(dir.path + '/config.json');
        if (!configFile.existsSync()) {
          configFile.createSync();
          final configJson = Config.empty().toJson();
          configFile.writeAsStringSync(jsonEncode(configJson));
        }
        setState(() {
          _wd = dir;
          _pastDirs = [dir];
        });
      },
    );
    super.initState();
  }

  Directory _wd;
  List<Directory> _pastDirs;

  File _configFile(Directory dir) {
    return File(dir.path + '/config.json');
  }

  Config _config(Directory dir) {
    assert(!_isFlashcard(dir));
    try { // Put here since this issue disappeared after I tried to print
      final configJson = jsonDecode(_configFile(dir).readAsStringSync());
      return Config.fromJson(configJson);
    } on FormatException catch(_) {
      print(_configFile(dir).readAsStringSync());
      return Config.empty();
    }
  }

  bool _isFlashcard(Directory dir) {
    final configFile = File(dir.path + '/config.json');
    final ls = dir.listSync();
    final nbFiles = ls.where((entity) => entity is File).length;
    if (configFile.existsSync()) {
      assert(nbFiles == 1); // only config.json
      return false;
    } else {
      assert(nbFiles == 2); // front.svg and back.svg
      return true;
    }
  }

  void _cd(Directory dir) {
    _pastDirs.add(_wd);
    setState(() {
      _wd = dir;
    });
  }

  bool _canCdUp() => _pastDirs.length > 1;

  void _cdUp() {
    assert(_pastDirs.length > 1);
    setState(() {
      _wd = _pastDirs.removeLast();
    });
  }

  String _relativeName(Directory root, FileSystemEntity f) {
    assert(f.path.startsWith(root.path));
    final relativeName = f.path.substring(root.path.length);
    return relativeName;
  }

  Widget _buildDirectory(Directory dir) {
    final isFlashcard = _isFlashcard(dir);
    final icon = isFlashcard ? Icon(Icons.copy) : Icon(Icons.folder);
    final color = isFlashcard ? null : Color(_config(dir).colourValue);
    return Column(
      children: [
        IconButton(
          iconSize: 100,
          icon: icon,
          color: color,
          tooltip: dir.path,
          // On tap, cd to the folder
          onPressed: () => _cd(dir),
        ),
        Text(_relativeName(_wd, dir).substring(1)), // /dir -> dir
      ],
    );
  }

  String _extension(File file) {
    assert(file.path.split('.').length >= 2);
    return file.path.split('.').last;
  }

  Widget _buildFile(File file) {
    assert(_extension(file) == 'svg');
    return IconButton(
      iconSize: 100,
      icon: Icon(Icons.image),
      onPressed: null,
    );
  }

  Widget _buildBody(List<FileSystemEntity> ls) {
    final lsFiltered = ls
        .where((entity) =>
            entity is Directory ||
            (entity is File && _extension(entity) == 'svg'))
        .toList();

    if (lsFiltered.isEmpty)
      return Center(
        child: Chip(
          avatar: Icon(Icons.folder_open),
          label: Text("Wow, such empty"),
        ),
      );

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 150,
      ),
      itemCount: lsFiltered.length,
      itemBuilder: (context, i) {
        final entity = lsFiltered[i];
        if (entity is Directory) {
          return _buildDirectory(entity);
        }
        if (entity is File) {
          return _buildFile(entity);
        }
        return Icon(Icons.device_unknown);
      },
    );
  }

  void _onCreateDir(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return DirectoryNameDialogue(
          root: _wd,
          title: Chip(
            label: Text("New folder"),
            avatar: Icon(Icons.folder),
          ),
          hintText: "Untitled Folder",
          onDone: (Directory dir) {
            dir.createSync();
            assert(dir.existsSync());

            final wdConfig = _config(_wd);
            wdConfig.orderedContents.add(_relativeName(_wd, dir));
            final wdConfigFile = _configFile(_wd);
            wdConfigFile.writeAsStringSync(jsonEncode(wdConfig.toJson()));

            final newConfigFile = _configFile(dir);
            assert(!newConfigFile.existsSync());

            newConfigFile.createSync();
            final newConfig = Config.empty();
            final newConfigJson = newConfig.toJson();
            newConfigFile.writeAsString(jsonEncode(newConfigJson));

            assert(newConfigFile.existsSync());

            _cd(dir);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_wd == null) return Text("Loading");

    final ls = _wd.listSync();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          // Undoes cd, going back to previous directory
          onPressed: _canCdUp() ? _cdUp : null,
        ),
        title: Text("~" + _relativeName(_pastDirs[0], _wd) + "/"),
        actions: [
          if (!_isFlashcard(_wd))
            IconButton(
              tooltip: "New folder",
              icon: Icon(Icons.create_new_folder),
              onPressed: () => _onCreateDir(context),
            ),
        ],
      ),
      body: _buildBody(ls),
    );
  }
}
