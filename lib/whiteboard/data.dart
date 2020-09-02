import 'dart:collection';
import 'dart:math';
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

  void addPath(String path) {
    var i = 0;
    double x, y;
    for (final s in path.split(" ")) {
      if (i % 3 == 0) {
        assert(s == 'M' || s == 'L');
      } else if (i % 3 == 1) {
        x = double.parse(s);
      } else {
        y = double.parse(s);
        _offsets.add(Offset(x, y));
      }

      i += 1;
    }
  }
}

// TODO merge with view
class WhiteboardData {
  Size _size;
  final List<Stroke> strokes;

  WhiteboardData(this._size, this.strokes);

  WhiteboardDataView get view => WhiteboardDataView(
        _size,
        UnmodifiableListView(strokes),
      );

  /// From (a subset of) a svg, where we only accept paths and masks for erasing
  factory WhiteboardData.fromSvg(XmlDocument document) {
    Color fromHex(String hex) {
      assert(hex.length == 7 && hex[0] == '#');
      final r = int.parse(hex.substring(1, 3), radix: 16);
      final g = int.parse(hex.substring(3, 5), radix: 16);
      final b = int.parse(hex.substring(5, 7), radix: 16);
      return Color.fromRGBO(r, g, b, 1.0);
    }

    final svg = document.getElement('svg');
    assert(svg != null);
    final viewBox = svg.getAttribute('viewbox').split(" ");
    assert(viewBox.length == 4);
    final width = double.parse(viewBox[2]);
    final height = double.parse(viewBox[3]);

    final strokes = <Stroke>[];
    final eraserStrokes = <int, Stroke>{};
    for (final mask in svg.findElements('mask')) {
      final idString = mask.getAttribute('id');
      final id = int.parse(idString.split('eraser')[1]);
      if (id != 0) {
        final path = mask.getElement('path');
        final strokeWidth = double.parse(path.getAttribute('stroke-width'));
        final eraserStroke = Stroke(
          color: null,
          isErasing: true,
          strokeWidth: strokeWidth,
        );
        eraserStroke.addPath(path.getAttribute('d'));
        eraserStrokes[id] = eraserStroke;
      }
    }
    var iEraser = eraserStrokes.length;
    for (final path in svg.findElements('path')) {
      final color = fromHex(path.getAttribute('stroke'));
      final strokeWidth = double.parse(path.getAttribute('stroke-width'));
      final stroke = Stroke(
        color: color,
        isErasing: false,
        strokeWidth: strokeWidth,
      );
      stroke.addPath(path.getAttribute('d'));
      final maskUrl = path.getAttribute('mask');
      final maskId = int.parse(maskUrl.split('url(#eraser')[1].split(')')[0]);
      assert(maskUrl == "url(#eraser$maskId)");
      assert(maskId <= iEraser);
      while (iEraser > max(1, maskId)) {
        strokes.add(eraserStrokes[iEraser]);
        iEraser -= 1;
      }
      strokes.add(stroke);
    }
    while (iEraser > 0) {
      strokes.add(eraserStrokes[iEraser]);
      iEraser -= 1;
    }

    return WhiteboardData(
      Size(width, height),
      strokes,
    );
  }
}

/// Unmodifiable view of whiteboard data
class WhiteboardDataView {
  final Size size;
  final UnmodifiableListView<Stroke> strokes;

  WhiteboardDataView(this.size, this.strokes);

  XmlDocument toSvg() {
    /// Convert Color instance to hex string
    String hex(Color c) {
      final r = c.red.toRadixString(16).padLeft(2, '0');
      final g = c.green.toRadixString(16).padLeft(2, '0');
      final b = c.blue.toRadixString(16).padLeft(2, '0');
      return "#$r$g$b";
    }

    /// Convert list of offsets to line commands drawing the line
    String lineCommands(List<Offset> offsets) {
      final buffer = new StringBuffer();
      assert(offsets.isNotEmpty);
      final offset0 = offsets.first;
      buffer.write('M ${offset0.dx} ${offset0.dy}');
      for (final offset in offsets) {
        buffer.write(' L ${offset.dx} ${offset.dy}');
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
