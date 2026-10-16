import 'package:flutter/material.dart';

/// Shared visual tokens; feature widgets use the theme for semantic colors.
abstract final class CompanionStyle {
  static const accent = Color(0xFF7DD3FC);
  static const accentDepth = Color(0xFF3583AA);
  static const background = Color(0xFF0C121B);
  static const surface = Color(0xFF162230);
  static const inset = Color(0xFF101A26);
  static const cardRadius = 28.0;
  static const controlRadius = 20.0;
  static const buttonDepth = 6.0;
  static const pressDuration = Duration(milliseconds: 90);
  static const releaseDuration = Duration(milliseconds: 160);
  static const softShadow = [
    BoxShadow(color: Color(0x33000000), blurRadius: 32, offset: Offset(0, 12)),
  ];
}
