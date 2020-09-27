import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';

typedef DirectoryCallback = void Function(Directory);
typedef ColorCallback = void Function(Color);

class DirectoryNameDialogue extends StatefulWidget {
  final Directory root;
  final Widget title;
  final String hintText;
  final DirectoryCallback onDone;

  const DirectoryNameDialogue({
    Key key,
    @required this.root,
    @required this.title,
    @required this.hintText,
    @required this.onDone,
  }) : super(key: key);

  @override
  _DirectoryNameDialogueState createState() => _DirectoryNameDialogueState();
}

enum DirectoryNameStatus {
  alreadyExists,
  containsSlash,
  empty,
  ok,
}

class _DirectoryNameDialogueState extends State<DirectoryNameDialogue> {
  String _input = "";
  DirectoryNameStatus _status = DirectoryNameStatus.empty;

  Directory get _directory => Directory(widget.root.path + "/" + _input);

  String get _errorText {
    switch (_status) {
      case DirectoryNameStatus.alreadyExists:
        return "$_input already exists.";
      case DirectoryNameStatus.empty:
        return "Name must not be empty.";
      case DirectoryNameStatus.containsSlash:
        return "Name must not contain '/'.";
      case DirectoryNameStatus.ok:
        return null;
    }
    return "Unexpected error";
  }

  void _onInputChange(String newInput) {
    final newDirectory = Directory(widget.root.path + "/" + newInput);
    DirectoryNameStatus status;
    if (newInput.isEmpty) {
      status = DirectoryNameStatus.empty;
    } else if (newInput.contains('/')) {
      status = DirectoryNameStatus.containsSlash;
    } else if (newDirectory.existsSync()) {
      status = DirectoryNameStatus.alreadyExists;
    } else {
      status = DirectoryNameStatus.ok;
    }
    setState(() {
      _input = newInput;
      _status = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: widget.title,
      content: TextField(
        autofocus: true,
        decoration: InputDecoration(
          hintText: widget.hintText,
          errorText: _errorText,
        ),
        keyboardType: TextInputType.text,
        onChanged: _onInputChange,
        onEditingComplete: () {
          if (_status == DirectoryNameStatus.ok) {
            Navigator.pop(context);
            widget.onDone(_directory);
          }
        },
      ),
    );
  }
}

class DeleteAlertDialogue extends StatelessWidget {
  final String titleText;
  final String deleteButtonText;
  final VoidCallback onConfirmDelete;

  const DeleteAlertDialogue({
    Key key,
    @required this.titleText,
    @required this.deleteButtonText,
    @required this.onConfirmDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(titleText),
      actions: [
        FlatButton(
          child: Text("Cancel"),
          onPressed: () => Navigator.pop(context),
        ),
        FlatButton(
          child: Text(
            deleteButtonText,
            style: TextStyle(color: Colors.redAccent),
          ),
          onPressed: () {
            onConfirmDelete();
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}

class ColourPickerDialogue extends StatelessWidget {
  final Color initialColour;
  final ColorCallback onDone;

  const ColourPickerDialogue({
    Key key,
    this.initialColour,
    this.onDone,
  }) : super(key: key);

  Widget _buildCell(BuildContext context, Color color) {
    final isChosen = initialColour.value == color.value;
    return InkWell(
      child: Padding(
        padding: const EdgeInsets.all(1.0),
        child: Transform.rotate(
          child: Container(
            width: 25,
            height: 25,
            color: color,
          ),
          angle: isChosen ? pi/4 : 0,
        ),
      ),
      onTap: () {
        onDone(color);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildRow(BuildContext context, ColorSwatch swatch) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        swatch[50],
        swatch[100],
        swatch[200],
        swatch[300],
        swatch[400],
        swatch,
        swatch[600],
        swatch[700],
        swatch[800],
        swatch[900],
      ].map((c) => _buildCell(context, c)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Colors.pink,
          Colors.red,
          Colors.deepOrange,
          Colors.orange,
          Colors.amber,
          Colors.yellow,
          Colors.lime,
          Colors.lightGreen,
          Colors.green,
          Colors.teal,
          Colors.cyan,
          Colors.lightBlue,
          Colors.blue,
          Colors.indigo,
          Colors.purple,
          Colors.blueGrey,
          Colors.brown,
          Colors.grey,
        ].map((c) => _buildRow(context, c)).toList(),
      ),
    );
  }
}
