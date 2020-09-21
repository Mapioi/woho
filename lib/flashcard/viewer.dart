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

  @override
  void initState() {
    super.initState();
    _controller = PageController(
      keepPage: true,
      viewportFraction: 0.9,
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
      ),
      body: PageView(
        controller: _controller,
        children: widget.flashcards.asMap().entries.map((e) {
          final i = e.key;
          final f = e.value;
          return Flashcard(
            flashcard: f,
            isBottomRevealed: _isRevealed[i],
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
  final onTapBottom;

  const Flashcard({
    Key key,
    @required this.flashcard,
    @required this.isBottomRevealed,
    @required this.onTapBottom,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final cardSize = Size(
        constraints.maxWidth * 0.54,
        constraints.maxHeight * 0.49,
      );
      print(cardSize);

      final front = svgData(frontSvg(flashcard), cardSize);
      final back = svgData(backSvg(flashcard), cardSize);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          InteractiveViewer(
            child: Card(
              child: CustomPaint(
                size: cardSize,
                painter: WhiteboardPainter.fromMutable(front),
              ),
            ),
          ),
          InteractiveViewer(
            child: GestureDetector(
              child: Card(
                child: isBottomRevealed
                    ? CustomPaint(
                        size: cardSize,
                        painter: WhiteboardPainter.fromMutable(back),
                      )
                    : SizedBox.fromSize(
                        size: cardSize,
                      ),
              ),
              onTap: onTapBottom,
            ),
          ),
        ],
      );
    });
  }
}
