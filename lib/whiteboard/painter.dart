import 'package:flutter/material.dart';
import './model.dart';

class WhiteboardPainter extends CustomPainter {
  final WhiteboardModel _model;
  final Color _canvasColor;

  WhiteboardPainter(this._model, this._canvasColor);

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
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = stroke.strokeWidth
        ..style = PaintingStyle.stroke;

      if (stroke.isErasing) {
        paint.color = _canvasColor;
      } else {
        paint.color = stroke.color;
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
