import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xml/xml.dart';
import './data.dart';
import './editor.dart';
import './model.dart';

WhiteboardData svgData(File svgFile, Size canvasSize) {
  assert(svgFile.existsSync());
  final xml = XmlDocument.parse(svgFile.readAsStringSync());
  final data = WhiteboardData.fromSvg(xml);
  if (canvasSize == null) {
    return data;
  } else {
    return data.fit(canvasSize);
  }
}

WhiteboardModel svgModel(File svgFile, Size canvasSize) {
  final model = WhiteboardModel(
    svgData(svgFile, canvasSize),
        (xmlString) {
      svgFile.writeAsStringSync(xmlString);
    },
  );
  return model;
}

void launchEditor(BuildContext context, File svg) {
  final parentSize = MediaQuery.of(context).size;
  final editorSize = Size(
    parentSize.width,
    // Deduct the status bar height and tool bar height from total height.
    parentSize.height - MediaQuery.of(context).padding.top - kToolbarHeight,
  );

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ChangeNotifierProvider(
        create: (context) => svgModel(svg, editorSize),
        child: WhiteboardEditor(),
      ),
      fullscreenDialog: true,
    ),
  );
}