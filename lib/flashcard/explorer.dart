import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:reorderables/reorderables.dart';
import './explorer_model.dart';
import './files_utils.dart' as files;
import './popups.dart';
import './viewer.dart';
import '../whiteboard/whiteboard.dart';

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
      create: (context) => FlashcardExplorerModel(_root),
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

      if (files.isFlashcard(dir)) {
        iconData = Icons.collections;
        final fLog = files.log(dir);
        if (fLog.dates.isEmpty) {
          color = Colors.black;
        } else {
          color = Color.lerp(
            Colors.red,
            Colors.black,
            1 - 1 / (fLog.daysSinceLastMarked() / 30 + 1),
          );
        }
      } else {
        iconData = Icons.folder;
        color = Color(files.config(dir).colourValue);
      }

      return InkWell(
        child: Column(
          children: [
            Icon(
              iconData,
              color: color,
              size: 125,
            ),
            Text(files.relativeName(model.wd, dir)),
          ],
        ),
        // On tap, cd to the folder
        onTap: () => model.cd(dir),
      );
    }

    final contents = files.config(model.wd).orderedContents;
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
      return InkWell(
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
    assert(!files.isFlashcard(model.wd));
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
    assert(!files.isFlashcard(model.wd));
    showDialog(
      context: context,
      builder: (context) {
        return DirectoryNameDialogue(
          root: model.wd,
          title: Chip(
            label: Text("New flashcard"),
            avatar: Icon(Icons.add_photo_alternate),
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
    final iconData = isFc ? Icons.collections : Icons.folder;
    showDialog(
      context: context,
      builder: (context) {
        return DirectoryNameDialogue(
          root: model.parentDir,
          title: Chip(
            label: Text("Rename $entityName"),
            avatar: Icon(iconData),
          ),
          hintText: files.relativeName(model.parentDir, model.wd),
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
      builder: (context) => DeleteAlertDialogue(
        titleText: "This $entityName will be deleted forever",
        deleteButtonText: "Delete",
        onConfirmDelete: model.deleteWdAndCdUp,
      ),
    );
  }

  void _onCopy(BuildContext context, String entityName) async {
    try {
      await model.copyWd();
      Scaffold.of(context).showSnackBar(
        SnackBar(
          content: Text("Copied $entityName!"),
        ),
      );
    } catch (e) {
      print("Error copying ${model.wd}:");
      print(e);
    }
  }

  void _onPaste(BuildContext context) {
    if (model.willPasteCreateConflict) {
      showDialog(
        context: context,
        builder: (context) => DeleteAlertDialogue(
          titleText: "'${model.clipboardName}' already exists in this folder.",
          deleteButtonText: "Overwrite",
          onConfirmDelete: model.pasteIntoWd,
        ),
      );
    } else {
      model.pasteIntoWd();
    }
  }

  void _onOpenFront(BuildContext context) {
    launchEditor(context, files.frontSvg(model.wd));
  }

  void _onOpenBack(BuildContext context) {
    launchEditor(context, files.backSvg(model.wd));
  }

  void _onEditFolderColour(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => ColourPickerDialogue(
        initialColour: Color(files.config(model.wd).colourValue),
        onDone: (color) {
          Scaffold.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Container(
                    width: 25,
                    height: 25,
                    color: color,
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                  ),
                  Text("Folder colour set!"),
                ],
              ),
            ),
          );
          model.setWdColour(color);
        },
      ),
    );
  }

  void _onBrowseFlashcards(BuildContext context) {
    patch(model.wd);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return FlashcardViewer(
            flashcards: files.listFlashcards(model.wd),
          );
        },
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFc = files.isFlashcard(model.wd);
    final entityName = isFc ? "flashcard" : "folder";

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: "Go back",
          icon: Icon(Icons.arrow_back_ios),
          // Undoes cd, going back to previous directory
          onPressed: model.canCdUp() ? model.cdUp : null,
        ),
        title: Text(
          model.canCdUp()
              ? "~/${files.relativeName(model.root, model.wd)}/"
              : "~/",
        ),
        centerTitle: true,
        actions: [
          if (!isFc)
            IconButton(
              tooltip: "New flashcard",
              icon: Icon(Icons.collections),
              onPressed: () => _onCreateFlashcard(context),
            ),
          if (!isFc)
            IconButton(
              tooltip: "New folder",
              icon: Icon(Icons.create_new_folder),
              onPressed: () => _onCreateFolder(context),
            ),
          // Use a builder to access a context 'under' the scaffold.
          Builder(
            builder: (context) => IconButton(
              tooltip: "Copy $entityName",
              icon: Icon(Icons.copy),
              onPressed:
                  model.canCdUp() ? () => _onCopy(context, entityName) : null,
            ),
          ),
          if (!isFc)
            IconButton(
              tooltip: "Paste",
              icon: Icon(Icons.paste),
              onPressed: model.canPaste ? () => _onPaste(context) : null,
            ),
          if (!isFc)
            Builder(
              builder: (context) => IconButton(
                tooltip: "Change folder colour",
                icon: Icon(Icons.palette),
                onPressed:
                    model.canCdUp() ? () => _onEditFolderColour(context) : null,
              ),
            ),
          IconButton(
            tooltip: "Rename $entityName",
            icon: Icon(Icons.drive_file_rename_outline),
            onPressed: model.canCdUp() ? () => _onRename(context, isFc) : null,
          ),
          IconButton(
            tooltip: "Delete $entityName",
            icon: Icon(Icons.delete),
            onPressed: model.canCdUp() ? () => _onDelete(context, isFc) : null,
          ),
        ],
      ),
      body: files.isFlashcard(model.wd)
          ? _buildFlashcard(context)
          : _buildFolder(),
      floatingActionButton: isFc
          ? null
          : FloatingActionButton(
              tooltip: "Browse flashcards",
              child: Icon(Icons.style),
              onPressed: () => _onBrowseFlashcards(context),
            ),
    );
  }
}
