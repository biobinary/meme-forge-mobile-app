import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EditorUtils {
  EditorUtils._();

  /// Available font options for the editor
  static const List<String> fontOptions = [
    'Anton',
    'Oswald',
    'Bebas Neue',
    'Black Ops One',
  ];

  static const double minFontSize = 12.0;
  static const double maxFontSize = 100.0;

  /// Available color options for meme text
  static const List<Color> colorOptions = [
    Colors.white,
    Color(0xFFFFD500), // Vibrant Yellow
    Color(0xFFF97316), // Orange
    Color(0xFFFF5555), // Red
    Color(0xFF00FF41), // Lime
    Color(0xFF4338CA), // Electric Indigo
    Colors.black,
  ];

  static TextStyle getMemeTextStyle({
    required String font,
    double fontSize = 42,
    Color? color,
    Paint? foreground,
  }) {
    final base = TextStyle(
      fontSize: fontSize,
      letterSpacing: 1.5,
      height: 1.1,
      color: foreground == null ? (color ?? Colors.white) : null,
      foreground: foreground,
    );
    switch (font) {
      case 'Oswald':
        return GoogleFonts.oswald(textStyle: base);
      case 'Bebas Neue':
        return GoogleFonts.bebasNeue(textStyle: base);
      case 'Black Ops One':
        return GoogleFonts.blackOpsOne(textStyle: base);
      case 'Anton':
      default:
        return GoogleFonts.anton(textStyle: base);
    }
  }

  static TextStyle getBaseFontStyle(String font) {
    switch (font) {
      case 'Oswald':
        return GoogleFonts.oswald();
      case 'Bebas Neue':
        return GoogleFonts.bebasNeue();
      case 'Black Ops One':
        return GoogleFonts.blackOpsOne();
      default:
        return GoogleFonts.anton();
    }
  }

  /// Get ColorFilter based on name
  static ColorFilter getFilter(String filter) {
    switch (filter) {
      case 'Grayscale':
        return const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case 'Sepia':
        return const ColorFilter.matrix(<double>[
          0.393, 0.769, 0.189, 0, 0,
          0.349, 0.686, 0.168, 0, 0,
          0.272, 0.534, 0.131, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case 'Cool Blue':
        return const ColorFilter.matrix(<double>[
          0.8, 0.0, 0.0, 0, 0,
          0.0, 0.9, 0.0, 0, 0,
          0.0, 0.0, 1.2, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case 'Normal':
      default:
        return const ColorFilter.mode(Colors.transparent, BlendMode.multiply);
    }
  }

  /// Trash detection logic
  static bool isNearTrash(Offset globalPosition, GlobalKey trashKey) {
    final trashBox = trashKey.currentContext?.findRenderObject() as RenderBox?;
    if (trashBox == null || !trashBox.hasSize) return false;

    final trashPosition = trashBox.localToGlobal(Offset.zero);
    final trashSize = trashBox.size;

    // Expand detection area
    final trashRect = Rect.fromLTWH(
      trashPosition.dx - 20,
      trashPosition.dy - 20,
      trashSize.width + 40,
      trashSize.height + 40,
    );

    return trashRect.contains(globalPosition);
  }
}
