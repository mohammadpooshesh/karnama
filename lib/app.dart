import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/timer_provider.dart';
import 'providers/worklog_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/log_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'l10n/strings_fa.dart';

const _primaryColor = Color(0xFFE8731A);
const _accentColor = Color(0xFFFF9F43);
const _darkBg = Color(0xFF0D1117);
const _darkSurface = Color(0xFF161B22);
const _darkCard = Color(0xFF1C2333);

class KarnamaApp extends StatelessWidget {
  const KarnamaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TimerProvider()),
        ChangeNotifierProvider(create: (_) => WorkLogProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const Directionality(
              textDirection: TextDirection.rtl,
              child: MainShell(),
            ),
          );
        },
      ),
    );
  }

  ThemeData _buildLightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primaryColor,
      primary: _primaryColor,
      secondary: _accentColor,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Vazir',
      scaffoldBackgroundColor: const Color(0xFFF5F5F7),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.04)),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 56,
        indicatorColor: _primaryColor.withValues(alpha: 0.12),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'Vazir');
          }
          return const TextStyle(fontSize: 11, fontFamily: 'Vazir');
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(size: 22, color: _primaryColor);
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
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Vazir'),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryColor,
          side: const BorderSide(color: _primaryColor, width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Vazir'),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primaryColor,
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, fontFamily: 'Vazir'),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _primaryColor, width: 1.5),
        ),
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFA0A0A0), fontFamily: 'Vazir'),
        labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF666666), fontFamily: 'Vazir'),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.black.withValues(alpha: 0.06),
        thickness: 1,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primaryColor,
      primary: _accentColor,
      secondary: _primaryColor,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Vazir',
      scaffoldBackgroundColor: _darkBg,
      cardTheme: CardThemeData(
        elevation: 0,
        color: _darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 56,
        backgroundColor: _darkSurface,
        indicatorColor: _accentColor.withValues(alpha: 0.15),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'Vazir');
          }
          return const TextStyle(fontSize: 11, fontFamily: 'Vazir');
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(size: 22, color: _accentColor);
          }
          return const IconThemeData(size: 22, color: Color(0xFF6B7280));
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
          backgroundColor: _accentColor,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Vazir'),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _accentColor,
          side: const BorderSide(color: _accentColor, width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Vazir'),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _accentColor,
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, fontFamily: 'Vazir'),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _accentColor, width: 1.5),
        ),
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF6B7280), fontFamily: 'Vazir'),
        labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF), fontFamily: 'Vazir'),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.06),
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

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _screens = const [
    DashboardScreen(),
    LogScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final navTheme = NavigationBarTheme.of(context);
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: KeyedSubtree(
                key: ValueKey(_currentIndex),
                child: _screens[_currentIndex],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        height: 56,
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined, size: 22),
            selectedIcon: Icon(Icons.dashboard, size: 22),
            label: AppStrings.dashboard,
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline, size: 22),
            selectedIcon: Icon(Icons.add_circle, size: 22),
            label: AppStrings.newLog,
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined, size: 22),
            selectedIcon: Icon(Icons.history, size: 22),
            label: AppStrings.history,
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined, size: 22),
            selectedIcon: Icon(Icons.settings, size: 22),
            label: AppStrings.settings,
          ),
        ],
      ),
    );
  }
}

