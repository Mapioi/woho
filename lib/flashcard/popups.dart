import 'dart:io';
import 'package:flutter/material.dart';

typedef DirectoryCallback = Function(Directory);

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
