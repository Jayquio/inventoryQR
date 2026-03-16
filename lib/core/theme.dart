// lib/core/theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4B0082), Color(0xFF6A0DAD)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Color primaryColor = Color(0xFF4B0082);
  static const Color secondaryColor = Color(0xFF6A0DAD);
  static const Color accentColor = Color(0xFFFF0000);
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color wisteria = Color(0xFFC9A0DC);
}
