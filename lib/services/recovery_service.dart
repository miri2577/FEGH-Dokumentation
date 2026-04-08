import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' as hash;
import 'package:cryptography/cryptography.dart' as aes;
import 'package:flutter/foundation.dart';

/// BIP39-aehnliche Wortliste (deutsch, 128 Woerter fuer Recovery-Key)
const _recoveryWords = [
  'Adler', 'Baum', 'Blume', 'Brücke', 'Dach', 'Erde', 'Falke', 'Garten',
  'Hafen', 'Insel', 'Jagd', 'Krone', 'Lampe', 'Mond', 'Nacht', 'Ozean',
  'Pfad', 'Quelle', 'Regen', 'Stern', 'Turm', 'Ufer', 'Vogel', 'Wald',
  'Anker', 'Berg', 'Dolch', 'Eiche', 'Flamme', 'Gold', 'Herbst', 'Juwel',
  'Kette', 'Licht', 'Mauer', 'Nebel', 'Opal', 'Perle', 'Ring', 'Schild',
  'Tiger', 'Uhr', 'Welle', 'Zeder', 'Amber', 'Birke', 'Donner', 'Ernte',
  'Feder', 'Glut', 'Honig', 'Jade', 'Kliff', 'Lilie', 'Muschel', 'Nordsee',
  'Olive', 'Pinie', 'Rubin', 'Saphir', 'Taube', 'Ulme', 'Weide', 'Zinne',
  'Ahorn', 'Basalt', 'Distel', 'Efeu', 'Fichte', 'Granit', 'Heide', 'Jasmin',
  'Koralle', 'Lavendel', 'Marmor', 'Nelke', 'Orchidee', 'Palme', 'Raute', 'Silber',
  'Tanne', 'Veilchen', 'Wacholder', 'Zitrone', 'Akazie', 'Buche', 'Dahlie', 'Eisvogel',
  'Flieder', 'Ginster', 'Holunder', 'Iris', 'Kastanie', 'Lorbeer', 'Magnolie', 'Narzisse',
  'Oleander', 'Primel', 'Quitte', 'Rose', 'Salbei', 'Thymian', 'Ulme', 'Veilchen',
  'Wolfsmilch', 'Ysop', 'Anis', 'Borretsch', 'Dill', 'Estragon', 'Fenchel', 'Glocke',
  'Hasel', 'Immergrün', 'Kamille', 'Linde', 'Minze', 'Nuss', 'Oregano', 'Petersilie',
  'Rosmarin', 'Safran', 'Tulpe', 'Vanille', 'Wermut', 'Zimt', 'Aloe', 'Bambus',
];

/// Service fuer Passwort-Recovery und Admin-Recovery-Key.
class RecoveryService {

  /// Generiert einen 12-Wort Recovery-Key (fuer Admin MEK-Wiederherstellung).
  static String generateRecoveryKey() {
    final random = Random.secure();
    final words = <String>[];
    for (int i = 0; i < 12; i++) {
      words.add(_recoveryWords[random.nextInt(_recoveryWords.length)]);
    }
    return words.join(' ');
  }

  /// Leitet einen 32-Byte Key aus dem Recovery-Key ab (PBKDF2).
  static Future<Uint8List> deriveKeyFromRecoveryPhrase(String phrase) async {
    final salt = utf8.encode('egh-recovery-key-v1');
    List<int> key = utf8.encode(phrase.trim().toLowerCase());
    for (int i = 0; i < 50000; i++) {
      final hmac = hash.Hmac(hash.sha256, salt);
      key = hmac.convert(key).bytes;
    }
    return Uint8List.fromList(key);
  }

  /// Verschluesselt den MEK mit dem Recovery-Key.
  /// Gibt Base64-kodierten verschluesselten MEK zurueck.
  static Future<String> encryptMekWithRecoveryKey(
    Uint8List mek,
    String recoveryPhrase,
  ) async {
    final recoveryKey = await deriveKeyFromRecoveryPhrase(recoveryPhrase);
    final cipher = aes.AesGcm.with256bits();
    final nonce = _generateSecureRandomBytes(12);
    final secretKey = aes.SecretKey(recoveryKey);
    final box = await cipher.encrypt(mek, secretKey: secretKey, nonce: nonce);
    final payload = {
      'v': 1,
      'nonce': base64Encode(nonce),
      'ciphertext': base64Encode(box.cipherText),
      'tag': base64Encode(box.mac.bytes),
    };
    return base64Encode(utf8.encode(jsonEncode(payload)));
  }

  /// Entschluesselt den MEK mit dem Recovery-Key.
  static Future<Uint8List?> decryptMekWithRecoveryKey(
    String encryptedMekB64,
    String recoveryPhrase,
  ) async {
    try {
      final recoveryKey = await deriveKeyFromRecoveryPhrase(recoveryPhrase);
      final payload = jsonDecode(utf8.decode(base64Decode(encryptedMekB64)));
      final cipher = aes.AesGcm.with256bits();
      final secretKey = aes.SecretKey(recoveryKey);
      final box = aes.SecretBox(
        base64Decode(payload['ciphertext']),
        nonce: base64Decode(payload['nonce']),
        mac: aes.Mac(base64Decode(payload['tag'])),
      );
      final clearBytes = await cipher.decrypt(box, secretKey: secretKey);
      return Uint8List.fromList(clearBytes);
    } catch (e) {
      debugPrint('[RECOVERY] decryptMek failed: $e');
      return null;
    }
  }

  /// Generiert einen Recovery-Token (fuer Teamleitung → Mitarbeiter).
  /// Einfacher als Provisioning-Token: nur Passwort-Reset, kein Key-Material.
  static Future<String> generateRecoveryToken({
    required String employeeId,
    required String pin,
    DateTime? expiresAt,
  }) async {
    final payload = {
      'type': 'egh-recovery-v1',
      'employeeId': employeeId,
      'expiresAt': (expiresAt ?? DateTime.now().add(const Duration(hours: 24)))
          .toIso8601String(),
      'ts': DateTime.now().toIso8601String(),
    };
    final payloadBytes = utf8.encode(jsonEncode(payload));
    final pinKey = await _deriveKeyFromPin(pin);
    final encrypted = await _encryptWithKey(payloadBytes, pinKey);
    return base64Encode(utf8.encode(jsonEncode(encrypted)));
  }

  /// Entschluesselt und validiert einen Recovery-Token.
  static Future<Map<String, dynamic>?> decryptRecoveryToken(
    String tokenB64,
    String pin,
  ) async {
    try {
      final tokenJson = jsonDecode(utf8.decode(base64Decode(tokenB64)));
      final pinKey = await _deriveKeyFromPin(pin);
      final clearBytes = await _decryptWithKey(tokenJson, pinKey);
      final payload = jsonDecode(utf8.decode(clearBytes));

      if (payload['type'] != 'egh-recovery-v1') return null;

      // Ablauf pruefen
      final expiresAt = DateTime.parse(payload['expiresAt']);
      if (DateTime.now().isAfter(expiresAt)) return null; // Abgelaufen

      return payload;
    } catch (e) {
      debugPrint('[RECOVERY] decryptRecoveryToken failed: $e');
      return null;
    }
  }

  // ── Hilfsfunktionen ─────────────────────────────────────────────

  static Uint8List _generateSecureRandomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }

  static Future<Uint8List> _deriveKeyFromPin(String pin) async {
    final salt = utf8.encode('egh-recovery-pin-v1');
    List<int> key = utf8.encode(pin);
    for (int i = 0; i < 10000; i++) {
      final hmac = hash.Hmac(hash.sha256, salt);
      key = hmac.convert(key).bytes;
    }
    return Uint8List.fromList(key);
  }

  static Future<Map<String, dynamic>> _encryptWithKey(
    List<int> plaintext,
    Uint8List key,
  ) async {
    final cipher = aes.AesGcm.with256bits();
    final nonce = _generateSecureRandomBytes(12);
    final secretKey = aes.SecretKey(key);
    final box = await cipher.encrypt(plaintext, secretKey: secretKey, nonce: nonce);
    return {
      'nonce': base64Encode(nonce),
      'ciphertext': base64Encode(box.cipherText),
      'tag': base64Encode(box.mac.bytes),
    };
  }

  static Future<Uint8List> _decryptWithKey(
    Map<String, dynamic> record,
    Uint8List key,
  ) async {
    final cipher = aes.AesGcm.with256bits();
    final secretKey = aes.SecretKey(key);
    final box = aes.SecretBox(
      base64Decode(record['ciphertext']),
      nonce: base64Decode(record['nonce']),
      mac: aes.Mac(base64Decode(record['tag'])),
    );
    final clearBytes = await cipher.decrypt(box, secretKey: secretKey);
    return Uint8List.fromList(clearBytes);
  }
}
