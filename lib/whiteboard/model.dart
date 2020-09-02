import 'dart:collection';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:xml/xml.dart';
import './history.dart';
import './data.dart';

enum Tool {
  pen,
  eraser,
}

const mockSvg = """
<?xml version="1.0" encoding="UTF-8" standalone="no"?><svg viewbox="0 0 1366.0 1024.0" xmlns="http://www.w3.org/2000/svg"><mask id="eraser0"><rect x="0" y="0" width="1366.0" height="1024.0" fill="white"/></mask><mask id="eraser1"><rect x="0" y="0" width="1366.0" height="1024.0" fill="white" mask="url(#eraser0)"/><path d="M 524.5 118.5 L 524.5 118.5 L 524.5 118.5 L 525.5 118.0 L 526.0 117.5 L 526.5 117.5 L 527.5 116.5 L 528.5 116.0 L 529.5 115.5 L 532.0 115.0 L 534.5 115.0 L 537.5 115.0 L 540.5 117.0 L 543.5 119.5 L 547.0 122.5 L 551.0 127.0 L 554.5 133.0 L 558.0 141.5 L 561.0 153.5 L 564.5 168.0 L 567.5 185.5 L 570.5 205.5 L 573.5 227.0 L 577.0 251.0 L 580.5 276.5 L 584.0 301.5 L 587.0 326.0 L 589.0 347.5 L 590.0 366.0 L 590.5 382.5 L 590.0 397.0 L 589.0 409.0 L 588.0 420.0 L 587.0 428.5 L 586.5 435.0 L 586.5 439.5 L 586.5 442.5 L 587.0 443.0 L 587.0 443.0 L 587.5 442.0" fill="transparent" stroke="black" stroke-width="100.0" stroke-linecap="round" stroke-linejoin="round"/></mask><mask id="eraser2"><rect x="0" y="0" width="1366.0" height="1024.0" fill="white" mask="url(#eraser1)"/><path d="M 258.0 233.0 L 258.0 233.0 L 258.0 233.5 L 258.0 233.5 L 258.0 233.5 L 258.0 234.0 L 258.0 234.0 L 257.5 234.0 L 257.5 234.0 L 257.5 234.0 L 257.5 234.0 L 257.5 234.0 L 258.0 233.5" fill="transparent" stroke="black" stroke-width="100.0" stroke-linecap="round" stroke-linejoin="round"/></mask><mask id="eraser3"><rect x="0" y="0" width="1366.0" height="1024.0" fill="white" mask="url(#eraser2)"/><path d="M 167.5 143.5 L 167.5 143.5 L 169.0 143.5 L 170.5 143.0 L 171.5 142.5 L 173.5 142.5 L 176.0 142.5 L 179.0 142.5 L 181.0 142.5 L 183.5 142.5 L 188.5 142.5 L 191.0 142.5 L 194.0 142.5 L 201.0 142.0 L 205.0 141.5 L 209.5 141.0 L 213.5 140.0 L 218.0 139.5 L 227.5 138.5 L 232.5 138.5 L 237.5 138.0 L 247.5 137.0 L 257.5 136.5 L 269.0 135.5 L 274.5 135.0 L 279.5 134.5 L 291.0 133.5 L 303.0 132.5 L 314.0 132.0 L 326.0 131.0 L 338.5 130.0 L 349.0 129.5 L 360.0 128.5 L 371.0 128.0 L 380.0 127.5 L 389.0 127.5 L 393.0 127.5 L 397.5 127.5 L 404.5 127.5 L 411.0 127.5 L 418.0 127.5 L 420.5 127.0 L 423.5 126.0" fill="transparent" stroke="black" stroke-width="20.0" stroke-linecap="round" stroke-linejoin="round"/></mask><path d="M 197.5 111.5 L 197.5 111.5 L 197.5 112.5 L 197.5 115.5 L 196.5 119.0 L 196.0 123.0 L 195.5 126.0 L 195.5 129.5 L 195.0 137.5 L 194.5 142.0 L 194.5 153.0 L 194.5 166.0 L 194.5 180.0 L 195.0 196.0 L 195.0 213.5 L 195.5 230.0 L 195.5 245.5 L 195.5 259.0 L 195.5 269.5 L 195.5 278.0 L 195.5 285.5 L 195.5 291.0 L 196.0 295.0 L 196.5 298.5 L 197.5 300.5 L 198.0 301.5" fill="transparent" stroke="#448aff" stroke-width="2.0" stroke-linecap="round" stroke-linejoin="round" mask="url(#eraser3)"/><path d="M 235.0 128.0 L 235.0 128.0 L 235.0 125.5 L 235.0 123.0 L 235.0 122.0 L 235.0 119.5 L 235.0 118.5 L 235.5 117.5 L 235.5 116.5 L 236.0 116.0 L 236.5 115.0 L 236.5 114.5 L 237.0 114.0 L 237.5 113.5 L 238.0 113.5 L 238.0 113.5 L 239.0 113.5 L 239.5 114.0 L 240.5 115.5 L 241.0 118.5 L 241.5 124.0 L 241.5 132.0 L 241.5 137.0 L 241.5 149.0 L 240.5 166.0 L 240.0 185.0 L 239.5 204.5 L 239.5 213.5 L 239.0 231.5 L 239.0 245.5 L 238.0 259.0 L 237.5 271.5 L 237.0 282.5 L 237.0 291.5 L 237.0 298.5 L 238.0 303.0 L 239.5 306.0 L 241.5 307.5 L 242.5 307.5" fill="transparent" stroke="#000000" stroke-width="2.0" stroke-linecap="round" stroke-linejoin="round" mask="url(#eraser3)"/><path d="M 289.5 107.0 L 289.5 107.0 L 288.5 107.5 L 287.5 108.0 L 287.0 109.0 L 286.5 110.0 L 285.5 112.0 L 285.0 116.0 L 284.5 122.0 L 284.5 125.5 L 285.0 135.0 L 285.5 140.5 L 287.0 155.5 L 288.0 171.5 L 289.0 189.0 L 289.5 208.0 L 289.5 225.0 L 289.5 242.5 L 289.5 259.5 L 289.0 272.5 L 288.5 283.0 L 289.0 290.0 L 290.5 292.5 L 292.5 293.5 L 294.5 293.5 L 295.0 292.5" fill="transparent" stroke="#f44336" stroke-width="2.0" stroke-linecap="round" stroke-linejoin="round" mask="url(#eraser3)"/><path d="M 314.0 113.5 L 314.0 113.5 L 314.0 115.0 L 314.0 116.0 L 314.5 116.5 L 314.5 118.0 L 314.5 120.5 L 314.5 123.0 L 315.0 125.5 L 315.5 132.5 L 315.5 137.5 L 317.0 150.5 L 317.5 157.5 L 318.5 166.0 L 320.0 184.5 L 321.5 204.5 L 322.5 221.0 L 323.5 238.0 L 324.0 246.0 L 324.5 254.0 L 325.0 268.0 L 325.5 274.0 L 325.5 285.5 L 325.5 294.0 L 325.5 300.5 L 327.0 304.5 L 327.5 305.5 L 328.5 306.0" fill="transparent" stroke="#9e9e9e" stroke-width="2.0" stroke-linecap="round" stroke-linejoin="round" mask="url(#eraser3)"/><path d="M 167.5 148.5 L 167.5 148.5 L 167.5 148.5 L 168.0 148.5 L 168.0 148.0 L 168.0 148.0 L 168.5 148.0 L 169.0 148.0 L 169.0 147.5 L 170.0 147.5 L 170.0 147.5 L 171.0 147.5 L 172.0 147.5 L 173.5 147.0 L 174.0 147.0 L 175.0 147.0 L 177.0 146.5 L 179.5 146.5 L 182.0 146.5 L 184.5 146.0 L 187.0 145.5 L 190.0 145.0 L 193.0 144.5 L 196.0 144.0 L 199.5 143.0 L 203.5 142.0 L 207.0 141.0 L 211.5 140.0 L 215.5 139.0 L 219.5 138.5 L 223.5 137.5 L 227.5 137.0 L 231.5 136.5 L 235.0 135.5 L 238.5 135.0 L 242.0 134.5 L 246.0 133.5 L 249.5 132.5 L 253.0 132.0 L 256.5 131.0 L 259.5 131.0 L 263.0 130.5 L 266.5 130.5 L 269.5 130.0 L 272.0 130.0 L 275.0 129.5 L 276.5 129.5 L 278.0 129.5 L 279.0 129.5 L 282.0 129.0 L 286.5 128.0 L 289.5 127.5 L 293.0 127.5 L 294.5 127.0 L 298.0 126.5 L 301.5 126.0 L 305.5 126.0 L 309.5 126.0 L 313.5 125.5 L 318.0 125.5 L 321.5 125.5 L 325.5 125.5 L 330.0 125.0 L 334.0 125.0 L 338.5 125.0 L 343.5 125.0 L 348.0 125.0 L 352.5 126.0 L 357.5 127.0 L 362.0 127.5 L 367.0 127.5 L 371.0 127.5 L 375.5 127.5 L 380.0 127.0 L 381.5 126.0" fill="transparent" stroke="#9e9e9e" stroke-width="5.0" stroke-linecap="round" stroke-linejoin="round" mask="url(#eraser2)"/><path d="M 236.5 227.5 L 236.5 227.5 L 237.5 227.0 L 238.5 226.0 L 240.0 225.0 L 241.5 224.0 L 244.0 222.5 L 247.0 221.5 L 250.5 220.0 L 254.0 219.0 L 257.0 218.0 L 260.0 217.0 L 262.5 216.0 L 264.5 215.5 L 266.5 214.5 L 268.0 213.5 L 269.0 212.5 L 269.0 212.0 L 269.5 211.5 L 269.5 211.5 L 269.0 211.5 L 268.5 211.5 L 268.0 211.5 L 267.0 212.5 L 266.0 213.0 L 265.0 214.5 L 263.5 216.0 L 262.0 218.0 L 260.0 220.5 L 258.5 223.5 L 256.0 227.5 L 253.5 232.0 L 250.5 237.0 L 248.0 241.5 L 245.5 245.0 L 243.5 247.0 L 241.5 248.5 L 240.0 249.0 L 239.0 249.0 L 238.0 248.0 L 237.5 246.0 L 237.5 243.0 L 237.5 239.5 L 237.5 236.0 L 237.5 231.5 L 238.5 227.0 L 239.0 222.5 L 240.5 218.5 L 241.5 215.5 L 243.0 213.5 L 244.5 212.0 L 246.0 211.5 L 248.0 211.5 L 249.5 211.5 L 251.5 212.0 L 253.5 213.5 L 256.0 215.5 L 258.0 218.5 L 260.0 222.0 L 262.0 225.5 L 264.0 228.5 L 266.0 231.5 L 267.5 234.5 L 269.0 236.5 L 269.5 237.5 L 270.0 238.5 L 270.0 239.0 L 269.0 239.5 L 267.0 239.5 L 264.5 239.5 L 261.0 239.5 L 256.5 239.5 L 252.0 239.5 L 246.5 239.0 L 240.0 237.5 L 235.0 235.5 L 230.5 233.5 L 227.0 231.5 L 225.5 230.5 L 224.5 230.5 L 223.5 230.0" fill="transparent" stroke="#f44336" stroke-width="5.0" stroke-linecap="round" stroke-linejoin="round" mask="url(#eraser1)"/></svg>""";

class WhiteboardModel extends ChangeNotifier with Undoable {
  WhiteboardModel({@required this.size})
      : _data = WhiteboardData.fromSvg(XmlDocument.parse(mockSvg));

  final Size size;
  final WhiteboardData _data;
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

  WhiteboardDataView get data => _data.view;

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
