import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// TOTP (Time-based One-Time Password) nach RFC 6238.
/// Komplett offline, kein Drittanbieter, DSGVO-konform.
class TotpService {
  /// Generiert ein kryptographisch sicheres TOTP-Secret (20 Byte / 160 Bit).
  static Uint8List generateSecret() {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(20, (_) => random.nextInt(256)),
    );
  }

  /// Kodiert Secret als Base32 (fuer QR-Code / Authenticator-Apps).
  static String secretToBase32(Uint8List secret) {
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final buffer = StringBuffer();
    int bits = 0;
    int value = 0;
    for (final byte in secret) {
      value = (value << 8) | byte;
      bits += 8;
      while (bits >= 5) {
        bits -= 5;
        buffer.write(alphabet[(value >> bits) & 0x1F]);
      }
    }
    if (bits > 0) {
      buffer.write(alphabet[(value << (5 - bits)) & 0x1F]);
    }
    return buffer.toString();
  }

  /// Dekodiert Base32 zurueck zu Bytes.
  static Uint8List base32ToSecret(String base32) {
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final input = base32.toUpperCase().replaceAll('=', '');
    final output = <int>[];
    int bits = 0;
    int value = 0;
    for (final char in input.codeUnits) {
      final idx = alphabet.indexOf(String.fromCharCode(char));
      if (idx < 0) continue;
      value = (value << 5) | idx;
      bits += 5;
      if (bits >= 8) {
        bits -= 8;
        output.add((value >> bits) & 0xFF);
      }
    }
    return Uint8List.fromList(output);
  }

  /// Generiert einen TOTP-Code fuer den aktuellen Zeitpunkt.
  /// [secret]: 20-Byte HMAC-SHA1 Key
  /// [timeStep]: Intervall in Sekunden (Standard: 30)
  /// [digits]: Anzahl Ziffern (Standard: 6)
  static String generateCode(
    Uint8List secret, {
    int timeStep = 30,
    int digits = 6,
    DateTime? now,
  }) {
    final time = now ?? DateTime.now();
    final counter = time.millisecondsSinceEpoch ~/ 1000 ~/ timeStep;
    return _hotp(secret, counter, digits);
  }

  /// Verifiziert einen TOTP-Code.
  /// Prueft aktuellen + vorherigen + naechsten Zeitschritt (Toleranz: ±1).
  static bool verifyCode(
    Uint8List secret,
    String code, {
    int timeStep = 30,
    int digits = 6,
    int tolerance = 1,
    DateTime? now,
  }) {
    final time = now ?? DateTime.now();
    final counter = time.millisecondsSinceEpoch ~/ 1000 ~/ timeStep;

    for (int i = -tolerance; i <= tolerance; i++) {
      final expected = _hotp(secret, counter + i, digits);
      if (expected == code) return true;
    }
    return false;
  }

  /// Generiert eine otpauth:// URI fuer Authenticator-Apps.
  static String generateOtpAuthUri({
    required String secret,
    required String accountName,
    String issuer = 'FEGH-Dokumentation',
    int period = 30,
    int digits = 6,
  }) {
    final encodedIssuer = Uri.encodeComponent(issuer);
    final encodedAccount = Uri.encodeComponent(accountName);
    return 'otpauth://totp/$encodedIssuer:$encodedAccount'
        '?secret=$secret'
        '&issuer=$encodedIssuer'
        '&period=$period'
        '&digits=$digits'
        '&algorithm=SHA1';
  }

  /// Berechnet verbleibende Sekunden bis zum naechsten Code-Wechsel.
  static int remainingSeconds({int timeStep = 30}) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return timeStep - (now % timeStep);
  }

  // ── HOTP (RFC 4226) ──────────────────────────────────────────────

  static String _hotp(Uint8List secret, int counter, int digits) {
    // Counter als 8-Byte Big-Endian
    final counterBytes = Uint8List(8);
    var c = counter;
    for (int i = 7; i >= 0; i--) {
      counterBytes[i] = c & 0xFF;
      c >>= 8;
    }

    // HMAC-SHA1
    final hmac = Hmac(sha1, secret);
    final hash = hmac.convert(counterBytes).bytes;

    // Dynamic Truncation
    final offset = hash[hash.length - 1] & 0x0F;
    final binary = ((hash[offset] & 0x7F) << 24) |
        ((hash[offset + 1] & 0xFF) << 16) |
        ((hash[offset + 2] & 0xFF) << 8) |
        (hash[offset + 3] & 0xFF);

    final otp = binary % _pow10(digits);
    return otp.toString().padLeft(digits, '0');
  }

  static int _pow10(int n) {
    int result = 1;
    for (int i = 0; i < n; i++) {
      result *= 10;
    }
    return result;
  }
}
