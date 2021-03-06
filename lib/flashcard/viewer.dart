import 'dart:io';
import 'package:flutter/material.dart';
import './explorer_model.dart';
import './files_utils.dart' as files;
import '../whiteboard/painter.dart';
import '../whiteboard/whiteboard.dart';

/// A viewer for the flashcards.
///
/// Appbar:
/// * Title shows the progress through the flashcards, such as '1 / 15'.
/// * Action buttons include: edit front, edit back, shuffle flashcards, toggle
/// bookmarked filter, show/hide red strokes.
/// * Floating action button: mark / unmark flashcard. The flashcard is shown as
/// marked if it has been marked at most [_maxDaysSinceMarked] days ago, and in
/// this case, tapping on the button removes the last marks. Otherwise, tapping
/// adds a new mark to the flashcard.
///
/// Body:
/// * [Flashcard] of the card directory at [_page].
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

  /// Produce a constant map that sends each of 0..length-1 to [value].
  Map<int, T> constantMapRange<T>(int length, T value) {
    return Map.fromIterable(
      List.generate(length, (i) => i),
      key: (i) => i,
      value: (_) => value,
    );
  }

  /// Initialise the page controller, and hide all back sides of the
  /// [_flashcards] at the start.
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

  /// Toggle between seeing every flashcard and seeing only flashcards that have
  /// been marked at most [_maxDaysSinceMarked] days ago.
  ///
  /// This resets the controller to the first page, and hides all back sides.
  void toggleFilteringMarked() {
    if (_isFilteringMarked) {
      // Remove filter.
      setState(() {
        if (_controller.hasClients)
          _controller.jumpToPage(0);
        else
          _page = 0;

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

  /// Filter the [_flashcards] to see only those that have been marked at most
  /// [maxDaysSinceMarked] days ago.
  ///
  /// If [maxDaysSinceMarked] is null, then return the flashcards that have
  /// been marked at least once at any time.
  ///
  /// This resets the controller to the first page, and hides all back sides.
  void filterMarked(int maxDaysSinceMarked) {
    assert(_isFilteringMarked);
    setState(() {
      if (_controller.hasClients)
        _controller.jumpToPage(0);
      else
        _page = 0;

      _flashcards = widget.flashcards.where(
        (f) {
          final fLog = files.log(f);
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

  List<DropdownMenuItem<int>> _buildFilterMarkedOptions() {
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

  /// Shuffle the [_flashcards].
  ///
  /// Resets the controller to the first page, and hides all back sides.
  void shuffle() {
    setState(() {
      // The animation also triggers onChange and sets _page to 0.
      // Note: .jumpToPage was used before when toggling the filter, because the
      // range of values can shrink and cause errors, whilst here the range
      // remains constant.
      _controller.animateToPage(
        0,
        duration: Duration(seconds: 1),
        curve: Curves.easeInOut,
      );
      _flashcards.shuffle();
      _isRevealed = constantMapRange(_flashcards.length, false);
    });
  }

  @override
  Widget build(BuildContext context) {
    FloatingActionButton fab;
    Widget body;

    if (_flashcards.isEmpty) {
      body = Center(
        child: Chip(
          avatar: Icon(Icons.self_improvement),
          label: Text("Wow, such empty"),
        ),
      );
      fab = null;
    } else {
      final pageLog = files.log(_flashcards[_page]);
      final isPageMarked = pageLog.dates.isNotEmpty &&
          (_maxDaysSinceMarked == null ||
              pageLog.daysSinceLastMarked() <= _maxDaysSinceMarked);
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
      body = PageView(
        controller: _controller,
        children: pages,
        onPageChanged: (page) => setState(() {
          _page = page;
        }),
      );
      fab = FloatingActionButton(
        tooltip: "Bookmark",
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
          if (_flashcards.isNotEmpty)
            IconButton(
              tooltip: "Edit front",
              icon: Icon(Icons.flip_to_front),
              onPressed: () => launchEditor(
                context,
                files.frontSvg(_flashcards[_page]),
                onDone: () => setState(() {}),
              ),
            ),
          if (_flashcards.isNotEmpty)
            IconButton(
              tooltip: "Edit back",
              icon: Icon(Icons.flip_to_back),
              onPressed: () => launchEditor(
                context,
                files.backSvg(_flashcards[_page]),
                onDone: () => setState(() {}),
              ),
            ),
          if (_flashcards.isNotEmpty)
            IconButton(
              tooltip: "Shuffle",
              icon: Icon(Icons.shuffle),
              onPressed: shuffle,
            ),
          IconButton(
            tooltip: "Bookmarked",
            icon: Icon(
              _isFilteringMarked ? Icons.bookmarks : Icons.bookmarks_outlined,
            ),
            onPressed: toggleFilteringMarked,
          ),
          if (_isFilteringMarked)
            DropdownButton<int>(
              items: _buildFilterMarkedOptions(),
              value: _maxDaysSinceMarked,
              onChanged: filterMarked,
              iconEnabledColor: Theme.of(context).buttonColor,
              dropdownColor: Theme.of(context).accentColor,
            ),
          IconButton(
            tooltip: "Hide/show red strokes",
            icon: Icon(
              _isRedRevealed ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: () => setState(() {
              _isRedRevealed = !_isRedRevealed;
            }),
          ),
        ],
      ),
      floatingActionButton: fab,
      body: body,
    );
  }
}

/// A column of 2 canvases rendering the front and back of the flashcard.
///
/// Supports zooming in and moving around when zooming.
/// On tapping the bottom, toggle the visibility of that canvas.
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
      final front = svgData(files.frontSvg(flashcard));
      final back = svgData(files.backSvg(flashcard));

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
