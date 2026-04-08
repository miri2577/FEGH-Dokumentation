import 'package:flutter/material.dart';
import 'package:material_color_utilities/material_color_utilities.dart';
import '../models/ui_customization.dart';

class ThemeConfig {
  static const Color _seedColor = Color(0xFF1976D2); // Material Blue

  // Erweiterte Farbpalette für bessere Zugänglichkeit
  static const Color _primaryBlue = Color(0xFF1976D2);
  static const Color _secondaryIndigo = Color(0xFF3F51B5);
  static const Color _tertiaryTeal = Color(0xFF009688);
  static const Color _errorRed = Color(0xFFD32F2F);
  static const Color _warningOrange = Color(0xFFFF9800);
  static const Color _successGreen = Color(0xFF4CAF50);

  static ThemeData createLightTheme({
    ColorScheme? dynamicColorScheme,
    UICustomization ui = const UICustomization(),
  }) {
    final colorScheme = dynamicColorScheme ??
        ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.light,
        );

    return _buildTheme(
      colorScheme: colorScheme,
      ui: ui,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
      outlineAlpha: 0.2,
    );
  }

  static ThemeData createDarkTheme({
    ColorScheme? dynamicColorScheme,
    UICustomization ui = const UICustomization(),
  }) {
    final colorScheme = dynamicColorScheme ??
        ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.dark,
        );

    return _buildTheme(
      colorScheme: colorScheme,
      ui: ui,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      outlineAlpha: 0.3,
    );
  }

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required UICustomization ui,
    required Color shadowColor,
    required double outlineAlpha,
  }) {
    final fs = ui.fontScale;
    final ss = ui.spacingScale;
    final brs = ui.borderRadiusScale;
    final ics = ui.iconScale;
    final lh = ui.lineHeightScale;

    // Card style configuration
    CardThemeData cardTheme;
    switch (ui.cardStyle) {
      case CardStyle.outlined:
        cardTheme = CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20 * brs),
            side: BorderSide(
              color: colorScheme.outline.withValues(alpha: outlineAlpha),
              width: 1,
            ),
          ),
          color: colorScheme.surface,
          shadowColor: shadowColor,
        );
        break;
      case CardStyle.elevated:
        cardTheme = CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20 * brs),
          ),
          color: colorScheme.surface,
          shadowColor: shadowColor,
        );
        break;
      case CardStyle.flat:
        cardTheme = CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20 * brs),
          ),
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          shadowColor: Colors.transparent,
        );
        break;
    }

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,

      // Typography
      typography: Typography.material2021(),

      // Icon Theme
      iconTheme: IconThemeData(
        size: 24 * ics,
        color: colorScheme.onSurface,
      ),

      // App Bar Theme
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: TextStyle(
          fontSize: 20 * fs,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
          height: lh,
        ),
        iconTheme: IconThemeData(
          color: colorScheme.onSurface,
          size: 24 * ics,
        ),
      ),

      // Card Theme
      cardTheme: cardTheme,

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: 32 * ss, vertical: 16 * ss),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16 * brs),
          ),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          textStyle: TextStyle(fontSize: 14 * fs, height: lh),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: 32 * ss, vertical: 16 * ss),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16 * brs),
          ),
          textStyle: TextStyle(fontSize: 14 * fs, height: lh),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 24 * ss, vertical: 12 * ss),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12 * brs),
          ),
          textStyle: TextStyle(fontSize: 14 * fs, height: lh),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 32 * ss, vertical: 16 * ss),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16 * brs),
          ),
          side: BorderSide(color: colorScheme.outline),
          textStyle: TextStyle(fontSize: 14 * fs, height: lh),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16 * brs),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16 * brs),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16 * brs),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16 * brs),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 1,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 20 * ss, vertical: 16 * ss),
        hintStyle: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.6),
          fontSize: 14 * fs,
          height: lh,
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20 * brs),
        ),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      ),

      // Navigation Bar
      navigationBarTheme: NavigationBarThemeData(
        height: 80,
        elevation: 0,
        backgroundColor: colorScheme.surface.withValues(alpha: 0.95),
        indicatorColor: colorScheme.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: colorScheme.onPrimaryContainer,
              size: 24 * ics,
            );
          }
          return IconThemeData(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
            size: 24 * ics,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 12 * fs,
              height: lh,
            );
          }
          return TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
            fontSize: 12 * fs,
            height: lh,
          );
        }),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24 * brs),
        ),
        backgroundColor: colorScheme.surface,
        titleTextStyle: TextStyle(
          fontSize: 20 * fs,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
          height: lh,
        ),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: BottomSheetThemeData(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24 * brs)),
        ),
        backgroundColor: colorScheme.surface,
      ),

      // List Tile Theme
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12 * brs),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16 * ss, vertical: 8 * ss),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        elevation: 0,
        pressElevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16 * brs),
        ),
        backgroundColor: colorScheme.surfaceContainerHighest,
        labelStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 14 * fs,
          height: lh,
        ),
        padding: EdgeInsets.symmetric(horizontal: 12 * ss, vertical: 8 * ss),
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimary;
          }
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.surfaceContainerHighest;
        }),
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: colorScheme.outline.withValues(alpha: outlineAlpha),
        thickness: 1,
        space: 1,
      ),

      // TextTheme with scaled sizes
      textTheme: TextTheme(
        displayLarge: TextStyle(fontSize: 57 * fs, height: lh),
        displayMedium: TextStyle(fontSize: 45 * fs, height: lh),
        displaySmall: TextStyle(fontSize: 36 * fs, height: lh),
        headlineLarge: TextStyle(fontSize: 32 * fs, height: lh),
        headlineMedium: TextStyle(fontSize: 28 * fs, height: lh),
        headlineSmall: TextStyle(fontSize: 24 * fs, height: lh),
        titleLarge: TextStyle(fontSize: 22 * fs, height: lh),
        titleMedium: TextStyle(fontSize: 16 * fs, height: lh, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(fontSize: 14 * fs, height: lh, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(fontSize: 16 * fs, height: lh),
        bodyMedium: TextStyle(fontSize: 14 * fs, height: lh),
        bodySmall: TextStyle(fontSize: 12 * fs, height: lh),
        labelLarge: TextStyle(fontSize: 14 * fs, height: lh, fontWeight: FontWeight.w500),
        labelMedium: TextStyle(fontSize: 12 * fs, height: lh, fontWeight: FontWeight.w500),
        labelSmall: TextStyle(fontSize: 11 * fs, height: lh, fontWeight: FontWeight.w500),
      ),

      // DataTable Theme
      dataTableTheme: DataTableThemeData(
        dataTextStyle: TextStyle(fontSize: 14 * fs, height: lh),
        headingTextStyle: TextStyle(fontSize: 14 * fs, height: lh, fontWeight: FontWeight.w600),
        dataRowMinHeight: ui.tableRowHeight,
        dataRowMaxHeight: ui.tableRowHeight + 16,
      ),
    );
  }

  // Hilfsfarben für spezielle UI-Elemente
  static const Map<String, Color> semanticColors = {
    'success': _successGreen,
    'warning': _warningOrange,
    'error': _errorRed,
    'info': _primaryBlue,
  };

  // Responsive Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Spacing Constants
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing48 = 48.0;
  static const double spacing64 = 64.0;

  // Border Radius Constants
  static const double borderRadius8 = 8.0;
  static const double borderRadius12 = 12.0;
  static const double borderRadius16 = 16.0;
  static const double borderRadius20 = 20.0;
  static const double borderRadius24 = 24.0;
}
