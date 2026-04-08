import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:safe_device/safe_device.dart';
import '../utils/platform_utils.dart';

class SecurityService {
  static const String _channel = 'eingliederungshilfe.security';
  static const MethodChannel _methodChannel = MethodChannel(_channel);

  static bool _isSecurityCheckCompleted = false;
  static SecurityStatus? _lastSecurityStatus;

  static Future<SecurityStatus> performSecurityCheck() async {
    if (_isSecurityCheckCompleted && _lastSecurityStatus != null) {
      return _lastSecurityStatus!;
    }

    final status = SecurityStatus();

    try {
      if (Platform.isAndroid || Platform.isIOS) {
        status.isJailbrokenRooted = await SafeDevice.isJailBroken;

        status.isOnExternalStorage = await SafeDevice.isOnExternalStorage;
        status.isDevelopmentModeEnabled = await SafeDevice.isDevelopmentModeEnable;
        status.isDebuggable = false; // wird über native Channels geprüft

        if (Platform.isAndroid) {
          status.hasUsbDebugging = await _checkUsbDebugging();
          status.hasUnknownSources = await _checkUnknownSources();
        }
      }

      status.riskLevel = _calculateRiskLevel(status);

      _isSecurityCheckCompleted = true;
      _lastSecurityStatus = status;

      return status;
    } catch (e) {
      status.riskLevel = SecurityRiskLevel.medium;
      status.errors.add('Sicherheitsprüfung unvollständig: $e');
      return status;
    }
  }

  static Future<bool> _checkUsbDebugging() async {
    try {
      return await _methodChannel.invokeMethod<bool>('isUsbDebuggingEnabled') ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> _checkUnknownSources() async {
    try {
      return await _methodChannel.invokeMethod<bool>('isUnknownSourcesEnabled') ?? false;
    } catch (e) {
      return false;
    }
  }

  static SecurityRiskLevel _calculateRiskLevel(SecurityStatus status) {
    int riskScore = 0;

    if (status.isJailbrokenRooted) riskScore += 10;
    if (status.isOnExternalStorage) riskScore += 3;
    if (status.isDevelopmentModeEnabled) riskScore += 5;
    if (status.isDebuggable) riskScore += 4;
    if (status.hasUsbDebugging) riskScore += 3;
    if (status.hasUnknownSources) riskScore += 2;

    if (riskScore >= 10) return SecurityRiskLevel.high;
    if (riskScore >= 5) return SecurityRiskLevel.medium;
    return SecurityRiskLevel.low;
  }

  static void enableScreenSecurity() {
    if (PlatformUtils.isWeb) {
      // Screen security nicht verfügbar im Web
      return;
    }
    if (PlatformUtils.isAndroid) {
      _methodChannel.invokeMethod('enableFlagSecure');
    } else if (PlatformUtils.isIOS) {
      _methodChannel.invokeMethod('enableScreenshotBlur');
    }
  }

  static void disableScreenSecurity() {
    if (PlatformUtils.isWeb) {
      // Screen security nicht verfügbar im Web
      return;
    }
    if (PlatformUtils.isAndroid) {
      _methodChannel.invokeMethod('disableFlagSecure');
    } else if (PlatformUtils.isIOS) {
      _methodChannel.invokeMethod('disableScreenshotBlur');
    }
  }

  static Widget buildSecurityWarningDialog(SecurityStatus status) {
    return AlertDialog(
      icon: Icon(
        Icons.security,
        color: _getRiskColor(status.riskLevel),
        size: 48,
      ),
      title: Text('Sicherheitswarnung'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Diese App verarbeitet sensible Gesundheitsdaten. Folgende Sicherheitsrisiken wurden erkannt:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 16),
          ...status.getWarningMessages().map((message) => Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber, size: 16, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(child: Text(message)),
              ],
            ),
          )),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    status.riskLevel == SecurityRiskLevel.high
                        ? 'Die App wurde in den Nur-Lese-Modus versetzt.'
                        : 'Bitte beseitigen Sie die Sicherheitsrisiken.',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(NavigationService.navigatorKey.currentContext!).pop(),
          child: Text('Verstanden'),
        ),
        if (status.riskLevel != SecurityRiskLevel.high)
          FilledButton(
            onPressed: () {
              Navigator.of(NavigationService.navigatorKey.currentContext!).pop();
              _showSecurityGuidance(status);
            },
            child: Text('Hilfe'),
          ),
      ],
    );
  }

  static void _showSecurityGuidance(SecurityStatus status) {
    showDialog(
      context: NavigationService.navigatorKey.currentContext!,
      builder: (context) => AlertDialog(
        title: Text('Sicherheitsempfehlungen'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (status.isJailbrokenRooted) ...[
                Text(
                  '🔓 Root/Jailbreak erkannt',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red),
                ),
                Text('• Verwenden Sie ein nicht-gerootetes/gejailbreaktes Gerät'),
                Text('• Root-Zugriff kann die Datensicherheit gefährden'),
                SizedBox(height: 12),
              ],
              if (status.isDevelopmentModeEnabled) ...[
                Text(
                  '🛠 Entwicklermodus aktiv',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.orange),
                ),
                Text('• Deaktivieren Sie den Entwicklermodus in den Einstellungen'),
                Text('• Android: Einstellungen → Über das Telefon → Build-Nummer (7x tippen rückgängig machen)'),
                SizedBox(height: 12),
              ],
              if (status.hasUsbDebugging) ...[
                Text(
                  '🔌 USB-Debugging aktiv',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.orange),
                ),
                Text('• Deaktivieren Sie USB-Debugging'),
                Text('• Einstellungen → Entwickleroptionen → USB-Debugging'),
                SizedBox(height: 12),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Schließen'),
          ),
        ],
      ),
    );
  }

  static Color _getRiskColor(SecurityRiskLevel level) {
    switch (level) {
      case SecurityRiskLevel.low:
        return Colors.green;
      case SecurityRiskLevel.medium:
        return Colors.orange;
      case SecurityRiskLevel.high:
        return Colors.red;
    }
  }

  static void clearSecurityCheck() {
    _isSecurityCheckCompleted = false;
    _lastSecurityStatus = null;
  }
}

class SecurityStatus {
  bool isJailbrokenRooted = false;
  bool isOnExternalStorage = false;
  bool isDevelopmentModeEnabled = false;
  bool isDebuggable = false;
  bool hasUsbDebugging = false;
  bool hasUnknownSources = false;
  SecurityRiskLevel riskLevel = SecurityRiskLevel.low;
  List<String> errors = [];

  bool get isSecure => riskLevel == SecurityRiskLevel.low;
  bool get allowsReadWrite => riskLevel != SecurityRiskLevel.high;

  List<String> getWarningMessages() {
    final messages = <String>[];

    if (isJailbrokenRooted) {
      messages.add('Gerät ist gerootet/gejailbreakt - Höchstes Risiko für Datensicherheit');
    }
    if (isDevelopmentModeEnabled) {
      messages.add('Entwicklermodus ist aktiviert');
    }
    if (hasUsbDebugging) {
      messages.add('USB-Debugging ist aktiviert');
    }
    if (isOnExternalStorage) {
      messages.add('App ist auf externem Speicher installiert');
    }
    if (hasUnknownSources) {
      messages.add('Installation aus unbekannten Quellen ist erlaubt');
    }
    if (isDebuggable) {
      messages.add('App ist im Debug-Modus');
    }

    return messages;
  }
}

enum SecurityRiskLevel {
  low,
  medium,
  high,
}

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}