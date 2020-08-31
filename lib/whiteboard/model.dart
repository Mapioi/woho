import 'dart:collection';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:xml/xml.dart';
import './history.dart';

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

enum Tool {
  pen,
  eraser,
}

class WhiteboardModel extends ChangeNotifier with Undoable {
  final List<Stroke> _strokes = <Stroke>[];
  Stroke _currentStroke;
  Tool _tool = Tool.pen;

  static final defaultColors = UnmodifiableMapView({
    Tool.pen: Colors.blueAccent,
    Tool.eraser: null,
  });

  static final colorChoices = UnmodifiableMapView({
    Tool.pen: UnmodifiableListView([
      Colors.red,
      Colors.blueAccent,
      Colors.black,
      Colors.grey,
    ]),
    Tool.eraser: UnmodifiableListView(<Color>[]),
  });

  static final defaultStrokeWidths = UnmodifiableMapView({
    Tool.pen: 2.0,
    Tool.eraser: 20.0,
  });

  static final strokeWidthChoices = UnmodifiableMapView({
    Tool.pen: UnmodifiableListView([
      1.0,
      2.0,
      5.0,
      10.0,
      20.0,
    ]),
    Tool.eraser: UnmodifiableListView([
      5.0,
      10.0,
      20.0,
      50.0,
      100.0,
    ]),
  });

  static final toolIcons = UnmodifiableMapView({
    Tool.pen: Icons.create,
    Tool.eraser: Icons.cleaning_services,
  });

  Map<Tool, double> _strokeWidths = Map.fromIterable(
    Tool.values,
    key: (t) => t,
    value: (t) => defaultStrokeWidths[t],
  );

  Map<Tool, Color> _colors = Map.fromIterable(
    Tool.values,
    key: (t) => t,
    value: (t) => defaultColors[t],
  );

  Color get color => _colors[_tool];

  set color(newColor) {
    _colors[_tool] = newColor;
    notifyListeners();
  }

  double get strokeWidth => _strokeWidths[_tool];

  set strokeWidth(newStrokeWidth) {
    _strokeWidths[_tool] = newStrokeWidth;
    notifyListeners();
  }

  UnmodifiableListView<Stroke> get strokes => UnmodifiableListView(_strokes);

  Tool get tool => _tool;

  set tool(newTool) {
    _tool = newTool;
    notifyListeners();
  }

  void onPointerDown(PointerDownEvent event) {
    // Only accept stylus input to achieve palm rejection
    if (event.kind == PointerDeviceKind.stylus) {
      if (_tool == Tool.pen || _tool == Tool.eraser) {
        _currentStroke = Stroke(
          color: color,
          isErasing: _tool == Tool.eraser,
          strokeWidth: strokeWidth,
        );
        _currentStroke.add(event.localPosition);
        execute(Command(() {
          _strokes.add(_currentStroke);
          notifyListeners();

          final i = _strokes.length - 1;
          final strokeRef = _currentStroke; // (Ab)using the mutable stroke
          return Change(
            undo: () {
              _strokes.remove(strokeRef);
              assert(!_strokes.contains(strokeRef));
              notifyListeners();
            },

            redo: () {
              _strokes.insert(i, strokeRef);
              notifyListeners();
            },
          );
        }));
      }
    }
  }

  void onPointerMove(PointerMoveEvent event) {
    if (event.kind == PointerDeviceKind.stylus) {
      if (_tool == Tool.pen || _tool == Tool.eraser) {
        _currentStroke.add(event.localPosition);
        notifyListeners();
      }
    }
  }

  void onPointerUp(PointerUpEvent event) {
    if (event.kind == PointerDeviceKind.stylus) {
      if (_tool == Tool.pen || _tool == Tool.eraser) {
        _currentStroke = null;
        notifyListeners();
      }
    }
  }

  String toSvg(Size size) {
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

      // Build up the eraser masks by iterating through the strokes in reverse
      // order, since erasing strokes only apply to previously drawn strokes.
      var iEraser = 0;
      final eraserStrokes = _strokes.where((stroke) => stroke.isErasing);
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
      for (final stroke in _strokes) {
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

    return builder.buildDocument().toXmlString();
  }
}
