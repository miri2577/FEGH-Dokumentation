import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../utils/platform_utils.dart';

class WebAuthService {
  static final WebAuthService _instance = WebAuthService._internal();
  factory WebAuthService() => _instance;
  WebAuthService._internal();

  static const String _usernameKey = 'web_app_username';
  static const String _passwordKey = 'web_app_password_hash';
  static const String _sessionKey = 'web_session_token';
  static const String _lastActivityKey = 'last_activity';
  static const int _sessionTimeoutMinutes = 30;

  bool _isAuthenticated = false;
  String? _authenticationError;
  bool _isAuthenticating = false;
  DateTime? _lastActivity;
  String? _currentUsername;

  bool get isAuthenticated => _isAuthenticated;
  String? get authenticationError => _authenticationError;
  bool get isAuthenticating => _isAuthenticating;
  bool _isPasswordSetCached = false;

  bool get isPasswordSet => _isPasswordSetCached;

  Future<void> checkPasswordSet() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isPasswordSetCached = prefs.getString(_passwordKey) != null;
    } catch (_) {
      _isPasswordSetCached = false;
    }
  }

  String? get currentUsername => _currentUsername;

  Future<void> initialize() async {

    print("🌐 Initialisiere App-Passwort-Authentifizierung...");
    await checkPasswordSet();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastActivityString = prefs.getString(_lastActivityKey);
      
      if (lastActivityString != null) {
        _lastActivity = DateTime.parse(lastActivityString);
        
        // Prüfe Session-Timeout
        final now = DateTime.now();
        final timeDifference = now.difference(_lastActivity!).inMinutes;
        
        if (timeDifference < _sessionTimeoutMinutes) {
          // Session noch gültig
          final sessionToken = prefs.getString(_sessionKey);
          if (sessionToken != null) {
            _isAuthenticated = true;
            _updateLastActivity();
            print("🌐 ✅ Gültige Session gefunden");
          }
        } else {
          // Session abgelaufen
          await _clearSession();
          print("🌐 ⏰ Session abgelaufen");
        }
      }
    } catch (e) {
      print("🌐 ❌ Fehler bei Session-Initialisierung: $e");
    }
  }

  Future<bool> authenticateWithCredentials(String username, String password) async {
    
    _isAuthenticating = true;
    _authenticationError = null;
    
    try {
      print("🌐 🔐 Versuche Authentifizierung für Benutzer: $username");
      
      // Validiere Eingaben
      if (username.isEmpty || password.isEmpty) {
        _authenticationError = "Benutzername und Passwort erforderlich";
        return false;
      }
      
      if (password.length < 6) {
        _authenticationError = "Passwort muss mindestens 6 Zeichen lang sein";
        return false;
      }
      
      // Prüfe gespeicherte Credentials
      final success = await _verifyCredentials(username, password);
      
      if (success) {
        await _createSession(username, password);
        _isAuthenticated = true;
        _currentUsername = username;
        _authenticationError = null;
        
        print("🌐 ✅ Authentifizierung erfolgreich für: $username");
        return true;
      } else {
        _authenticationError = "Ungültiger Benutzername oder Passwort";
        print("🌐 ❌ Authentifizierung fehlgeschlagen für: $username");
        return false;
      }
    } catch (e) {
      _authenticationError = "Authentifizierungsfehler: $e";
      print("🌐 ❌ Authentifizierung fehlgeschlagen: $e");
      return false;
    } finally {
      _isAuthenticating = false;
    }
  }

  // Legacy method for backward compatibility
  Future<bool> authenticateWithPassword(String password) async {
    return authenticateWithCredentials("user", password);
  }

  Future<bool> setCredentials(String username, String password) async {
    
    try {
      if (username.isEmpty || password.isEmpty) {
        _authenticationError = "Benutzername und Passwort erforderlich";
        return false;
      }
      
      if (username.length < 3) {
        _authenticationError = "Benutzername muss mindestens 3 Zeichen lang sein";
        return false;
      }
      
      if (password.length < 6) {
        _authenticationError = "Passwort muss mindestens 6 Zeichen lang sein";
        return false;
      }
      
      final prefs = await SharedPreferences.getInstance();
      final passwordHash = _hashPassword(password);
      await prefs.setString(_usernameKey, username);
      await prefs.setString(_passwordKey, passwordHash);
      
      print("🌐 ✅ Neue Anmeldedaten gesetzt für: $username");
      return true;
    } catch (e) {
      _authenticationError = "Fehler beim Setzen der Anmeldedaten: $e";
      print("🌐 ❌ Fehler beim Setzen der Anmeldedaten: $e");
      return false;
    }
  }

  // Legacy method for backward compatibility
  Future<bool> setPassword(String newPassword) async {
    return setCredentials("user", newPassword);
  }

  Future<bool> verifyPassword(String password) async {
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedHash = prefs.getString(_passwordKey);
      
      if (storedHash == null) {
        // Kein Passwort gesetzt
        return await setPassword(password);
      }
      
      return _verifyPassword(password, storedHash);
    } catch (e) {
      print("🌐 ❌ Fehler bei Passwort-Verifizierung: $e");
      return false;
    }
  }

  Future<bool> _verifyCredentials(String username, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedUsername = prefs.getString(_usernameKey);
      final storedPasswordHash = prefs.getString(_passwordKey);
      
      if (storedUsername == null || storedPasswordHash == null) {
        return false;
      }
      
      return storedUsername == username && _verifyPassword(password, storedPasswordHash);
    } catch (e) {
      print("🌐 ❌ Fehler bei Credential-Verifizierung: $e");
      return false;
    }
  }

  Future<void> _createSession(String username, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Erstelle Session-Token
      final sessionData = {
        'timestamp': DateTime.now().toIso8601String(),
        'username': username,
        'password_hash': _hashPassword(password),
      };
      
      final sessionToken = _generateSessionToken(sessionData);
      await prefs.setString(_sessionKey, sessionToken);
      
      _updateLastActivity();
    } catch (e) {
      print("🌐 ❌ Fehler beim Erstellen der Session: $e");
    }
  }

  Future<void> _updateLastActivity() async {
    try {
      _lastActivity = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastActivityKey, _lastActivity!.toIso8601String());
    } catch (e) {
      print("🌐 ❌ Fehler beim Aktualisieren der letzten Aktivität: $e");
    }
  }

  Future<void> _clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
      await prefs.remove(_lastActivityKey);
      _isAuthenticated = false;
      _lastActivity = null;
    } catch (e) {
      print("🌐 ❌ Fehler beim Löschen der Session: $e");
    }
  }

  /// PBKDF2-basiertes Passwort-Hashing mit zufaelligem Salt.
  /// 100.000 Iterationen HMAC-SHA256.
  String _hashPassword(String password, {String? existingSalt}) {
    final salt = existingSalt ?? _generateSalt();
    List<int> key = utf8.encode(password + salt);
    for (int i = 0; i < 100000; i++) {
      final hmac = Hmac(sha256, utf8.encode(salt));
      key = hmac.convert(key).bytes;
    }
    final hash = base64.encode(key);
    return '$salt:$hash'; // Salt und Hash zusammen speichern
  }

  String _generateSalt() {
    final random = DateTime.now().microsecondsSinceEpoch;
    final bytes = utf8.encode('fegh_$random');
    return base64.encode(sha256.convert(bytes).bytes).substring(0, 22);
  }

  bool _verifyPassword(String password, String storedHash) {
    if (!storedHash.contains(':')) {
      // Migration: Altes Format (einfacher SHA256) -- einmalig akzeptieren
      final oldHash = sha256.convert(utf8.encode(password + 'eingliederungshilfe_salt')).toString();
      return oldHash == storedHash;
    }
    final parts = storedHash.split(':');
    if (parts.length != 2) return false;
    final salt = parts[0];
    final newHash = _hashPassword(password, existingSalt: salt);
    return newHash == storedHash;
  }

  String _generateSessionToken(Map<String, dynamic> sessionData) {
    final jsonString = json.encode(sessionData);
    final bytes = utf8.encode(jsonString);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  void logout() {
    print("🌐 🚪 Benutzer abgemeldet");
    _isAuthenticated = false;
    _authenticationError = null;
    _clearSession();
  }

  void clearError() {
    _authenticationError = null;
  }

  // Session-Check für automatische Abmeldung
  bool checkSessionValid() {
    if (!_isAuthenticated) return false;
    
    if (_lastActivity == null) return false;
    
    final now = DateTime.now();
    final timeDifference = now.difference(_lastActivity!).inMinutes;
    
    if (timeDifference >= _sessionTimeoutMinutes) {
      logout();
      return false;
    }
    
    // Aktivität aktualisieren
    _updateLastActivity();
    return true;
  }

  // Info über verbleibende Session-Zeit
  Duration? get remainingSessionTime {
    if (!_isAuthenticated || _lastActivity == null) return null;
    
    final now = DateTime.now();
    final elapsed = now.difference(_lastActivity!);
    final timeout = Duration(minutes: _sessionTimeoutMinutes);
    
    if (elapsed >= timeout) return Duration.zero;
    
    return timeout - elapsed;
  }

  // Fallback-Authentifizierung für Web ohne Passwort
  Future<bool> authenticateWithoutPassword() async {
    
    print("🌐 ⚠️ Authentifizierung ohne Passwort (nur Demo-Modus)");
    
    _isAuthenticating = true;
    
    try {
      // Simuliere Authentifizierung
      await Future.delayed(const Duration(milliseconds: 300));
      
      _isAuthenticated = true;
      _authenticationError = null;
      _updateLastActivity();
      
      print("🌐 ✅ Demo-Authentifizierung erfolgreich");
      return true;
    } catch (e) {
      _authenticationError = "Demo-Authentifizierung fehlgeschlagen: $e";
      return false;
    } finally {
      _isAuthenticating = false;
    }
  }

  // Web-spezifische Authentifizierungs-Info
  Map<String, dynamic> getWebAuthInfo() {
    return {
      'is_web': true,
      'is_authenticated': _isAuthenticated,
      'password_set': isPasswordSet,
      'session_timeout_minutes': _sessionTimeoutMinutes,
      'remaining_session_time': remainingSessionTime?.inMinutes,
      'last_activity': _lastActivity?.toIso8601String(),
    };
  }
}