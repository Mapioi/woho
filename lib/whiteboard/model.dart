import 'dart:collection';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

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

class WhiteboardModel extends ChangeNotifier {
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
        _strokes.add(_currentStroke);
        notifyListeners();
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
}
