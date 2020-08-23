import 'dart:collection';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class Stroke {
  final Color color;
  final double strokeWidth;
  final List<Offset> _offsets = [];

  Stroke({
    @required this.color,
    @required this.strokeWidth,
  });

  UnmodifiableListView<Offset> get offsets => UnmodifiableListView(_offsets);

  void add(Offset offset) => _offsets.add(offset);
}

class WhiteboardModel extends ChangeNotifier {
  final List<Stroke> _strokes = <Stroke>[];
  var _currentStroke;

  Color get color => Colors.deepPurple;

  double get strokeWidth => 2.5;

  UnmodifiableListView<Stroke> get strokes => UnmodifiableListView(_strokes);

  void onPointerDown(PointerDownEvent event) {
    // Only accept stylus input to achieve palm rejection
    if (event.kind == PointerDeviceKind.stylus) {
      _currentStroke = Stroke(
        color: color,
        strokeWidth: strokeWidth,
      );
      _currentStroke.add(event.localPosition);
      _strokes.add(_currentStroke);
      notifyListeners();
    }
  }

  void onPointerMove(PointerMoveEvent event) {
    if (event.kind == PointerDeviceKind.stylus) {
      _currentStroke.add(event.localPosition);
      notifyListeners();
    }
  }

  void onPointerUp(PointerUpEvent event) {
    if (event.kind == PointerDeviceKind.stylus) {
      _currentStroke = null;
      notifyListeners();
    }
  }
}
