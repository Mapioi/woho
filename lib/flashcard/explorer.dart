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

/// A file explorer window for flashcards and folders.
class FlashcardExplorer extends StatefulWidget {
  @override
  _FlashcardExplorerState createState() => _FlashcardExplorerState();
}

class _FlashcardExplorerState extends State<FlashcardExplorer> {
  Directory _root;

  /// Asynchronously obtain the application documents directory when this object
  /// is instantiated. Display loading text before the future completes, and use
  /// [FlashcardExplorerModel] after completion.
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

/// The UI part of a [FlashcardExplorer].
///
/// This widget is responsible for rendering the file contents, prompting the
/// user with popup dialogues for certain actions, and invoking appropriate
/// methods from the internal [FlashcardExplorerModel] to perform the actual
/// changes on disk.
///
/// Appbar:
/// * The leading icon is a back arrow which is enabled iff [model.canCdUp];
/// on tap, invoke [model.cdUp] and display the new file contents.
/// * The title is the relative name of [model.wd].
/// * Action buttons include: reload files, create new flashcard, create new
/// folder, copy, paste, change folder colour, rename, delete. When [model.wd]
/// is a flashcard, buttons for functions that are only enabled when [model.wd]
/// is a folder are hidden. When [model.wd] is the root directory, buttons for
/// functions that are only enabled when [model.wd] is not the root directory
/// are disabled.
///
/// Body:
/// * See [_buildFlashcard] and [_buildFolder].
///
/// Floating action button:
/// * See [_onBrowseFlashcards].
///
class _FlashcardExplorerView extends StatelessWidget {
  final FlashcardExplorerModel model;

  _FlashcardExplorerView(this.model);

  /// Build a grid of icon buttons representing folders and flashcards which are
  /// the direct children of the folder [model.wd].
  ///
  /// The icons can be dragged around to alter the order of the contents.
  /// On tapped, [model] navigates to the folder or flashcard represented by the
  /// tapped icon.
  /// If the icon represents a folder, the colour is taken from that folder's
  /// configuration; if the icon represents a flashcard, the colour is red if
  /// the said flashcard is marked today, and decays to black with a half-life
  /// of 30 days.
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

      return GestureDetector(
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

  /// Build the contents of the flashcard [model.wd].
  ///
  /// The contents are: front, back.
  /// On tapped, [_onOpenFront] or [_onOpenBack] is invoked to launch an editor
  /// loaded with that side of the flashcard.
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

  /// Prompt the user with [DirectoryNameDialogue] for the name of the folder
  /// to be created within [model.wd], and create such a folder.
  ///
  /// Only allowed if [model.wd] is a folder.
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

  /// Prompt the user with [DirectoryNameDialogue] for the name of the flashcard
  /// to be created within [model.wd], and create such a flashcard.
  ///
  /// Only allowed if [model.wd] is a folder.
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

  /// Prompt the user with [DirectoryNameDialogue] for the new name of
  /// [model.wd], which can either be a flashcard or a folder, and then rename
  /// it accordingly.
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

  /// Make the user confirm whether he/she wants to delete [model.wd] via
  /// [DeleteAlertDialogue] before deleting this folder/flashcard.
  ///
  /// Only allowed when [model.wd] is different from [model.root].
  void _onDelete(BuildContext context, bool isFc) {
    assert(model.wd.toString() != model.root.toString());
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

  /// Copy [model.wd] onto the clipboard and inform the user with a snackbar.
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

  /// Paste the flashcard/folder on the clipboard into [model.wd].
  ///
  /// Only allowed if [model.wd] is a folder.
  /// If a folder in [model.wd] shares the same name with the directory on the
  /// clipboard, then prompt the user with [DeleteAlertDialogue] before
  /// overwriting the old directory with the one pasted.
  void _onPaste(BuildContext context) {
    assert(!files.isFlashcard(model.wd));
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

  /// Launch a fullscreen editor with the front side of the front side of the
  /// flashcard [model.wd].
  ///
  /// Only allowed if [model.wd] is a flashcard.
  void _onOpenFront(BuildContext context) {
    assert(files.isFlashcard(model.wd));
    launchEditor(context, files.frontSvg(model.wd));
  }

  /// Launch a fullscreen editor with the back side of the front side of the
  /// flashcard [model.wd].
  ///
  /// Only allowed if [model.wd] is a flashcard.
  void _onOpenBack(BuildContext context) {
    assert(files.isFlashcard(model.wd));
    launchEditor(context, files.backSvg(model.wd));
  }

  /// Prompt the user for the new colour of the folder [model.wd] with
  /// [ColourPickerDialogue].
  ///
  /// Only allowed when [model.wd] is a folder.
  void _onEditFolderColour(BuildContext context) {
    assert(!files.isFlashcard(model.wd));
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

  /// Launch a new [FlashcardViewer] screen showing flashcards given by
  /// [files.listFlashcards] called on [model.wd].
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
              ? files.relativeName(model.parentDir, model.wd)
              : "~/",
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: "Reload files",
            icon: Icon(Icons.refresh),
            onPressed: model.reset,
          ),
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
