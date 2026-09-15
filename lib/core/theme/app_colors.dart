import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Dark Obsidian Color System
  static const Color backgroundBase = Color(0xFF0D0F12); // Deep obsidian black
  static const Color cardSurface = Color(0xFF161A20);    // Dark charcoal surface
  static const Color inputSurface = Color(0xFF212731);   // Lighter charcoal for inputs & buttons
  static const Color cardBorderStroke = Color(0xFF2E3646); // Subdued slate stroke (1px)
  
  // High-Contrast Typography
  static const Color primaryText = Color(0xFFF5F6F8);    // Off-white for timers, bills, headers
  static const Color secondaryText = Color(0xFF9EA8B6);  // Muted slate gray for specs, hints
  static const Color textDisabled = Color(0xFF5A6474);

  // Table Matrix Status Colors
  static const Color tableAvailable = Color(0xFF00E676);   // Emerald green
  static const Color tableOccupied = Color(0xFFFF355E);    // Neon red
  static const Color tableMaintenance = Color(0xFFFFC107); // Amber yellow (Ironing/Maintenance)
  static const Color tableReserved = Color(0xFF29B6F6);    // Sky blue

  // Brand & Accent
  static const Color brandAccent = Color(0xFF7C4DFF);     // Electric purple for admin actions & POS
  static const Color brandAccentLight = Color(0xFF9E77FF);
  static const Color brandAccentDark = Color(0xFF5E35B1);

  // Semantic
  static const Color success = Color(0xFF00E676);
  static const Color error = Color(0xFFFF355E);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF29B6F6);
}
