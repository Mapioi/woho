import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:reorderables/reorderables.dart';
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

  Widget _buildFolder() {
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
              size: 125,
            ),
            Text(relativeName(model.wd, dir)),
          ],
        ),
        // On tap, cd to the folder
        onTap: () => model.cd(dir),
      );
    }

    final contents = config(model.wd).orderedContents;
    if (contents.isEmpty)
      return Center(
        child: Chip(
          avatar: Icon(Icons.self_improvement),
          label: Text("Wow, such empty"),
        ),
      );

    return ReorderableWrap(
      children: contents.map((f) {
        final dir = Directory(model.wd.path + '/' + f);
        return _buildFolderTile(dir);
      }).toList(),
      onReorder: model.reorderContents,
      spacing: 10.0,
      runSpacing: 10.0,
      padding: EdgeInsets.all(10.0),
    );
  }

  Widget _buildFlashcard(BuildContext context) {
    Widget _buildFlashcardTile(
      BuildContext context,
      IconData iconData,
      String fileName,
      onTap,
    ) {
      return GestureDetector(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              Icon(
                iconData,
                size: 125,
              ),
              Text(fileName),
            ],
          ),
        ),
        onTap: onTap,
      );
    }

    return Row(
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

  void _onRename(BuildContext context, bool isFc) {
    final entityName = isFc ? "flashcard" : "folder";
    final iconData = isFc ? Icons.copy : Icons.folder;
    showDialog(
      context: context,
      builder: (context) {
        return DirectoryNameDialogue(
          root: model.parentDir,
          title: Chip(
            label: Text("Rename $entityName"),
            avatar: Icon(iconData),
          ),
          hintText: relativeName(model.parentDir, model.wd),
          onDone: (Directory newDir) {
            model.renameWd(newDir.path);
          },
        );
      },
    );
  }

  void _onDelete(BuildContext context, bool isFc) {
    final entityName = isFc ? "flashcard" : "folder";
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("This $entityName will be deleted forever."),
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
    final isFc = isFlashcard(model.wd);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          // Undoes cd, going back to previous directory
          onPressed: model.canCdUp() ? model.cdUp : null,
          tooltip: "Go back",
        ),
        title: Text(
          model.canCdUp() ? "~/${relativeName(model.root, model.wd)}/" : "~/",
        ),
        centerTitle: true,
        actions: [
          if (!isFc)
            IconButton(
              tooltip: "New flashcard",
              icon: Icon(Icons.copy),
              onPressed: () => _onCreateFlashcard(context),
            ),
          if (!isFc)
            IconButton(
              tooltip: "New folder",
              icon: Icon(Icons.create_new_folder),
              onPressed: () => _onCreateFolder(context),
            ),
          if (model.canCdUp())
            IconButton(
              tooltip: "Rename " + (isFc ? "flashcard" : "folder"),
              icon: Icon(Icons.drive_file_rename_outline),
              onPressed: () => _onRename(context, isFc),
            ),
          if (model.canCdUp())
            IconButton(
              tooltip: "Delete " + (isFc ? "flashcard" : "folder"),
              icon: Icon(Icons.delete),
              onPressed: () => _onDelete(context, isFc),
            ),
        ],
      ),
      body: isFlashcard(model.wd) ? _buildFlashcard(context) : _buildFolder(),
      floatingActionButton: isFc
          ? null
          : FloatingActionButton(
              child: Icon(Icons.style),
              onPressed: null,
            ),
    );
  }
}
