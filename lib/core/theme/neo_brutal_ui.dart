import 'package:flutter/material.dart';

/// NeoBrutalUI - Utility class for consistent Neo-Brutalism styles
class NeoBrutalUI {
  NeoBrutalUI._();

  /// Consistent border radius for cards and containers
  static const double borderRadius = 16.0;
  static const double borderRadiusLarge = 20.0;

  /// Standard border thickness for Neo-Brutalist look
  static const double borderWidth = 2.0;
  static const double borderWidthThin = 1.5;

  /// Neo-Brutalist BoxDecoration with solid border and optional shadow
  static BoxDecoration boxDecoration(
    BuildContext context, {
    Color? color,
    double radius = borderRadius,
    double width = borderWidth,
    bool hasShadow = false,
    Color? shadowColor,
    Offset shadowOffset = const Offset(4, 4),
    BoxShape shape = BoxShape.rectangle,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return BoxDecoration(
      color: color ?? colorScheme.surface,
      shape: shape,
      borderRadius: shape == BoxShape.rectangle ? BorderRadius.circular(radius) : null,
      border: Border.all(
        color: colorScheme.onSurface,
        width: width,
      ),
      boxShadow: hasShadow
          ? [
              BoxShadow(
                color: shadowColor ?? colorScheme.onSurface,
                offset: shadowOffset,
                blurRadius: 0,
              ),
            ]
          : null,
    );
  }

  /// Sharp shadow for Neo-Brutalist elements
  static List<BoxShadow> sharpShadow(BuildContext context, {Color? color}) {
    return [
      BoxShadow(
        color: color ?? Theme.of(context).colorScheme.onSurface,
        offset: const Offset(4, 4),
        blurRadius: 0,
      ),
    ];
  }
}
