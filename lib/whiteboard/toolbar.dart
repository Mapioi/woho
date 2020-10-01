import 'package:flutter/material.dart';
import './model.dart';

/// The leading close button on the top left of the app bar.
///
/// Launches an alert dialog if the changes have not been saved.
Widget closeButton(BuildContext context, WhiteboardModel model) {
  return IconButton(
    icon: Icon(Icons.close),
    onPressed: model.isSaved()
        ? () => Navigator.of(context).pop()
        : () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text("Unsaved Changes"),
                content: Text("Do you want to discard unsaved changes?"),
                actions: <Widget>[
                  FlatButton(
                    child: Text("No"),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  FlatButton(
                    child: Text(
                      "Yes",
                      style: TextStyle(color: Colors.redAccent),
                    ),
                    onPressed: () {
                      // Pop alert dialog.
                      Navigator.of(context).pop();
                      // Pop editor page.
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            );
          },
  );
}

List<Widget> toolbarButtons(BuildContext context, WhiteboardModel model) {
  final strokeWidthDropdown = DropdownButton<double>(
    items: WhiteboardModel.strokeWidthChoices[model.tool].map((w) {
      final strokeWidthDisplay = Text(
        "$w px",
        style: TextStyle(
          color: Theme.of(context).accentTextTheme.bodyText1.color,
        ),
      );

      return DropdownMenuItem<double>(
        child: strokeWidthDisplay,
        value: w,
      );
    }).toList(),
    value: model.strokeWidth,
    onChanged: (newStrokeWidth) => model.strokeWidth = newStrokeWidth,
    iconEnabledColor: Theme.of(context).buttonColor,
    dropdownColor: Theme.of(context).accentColor,
  );

  final colorDropdown = DropdownButton<Color>(
    items: WhiteboardModel.colorChoices[model.tool].map((c) {
      final colorDisplay = Container(
        child: Icon(
          Icons.lens,
          color: c,
        ),
        color: Theme.of(context).canvasColor,
      );

      return DropdownMenuItem(
        child: colorDisplay,
        value: c,
      );
    }).toList(),
    value: model.color,
    onChanged: (newColor) => model.color = newColor,
    iconEnabledColor: Theme.of(context).buttonColor,
    dropdownColor: Theme.of(context).accentColor,
  );

  Widget makeToolButton(Tool tool) {
    return IconButton(
      tooltip: tool.toString().split('.')[1],
      icon: Icon(WhiteboardModel.toolIcons[tool]),
      onPressed: model.tool == tool
          ? null
          : () {
              model.tool = tool;
            },
      color: Theme.of(context).backgroundColor,
      disabledColor: Theme.of(context).canvasColor,
    );
  }

  final saveButton = IconButton(
    tooltip: "Save changes",
    icon: Icon(Icons.save),
    onPressed: model.isSaved() ? null : model.save,
  );

  final undoButton = IconButton(
    tooltip: "Undo change",
    icon: Icon(Icons.undo),
    onPressed: model.canUndo() ? model.undo : null,
  );

  final redoButton = IconButton(
    tooltip: "Redo change",
    icon: Icon(Icons.redo),
    onPressed: model.canRedo() ? model.redo : null,
  );

  final buttons = <Widget>[
    saveButton,
    strokeWidthDropdown,
    colorDropdown,
    ...Tool.values.map(makeToolButton),
    undoButton,
    redoButton
  ];

  final paddedButtons = buttons.map((w) {
    return Padding(
      padding: EdgeInsets.only(right: 20.0),
      child: Container(
        child: w,
      ),
    );
  }).toList();

  return paddedButtons;
}
