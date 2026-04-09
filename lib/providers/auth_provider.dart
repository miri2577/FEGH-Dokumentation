import 'package:flutter/foundation.dart';
import '../services/authentication_service.dart';
import '../services/web_auth_service.dart';
import '../services/totp_service.dart';
import '../utils/platform_utils.dart';

/// Spezialisierter Provider fuer Authentifizierung.
/// Verwaltet Login-Status, Biometrie, TOTP, Passwort.
class AuthProvider extends ChangeNotifier {
  final AuthenticationService _authService = AuthenticationService();
  final WebAuthService _webAuthService = WebAuthService();
  bool _useAppPassword = false;

  // Getters
  bool get useAppPassword => _useAppPassword || PlatformUtils.isWeb;
  bool get isAuthenticated {
    if (useAppPassword) return _webAuthService.isAuthenticated;
    return _authService.isAuthenticated;
  }
  bool get isAuthenticating {
    if (useAppPassword) return _webAuthService.isAuthenticating;
    return _authService.isAuthenticating;
  }
  bool get canUseBiometry {
    if (useAppPassword) return false;
    return _authService.canUseBiometry;
  }
  bool get isPasswordSet => _webAuthService.isPasswordSet;
  String? get authenticationError {
    if (useAppPassword) return _webAuthService.authenticationError;
    return _authService.authenticationError;
  }

  AuthenticationService get authService => _authService;
  WebAuthService get webAuthService => _webAuthService;

  Future<void> initialize() async {
    await _authService.checkBiometricAvailability();
    if (!_authService.canUseBiometry && !_authService.canUseDeviceAuth) {
      _useAppPassword = true;
    }
    await _webAuthService.loadCredentials();
    notifyListeners();
  }

  Future<void> authenticate() async {
    if (useAppPassword) {
      await _webAuthService.authenticateWithoutPassword();
    } else {
      await _authService.authenticate();
    }
    notifyListeners();
  }

  Future<void> authenticateWithCredentials(String username, String password) async {
    await _webAuthService.authenticateWithCredentials(username, password);
    notifyListeners();
  }

  Future<void> setupPassword(String username, String password) async {
    await _webAuthService.setCredentials(username, password);
    notifyListeners();
  }

  Future<void> logout() async {
    if (useAppPassword) {
      _webAuthService.logout();
    } else {
      _authService.logout();
    }
    notifyListeners();
  }

  bool verifyTotpCode(String code, String totpSecret) {
    if (totpSecret.isEmpty) return true;
    final secret = TotpService.base32ToSecret(totpSecret);
    return TotpService.verifyCode(secret, code);
  }
}
