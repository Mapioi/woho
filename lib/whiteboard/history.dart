import 'package:flutter/material.dart';

typedef Callback<T> = T Function();

class Command {
  final Callback<Change> execute;

  Command(this.execute);
}

class Change {
  final Callback<void> undo, redo;

  Change({@required this.undo, @required this.redo});
}

mixin Undoable {
  final List<Change> _buffer = [];
  int _i = -1;

  /// The index of the last executed command in the buffer

  bool canUndo() => _i >= 0;

  bool canRedo() => _i < _buffer.length - 1;

  void undo() {
    assert(canUndo());

    _buffer[_i].undo();
    _i -= 1;
  }

  void redo() {
    assert(canRedo());

    _buffer[_i + 1].redo();
    _i += 1;
  }

  void execute(Command cmd) {
    final change = cmd.execute();

    if (canRedo()) {
      _buffer.removeRange(_i + 1, _buffer.length);
      assert(_i == _buffer.length - 1);
    }
    _buffer.add(change);
    _i += 1;
  }
}
