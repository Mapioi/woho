import 'dart:collection';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

/// A pen or eraser stroke.
class Stroke {
  /// The fill colour of this stroke.
  ///
  /// If [isErasing] is true, [color] is ignored and can/should be null.
  Color color;
  bool isErasing;
  double strokeWidth;

  /// The coordinates that the tip of the pen/eraser passes through, used to
  /// produce this stroke via linear interpolation.
  List<Offset> offsets = [];

  Stroke({
    @required this.color,
    @required this.isErasing,
    @required this.strokeWidth,
  });

  /// Adds the points specified in the d attribute to this stroke.
  ///
  /// The d attribute must only contain space-delimited commands, starting with
  /// a MoveTo 'M $x $y' command followed by only LineTo 'L $x $y' commands,
  /// where x and y are doubles.
  ///
  /// ```dart
  /// Stroke s = Stroke(color: null, isErasing: true, strokeWidth: 1.0);
  /// s.addSvgPath("M 524.5 118.5 L 524.5 118.5 L 524.5 118.5");
  /// s.offsets.length == 3
  /// ```
  void addSvgPath(String path) {
    final params = path.split(" ");
    double x, y;
    assert(params[0] == 'M');
    final x0 = double.parse(params[1]);
    final y0 = double.parse(params[2]);
    for (var i = 3; i < params.length; i += 1) {
      final s = params[i];
      if (i % 3 == 0) {
        assert(s == 'L');
      } else if (i % 3 == 1) {
        x = double.parse(s);
        if (i == 4) assert(x == x0);
      } else {
        y = double.parse(s);
        if (i == 5) assert(y == y0);
        offsets.add(Offset(x, y));
      }
    }
  }
}

/// An unmodifiable [Stroke] view of another [Stroke].
///
/// This class exposes only getters; it is not possible to mutate the fields of
/// the underlying [_stroke] of this view via the returned values.
class UnmodifiableStrokeView {
  final Stroke _stroke;

  UnmodifiableStrokeView(this._stroke);

  Color get color => _stroke.color;

  bool get isErasing => _stroke.isErasing;

  double get strokeWidth => _stroke.strokeWidth;

  UnmodifiableListView<Offset> get offsets =>
      UnmodifiableListView(_stroke.offsets);
}

/// A container for the [Size] of the whiteboard and the [Stroke]s on it.
class WhiteboardData {
  Size size;
  List<Stroke> strokes;
  String title;

  WhiteboardData(this.size, this.strokes, {this.title});

  /// Generates an svg document that produces the same image as painted by a
  /// [WhiteboardPainter].
  ///
  /// * The dimension of the svg's `viewBox` is set to [size];
  /// * Pen strokes are represented by svg paths specified by line commands,
  /// with the attributes `stroke`, `stroke-width` set to [Stroke.color] and
  /// [Stroke.strokeWidth];
  /// * The effects of the erasing strokes are achieved via masks (see below for
  /// a more detailed explanation).
  XmlDocument get svg {
    // Utility functions
    // Convert Color instance to hex string
    String hex(Color c) {
      final r = c.red.toRadixString(16).padLeft(2, '0');
      final g = c.green.toRadixString(16).padLeft(2, '0');
      final b = c.blue.toRadixString(16).padLeft(2, '0');
      return "#$r$g$b";
    }

    // Convert list of offsets to line commands drawing the stroke
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
      builder.attribute('viewBox', "0 0 ${size.width} ${size.height}");
      builder.attribute('xmlns', "http://www.w3.org/2000/svg");

      // Title
      if (title != null) {
        builder.element('text', nest: () {
          final phi = (1 + sqrt(5)) / 2;

          final x = size.width / 2;
          final y = size.height * phi / (1 + phi);
          builder.attribute('x', x);
          builder.attribute('y', y);
          builder.attribute('font-size', 64);
          builder.attribute('text-anchor', 'middle');

          builder.text(title);
        });
      }

      // Suppose that we have painted the strokes p_1, p_2, e_1, p_3, e_2 in
      // this order, where p_i is a pen stroke and e_j is an erasing stroke.
      // Then we see that the strokes p_1 and p_2 are masked by both e_1 and
      // e_2, whilst the stroke p_3 is only masked by e_2.
      // We therefore build up the eraser masks by iterating through the erasing
      // strokes in reverse order: the initial mask m_0 doesn't mask anything;
      // the next mask m_1 masks out the stroke e_2 on top of m_0, and is
      // applied to p_3; the last mask m_2 masks the stroke e_1 on top of m_1,
      // and is applied to p_1 and p_2.
      // First we construct the masks as described above:
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

          // Mask out current eraser stroke
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

      // Now we add the pen strokes, while applying appropriate eraser masks:
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
      // Draw the remaining pen strokes which aren't covered by eraser strokes
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

  /// Parses a svg generated by the svg getter method.
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
    final viewBox = svg.getAttribute('viewBox').split(" ");
    assert(viewBox.length == 4);
    assert(viewBox[0] == '0' && viewBox[1] == '0');
    final width = double.parse(viewBox[2]);
    final height = double.parse(viewBox[3]);

    // Construct the erasing strokes from the masks
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
        eraserStroke.addSvgPath(path.getAttribute('d'));
        eraserStrokes[id] = eraserStroke;
      }
    }

    // Draw the eraser strokes when the mask changes, and then the pen strokes
    var iEraser = eraserStrokes.length;
    for (final path in svg.findElements('path')) {
      final color = fromHex(path.getAttribute('stroke'));
      final strokeWidth = double.parse(path.getAttribute('stroke-width'));
      final stroke = Stroke(
        color: color,
        isErasing: false,
        strokeWidth: strokeWidth,
      );
      stroke.addSvgPath(path.getAttribute('d'));
      final maskUrl = path.getAttribute('mask');
      final maskId = int.parse(maskUrl.split('url(#eraser')[1].split(')')[0]);
      assert(maskUrl == "url(#eraser$maskId)");
      assert(maskId <= iEraser);
      while (iEraser > maskId) {
        strokes.add(eraserStrokes[iEraser]);
        iEraser -= 1;
      }
      strokes.add(stroke);
    }
    // Draw the remaining eraser strokes covering all pen strokes
    while (iEraser > 0) {
      strokes.add(eraserStrokes[iEraser]);
      iEraser -= 1;
    }

    String title;
    final texts = svg.findElements('text');
    assert(texts.length <= 1);
    if (texts.isNotEmpty) {
      title = texts.first.text;
    }

    return WhiteboardData(
      Size(width, height),
      strokes,
      title: title,
    );
  }

  /// Returns a scaled copy of this image that fits in [newSize].
  ///
  /// * Preserves aspect ratio, so scales to the minimum between the width ratio
  /// and the height ratio;
  /// * strokeWidths and each offset (representing the distance from the origin)
  /// are scaled by this ratio;
  /// * leaves this instance unchanged.
  WhiteboardData fit(Size newSize) {
    final widthRatio = newSize.width / size.width;
    final heightRatio = newSize.height / size.height;
    final ratio = min(widthRatio, heightRatio);

    final data = WhiteboardData(
      newSize,
      strokes.map((stroke) {
        final resizedStroke = Stroke(
          color: stroke.color,
          isErasing: stroke.isErasing,
          strokeWidth: stroke.strokeWidth * ratio,
        );
        for (final offset in stroke.offsets) {
          resizedStroke.offsets.add(Offset(
            offset.dx * ratio,
            offset.dy * ratio,
          ));
        }
        return resizedStroke;
      }).toList(),
      title: title,
    );
    return data;
  }
}

/// An unmodifiable [WhiteboardData] view of another WhiteboardData instance.
///
/// This class exposes only getters; it is not possible to mutate the fields of
/// the underlying [_data] of this view via the returned values. In particular,
/// each [Stroke] in the [strokes] are encapsulated by [UnmodifiableStrokeView].
class UnmodifiableWhiteboardDataView {
  final WhiteboardData _data;

  UnmodifiableWhiteboardDataView(this._data);

  Size get size => _data.size;

  UnmodifiableListView<UnmodifiableStrokeView> get strokes =>
      UnmodifiableListView(
        _data.strokes.map((stroke) => UnmodifiableStrokeView(stroke)),
      );

  String get title => _data.title;

  XmlDocument get svg => _data.svg;
}
