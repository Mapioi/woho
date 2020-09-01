import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './model.dart';
import './painter.dart';
import './toolbar.dart';

class WhiteboardEditor extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<WhiteboardModel>(builder: (context, model, child) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Edit Flashcard"),
          actions: toolbarButtons(context, model),
        ),
        body: Listener(
          child: CustomPaint(
            size: MediaQuery.of(context).size,
            painter: WhiteboardPainter(model.data),
          ),
          onPointerDown: model.onPointerDown,
          onPointerMove: model.onPointerMove,
          onPointerUp: model.onPointerUp,
        ),
      );
    });
  }
}
