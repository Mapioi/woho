import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import './data.dart';

class WhiteboardPainter extends CustomPainter {
  final UnmodifiableWhiteboardDataView _data;
  final Offset eraserCircleCenter;
  final double eraserCircleRadius;

  WhiteboardPainter(
    this._data, {
    this.eraserCircleCenter,
    this.eraserCircleRadius,
  });

  WhiteboardPainter.fromMutable(
    WhiteboardData data, {
    this.eraserCircleCenter,
    this.eraserCircleRadius,
  }) : _data = UnmodifiableWhiteboardDataView(data);

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
        textScaleFactor: 5 * size.height / 1024,
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

    // Shows the current erasing cursor
    if (eraserCircleCenter != null && eraserCircleRadius != null) {
      final eraserCirclePaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(
        eraserCircleCenter,
        eraserCircleRadius,
        eraserCirclePaint,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
