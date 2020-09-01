import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

class Stroke {
  final Color color;
  final bool isErasing;
  final double strokeWidth;
  final List<Offset> _offsets = [];

  Stroke({
    @required this.color,
    @required this.isErasing,
    @required this.strokeWidth,
  });

  UnmodifiableListView<Offset> get offsets => UnmodifiableListView(_offsets);

  void add(Offset offset) => _offsets.add(offset);
}

class WhiteboardData {
  Size _size;
  final List<Stroke> strokes;

  WhiteboardData(this._size, this.strokes);

  WhiteboardDataView get view => WhiteboardDataView(
        _size,
        UnmodifiableListView(strokes),
      );
}

/// Unmodifiable view of whiteboard data
class WhiteboardDataView {
  final Size size;
  final UnmodifiableListView<Stroke> strokes;

  WhiteboardDataView(this.size, this.strokes);

  XmlDocument toSvg() {
    /// Convert Color instance to hex string
    String hex(Color c) {
      final r = c.red.toRadixString(16);
      final g = c.green.toRadixString(16);
      final b = c.blue.toRadixString(16);
      return "#$r$g$b";
    }

    /// Convert list of offsets to line commands drawing the line
    String lineCommands(List<Offset> offsets) {
      final buffer = new StringBuffer();
      assert(offsets.isNotEmpty);
      final offset0 = offsets.first;
      buffer.write('M ${offset0.dx} ${offset0.dy} ');
      for (final offset in offsets) {
        buffer.write('L ${offset.dx} ${offset.dy} ');
      }
      return buffer.toString();
    }

    String eraserMaskId(int n) => "eraser$n";

    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8" standalone="no"');
    builder.element('svg', nest: () {
      builder.attribute('viewbox', "0 0 ${size.width} ${size.height}");
      builder.attribute('xmlns', "http://www.w3.org/2000/svg");

      // Build up the eraser masks by iterating through the strokes in reverse
      // order, since erasing strokes only apply to previously drawn strokes.
      var iEraser = 0;
      final eraserStrokes = strokes.where((stroke) => stroke.isErasing);
      builder.element('mask', nest: () {
        builder.attribute('id', eraserMaskId(iEraser));
        // Initial mask keeps everything visible
        builder.element('rect', nest: () {
          builder.attribute('x', 0);
          builder.attribute('y', 0);
          builder.attribute('width', size.width);
          builder.attribute('height', size.height);
          // Everything under white pixels are visible
          builder.attribute('fill', "white");
        });
      });
      for (final eraserStroke in eraserStrokes.toList().reversed) {
        iEraser += 1;
        builder.element('mask', nest: () {
          builder.attribute('id', eraserMaskId(iEraser));
          builder.element('rect', nest: () {
            builder.attribute('x', 0);
            builder.attribute('y', 0);
            builder.attribute('width', size.width);
            builder.attribute('height', size.height);
            builder.attribute('fill', "white");
            // Apply previous mask
            builder.attribute('mask', "url(#${eraserMaskId(iEraser - 1)})");
          });

          // Add current eraser stroke
          builder.element('path', nest: () {
            builder.attribute('d', lineCommands(eraserStroke.offsets));
            builder.attribute('fill', "transparent");
            // Everything under black pixels are invisible
            builder.attribute('stroke', "black");
            builder.attribute('stroke-width', eraserStroke.strokeWidth);
            builder.attribute('stroke-linecap', "round");
            builder.attribute('stroke-linejoin', "round");
          });
        });
      }
      assert(iEraser == eraserStrokes.length);

      // Draw all strokes, while applying appropriate eraser masks
      final eraserMaskedStrokes = <Stroke>[];
      for (final stroke in strokes) {
        if (stroke.isErasing) {
          for (final maskedStroke in eraserMaskedStrokes) {
            builder.element('path', nest: () {
              builder.attribute('d', lineCommands(maskedStroke.offsets));
              builder.attribute('fill', "transparent");
              builder.attribute('stroke', hex(maskedStroke.color));
              builder.attribute('stroke-width', maskedStroke.strokeWidth);
              builder.attribute('stroke-linecap', "round");
              builder.attribute('stroke-linejoin', "round");
              builder.attribute('mask', "url(#${eraserMaskId(iEraser)})");
            });
          }
          eraserMaskedStrokes.clear();
          // "Peel away" this eraser stroke, since the later strokes write over
          // the current eraser stroke.
          iEraser -= 1;
        } else {
          eraserMaskedStrokes.add(stroke);
        }
      }
      assert(iEraser == 0);
      for (final maskedStroke in eraserMaskedStrokes) {
        builder.element('path', nest: () {
          builder.attribute('d', lineCommands(maskedStroke.offsets));
          builder.attribute('fill', "transparent");
          builder.attribute('stroke', hex(maskedStroke.color));
          builder.attribute('stroke-width', maskedStroke.strokeWidth);
          builder.attribute('stroke-linecap', "round");
          builder.attribute('stroke-linejoin', "round");
          builder.attribute('mask', "url(#${eraserMaskId(iEraser)})");
        });
      }
    });

    return builder.buildDocument();
  }
}
