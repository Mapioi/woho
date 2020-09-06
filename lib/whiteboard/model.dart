import 'dart:collection';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import './history.dart';
import './data.dart';

enum Tool {
  /// Produces a pen stroke following the stylus position with
  /// [WhiteboardModel.strokeWidth] and [WhiteboardModel.color].
  pen,

  /// Produces an erasing stroke (essentially a white/transparentising stroke)
  /// following the stylus position with [WhiteboardModel.strokeWidth].
  eraser,
}

/// A model for WhiteboardEditor, which stores the currently selected stroke
/// width and colour for each tool along with the available options, and handles
/// stylus pointer down, move and up events.
class WhiteboardModel extends ChangeNotifier with Undoable {
  /// Create a whiteboard rendering the data.
  ///
  /// It is assumed that [_data]'s dimension fits inside the canvas size.
  WhiteboardModel(this._data);

  WhiteboardModel.empty(Size size) : _data = WhiteboardData(size, []);

  final WhiteboardData _data;
  Stroke _currentStroke;
  Tool _tool = Tool.pen;

  UnmodifiableWhiteboardDataView get data =>
      UnmodifiableWhiteboardDataView(_data);

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
        _currentStroke.offsets.add(event.localPosition);
        execute(Command(() {
          _data.strokes.add(_currentStroke);
          notifyListeners();

          final i = _data.strokes.length - 1;
          final strokeRef = _currentStroke; // (Ab)using the mutable stroke
          return Change(
            undo: () {
              _data.strokes.remove(strokeRef);
              assert(!_data.strokes.contains(strokeRef));
              notifyListeners();
            },
            redo: () {
              _data.strokes.insert(i, strokeRef);
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
        _currentStroke.offsets.add(event.localPosition);
        notifyListeners();
      }
    }
  }

  void onPointerUp(PointerUpEvent event) {
    if (event.kind == PointerDeviceKind.stylus) {
      if (_tool == Tool.pen || _tool == Tool.eraser) {
        _currentStroke = null;
      }
    }
  }

  @override
  void save() {
    super.save();
    notifyListeners();
    print(_data.svg.toXmlString(pretty: true));
  }
}
