import 'package:test/test.dart';
import 'package:woho/whiteboard/history.dart';

class Editor with Undoable {
  var state = "0";

  void setState(int i) {
    execute(Command(() {
      state = "set$i";

      return Change(
        undo: () => state = "undo$i",
        redo: () => state = "redo$i",
      );
    }));
  }
}

void main() {
  group("Undoable", () {
    test(".canUndo and .undo ", () {
      final editor = Editor();
      expect(editor.canUndo(), false);
      expect(editor.state, "0");
      editor.setState(1);
      expect(editor.state, "set1");
      expect(editor.canUndo(), true);
      editor.setState(2);
      expect(editor.state, "set2");
      expect(editor.canUndo(), true);
      editor.undo();
      expect(editor.state, "undo2");
      expect(editor.canUndo(), true);
      editor.undo();
      expect(editor.state, "undo1");
      expect(editor.canUndo(), false);
    });

    test(".canRedo and .redo", () {
      final editor = Editor();
      expect(editor.canRedo(), false);
      expect(editor.state, "0");
      editor.setState(1);
      expect(editor.canRedo(), false);
      editor.setState(2);
      expect(editor.canRedo(), false);
      editor.undo();
      expect(editor.canRedo(), true);
      editor.undo();
      expect(editor.canRedo(), true);
      editor.redo();
      expect(editor.state, "redo1");
      expect(editor.canRedo(), true);
      editor.redo();
      expect(editor.state, "redo2");
      expect(editor.canRedo(), false);
    });

    test(".execute disposes of any remaining redoable changes", () {
      final editor = Editor();
      editor.setState(1);
      editor.undo();
      expect(editor.canRedo(), true);
      editor.setState(2);
      expect(editor.canRedo(), false);
    });

    test(".isSaved and save", () {
      final editor = Editor();
      expect(editor.isSaved(), true);
      editor.save();
      expect(editor.isSaved(), true);
      expect(editor.state, "0");
      editor.setState(1);
      expect(editor.isSaved(), false);
      editor.save();
      expect(editor.state, "set1");
      expect(editor.isSaved(), true);
      editor.undo();
      expect(editor.state, "undo1");
      expect(editor.isSaved(), false);
      editor.redo();
      expect(editor.state, "redo1");
      expect(editor.isSaved(), true);
      editor.undo();
      expect(editor.isSaved(), false);
      editor.setState(2);
      expect(editor.state, "set2");
      expect(editor.isSaved(), false);
    });
  });
}
