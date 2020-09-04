import 'package:test/test.dart';
import 'package:woho/whiteboard/data.dart';
import 'package:xml/xml.dart';

void main() {
  group("WhiteboardData", () {
    test(".svg . .fromSvg = id, pen strokes with colours and stroke widths",
        () {
      const svgString =
          """<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg viewBox="0 0 1366.0 1024.0" xmlns="http://www.w3.org/2000/svg">
  <mask id="eraser0">
    <rect x="0" y="0" width="1366.0" height="1024.0" fill="white"/>
  </mask>
  <path d="M 768.5 207.5 L 768.5 207.5 L 768.5 207.5 L 768.5 208.0 L 768.5 208.0 L 768.5 208.0 L 768.5 208.0 L 768.5 208.5 L 768.5 208.5 L 768.5 208.5 L 768.5 208.5 L 768.5 208.5 L 769.0 208.5 L 769.0 208.5 L 769.0 208.5 L 769.0 208.5 L 769.0 208.5 L 769.0 208.5 L 769.0 208.0" fill="transparent" stroke="#448aff" stroke-width="2.0" stroke-linecap="round" stroke-linejoin="round" mask="url(#eraser0)"/>
  <path d="M 783.5 207.0 L 783.5 207.0 L 783.5 207.0 L 783.5 207.0 L 783.0 207.0 L 783.0 207.0 L 783.0 207.5 L 783.0 207.5 L 783.0 207.5 L 783.0 207.5 L 783.0 207.5 L 783.0 207.5 L 783.0 207.5 L 783.0 207.5 L 783.0 207.5 L 783.0 207.5 L 784.5 207.5 L 786.0 207.5 L 789.0 207.5 L 792.5 207.5 L 797.0 207.5 L 804.5 207.5 L 809.5 207.5 L 813.5 207.5 L 816.5 207.5 L 817.5 207.5" fill="transparent" stroke="#448aff" stroke-width="2.0" stroke-linecap="round" stroke-linejoin="round" mask="url(#eraser0)"/>
  <path d="M 766.5 239.0 L 766.5 239.0 L 766.5 239.0 L 766.5 239.0 L 766.5 239.0 L 766.5 239.0 L 766.5 239.0 L 766.0 239.0 L 766.0 239.0 L 766.0 239.0 L 766.0 239.0 L 766.0 239.0 L 766.0 239.0 L 766.0 239.0 L 766.0 239.0 L 766.5 239.5" fill="transparent" stroke="#f44336" stroke-width="5.0" stroke-linecap="round" stroke-linejoin="round" mask="url(#eraser0)"/>
  <path d="M 779.5 239.5 L 779.5 239.5 L 780.5 239.5 L 781.0 240.0 L 781.5 240.0 L 781.5 240.0 L 782.0 240.0 L 782.5 240.0 L 784.0 240.5 L 785.0 240.5 L 787.5 241.0 L 789.5 241.0 L 792.0 241.5 L 797.0 241.5 L 802.5 241.5 L 808.0 241.5 L 812.0 241.5 L 815.0 241.5 L 816.5 242.0" fill="transparent" stroke="#f44336" stroke-width="5.0" stroke-linecap="round" stroke-linejoin="round" mask="url(#eraser0)"/>
  <path d="M 765.5 277.5 L 765.5 277.5 L 765.5 277.0 L 765.5 277.0 L 765.5 277.0 L 765.5 277.0 L 765.0 277.0 L 765.0 277.0 L 765.0 277.0 L 765.0 277.0 L 765.0 276.5 L 765.0 276.5 L 764.5 276.5" fill="transparent" stroke="#000000" stroke-width="10.0" stroke-linecap="round" stroke-linejoin="round" mask="url(#eraser0)"/>
  <path d="M 784.5 277.5 L 784.5 277.5 L 785.0 277.5 L 785.0 277.5 L 785.5 277.5 L 786.0 277.5 L 787.0 277.5 L 788.5 277.5 L 793.0 277.5 L 798.5 277.5 L 801.0 277.5 L 804.5 277.5 L 811.0 277.5 L 814.5 277.0 L 818.5 277.0 L 821.0 276.5 L 826.0 276.0 L 830.0 276.0 L 833.0 276.0 L 834.0 276.5" fill="transparent" stroke="#000000" stroke-width="10.0" stroke-linecap="round" stroke-linejoin="round" mask="url(#eraser0)"/>
</svg>""";
      final onlyPenSvg = XmlDocument.parse(svgString);
      expect(
        WhiteboardData.fromSvg(onlyPenSvg).svg.toXmlString(pretty: true),
        svgString,
      );
    });

    test(".svg . .fromSvg = id, pen strokes with eraser strokes", () {
      const svgString =
          """<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg viewBox="0 0 1366.0 1024.0" xmlns="http://www.w3.org/2000/svg">
  <mask id="eraser0">
    <rect x="0" y="0" width="1366.0" height="1024.0" fill="white"/>
  </mask>
  <mask id="eraser1">
    <rect x="0" y="0" width="1366.0" height="1024.0" fill="white" mask="url(#eraser0)"/>
    <path d="M 490.5 234.0 L 490.5 234.0 L 490.5 234.0 L 490.5 234.0 L 490.5 234.0 L 490.5 234.0 L 490.5 234.0 L 490.5 234.5 L 490.5 235.5 L 490.5 236.5 L 490.5 239.5 L 490.5 241.5 L 490.5 244.0 L 490.5 246.5 L 490.5 252.5 L 490.5 255.5 L 491.0 258.0 L 491.5 263.0 L 491.5 265.0 L 492.0 267.0 L 492.5 270.0 L 493.0 271.0 L 493.0 272.5" fill="transparent" stroke="black" stroke-width="20.0" stroke-linecap="round" stroke-linejoin="round"/>
  </mask>
  <mask id="eraser2">
    <rect x="0" y="0" width="1366.0" height="1024.0" fill="white" mask="url(#eraser1)"/>
    <path d="M 380.5 235.0 L 380.5 235.0 L 380.5 235.0 L 380.5 235.0 L 380.5 235.0 L 380.5 235.0 L 380.5 235.0 L 380.5 235.0 L 380.5 235.0 L 380.5 235.0 L 380.5 236.5 L 380.5 239.0 L 380.5 242.5 L 380.5 246.5 L 380.5 252.0 L 380.5 254.5 L 380.5 257.5 L 380.5 262.0 L 380.5 264.0 L 380.5 266.0 L 380.5 268.0 L 380.5 270.0 L 381.0 271.5" fill="transparent" stroke="black" stroke-width="20.0" stroke-linecap="round" stroke-linejoin="round"/>
  </mask>
  <mask id="eraser3">
    <rect x="0" y="0" width="1366.0" height="1024.0" fill="white" mask="url(#eraser2)"/>
    <path d="M 434.0 237.5 L 434.0 237.5 L 434.0 237.5 L 434.5 237.5 L 434.5 237.0 L 434.5 237.0 L 434.5 237.0 L 434.5 237.0 L 434.5 237.0 L 434.5 237.0 L 434.5 237.5 L 434.5 237.5 L 434.5 238.0 L 434.5 238.5 L 434.5 239.0 L 434.5 239.5 L 435.0 240.0 L 435.0 242.5 L 435.0 245.0 L 435.5 249.0 L 436.0 256.0 L 436.0 261.5 L 436.5 267.0 L 436.5 269.0 L 436.5 272.5 L 437.0 275.5 L 437.0 278.0 L 437.5 279.5 L 438.0 281.0 L 438.5 282.5 L 439.0 283.0 L 439.0 283.5 L 439.0 283.5 L 439.0 283.5 L 439.0 282.5" fill="transparent" stroke="black" stroke-width="20.0" stroke-linecap="round" stroke-linejoin="round"/>
  </mask>
  <path d="M 342.5 249.5 L 342.5 249.5 L 344.0 249.5 L 344.0 249.5 L 344.5 250.0 L 345.5 250.0 L 346.0 250.0 L 347.0 250.5 L 349.0 251.0 L 350.5 251.5 L 354.0 251.5 L 358.5 251.5 L 364.0 251.5 L 371.0 251.0 L 378.0 250.0 L 385.5 249.0 L 394.0 248.5 L 401.5 248.5 L 410.0 248.0 L 419.0 248.0 L 428.0 248.0 L 437.0 248.0 L 446.5 248.5 L 455.5 248.5 L 464.5 248.5 L 473.5 249.0 L 482.0 249.5 L 490.5 250.0 L 498.5 251.0 L 506.0 252.0 L 513.0 252.5 L 519.5 252.5 L 525.5 252.5 L 531.5 252.5 L 535.5 251.0 L 537.5 250.0" fill="transparent" stroke="#448aff" stroke-width="2.0" stroke-linecap="round" stroke-linejoin="round" mask="url(#eraser3)"/>
  <path d="M 435.5 220.5 L 435.5 220.5 L 435.5 220.5 L 435.5 220.5 L 435.5 220.5 L 435.5 220.5 L 435.5 221.0 L 436.0 221.0 L 436.0 221.0 L 436.0 221.5 L 436.0 222.0 L 436.0 222.0 L 436.0 223.0 L 436.0 225.5 L 436.0 227.0 L 436.0 228.5 L 436.0 230.5 L 436.0 236.5 L 436.0 244.0 L 436.0 252.0 L 436.0 259.5 L 436.5 266.0 L 436.5 273.5 L 437.0 277.0 L 437.5 279.0 L 438.0 281.5 L 438.0 282.0 L 438.5 283.0" fill="transparent" stroke="#448aff" stroke-width="2.0" stroke-linecap="round" stroke-linejoin="round" mask="url(#eraser2)"/>
</svg>""";
      final erasedSvg = XmlDocument.parse(svgString);
      expect(
        WhiteboardData.fromSvg(erasedSvg).svg.toXmlString(pretty: true),
        svgString,
      );
    });
  });
}
