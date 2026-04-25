import 'package:flutter/material.dart';
import '../utils/editor_utils.dart';

class MemeTextWidget extends StatelessWidget {
  const MemeTextWidget({
    super.key,
    required this.text,
    required this.font,
    required this.color,
    this.fontSize = 42,
  });

  final String text;
  final String font;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.black;

    return SizedBox(
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: EditorUtils.getMemeTextStyle(
              font: font,
              foreground: strokePaint,
              fontSize: fontSize,
            ),
          ),
          Text(
            text,
            textAlign: TextAlign.center,
            style: EditorUtils.getMemeTextStyle(
              font: font,
              color: color,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }
}
