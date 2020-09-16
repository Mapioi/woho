import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import './explorer_model.dart';
import './popups.dart';

class FlashcardExplorer extends StatefulWidget {
  @override
  _FlashcardExplorerState createState() => _FlashcardExplorerState();
}

class _FlashcardExplorerState extends State<FlashcardExplorer> {
  Directory _root;

  @override
  initState() {
    getApplicationDocumentsDirectory().then(
      (root) => setState(() {
        _root = root;
      }),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_root == null) return Text("Loading...");
    return ChangeNotifierProvider(
      create: (context) => FlashcardExplorerModel.maybeNoConfig(_root),
      child: Consumer<FlashcardExplorerModel>(
        builder: (context, model, child) => _FlashcardExplorerView(model),
      ),
    );
  }
}

class _FlashcardExplorerView extends StatelessWidget {
  final FlashcardExplorerModel model;

  _FlashcardExplorerView(this.model);

  Widget _buildFolderTile(Directory dir) {
    IconData iconData;
    Color color;

    if (isFlashcard(dir)) {
      iconData = Icons.copy;
      color = null;
    } else {
      iconData = Icons.folder;
      color = Color(config(dir).colourValue);
    }

    return Column(
      children: [
        IconButton(
          iconSize: 100,
          icon: Icon(iconData),
          color: color,
          // On tap, cd to the folder
          onPressed: () => model.cd(dir),
        ),
        Text(relativeName(model.wd, dir)),
      ],
    );
  }

  Widget _buildFolder() {
    final contents = config(model.wd).orderedContents;
    if (contents.isEmpty)
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
      itemCount: contents.length,
      itemBuilder: (context, i) {
        final dir = Directory(model.wd.path + '/' + contents[i]);
        return _buildFolderTile(dir);
      },
    );
  }

  Widget _buildFlashcard() {
    return Text("front.svg, back.svg");
  }

  void _onCreateFolder(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return DirectoryNameDialogue(
          root: model.wd,
          title: Chip(
            label: Text("New folder"),
            avatar: Icon(Icons.folder),
          ),
          hintText: "Untitled Folder",
          onDone: (Directory dir) {
            model.createFolder(dir);
            model.cd(dir);
          },
        );
      },
    );
  }

  void _onRenameFolder(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return DirectoryNameDialogue(
          root: model.parentDir,
          title: Chip(
            label: Text("Rename folder"),
            avatar: Icon(Icons.folder),
          ),
          hintText: relativeName(model.parentDir, model.wd),
          onDone: (Directory newDir) {
            model.renameWd(newDir.path);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          // Undoes cd, going back to previous directory
          onPressed: model.canCdUp() ? model.cdUp : null,
        ),
        title: Text(
          model.canCdUp() ? "~/${relativeName(model.root, model.wd)}/" : "~/",
        ),
        actions: [
          if (model.canCdUp() && !isFlashcard(model.wd))
            IconButton(
              tooltip: "Rename folder",
              icon: Icon(Icons.drive_file_rename_outline),
              onPressed: () => _onRenameFolder(context),
            ),
          if (!isFlashcard(model.wd))
            IconButton(
              tooltip: "New folder",
              icon: Icon(Icons.create_new_folder),
              onPressed: () => _onCreateFolder(context),
            ),
        ],
      ),
      body: isFlashcard(model.wd) ? _buildFlashcard() : _buildFolder(),
    );
  }
}
