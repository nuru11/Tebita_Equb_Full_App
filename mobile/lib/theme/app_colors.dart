import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  /// Main brand blue – CTAs, nav selected, highlights.
  static const Color primary = Color(0xFF2563EB);

  /// Same as [primary]; use for explicit “brand accent” reads in code.
  static const Color brandAccent = primary;

  /// Sky blue – secondary highlights (cards, borders) paired with [primary].
  static const Color secondary = Color(0xFF0EA5E9);

  static const Color accent = Color(0xFFF59E0B); // amber (sparse use)

  // Neutrals
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE5E7EB);

  /// Positive / completed / “available” – aligned with brand blue (not green).
  static const Color success = primary;

  static const Color warning = Color(0xFFF97316);
  static const Color error = Color(0xFFDC2626);
}
