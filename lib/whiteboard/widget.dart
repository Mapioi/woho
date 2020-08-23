import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './model.dart';
import './painter.dart';

class WhiteboardEditor extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [],
      ),
      body: Consumer<WhiteboardModel>(
        builder: (context, model, child) {
          return Listener(
            child: CustomPaint(
              size: MediaQuery.of(context).size,
              painter: WhiteboardPainter(model),
            ),
            onPointerDown: model.onPointerDown,
            onPointerMove: model.onPointerMove,
            onPointerUp: model.onPointerUp,
          );
        },
      ),
    );
  }
}
