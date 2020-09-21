import 'dart:io';
import 'package:flutter/material.dart';
import './explorer_model.dart';
import '../whiteboard/painter.dart';

class FlashcardViewer extends StatefulWidget {
  final List<Directory> flashcards;

  const FlashcardViewer({Key key, this.flashcards}) : super(key: key);

  @override
  _FlashcardViewerState createState() => _FlashcardViewerState();
}

class _FlashcardViewerState extends State<FlashcardViewer> {
  PageController _controller;
  int _page = 0;
  Map<int, bool> _isRevealed;
  bool _isRedRevealed = true;

  @override
  void initState() {
    super.initState();
    _controller = PageController(
      keepPage: true,
    );
    _isRevealed = Map.fromIterable(
      List.generate(widget.flashcards.length, (index) => index),
      key: (i) => i,
      value: (_) => false,
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${_page + 1} / ${widget.flashcards.length}"),
        actions: [
          IconButton(
            icon: Icon(
              _isRedRevealed ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: () => setState(() {
              _isRedRevealed = !_isRedRevealed;
            }),
            tooltip: "Hide/show red strokes",
          ),
        ],
      ),
      body: PageView(
        controller: _controller,
        children: widget.flashcards.asMap().entries.map((e) {
          final i = e.key;
          final f = e.value;
          return Flashcard(
            flashcard: f,
            isBottomRevealed: _isRevealed[i],
            isRedRevealed: _isRedRevealed,
            onTapBottom: () => setState(() {
              _isRevealed[i] = !_isRevealed[i];
            }),
          );
        }).toList(),
        onPageChanged: (page) => setState(() {
          _page = page;
        }),
      ),
    );
  }
}

class Flashcard extends StatelessWidget {
  final Directory flashcard;
  final bool isBottomRevealed;
  final bool isRedRevealed;
  final onTapBottom;

  const Flashcard({
    Key key,
    @required this.flashcard,
    @required this.isBottomRevealed,
    @required this.isRedRevealed,
    @required this.onTapBottom,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      // Keep aspect ratio so that the title text is correctly positioned.
      final front = svgData(frontSvg(flashcard), null);
      final back = svgData(backSvg(flashcard), null);

      // Both cards have a 4.0px margin, top and bottom.
      final availableHeight = constraints.maxHeight - 4 * 4.0;
      final cardHeight = availableHeight / 2;
      final frontWidth = front.size.width * (cardHeight / front.size.height);
      final backWidth = back.size.width * (cardHeight / back.size.height);
      final frontSize = Size(frontWidth, cardHeight);
      final backSize = Size(backWidth, cardHeight);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Limit the viewport to the card to prevent PageView scrolling.
          ClipRect(
            child: InteractiveViewer(
              // Disables dragging around since PageView interferes with it.
              panEnabled: false,
              child: Card(
                child: CustomPaint(
                  size: frontSize,
                  painter: WhiteboardPainter.fromMutable(
                    front.fit(frontSize),
                    isRedRevealed: isRedRevealed,
                  ),
                ),
              ),
            ),
          ),
          ClipRect(
            child: InteractiveViewer(
              panEnabled: false,
              child: InkWell(
                child: Card(
                  child: isBottomRevealed
                      ? CustomPaint(
                          size: backSize,
                          painter: WhiteboardPainter.fromMutable(
                            back.fit(backSize),
                            isRedRevealed: isRedRevealed,
                          ),
                        )
                      : SizedBox.fromSize(
                          size: backSize,
                          child: Center(
                            child: Text("Tap to reveal"),
                          ),
                        ),
                ),
                onTap: onTapBottom,
              ),
            ),
          ),
        ],
      );
    });
  }
}
