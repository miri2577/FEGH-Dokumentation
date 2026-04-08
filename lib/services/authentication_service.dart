import 'package:local_auth/local_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/developer_mode.dart';

class AuthenticationService {
  static final AuthenticationService _instance = AuthenticationService._internal();
  factory AuthenticationService() => _instance;
  AuthenticationService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  
  bool _isAuthenticated = false;
  BiometricType? _biometricType;
  bool _canUseBiometry = false;
  bool _canUseDeviceAuth = false;
  String? _authenticationError;
  bool _isAuthenticating = false;

  bool get isAuthenticated => _isAuthenticated;
  BiometricType? get biometricType => _biometricType;
  bool get canUseBiometry => _canUseBiometry;
  bool get canUseDeviceAuth => _canUseDeviceAuth;
  String? get authenticationError => _authenticationError;
  bool get isAuthenticating => _isAuthenticating;

  String get biometryTypeName {
    switch (_biometricType) {
      case BiometricType.face:
        return "Face ID";
      case BiometricType.fingerprint:
        return "Touch ID";
      case BiometricType.iris:
        return "Iris";
      case BiometricType.strong:
        return "Starke Biometrie";
      case BiometricType.weak:
        return "Schwache Biometrie";
      default:
        return "Biometrie";
    }
  }

  Future<void> checkBiometricAvailability() async {
    try {
      print("🔒 Überprüfe Biometrie-Verfügbarkeit...");

      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      _canUseDeviceAuth = isDeviceSupported;

      final bool isAvailable = await _localAuth.canCheckBiometrics;
      final List<BiometricType> availableBiometrics = await _localAuth.getAvailableBiometrics();

      if (isAvailable && isDeviceSupported && availableBiometrics.isNotEmpty) {
        _canUseBiometry = true;
        _biometricType = availableBiometrics.first;
        print("🔒 ✅ Biometrie verfügbar: $biometryTypeName");
      } else {
        _canUseBiometry = false;
        _biometricType = null;
        print("🔒 ❌ Biometrie nicht verfügbar (Gerät unterstützt Auth: $isDeviceSupported)");
      }
    } catch (e) {
      print("🔒 ❌ Fehler bei Biometrie-Check: $e");
      _canUseBiometry = false;
      _canUseDeviceAuth = false;
      _biometricType = null;
    }
  }

  Future<bool> requestBiometricUnlock() async {
    if (_isAuthenticating) {
      print("🔒 ⚠️ Authentifizierung läuft bereits");
      return false;
    }

    if (!_canUseBiometry) {
      print("🔒 ⚠️ Biometrie nicht verfügbar - Fallback zu Passcode");
      return await requestPasscodeUnlock();
    }

    print("🔒 Starte biometrische Authentifizierung...");
    _isAuthenticating = true;
    _authenticationError = null;

    try {
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Entsperren Sie die Eingliederungshilfe App mit $biometryTypeName',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      _isAuthenticating = false;

      if (didAuthenticate) {
        print("🔒 ✅ Biometrische Authentifizierung erfolgreich");
        _isAuthenticated = true;
        _authenticationError = null;
        return true;
      } else {
        print("🔒 ❌ Biometrische Authentifizierung fehlgeschlagen");
        _authenticationError = "Biometrische Authentifizierung fehlgeschlagen";
        return false;
      }
    } on PlatformException catch (e) {
      _isAuthenticating = false;
      print("🔒 ❌ Biometrische Authentifizierung Fehler: ${e.message}");
      
      switch (e.code) {
        case 'UserCancel':
          _authenticationError = "Biometrische Authentifizierung abgebrochen";
          break;
        case 'BiometryNotAvailable':
          _authenticationError = "$biometryTypeName ist nicht verfügbar";
          break;
        case 'BiometryNotEnrolled':
          _authenticationError = "$biometryTypeName ist nicht eingerichtet";
          break;
        case 'BiometryLockout':
          _authenticationError = "$biometryTypeName ist gesperrt";
          break;
        default:
          _authenticationError = e.message ?? "Unbekannter Fehler";
      }
      return false;
    } catch (e) {
      _isAuthenticating = false;
      print("🔒 ❌ Unbekannter Authentifizierungsfehler: $e");
      _authenticationError = "Unbekannter Fehler bei der Authentifizierung";
      return false;
    }
  }

  Future<bool> requestPasscodeUnlock() async {
    if (_isAuthenticating) {
      print("🔒 ⚠️ Authentifizierung läuft bereits");
      return false;
    }

    // Im Entwicklermodus Passcode überspringen
    if (DeveloperMode.skipBiometricCheck) {
      print("🔓 DEV: Passcode-Authentifizierung übersprungen (Entwicklermodus)");
      _isAuthenticated = true;
      _authenticationError = null;
      return true;
    }

    print("🔒 Starte Passcode-Authentifizierung...");
    _isAuthenticating = true;
    _authenticationError = null;

    try {
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Entsperren Sie die Eingliederungshilfe App mit Ihrem Passcode',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );

      _isAuthenticating = false;

      if (didAuthenticate) {
        print("🔒 ✅ Passcode-Authentifizierung erfolgreich");
        _isAuthenticated = true;
        _authenticationError = null;
        return true;
      } else {
        print("🔒 ❌ Passcode-Authentifizierung fehlgeschlagen");
        _authenticationError = "Passcode-Authentifizierung fehlgeschlagen";
        return false;
      }
    } on PlatformException catch (e) {
      _isAuthenticating = false;
      print("🔒 ❌ Passcode-Authentifizierung Fehler: ${e.message}");
      // Gerät unterstützt keine Geräte-Authentifizierung (z.B. Windows ohne PIN/Hello)
      _canUseDeviceAuth = false;
      _authenticationError = "Geräte-Authentifizierung nicht verfügbar. "
          "Bitte verwenden Sie die App-Passwort-Anmeldung.";
      return false;
    } catch (e) {
      _isAuthenticating = false;
      print("🔒 ❌ Unbekannter Passcode-Fehler: $e");
      _canUseDeviceAuth = false;
      _authenticationError = "Geräte-Authentifizierung nicht verfügbar. "
          "Bitte verwenden Sie die App-Passwort-Anmeldung.";
      return false;
    }
  }

  Future<bool> authenticate() async {
    if (_canUseBiometry) {
      return await requestBiometricUnlock();
    } else {
      return await requestPasscodeUnlock();
    }
  }

  void logout() {
    print("🔒 Benutzer abgemeldet");
    _isAuthenticated = false;
    _authenticationError = null;
  }

  void clearError() {
    _authenticationError = null;
  }
}