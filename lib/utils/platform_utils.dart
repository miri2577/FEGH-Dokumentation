import 'package:flutter/foundation.dart';
import 'package:universal_io/io.dart';

class PlatformUtils {
  
  // Platform Detection
  static bool get isWeb => kIsWeb;
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;
  static bool get isIOS => !kIsWeb && Platform.isIOS;
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;
  static bool get isWindows => !kIsWeb && Platform.isWindows;
  static bool get isLinux => !kIsWeb && Platform.isLinux;
  static bool get isFuchsia => !kIsWeb && Platform.isFuchsia;
  
  // Desktop Platforms
  static bool get isDesktopPlatform => isMacOS || isWindows || isLinux;
  
  // Mobile Platforms
  static bool get isMobilePlatform => isAndroid || isIOS;
  
  // Feature Availability
  static bool get supportsBiometricAuth => isMobilePlatform && !isWeb;
  static bool get supportsSpeechToText => (isMobilePlatform || isWeb) && !isWeb; // Derzeit nur Mobile
  static bool get supportsFileSystem => !isWeb;
  static bool get supportsNotifications => isMobilePlatform;
  static bool get supportsCalendarIntegration => isMobilePlatform;
  static bool get supportsSecureStorage => !isWeb;
  static bool get supportsBackgroundProcessing => !isWeb;
  
  // Web-specific features
  static bool get supportsWebShare => isWeb;
  static bool get supportsLocalStorage => isWeb;
  static bool get supportsURLNavigation => isWeb;
  static bool get supportsBrowserNotifications => isWeb;
  static bool get supportsOfflineStorage => isWeb;
  
  // Platform-specific UI adjustments
  static bool get useNativeScrollBars => isDesktopPlatform;
  static bool get useHoverEffects => isDesktopPlatform || isWeb;
  static bool get useRightClickContextMenus => isDesktopPlatform || isWeb;
  static bool get useTouchFriendlyUI => isMobilePlatform;
  static bool get useKeyboardShortcuts => isDesktopPlatform || isWeb;
  
  // Performance considerations
  static bool get shouldUseCachedNetworkImages => isMobilePlatform;
  static bool get shouldLimitAnimations => isWeb; // Web kann langsamer sein
  static bool get shouldUseVirtualization => isDesktopPlatform || isWeb;
  
  // Storage capabilities
  static String get defaultStorageLocation {
    if (isWeb) return 'browser_storage';
    if (isAndroid) return 'app_documents';
    if (isIOS) return 'app_documents';
    if (isMacOS) return 'user_documents';
    if (isWindows) return 'user_documents';
    if (isLinux) return 'user_documents';
    return 'app_documents';
  }
  
  // Default authentication method
  static String get defaultAuthMethod {
    if (supportsBiometricAuth) return 'biometric';
    if (isWeb) return 'password';
    return 'passcode';
  }
  
  // Platform-specific error messages
  static String get biometricNotSupportedMessage {
    if (isWeb) {
      return 'Biometrische Authentifizierung ist im Browser nicht verfügbar. Verwenden Sie ein sicheres Passwort.';
    }
    if (isDesktopPlatform) {
      return 'Biometrische Authentifizierung ist auf dem Desktop nicht verfügbar.';
    }
    return 'Biometrische Authentifizierung ist auf diesem Gerät nicht verfügbar.';
  }
  
  static String get speechNotSupportedMessage {
    if (isWeb) {
      return 'Spracherkennung ist derzeit im Browser nicht verfügbar. Verwenden Sie die Tastatur für die Texteingabe.';
    }
    return 'Spracherkennung ist auf diesem Gerät nicht verfügbar.';
  }
  
  static String get fileSystemNotSupportedMessage {
    if (isWeb) {
      return 'Direkter Dateizugriff ist im Browser eingeschränkt. Verwenden Sie die Download-/Upload-Funktionen.';
    }
    return 'Dateisystem-Zugriff ist nicht verfügbar.';
  }
  
  // Platform-specific fallbacks
  static Map<String, dynamic> getAuthenticationConfig() {
    return {
      'biometric_enabled': supportsBiometricAuth,
      'password_required': isWeb,
      'auto_logout_minutes': isWeb ? 30 : 0, // Web: Auto-logout nach Inaktivität
      'session_storage': isWeb ? 'session' : 'secure',
    };
  }
  
  static Map<String, dynamic> getStorageConfig() {
    return {
      'use_local_storage': !isWeb,
      'use_session_storage': isWeb,
      'encryption_enabled': !isWeb,
      'auto_backup': !isWeb,
      'max_storage_mb': isWeb ? 50 : 500,
    };
  }
  
  static Map<String, dynamic> getUIConfig() {
    return {
      'show_debug_info': kDebugMode,
      'enable_hover_effects': useHoverEffects,
      'enable_context_menus': useRightClickContextMenus,
      'enable_keyboard_shortcuts': useKeyboardShortcuts,
      'animation_duration_ms': shouldLimitAnimations ? 200 : 300,
      'use_native_scrollbars': useNativeScrollBars,
    };
  }
  
  // Browser-specific detection (nur für Web)
  static String get browserType {
    if (!isWeb) return 'not_web';
    
    final userAgent = kIsWeb ? 'unknown' : 'unknown';
    // In echten Web-Apps könnte hier window.navigator.userAgent verwendet werden
    return userAgent;
  }
  
  // Platform-specific feature warnings
  static List<String> getFeatureWarnings() {
    List<String> warnings = [];
    
    if (isWeb) {
      warnings.addAll([
        'Biometrische Authentifizierung nicht verfügbar',
        'Spracherkennung eingeschränkt',
        'Dateisystem-Zugriff eingeschränkt',
        'Kalender-Integration nicht verfügbar',
      ]);
    }
    
    if (isDesktopPlatform) {
      warnings.addAll([
        'Biometrische Authentifizierung nicht verfügbar',
        'Push-Benachrichtigungen eingeschränkt',
      ]);
    }
    
    return warnings;
  }
  
  // Platform-specific recommendations
  static List<String> getPlatformRecommendations() {
    List<String> recommendations = [];
    
    if (isWeb) {
      recommendations.addAll([
        'Verwenden Sie ein starkes Passwort für die Anmeldung',
        'Speichern Sie wichtige Daten regelmäßig durch Export',
        'Verwenden Sie moderne Browser für beste Performance',
      ]);
    }
    
    if (isMobilePlatform) {
      recommendations.addAll([
        'Aktivieren Sie biometrische Authentifizierung für mehr Sicherheit',
        'Erlauben Sie Mikrofon-Zugriff für Spracherkennung',
        'Aktivieren Sie Benachrichtigungen für Terminerinnerungen',
      ]);
    }
    
    if (isDesktopPlatform) {
      recommendations.addAll([
        'Verwenden Sie Tastenkürzel für effizientere Bedienung',
        'Nutzen Sie die größere Bildschirmfläche für Multi-Tasking',
      ]);
    }
    
    return recommendations;
  }
  
  // Development helpers
  static String get platformDebugInfo {
    return '''
Platform: ${_getCurrentPlatform()}
Web: $isWeb
Mobile: $isMobilePlatform  
Desktop: $isDesktopPlatform
Biometric Auth: $supportsBiometricAuth
Speech-to-Text: $supportsSpeechToText
File System: $supportsFileSystem
''';
  }
  
  static String _getCurrentPlatform() {
    if (isWeb) return 'Web';
    if (isAndroid) return 'Android';
    if (isIOS) return 'iOS';
    if (isMacOS) return 'macOS';
    if (isWindows) return 'Windows';
    if (isLinux) return 'Linux';
    if (isFuchsia) return 'Fuchsia';
    return 'Unknown';
  }
}