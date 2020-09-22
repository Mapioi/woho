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
  int _page;
  Map<int, bool> _isRevealed;
  bool _isRedRevealed = true;
  List<Directory> _flashcards;
  bool _isFilteringMarked = false;
  int _maxDaysSinceMarked = 7;

  Map<int, T> constantMapRange<T>(int length, T value) {
    return Map.fromIterable(
      List.generate(length, (i) => i),
      key: (i) => i,
      value: (_) => value,
    );
  }

  @override
  void initState() {
    super.initState();
    _page = 0;
    _controller = PageController();
    _flashcards = widget.flashcards;
    _isRevealed = constantMapRange(_flashcards.length, false);
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  void toggleFilteringMarked() {
    if (_isFilteringMarked) {
      // Remove filter.
      setState(() {
        _page = 0;
        _controller.jumpToPage(_page);
        _flashcards = widget.flashcards;
        _isRevealed = constantMapRange(_flashcards.length, false);
        _isFilteringMarked = false;
      });
    } else {
      // Apply filter.
      _isFilteringMarked = true;
      filterMarked(_maxDaysSinceMarked);
    }
  }

  void filterMarked(int maxDaysSinceMarked) {
    assert(_isFilteringMarked);
    setState(() {
      _page = 0;
      _controller.jumpToPage(_page);
      _flashcards = widget.flashcards.where(
        (f) {
          final fLog = log(f);
          if (fLog.dates.isEmpty) {
            return false;
          } else {
            // A null value represents an infinite upper threshold.
            if (maxDaysSinceMarked == null) {
              return true;
            } else {
              return fLog.daysSinceLastMarked() <= maxDaysSinceMarked;
            }
          }
        },
      ).toList();
      _isRevealed = constantMapRange(_flashcards.length, false);
      _maxDaysSinceMarked = maxDaysSinceMarked;
    });
  }

  List<DropdownMenuItem<int>> buildFilterMarkedOptions() {
    final days = [1, 7, 30, 365];
    final options = days.map((d) {
      final dayOrDays = d == 1 ? "day" : "days";
      return DropdownMenuItem(
        child: Text(
          "$d $dayOrDays",
          style: TextStyle(
            color: Theme.of(context).accentTextTheme.bodyText1.color,
          ),
        ),
        value: d,
      );
    }).toList();
    final foreverOption = DropdownMenuItem(
      child: Text(
        "Forever",
        style: TextStyle(
          color: Theme.of(context).accentTextTheme.bodyText1.color,
        ),
      ),
      value: null,
    );
    return [...options, foreverOption];
  }

  @override
  Widget build(BuildContext context) {
    final pages = _flashcards.asMap().entries.map((entry) {
      final i = entry.key;
      final f = entry.value;
      return Flashcard(
        key: Key(entry.toString()),
        flashcard: f,
        isBottomRevealed: _isRevealed[i],
        isRedRevealed: _isRedRevealed,
        onTapBottom: () => setState(() {
          _isRevealed[i] = !_isRevealed[i];
        }),
      );
    }).toList();
    FloatingActionButton fab;
    Widget body;

    if (pages.isEmpty) {
      body = Center(
        child: Chip(
          avatar: Icon(Icons.self_improvement),
          label: Text("Wow, such empty"),
        ),
      );
      fab = null;
    } else {
      final pageLog = log(_flashcards[_page]);
      final isPageMarked = pageLog.dates.isNotEmpty &&
          pageLog.daysSinceLastMarked() <= _maxDaysSinceMarked;
      body = PageView(
        controller: _controller,
        children: pages,
        onPageChanged: (page) => setState(() {
          _page = page;
        }),
      );
      fab = FloatingActionButton(
        child: Icon(isPageMarked ? Icons.favorite : Icons.favorite_border),
        onPressed: () {
          setState(() {
            if (isPageMarked) {
              unmarkFlashcard(_flashcards[_page]);
            } else {
              markFlashcard(_flashcards[_page]);
            }
          });
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("${_page + 1} / ${_flashcards.length}"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isFilteringMarked ? Icons.bookmarks : Icons.bookmarks_outlined,
            ),
            onPressed: toggleFilteringMarked,
          ),
          if (_isFilteringMarked)
            DropdownButton<int>(
              items: buildFilterMarkedOptions(),
              value: _maxDaysSinceMarked,
              onChanged: filterMarked,
              dropdownColor: Theme.of(context).accentColor,
            ),
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
      floatingActionButton: fab,
      body: body,
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
