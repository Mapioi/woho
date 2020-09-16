import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
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

  bool _isFlashcard(Directory dir) {
    final ls = dir.listSync();
    final nbFiles = ls.where((entity) => entity is File).length;
    // assert(nbFiles == 1 || nbFiles == 3); // config [+ front, back.svg]
    return nbFiles == 3;
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

  String _relativeName(Directory root, Directory dir) {
    assert(dir.path.startsWith(root.path));
    final relativeName = dir.path.substring(root.path.length);
    return relativeName;
  }

  Widget _buildDirectory(Directory dir) {
    final icon = _isFlashcard(dir) ? Icon(Icons.copy) : Icon(Icons.folder);
    return Column(
      children: [
        IconButton(
          iconSize: 100,
          icon: icon,
          tooltip: dir.path,
          // On tap, cd to the folder
          onPressed: () => _cd(dir),
        ),
        Text(_relativeName(_wd, dir).substring(1)), // /dir -> dir
      ],
    );
  }

  Widget _buildFile(File file) {
    return IconButton(
      iconSize: 100,
      icon: Icon(Icons.image),
      onPressed: null,
    );
  }

  Widget _buildBody(List<FileSystemEntity> ls) {
    if (ls.isEmpty)
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
      itemCount: ls.length,
      itemBuilder: (context, i) {
        final entity = ls[i];
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

            _cd(dir);

            final configFile = File(dir.path + "/config.json");

            assert(!configFile.existsSync());

            // TODO write config; maybe replace json with yaml
            configFile.createSync();
            configFile.writeAsString("");

            assert(configFile.existsSync());
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
