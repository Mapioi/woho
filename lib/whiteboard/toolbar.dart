import 'package:flutter/material.dart';
import './model.dart';

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

  final printSvgButton = IconButton(
    icon: Icon(Icons.print),
    onPressed: () {
      // TODO get the actuel canvas size
      print(model.toSvg(Size(1366, 1024)));
    },
  );

  final undoButton = IconButton(
    icon: Icon(Icons.undo),
    onPressed: model.canUndo() ? model.undo : null,
  );

  final redoButton = IconButton(
    icon: Icon(Icons.redo),
    onPressed: model.canRedo() ? model.redo : null,
  );

  final buttons = <Widget>[printSvgButton, strokeWidthDropdown, colorDropdown]
    ..addAll(Tool.values.map(makeToolButton))
    ..addAll([undoButton, redoButton]);

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
