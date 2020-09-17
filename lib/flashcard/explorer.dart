import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import './explorer_model.dart';
import './popups.dart';
import '../whiteboard/editor.dart';

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

    return GestureDetector(
      child: Column(
        children: [
          Icon(
            iconData,
            color: color,
            size: 100,
          ),
          Text(relativeName(model.wd, dir)),
        ],
      ),
      // On tap, cd to the folder
      onTap: () => model.cd(dir),
    );
  }

  Widget _buildFolder() {
    final contents = config(model.wd).orderedContents;
    if (contents.isEmpty)
      return Center(
        child: Chip(
          avatar: Icon(Icons.self_improvement),
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

  Widget _buildFlashcardTile(
    BuildContext context,
    IconData iconData,
    String fileName,
    onTap,
  ) {
    return GestureDetector(
      child: Column(
        children: [
          Icon(
            iconData,
            size: 100,
          ),
          Text(fileName),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildFlashcard(BuildContext context) {
    return GridView(
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 150,
      ),
      children: [
        _buildFlashcardTile(
          context,
          Icons.flip_to_front,
          "front.svg",
          () => _onOpenFront(context),
        ),
        _buildFlashcardTile(
          context,
          Icons.flip_to_back,
          "back.svg",
          () => _onOpenBack(context),
        )
      ],
    );
  }

  void _onCreateFolder(BuildContext context) {
    assert(!isFlashcard(model.wd));
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

  void _onCreateFlashcard(BuildContext context) {
    assert(!isFlashcard(model.wd));
    showDialog(
      context: context,
      builder: (context) {
        return DirectoryNameDialogue(
          root: model.wd,
          title: Chip(
            label: Text("New flashcard"),
            avatar: Icon(Icons.copy),
          ),
          hintText: "Untitled flashcard",
          onDone: (Directory dir) {
            model.createFlashcard(dir);
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

  void _onDeleteFolder(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("This folder will be deleted forever."),
        actions: [
          FlatButton(
            child: Text(
              "Delete",
              style: TextStyle(color: Colors.redAccent),
            ),
            onPressed: () {
              Navigator.pop(context);
              model.deleteWdAndCdUp();
            },
          ),
          FlatButton(
            child: Text("Abort"),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  void _onEditFlashcard(BuildContext context, File svg) {
    final size = MediaQuery.of(context).size;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (context) => svgModel(svg, size),
          child: WhiteboardEditor(),
        ),
        fullscreenDialog: true,
      ),
    );
  }

  void _onOpenFront(BuildContext context) {
    _onEditFlashcard(context, frontSvg(model.wd));
  }

  void _onOpenBack(BuildContext context) {
    _onEditFlashcard(context, backSvg(model.wd));
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
        centerTitle: true,
        actions: [
          if (!isFlashcard(model.wd))
            IconButton(
              tooltip: "New flashcard",
              icon: Icon(Icons.copy),
              onPressed: () => _onCreateFlashcard(context),
            ),
          if (!isFlashcard(model.wd))
            IconButton(
              tooltip: "New folder",
              icon: Icon(Icons.create_new_folder),
              onPressed: () => _onCreateFolder(context),
            ),
          if (model.canCdUp() && !isFlashcard(model.wd))
            IconButton(
              tooltip: "Rename folder",
              icon: Icon(Icons.drive_file_rename_outline),
              onPressed: () => _onRenameFolder(context),
            ),
          if (model.canCdUp() && !isFlashcard(model.wd))
            IconButton(
              tooltip: "Delete folder",
              icon: Icon(Icons.delete),
              onPressed: () => _onDeleteFolder(context),
            ),
        ],
      ),
      body: isFlashcard(model.wd) ? _buildFlashcard(context) : _buildFolder(),
    );
  }
}
