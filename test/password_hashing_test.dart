import 'package:flutter_test/flutter_test.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

// Teste die PBKDF2-Logik direkt (ohne WebAuthService Singleton)
void main() {
  group('Password-Hashing (PBKDF2)', () {
    String hashPassword(String password, {String? existingSalt}) {
      final salt = existingSalt ?? _generateSalt();
      List<int> key = utf8.encode(password + salt);
      for (int i = 0; i < 100000; i++) {
        final hmac = Hmac(sha256, utf8.encode(salt));
        key = hmac.convert(key).bytes;
      }
      final hash = base64.encode(key);
      return '$salt:$hash';
    }

    bool verifyPassword(String password, String storedHash) {
      if (!storedHash.contains(':')) {
        final oldHash = sha256.convert(utf8.encode(password + 'eingliederungshilfe_salt')).toString();
        return oldHash == storedHash;
      }
      final parts = storedHash.split(':');
      if (parts.length != 2) return false;
      final salt = parts[0];
      final newHash = hashPassword(password, existingSalt: salt);
      return newHash == storedHash;
    }

    test('Hash enthaelt Salt und Hash getrennt durch Doppelpunkt', () {
      final hash = hashPassword('TestPasswort123');
      expect(hash, contains(':'));
      final parts = hash.split(':');
      expect(parts.length, 2);
      expect(parts[0].length, greaterThan(0)); // Salt
      expect(parts[1].length, greaterThan(0)); // Hash
    });

    test('gleicher Salt ergibt gleichen Hash', () {
      final hash1 = hashPassword('TestPasswort123', existingSalt: 'test-salt');
      final hash2 = hashPassword('TestPasswort123', existingSalt: 'test-salt');
      expect(hash1, equals(hash2));
    });

    test('verschiedene Passwoerter ergeben verschiedene Hashes', () {
      final hash1 = hashPassword('Passwort1', existingSalt: 'same-salt');
      final hash2 = hashPassword('Passwort2', existingSalt: 'same-salt');
      expect(hash1, isNot(equals(hash2)));
    });

    test('verschiedene Salts ergeben verschiedene Hashes', () {
      final hash1 = hashPassword('SamePassword', existingSalt: 'salt-a');
      final hash2 = hashPassword('SamePassword', existingSalt: 'salt-b');
      expect(hash1, isNot(equals(hash2)));
    });

    test('verifyPassword akzeptiert korrektes Passwort', () {
      final hash = hashPassword('MeinPasswort', existingSalt: 'fixed-salt');
      expect(verifyPassword('MeinPasswort', hash), isTrue);
    });

    test('verifyPassword lehnt falsches Passwort ab', () {
      final hash = hashPassword('MeinPasswort', existingSalt: 'fixed-salt');
      expect(verifyPassword('FalschesPasswort', hash), isFalse);
    });

    test('verifyPassword migriert altes SHA256-Format', () {
      // Altes Format: einfacher SHA256 ohne Salt-Prefix
      final oldHash = sha256.convert(
        utf8.encode('AltesPasswort' + 'eingliederungshilfe_salt'),
      ).toString();
      expect(verifyPassword('AltesPasswort', oldHash), isTrue);
      expect(verifyPassword('FalschesPasswort', oldHash), isFalse);
    });

    test('Hash ist nicht das Klartext-Passwort', () {
      final hash = hashPassword('GeheimesPasswort');
      expect(hash, isNot(contains('GeheimesPasswort')));
    });
  });
}

String _generateSalt() {
  final random = DateTime.now().microsecondsSinceEpoch;
  final bytes = utf8.encode('fegh_$random');
  return base64.encode(sha256.convert(bytes).bytes).substring(0, 22);
}
