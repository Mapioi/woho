/// Log of the dates when a flashcard is bookmarked.
class FlashcardLog {
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

  mark() {
    dates.add(DateTime.now());
  }

  unMark() {
    assert(dates.isNotEmpty);
    dates.removeLast();
  }

  int daysSinceLastMarked() {
    if (dates.isEmpty)
      return null;
    else {
      return DateTime.now().difference(dates.last).inDays;
    }
  }
}
