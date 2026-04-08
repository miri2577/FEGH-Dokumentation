import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

class ResponsiveUtils {
  
  static bool isMobile(BuildContext context) {
    return ResponsiveBreakpoints.of(context).isMobile;
  }
  
  static bool isTablet(BuildContext context) {
    return ResponsiveBreakpoints.of(context).isTablet;
  }
  
  static bool isDesktop(BuildContext context) {
    return ResponsiveBreakpoints.of(context).isDesktop;
  }
  
  static bool isLargeScreen(BuildContext context) {
    return ResponsiveBreakpoints.of(context).largerThan(TABLET);
  }
  
  static bool isSmallScreen(BuildContext context) {
    return ResponsiveBreakpoints.of(context).smallerThan(TABLET);
  }

  // Dynamische Grid-Columns basierend auf Bildschirmgröße
  static int getGridColumns(BuildContext context) {
    if (isMobile(context)) return 2;
    if (isTablet(context)) return 3;
    return 4; // Desktop
  }

  // Dynamische Padding basierend auf Bildschirmgröße  
  static EdgeInsets getScreenPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(16);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(24);
    } else {
      return const EdgeInsets.all(32);
    }
  }

  // Dynamische Card-Padding
  static EdgeInsets getCardPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(16);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(20);
    } else {
      return const EdgeInsets.all(24);
    }
  }

  // Dynamische Font-Größen
  static double getHeadlineFontSize(BuildContext context) {
    if (isMobile(context)) return 24;
    if (isTablet(context)) return 28;
    return 32; // Desktop
  }

  static double getTitleFontSize(BuildContext context) {
    if (isMobile(context)) return 18;
    if (isTablet(context)) return 20;
    return 22; // Desktop
  }

  static double getBodyFontSize(BuildContext context) {
    if (isMobile(context)) return 14;
    if (isTablet(context)) return 15;
    return 16; // Desktop
  }

  // Dynamische Spacing
  static double getSpacing(BuildContext context, {double mobile = 16, double tablet = 20, double desktop = 24}) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  // Maximale Content-Breite für Desktop
  static double getMaxContentWidth(BuildContext context) {
    return isDesktop(context) ? 1200 : double.infinity;
  }

  // Card-Aspekt-Verhältnis für verschiedene Bildschirmgrößen
  static double getCardAspectRatio(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;

    if (isMobile(context)) {
      return isLandscape ? 1.8 : 1.2; // Landscape: breitere Cards
    }
    if (isTablet(context)) return 1.3;
    return 1.4; // Desktop
  }

  // Navigation-Typ basierend auf Bildschirmgröße
  static NavigationType getNavigationType(BuildContext context) {
    if (isDesktop(context)) return NavigationType.rail;
    if (isTablet(context)) return NavigationType.drawer;
    return NavigationType.bottom;
  }

  // FAB-Position basierend auf Navigation-Typ
  static FloatingActionButtonLocation getFABLocation(BuildContext context) {
    // Einheitlich alle FABs rechts unten positionieren
    return FloatingActionButtonLocation.endFloat;
  }

  // Sidebar-Breite für Desktop
  static double getSidebarWidth(BuildContext context) {
    return isDesktop(context) ? 280 : 0;
  }

  // Dialog-Breite für verschiedene Bildschirmgrößen
  static double getDialogWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (isMobile(context)) {
      return screenWidth * 0.9;
    } else if (isTablet(context)) {
      return screenWidth * 0.7;
    } else {
      return 600; // Fixed width für Desktop
    }
  }

  // Bottom Sheet Höhe
  static double getBottomSheetHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    if (isMobile(context)) {
      return screenHeight * 0.8;
    } else if (isTablet(context)) {
      return screenHeight * 0.7;
    } else {
      return 600; // Fixed height für Desktop
    }
  }

  // Adaptive List-Item-Height
  static double getListItemHeight(BuildContext context) {
    if (isMobile(context)) return 68;
    if (isTablet(context)) return 72;
    return 76; // Desktop
  }

  // App Bar Height
  static double getAppBarHeight(BuildContext context) {
    if (isMobile(context)) return kToolbarHeight;
    if (isTablet(context)) return 64;
    return 72; // Desktop
  }

  // Safe Area für Web
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    if (isDesktop(context)) {
      return EdgeInsets.zero; // Kein Safe Area auf Desktop
    }
    return MediaQuery.of(context).padding;
  }

  // Adaptive Border Radius
  static double getBorderRadius(BuildContext context, {double mobile = 12, double tablet = 16, double desktop = 20}) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  // Icon-Größen
  static double getIconSize(BuildContext context, {double mobile = 24, double tablet = 28, double desktop = 32}) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  // Animation-Dauer basierend auf Performance
  static Duration getAnimationDuration(BuildContext context) {
    // Auf schwächeren Geräten (meist Mobile) kürzere Animationen
    if (isMobile(context)) {
      return const Duration(milliseconds: 200);
    } else {
      return const Duration(milliseconds: 300);
    }
  }

  // Scaffold-Body mit adaptivem Layout
  static Widget adaptiveScaffoldBody({
    required BuildContext context,
    required Widget body,
    Widget? sidebar,
  }) {
    if (isDesktop(context) && sidebar != null) {
      return Row(
        children: [
          SizedBox(
            width: getSidebarWidth(context),
            child: sidebar,
          ),
          Expanded(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: getMaxContentWidth(context),
              ),
              child: body,
            ),
          ),
        ],
      );
    }
    
    return Container(
      constraints: BoxConstraints(
        maxWidth: getMaxContentWidth(context),
      ),
      child: body,
    );
  }

  // Adaptive Grid View
  static Widget adaptiveGridView({
    required BuildContext context,
    required List<Widget> children,
    double? childAspectRatio,
    double? mainAxisSpacing,
    double? crossAxisSpacing,
  }) {
    return GridView.count(
      crossAxisCount: getGridColumns(context),
      childAspectRatio: childAspectRatio ?? getCardAspectRatio(context),
      mainAxisSpacing: mainAxisSpacing ?? getSpacing(context),
      crossAxisSpacing: crossAxisSpacing ?? getSpacing(context),
      padding: getScreenPadding(context),
      children: children,
    );
  }

  // Adaptive Container
  static Widget adaptiveContainer({
    required BuildContext context,
    required Widget child,
    EdgeInsets? padding,
    EdgeInsets? margin,
    double? borderRadius,
  }) {
    return Container(
      padding: padding ?? getCardPadding(context),
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          borderRadius ?? getBorderRadius(context),
        ),
      ),
      child: child,
    );
  }
}

enum NavigationType {
  bottom,
  drawer,
  rail,
}