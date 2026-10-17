import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App typography.
///
/// Headings use *Poppins*; body, input and caption text use *Inter*. Colours are
/// intentionally unset so the styles can be dropped into [ThemeData.textTheme]
/// and coloured per-brightness by the theme — use `copyWith(color: ...)` when a
/// muted/variant colour is needed.
abstract final class AppTextStyles {
  // ---------------------------------------------------------------------------
  // Headings
  // ---------------------------------------------------------------------------
  static final TextStyle h1 = GoogleFonts.poppins(
    fontSize: 30,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
  );

  static final TextStyle h2 = GoogleFonts.poppins(
    fontSize: 24,
    height: 1.25,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
  );

  static final TextStyle h3 = GoogleFonts.poppins(
    fontSize: 20,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );

  // ---------------------------------------------------------------------------
  // Body
  // ---------------------------------------------------------------------------
  static final TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    height: 1.6,
    fontWeight: FontWeight.w400,
  );

  static final TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    height: 1.55,
    fontWeight: FontWeight.w400,
  );

  static final TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12.5,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );

  // ---------------------------------------------------------------------------
  // Supporting
  // ---------------------------------------------------------------------------
  static final TextStyle subtitle = GoogleFonts.inter(
    fontSize: 15,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );

  static final TextStyle button = GoogleFonts.inter(
    fontSize: 15,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  static final TextStyle input = GoogleFonts.inter(
    fontSize: 15,
    height: 1.4,
    fontWeight: FontWeight.w400,
  );

  static final TextStyle label = GoogleFonts.inter(
    fontSize: 13,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  static final TextStyle caption = GoogleFonts.inter(
    fontSize: 11.5,
    height: 1.4,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
  );
}
