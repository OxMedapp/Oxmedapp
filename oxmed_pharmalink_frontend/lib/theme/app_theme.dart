import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const oxfordNavy = Color(0xFF0A1B3D);
  static const royalBlue = Color(0xFF1E5BFF);
  static const limeGreen = Color(0xFF8CC63F);
  static const tealGreen = Color(0xFF009E8F);
  static const redAccent = Color(0xFFE53935);
  static const white = Colors.white;
  static const lightGrey = Color(0xFFF5F6FA);
  static const borderGrey = Color(0xFFE0E4EA);
  static const darkText = Color(0xFF1A1A2E);
  static const mutedText = Color(0xFF7A8290);
  static const urgentOrange = Color(0xFFFB8C00);

  // Gradient
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [oxfordNavy, royalBlue],
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      primaryColor: AppColors.oxfordNavy,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.oxfordNavy,
        secondary: AppColors.royalBlue,
        surface: AppColors.white,
        error: AppColors.redAccent,
      ),
      scaffoldBackgroundColor: AppColors.lightGrey,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.oxfordNavy,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.oxfordNavy,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.borderGrey.withValues(alpha: 0.5)),
        ),
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        bodyLarge: const TextStyle(color: AppColors.darkText),
        bodyMedium: const TextStyle(color: AppColors.darkText),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.royalBlue, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.mutedText),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.oxfordNavy,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle:
              GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith<Color>(
            (states) => states.contains(WidgetState.pressed)
                ? AppColors.royalBlue
                : AppColors.oxfordNavy,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.oxfordNavy,
          side: const BorderSide(color: AppColors.oxfordNavy, width: 1.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle:
              GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme:
          const DividerThemeData(color: AppColors.borderGrey, thickness: 1),
    );
  }
}
