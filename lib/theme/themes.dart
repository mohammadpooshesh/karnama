import 'package:flutter/material.dart';

class AppTheme {
  final String name;
  final ThemeData light;
  final ThemeData dark;

  const AppTheme({required this.name, required this.light, required this.dark});
}

class AppThemes {
  static final themes = <AppTheme>[
    AppTheme(name: 'Karnama', light: _karnamaLight, dark: _karnamaDark),
    AppTheme(name: 'Nature', light: _natureLight, dark: _natureDark),
    AppTheme(name: 'Rose', light: _roseLight, dark: _roseDark),
  ];

  static final ThemeData _karnamaLight = _buildTheme(
    primary: const Color(0xFF036DEC),
    secondary: const Color(0xFF0CCAAE),
    scaffoldBg: const Color(0xFFF5F5F7),
    brightness: Brightness.light,
  );

  static final ThemeData _karnamaDark = _buildTheme(
    primary: const Color(0xFF036DEC),
    secondary: const Color(0xFF0CCAAE),
    scaffoldBg: const Color(0xFF050719),
    brightness: Brightness.dark,
  );

  static final ThemeData _natureLight = _buildTheme(
    primary: const Color(0xFF2D6A4F),
    secondary: const Color(0xFF52B788),
    scaffoldBg: const Color(0xFFF5F5F7),
    brightness: Brightness.light,
  );

  static final ThemeData _natureDark = _buildTheme(
    primary: const Color(0xFF2D6A4F),
    secondary: const Color(0xFF52B788),
    scaffoldBg: const Color(0xFF081C15),
    brightness: Brightness.dark,
  );

  static final ThemeData _roseLight = _buildTheme(
    primary: const Color(0xFF7C3AED),
    secondary: const Color(0xFFEC4899),
    scaffoldBg: const Color(0xFFF5F5F7),
    brightness: Brightness.light,
  );

  static final ThemeData _roseDark = _buildTheme(
    primary: const Color(0xFF7C3AED),
    secondary: const Color(0xFFEC4899),
    scaffoldBg: const Color(0xFF0F0A1A),
    brightness: Brightness.dark,
  );

  static ThemeData _buildTheme({
    required Color primary,
    required Color secondary,
    required Color scaffoldBg,
    required Brightness brightness,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: secondary,
      brightness: brightness,
    );
    final isDark = brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF043C98) : Colors.white;
    final cardColor = isDark ? const Color(0xFF1C2333) : Colors.white;
    final onSurface = isDark ? Colors.white : Colors.black;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Vazir',
      scaffoldBackgroundColor: scaffoldBg,
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: onSurface.withValues(alpha: 0.06)),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 56,
        backgroundColor: surfaceColor,
        indicatorColor: primary.withValues(alpha: 0.12),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'Vazir');
          }
          return const TextStyle(fontSize: 11, fontFamily: 'Vazir');
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(size: 22, color: primary);
          }
          return const IconThemeData(size: 22, color: Color(0xFF8E8E93));
        }),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, fontFamily: 'Vazir'),
        headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, fontFamily: 'Vazir'),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'Vazir'),
        titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Vazir'),
        titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, fontFamily: 'Vazir'),
        bodyLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, fontFamily: 'Vazir'),
        bodyMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, fontFamily: 'Vazir'),
        bodySmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w400, fontFamily: 'Vazir'),
        labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, fontFamily: 'Vazir'),
        labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, fontFamily: 'Vazir'),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: isDark ? Colors.black : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Vazir'),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary, width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Vazir'),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, fontFamily: 'Vazir'),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1C2333) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: onSurface.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: onSurface.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFA0A0A0), fontFamily: 'Vazir'),
        labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF666666), fontFamily: 'Vazir'),
      ),
      dividerTheme: DividerThemeData(
        color: onSurface.withValues(alpha: 0.06),
        thickness: 1,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
