import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import './data.dart';

class WhiteboardPainter extends CustomPainter {
  final UnmodifiableWhiteboardDataView _data;

  WhiteboardPainter(this._data);

  @override
  void paint(Canvas canvas, Size size) {
    if (_data.title != null) {
      final phi = (1 + sqrt(5)) / 2;

      final tp = TextPainter(
        text: TextSpan(
          text: _data.title,
          style: TextStyle(color: Colors.black),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        textScaleFactor: 5,
      );
      tp.layout();
      tp.paint(
        canvas,
        Offset(
          (size.width - tp.width) / 2,
          (size.height - tp.height) / (1 + phi),
        ),
      );
    }

    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    for (final stroke in _data.strokes) {
      final path = Path();
      assert(stroke.offsets.isNotEmpty);
      final offset0 = stroke.offsets.first;
      path.moveTo(offset0.dx, offset0.dy);
      // Note that first a line is drawn from offset0 to itself, so that a
      // stroke with one single offset (a point) will be rendered too.
      for (final offset in stroke.offsets) {
        path.lineTo(offset.dx, offset.dy);
      }

      final paint = Paint()
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = stroke.strokeWidth
        ..style = PaintingStyle.stroke;

      if (stroke.isErasing) {
        paint.blendMode = BlendMode.clear;
      } else {
        paint.color = stroke.color;
      }
      canvas.drawPath(path, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
