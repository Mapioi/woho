/// Log of the dates when a flashcard is bookmarked.
class FlashcardLog {
  /// A list of the dates on which this flashcard is marked.
  ///
  /// The list must be ordered chronologically.
  final List<DateTime> dates;

  FlashcardLog(this.dates);

  factory FlashcardLog.fromLines(List<String> lines) {
    final dates = lines.map(DateTime.parse).toList();
    for (int i = 1; i < dates.length; i++) {
      assert(dates[i - 1].isBefore(dates[i]));
    }
    return FlashcardLog(dates);
  }

  @override
  String toString() {
    return dates.map((d) => d.toString()).join("\n");
  }

  /// Add a new mark to this flashcard.
  mark() {
    dates.add(DateTime.now());
  }

  /// Remove the last date when this flashcard is marked.
  unMark() {
    assert(dates.isNotEmpty);
    dates.removeLast();
  }

  /// Compute the number of days since this flashcard was last marked.
  ///
  /// Returns null if this flashcard has never been marked.
  int daysSinceLastMarked() {
    if (dates.isEmpty)
      return null;
    else {
      return DateTime.now().difference(dates.last).inDays;
    }
  }
}
