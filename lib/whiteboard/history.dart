import 'package:flutter/material.dart';

/// A callback function taking no parameters and returning a [T].
typedef Callback<T> = T Function();

/// An undoable/redoable change.
class Change {
  final Callback<void> undo, redo;

  Change({@required this.undo, @required this.redo});
}

/// An command that produces a [Change].
class Command {
  final Callback<Change> execute;

  Command(this.execute);
}

/// A state that supports undoing and redoing.
mixin Undoable {
  final List<Change> _buffer = [];

  /// The index of the last applied change in the buffer.
  ///
  /// The changes of indices 0 .. [_i] (both inclusive) of [_buffer] can be
  /// undone, and the changes of indices [_i] + 1 .. can be redone.
  int _i = -1;

  /// The index of the last saved change in the buffer.
  ///
  /// The changes 0 .. [_iSaved] inclusive are saved.
  int _iSaved = -1;

  bool canUndo() => _i >= 0;

  bool canRedo() => _i < _buffer.length - 1;

  bool isSaved() => _i == _iSaved;

  /// Undoes the effect of the last command, only if [canUndo] is true.
  void undo() {
    assert(canUndo());

    _buffer[_i].undo();
    _i -= 1;
  }

  /// Redoes the last undone change, only if [canRedo] is true.
  void redo() {
    assert(canRedo());

    _buffer[_i + 1].redo();
    _i += 1;
  }

  /// Executes [cmd] and registers the produced [Change] on the [_buffer],
  /// disposing of any previously redoable changes.
  void execute(Command cmd) {
    final change = cmd.execute();

    // History diverges, remove old change log.
    if (canRedo()) {
      _buffer.removeRange(_i + 1, _buffer.length);
      assert(_buffer.length - 1 == _i);
      // The old save point can't be reached, unless saved again .
      if (_iSaved > _i) _iSaved = -1;
    }
    _buffer.add(change);
    _i += 1;
  }

  /// Registers the new save point and performs overridden behaviour (for
  /// example saving to google drive).
  void save() {
    _iSaved = _i;
  }
}
