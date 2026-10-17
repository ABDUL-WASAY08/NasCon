import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App typography.
///
/// Headings use *Poppins*; body, input, captions and table text use *Inter*.
/// Colours are intentionally unset so the styles drop straight into
/// [ThemeData.textTheme] and are coloured per-brightness by the theme — use
/// `copyWith(color: ...)` (or `context.semantic`) when a variant is needed.
abstract final class AppTextStyles {
  // ---------------------------------------------------------------------------
  // Display & headings
  // ---------------------------------------------------------------------------
  static final TextStyle display = GoogleFonts.poppins(
    fontSize: 32,
    height: 1.15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
  );

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

  static final TextStyle primaryButton = GoogleFonts.inter(
    fontSize: 15,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  /// Retained name for existing call sites.
  static final TextStyle button = primaryButton;

  static final TextStyle secondaryButton = GoogleFonts.inter(
    fontSize: 14.5,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
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

  static final TextStyle helper = GoogleFonts.inter(
    fontSize: 11.5,
    height: 1.35,
    fontWeight: FontWeight.w400,
  );

  // ---------------------------------------------------------------------------
  // Data display
  // ---------------------------------------------------------------------------
  static final TextStyle tableHeading = GoogleFonts.inter(
    fontSize: 12,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
  );

  static final TextStyle score = GoogleFonts.poppins(
    fontSize: 40,
    height: 1,
    fontWeight: FontWeight.w700,
    letterSpacing: -1,
  );

  static final TextStyle price = GoogleFonts.poppins(
    fontSize: 18,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );

  static final TextStyle status = GoogleFonts.inter(
    fontSize: 12,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );
}
