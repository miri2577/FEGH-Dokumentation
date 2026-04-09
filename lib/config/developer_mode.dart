import 'package:flutter/foundation.dart';

/// Entwicklermodus-Konfiguration für sichere Entwicklung
///
/// WICHTIG: Diese Klasse steuert sicherheitsrelevante Features.
/// Vor Release MUSS sichergestellt werden, dass der Entwicklermodus deaktiviert ist!
class DeveloperMode {
  // Entwicklermodus wird über Build-Parameter aktiviert
  static const bool isDeveloperMode = bool.fromEnvironment('DEVELOPER_MODE', defaultValue: false);

  // Alternative: Für Tests kann der Entwicklermodus auch über Debug-Modus aktiviert werden
  static const bool allowDebugModeActivation = bool.fromEnvironment('ALLOW_DEBUG_DEV_MODE', defaultValue: false);

  /// Gibt zurück ob der Entwicklermodus aktiv ist
  static bool get isActive => isDeveloperMode || (allowDebugModeActivation && kDebugMode);

  /// Keychain-Verschlüsselung verwenden (in Dev-Modus deaktiviert für Tests)
  static bool get useKeychain => !isActive;

  /// Entwickler-Warnungen in der UI anzeigen
  static bool get showDeveloperWarnings => isActive;

  /// Debug-Logs für Sicherheitsoperationen erlauben
  static bool get allowSecurityDebugLogs => isActive;

  /// Erweiterte Datei-Zugriffe erlauben (nur für Tests)
  static bool get allowExtendedFileAccess => isActive;

  /// Backup-Import ohne Verschlüsselung erlauben
  static bool get allowUnencryptedBackupImport => isActive;

  /// Biometrie-Überprüfung überspringen (für Tests)
  static bool get skipBiometricCheck => isActive;

  /// Entwickler-Informationen anzeigen
  static String get developmentInfo => '''
🛠️ ENTWICKLERMODUS AKTIV
⚠️  NICHT FÜR PRODUKTION VERWENDEN!

Aktive Entwickler-Features:
${useKeychain ? '❌' : '✅'} Keychain deaktiviert
${allowSecurityDebugLogs ? '✅' : '❌'} Debug-Logs aktiviert
${allowExtendedFileAccess ? '✅' : '❌'} Erweiterte Datei-Zugriffe
${allowUnencryptedBackupImport ? '✅' : '❌'} Unverschlüsselte Backups
${skipBiometricCheck ? '✅' : '❌'} Biometrie übersprungen

WICHTIG: Vor Release alle Features deaktivieren!
''';
}

/// Sicherheits-Check-Item für Production-Readiness
class SecurityCheckItem {
  final String name;
  final bool isCompliant;
  final String description;
  final SecurityLevel level;

  const SecurityCheckItem({
    required this.name,
    required this.isCompliant,
    required this.description,
    this.level = SecurityLevel.critical,
  });
}

enum SecurityLevel {
  critical,
  important,
  recommended,
}

/// Überprüfung der Produktionsbereitschaft
class ProductionReadinessChecker {
  /// Vollständige Sicherheits-Checkliste für Release
  static List<SecurityCheckItem> getSecurityChecklist() {
    return [
      SecurityCheckItem(
        name: 'Entwicklermodus deaktiviert',
        isCompliant: !DeveloperMode.isActive,
        description: 'Der Entwicklermodus muss für Production deaktiviert sein',
        level: SecurityLevel.critical,
      ),
      SecurityCheckItem(
        name: 'Keychain-Verschlüsselung aktiviert',
        isCompliant: DeveloperMode.useKeychain,
        description: 'Sichere Keychain-Speicherung muss aktiviert sein',
        level: SecurityLevel.critical,
      ),
      SecurityCheckItem(
        name: 'Debug-Logs deaktiviert',
        isCompliant: !DeveloperMode.allowSecurityDebugLogs,
        description: 'Sicherheits-Debug-Logs müssen deaktiviert sein',
        level: SecurityLevel.important,
      ),
      SecurityCheckItem(
        name: 'Erweiterte Datei-Zugriffe entfernt',
        isCompliant: !DeveloperMode.allowExtendedFileAccess,
        description: 'Entwickler-Datei-Zugriffe müssen entfernt sein',
        level: SecurityLevel.critical,
      ),
      SecurityCheckItem(
        name: 'Biometrie-Überprüfung aktiviert',
        isCompliant: !DeveloperMode.skipBiometricCheck,
        description: 'Biometrische Authentifizierung muss aktiviert sein',
        level: SecurityLevel.critical,
      ),
      SecurityCheckItem(
        name: 'Release-Build-Modus',
        isCompliant: kReleaseMode,
        description: 'App muss im Release-Modus gebaut sein',
        level: SecurityLevel.critical,
      ),
    ];
  }

  /// Gibt true zurück wenn alle kritischen Sicherheitschecks bestanden sind
  static bool isProductionReady() {
    return getSecurityChecklist()
        .where((item) => item.level == SecurityLevel.critical)
        .every((item) => item.isCompliant);
  }

  /// Anzahl der fehlgeschlagenen kritischen Checks
  static int getCriticalIssuesCount() {
    return getSecurityChecklist()
        .where((item) => item.level == SecurityLevel.critical && !item.isCompliant)
        .length;
  }

  /// Entwickler-freundliche Zusammenfassung
  static String getReadinessReport() {
    final checks = getSecurityChecklist();
    final critical = checks.where((c) => c.level == SecurityLevel.critical);
    final criticalFailed = critical.where((c) => !c.isCompliant).length;

    if (criticalFailed == 0) {
      return '✅ Alle kritischen Sicherheitschecks bestanden - Bereit für Release!';
    } else {
      return '❌ $criticalFailed kritische Sicherheitsprobleme müssen behoben werden';
    }
  }
}