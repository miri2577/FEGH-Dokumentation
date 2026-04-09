import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:eingliederungshilfe_flutter/services/recovery_service.dart';

void main() {
  group('RecoveryService', () {
    group('Recovery-Key', () {
      test('generiert 12 Woerter', () {
        final key = RecoveryService.generateRecoveryKey();
        final words = key.split(' ');
        expect(words.length, 12);
      });

      test('generiert unterschiedliche Keys', () {
        final k1 = RecoveryService.generateRecoveryKey();
        final k2 = RecoveryService.generateRecoveryKey();
        expect(k1, isNot(equals(k2)));
      });

      test('Woerter sind nicht leer', () {
        final key = RecoveryService.generateRecoveryKey();
        for (final word in key.split(' ')) {
          expect(word.length, greaterThan(0));
        }
      });
    });

    group('MEK-Verschluesselung', () {
      test('verschluesselt und entschluesselt MEK korrekt', () async {
        final mek = Uint8List.fromList(List.generate(32, (i) => i));
        final phrase = 'Adler Baum Blume Dach Erde Falke Garten Hafen Insel Jagd Krone Lampe';

        final encrypted = await RecoveryService.encryptMekWithRecoveryKey(mek, phrase);
        expect(encrypted, isNotEmpty);

        final decrypted = await RecoveryService.decryptMekWithRecoveryKey(encrypted, phrase);
        expect(decrypted, isNotNull);
        expect(decrypted, equals(mek));
      });

      test('falscher Recovery-Key entschluesselt nicht', () async {
        final mek = Uint8List.fromList(List.generate(32, (i) => i));
        final correct = 'Adler Baum Blume Dach Erde Falke Garten Hafen Insel Jagd Krone Lampe';
        final wrong = 'Lampe Krone Jagd Insel Hafen Garten Falke Erde Dach Blume Baum Adler';

        final encrypted = await RecoveryService.encryptMekWithRecoveryKey(mek, correct);
        final decrypted = await RecoveryService.decryptMekWithRecoveryKey(encrypted, wrong);
        expect(decrypted, isNull);
      });
    });

    group('Recovery-Token', () {
      test('generiert und entschluesselt Token korrekt', () async {
        final pin = '123456';
        final token = await RecoveryService.generateRecoveryToken(
          employeeId: 'emp-123',
          pin: pin,
        );
        expect(token, isNotEmpty);

        final decoded = await RecoveryService.decryptRecoveryToken(token, pin);
        expect(decoded, isNotNull);
        expect(decoded!['type'], 'egh-recovery-v1');
        expect(decoded['employeeId'], 'emp-123');
      });

      test('falscher PIN entschluesselt nicht', () async {
        final token = await RecoveryService.generateRecoveryToken(
          employeeId: 'emp-123',
          pin: '123456',
        );

        final decoded = await RecoveryService.decryptRecoveryToken(token, '999999');
        expect(decoded, isNull);
      });

      test('abgelaufener Token wird abgelehnt', () async {
        final token = await RecoveryService.generateRecoveryToken(
          employeeId: 'emp-123',
          pin: '123456',
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        );

        final decoded = await RecoveryService.decryptRecoveryToken(token, '123456');
        expect(decoded, isNull);
      });
    });

    group('Key-Ableitung', () {
      test('deriveKeyFromRecoveryPhrase erzeugt 32 Byte', () async {
        final key = await RecoveryService.deriveKeyFromRecoveryPhrase('Test Phrase');
        expect(key.length, 32);
      });

      test('gleiche Phrase ergibt gleichen Key', () async {
        final k1 = await RecoveryService.deriveKeyFromRecoveryPhrase('Test Phrase');
        final k2 = await RecoveryService.deriveKeyFromRecoveryPhrase('Test Phrase');
        expect(k1, equals(k2));
      });

      test('verschiedene Phrasen ergeben verschiedene Keys', () async {
        final k1 = await RecoveryService.deriveKeyFromRecoveryPhrase('Phrase A');
        final k2 = await RecoveryService.deriveKeyFromRecoveryPhrase('Phrase B');
        expect(k1, isNot(equals(k2)));
      });
    });
  });
}
