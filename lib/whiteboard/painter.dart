import 'package:flutter/material.dart';
import './model.dart';

class WhiteboardPainter extends CustomPainter {
  final WhiteboardModel _model;

  WhiteboardPainter(this._model);

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in _model.strokes) {
      final path = Path();
      if (stroke.offsets.isNotEmpty) {
        final offset0 = stroke.offsets.first;
        path.moveTo(offset0.dx, offset0.dy);
      }
      for (final offset in stroke.offsets) {
        path.lineTo(offset.dx, offset.dy);
      }

      final paint = Paint()
        ..color = stroke.color
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = stroke.strokeWidth
        ..style = PaintingStyle.stroke;

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
