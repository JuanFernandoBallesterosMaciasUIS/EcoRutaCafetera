import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// EcoRuta Cafetera - Material 3 Design System
/// Paleta inspirada en el ecosistema cafetero de Santander
class EcoRutaColors {
  EcoRutaColors._();

  // Primary - Deep Forest Green
  static const Color primary = Color(0xFF00450D);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF1B5E20);
  static const Color onPrimaryContainer = Color(0xFF90D689);
  static const Color primaryFixed = Color(0xFFACF4A4);
  static const Color primaryFixedDim = Color(0xFF91D78A);
  static const Color onPrimaryFixed = Color(0xFF002203);
  static const Color onPrimaryFixedVariant = Color(0xFF0C5216);
  static const Color inversePrimary = Color(0xFF91D78A);

  // Secondary - Vibrant Green
  static const Color secondary = Color(0xFF006E1C);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFF91F78E);
  static const Color onSecondaryContainer = Color(0xFF00731E);
  static const Color secondaryFixed = Color(0xFF94F990);
  static const Color secondaryFixedDim = Color(0xFF78DC77);
  static const Color onSecondaryFixed = Color(0xFF002204);
  static const Color onSecondaryFixedVariant = Color(0xFF005313);

  // Tertiary - Warm Earth Tones (café)
  static const Color tertiary = Color(0xFF4D352B);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFF674B41);
  static const Color onTertiaryContainer = Color(0xFFE2BDB0);
  static const Color tertiaryFixed = Color(0xFFFFDBCE);
  static const Color tertiaryFixedDim = Color(0xFFE4BEB2);
  static const Color onTertiaryFixed = Color(0xFF2B160F);
  static const Color onTertiaryFixedVariant = Color(0xFF5B4137);

  // Error
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  // Surface & Background
  static const Color background = Color(0xFFF9F9F9);
  static const Color onBackground = Color(0xFF1A1C1C);
  static const Color surface = Color(0xFFF9F9F9);
  static const Color onSurface = Color(0xFF1A1C1C);
  static const Color surfaceDim = Color(0xFFDADADA);
  static const Color surfaceBright = Color(0xFFF9F9F9);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF3F3F3);
  static const Color surfaceContainer = Color(0xFFEEEEEE);
  static const Color surfaceContainerHigh = Color(0xFFE8E8E8);
  static const Color surfaceContainerHighest = Color(0xFFE2E2E2);
  static const Color onSurfaceVariant = Color(0xFF41493E);
  static const Color surfaceVariant = Color(0xFFE2E2E2);

  // Outline
  static const Color outline = Color(0xFF717A6D);
  static const Color outlineVariant = Color(0xFFC0C9BB);

  // Inverse
  static const Color inverseSurface = Color(0xFF2F3131);
  static const Color inverseOnSurface = Color(0xFFF1F1F1);
  static const Color surfaceTint = Color(0xFF2A6B2C);
}

class EcoRutaTheme {
  EcoRutaTheme._();

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: EcoRutaColors.primary,
      onPrimary: EcoRutaColors.onPrimary,
      primaryContainer: EcoRutaColors.primaryContainer,
      onPrimaryContainer: EcoRutaColors.onPrimaryContainer,
      secondary: EcoRutaColors.secondary,
      onSecondary: EcoRutaColors.onSecondary,
      secondaryContainer: EcoRutaColors.secondaryContainer,
      onSecondaryContainer: EcoRutaColors.onSecondaryContainer,
      tertiary: EcoRutaColors.tertiary,
      onTertiary: EcoRutaColors.onTertiary,
      tertiaryContainer: EcoRutaColors.tertiaryContainer,
      onTertiaryContainer: EcoRutaColors.onTertiaryContainer,
      error: EcoRutaColors.error,
      onError: EcoRutaColors.onError,
      errorContainer: EcoRutaColors.errorContainer,
      onErrorContainer: EcoRutaColors.onErrorContainer,
      surface: EcoRutaColors.surface,
      onSurface: EcoRutaColors.onSurface,
      onSurfaceVariant: EcoRutaColors.onSurfaceVariant,
      outline: EcoRutaColors.outline,
      outlineVariant: EcoRutaColors.outlineVariant,
      inverseSurface: EcoRutaColors.inverseSurface,
      onInverseSurface: EcoRutaColors.inverseOnSurface,
      inversePrimary: EcoRutaColors.inversePrimary,
      surfaceTint: EcoRutaColors.surfaceTint,
    );

    final textTheme = GoogleFonts.hankenGroteskTextTheme().copyWith(
      displayLarge: GoogleFonts.hankenGrotesk(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02 * 30,
        height: 36 / 30,
        color: EcoRutaColors.onBackground,
      ),
      headlineLarge: GoogleFonts.hankenGrotesk(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        height: 1.2,
        color: EcoRutaColors.onBackground,
      ),
      headlineMedium: GoogleFonts.hankenGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 32 / 24,
        color: EcoRutaColors.onBackground,
      ),
      headlineSmall: GoogleFonts.hankenGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 28 / 20,
        color: EcoRutaColors.onBackground,
      ),
      titleLarge: GoogleFonts.hankenGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: EcoRutaColors.onBackground,
      ),
      bodyLarge: GoogleFonts.hankenGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
        color: EcoRutaColors.onBackground,
      ),
      bodyMedium: GoogleFonts.hankenGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
        color: EcoRutaColors.onBackground,
      ),
      labelLarge: GoogleFonts.hankenGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.01 * 14,
        height: 20 / 14,
      ),
      labelMedium: GoogleFonts.hankenGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.04 * 12,
        height: 16 / 12,
      ),
      labelSmall: GoogleFonts.hankenGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.04 * 12,
        height: 16 / 12,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: EcoRutaColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: EcoRutaColors.surface,
        foregroundColor: EcoRutaColors.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: EcoRutaColors.outlineVariant.withOpacity(0.5),
        titleTextStyle: GoogleFonts.hankenGrotesk(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: EcoRutaColors.primary,
        ),
      ),
      cardTheme: CardThemeData(
        color: EcoRutaColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side:
              BorderSide(color: EcoRutaColors.outlineVariant.withOpacity(0.3)),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: EcoRutaColors.secondary,
          foregroundColor: EcoRutaColors.onSecondary,
          elevation: 4,
          shadowColor: EcoRutaColors.secondary.withOpacity(0.4),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.hankenGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.14,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: EcoRutaColors.primary,
          side: const BorderSide(color: EcoRutaColors.primary, width: 2),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.hankenGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.14,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: EcoRutaColors.surfaceContainer,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: EcoRutaColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: EcoRutaColors.error, width: 1.5),
        ),
        labelStyle: GoogleFonts.hankenGrotesk(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: EcoRutaColors.onSurfaceVariant,
          letterSpacing: 0.04 * 12,
        ),
        hintStyle: GoogleFonts.hankenGrotesk(
          fontSize: 14,
          color: EcoRutaColors.onSurfaceVariant.withOpacity(0.5),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return EcoRutaColors.secondary;
          }
          return null;
        }),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: EcoRutaColors.surfaceContainer,
        indicatorColor: EcoRutaColors.secondaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
                color: EcoRutaColors.onSecondaryContainer);
          }
          return const IconThemeData(color: EcoRutaColors.onSurfaceVariant);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return GoogleFonts.hankenGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? EcoRutaColors.onSecondaryContainer
                : EcoRutaColors.onSurfaceVariant,
          );
        }),
        elevation: 8,
        shadowColor: Colors.black26,
      ),
      dividerTheme: const DividerThemeData(
        color: EcoRutaColors.outlineVariant,
        thickness: 1,
      ),
    );
  }
}
