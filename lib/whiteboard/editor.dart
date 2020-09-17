import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './model.dart';
import './painter.dart';
import './toolbar.dart';

/// A whiteboard widget that supports editing.
///
/// ```dart
/// MaterialPageRoute(
///   builder: (context) => ChangeNotifierProvider(
///     create: (context) => WhiteboardModel(data),
///     child: WhiteboardEditor(),
///   ),
///   fullscreenDialog: true,
/// )
/// ```
class WhiteboardEditor extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<WhiteboardModel>(builder: (context, model, child) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Edit Flashcard"),
          actions: toolbarButtons(context, model),
          leading: closeButton(context, model),
        ),
        body: Listener(
          child: CustomPaint(
            size: MediaQuery.of(context).size,
            painter: WhiteboardPainter(
              model.data,
              eraserCircleCenter: model.eraserCursorPosition,
              eraserCircleRadius:
                  model.tool == Tool.eraser ? model.strokeWidth / 2 : null,
            ),
          ),
          onPointerDown: model.onPointerDown,
          onPointerMove: model.onPointerMove,
          onPointerUp: model.onPointerUp,
        ),
      );
    });
  }
}
