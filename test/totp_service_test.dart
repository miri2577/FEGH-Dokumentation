import 'package:flutter_test/flutter_test.dart';
import 'package:eingliederungshilfe_flutter/services/totp_service.dart';

void main() {
  group('TotpService', () {
    test('generateSecret erzeugt 20 Byte', () {
      final secret = TotpService.generateSecret();
      expect(secret.length, 20);
    });

    test('generateSecret erzeugt unterschiedliche Secrets', () {
      final s1 = TotpService.generateSecret();
      final s2 = TotpService.generateSecret();
      expect(s1, isNot(equals(s2)));
    });

    test('secretToBase32 und base32ToSecret sind invers', () {
      final original = TotpService.generateSecret();
      final base32 = TotpService.secretToBase32(original);
      final decoded = TotpService.base32ToSecret(base32);
      expect(decoded, equals(original));
    });

    test('Base32-Kodierung enthaelt nur gueltige Zeichen', () {
      final secret = TotpService.generateSecret();
      final base32 = TotpService.secretToBase32(secret);
      expect(base32, matches(RegExp(r'^[A-Z2-7]+$')));
    });

    test('generateCode erzeugt 6-stelligen Code', () {
      final secret = TotpService.generateSecret();
      final code = TotpService.generateCode(secret);
      expect(code.length, 6);
      expect(int.tryParse(code), isNotNull);
    });

    test('generateCode ist deterministisch fuer gleichen Zeitpunkt', () {
      final secret = TotpService.generateSecret();
      final now = DateTime(2026, 4, 9, 12, 0, 0);
      final code1 = TotpService.generateCode(secret, now: now);
      final code2 = TotpService.generateCode(secret, now: now);
      expect(code1, equals(code2));
    });

    test('generateCode aendert sich nach 30 Sekunden', () {
      final secret = TotpService.generateSecret();
      final t1 = DateTime(2026, 4, 9, 12, 0, 0);
      final t2 = DateTime(2026, 4, 9, 12, 0, 31);
      final code1 = TotpService.generateCode(secret, now: t1);
      final code2 = TotpService.generateCode(secret, now: t2);
      expect(code1, isNot(equals(code2)));
    });

    test('verifyCode akzeptiert aktuellen Code', () {
      final secret = TotpService.generateSecret();
      final now = DateTime.now();
      final code = TotpService.generateCode(secret, now: now);
      expect(TotpService.verifyCode(secret, code, now: now), isTrue);
    });

    test('verifyCode akzeptiert Code vom vorherigen Intervall (Toleranz)', () {
      final secret = TotpService.generateSecret();
      final now = DateTime(2026, 4, 9, 12, 1, 0);
      final prev = DateTime(2026, 4, 9, 12, 0, 30);
      final code = TotpService.generateCode(secret, now: prev);
      expect(TotpService.verifyCode(secret, code, now: now), isTrue);
    });

    test('verifyCode lehnt falschen Code ab', () {
      final secret = TotpService.generateSecret();
      expect(TotpService.verifyCode(secret, '000000'), isFalse);
    });

    test('verifyCode lehnt alten Code ab (ausserhalb Toleranz)', () {
      final secret = TotpService.generateSecret();
      final old = DateTime(2026, 4, 9, 10, 0, 0);
      final now = DateTime(2026, 4, 9, 12, 0, 0);
      final code = TotpService.generateCode(secret, now: old);
      expect(TotpService.verifyCode(secret, code, now: now), isFalse);
    });

    test('generateOtpAuthUri hat korrektes Format', () {
      final uri = TotpService.generateOtpAuthUri(
        secret: 'JBSWY3DPEHPK3PXP',
        accountName: 'test@example.com',
      );
      expect(uri, startsWith('otpauth://totp/'));
      expect(uri, contains('secret=JBSWY3DPEHPK3PXP'));
      expect(uri, contains('issuer=FEGH-Dokumentation'));
      expect(uri, contains('period=30'));
      expect(uri, contains('digits=6'));
    });

    test('remainingSeconds ist zwischen 1 und 30', () {
      final remaining = TotpService.remainingSeconds();
      expect(remaining, greaterThan(0));
      expect(remaining, lessThanOrEqualTo(30));
    });
  });
}
