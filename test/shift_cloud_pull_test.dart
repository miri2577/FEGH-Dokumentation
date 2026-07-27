import 'dart:convert';
import 'dart:typed_data';

import 'package:eingliederungshilfe_flutter/models/shift.dart';
import 'package:eingliederungshilfe_flutter/services/crypto_storage.dart';
import 'package:eingliederungshilfe_flutter/services/hidrive_webdav_client.dart';
import 'package:eingliederungshilfe_flutter/services/shift_cloud_pull_service.dart';
import 'package:fegh_cloud/fegh_cloud.dart' show FeghPaths;
import 'package:flutter_test/flutter_test.dart';

/// In-Memory-Doku-WebDAV: liefert vorbereitete (verschluesselte) Records.
class _FakeWebDav extends HiDriveWebDAVClient {
  _FakeWebDav()
      : super(
          baseUrl: 'https://example.invalid',
          username: 'u',
          password: 'p',
          certificatePins: const [],
        );
  final Map<String, List<int>> store = {};

  @override
  Future<WebDAVResult<List<String>>> list(String remotePath) async {
    final prefix = '$remotePath/';
    final names = store.keys
        .where((k) => k.startsWith(prefix))
        .map((k) => k.substring(prefix.length))
        .where((n) => !n.contains('/'))
        .toList();
    return WebDAVResult.success(data: names);
  }

  @override
  Future<WebDAVResult<Uint8List>> get(String remotePath) async {
    final d = store[remotePath];
    return d == null
        ? WebDAVResult.failure('404')
        : WebDAVResult.success(data: Uint8List.fromList(d));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const paths = FeghPaths(orgId: 'org1');

  test('downloadShifts liest die von der Verwaltung geschriebenen Records',
      () async {
    final crypto = CryptoStorage();
    crypto.setExternalMEK(List.filled(32, 7));
    final fake = _FakeWebDav();

    // So legt die Verwaltung eine Schicht ab: EncryptedRecord als JSON-Bytes.
    final shift = Shift(
      id: 's1',
      employeeId: 'e1',
      teamId: 't1',
      startTime: DateTime(2026, 5, 10, 8),
      endTime: DateTime(2026, 5, 10, 16),
      status: ShiftStatus.scheduled,
      type: ShiftType.regular,
      hourlyRate: 20,
      createdAt: DateTime(2026, 5, 1),
      updatedAt: DateTime(2026, 5, 1),
    );
    final recMap = await crypto.encryptRecord(
      plaintext: utf8.encode(jsonEncode(shift.toJson())),
      aad: {'schema': 'shift', 'version': 1},
    );
    fake.store[paths.teamShiftRecord('t1', 's1')] =
        utf8.encode(jsonEncode(recMap));

    final pull =
        ShiftCloudPullService(webdav: fake, crypto: crypto, paths: paths);
    final loaded = await pull.downloadShifts('t1');

    expect(loaded, hasLength(1));
    expect(loaded.first.id, 's1');
    expect(loaded.first.employeeId, 'e1');
    expect(loaded.first.teamId, 't1');
    expect(loaded.first.type, ShiftType.regular);
  });

  test('downloadShifts: leeres Team -> leere Liste', () async {
    final crypto = CryptoStorage()..setExternalMEK(List.filled(32, 7));
    final pull = ShiftCloudPullService(
        webdav: _FakeWebDav(), crypto: crypto, paths: paths);
    expect(await pull.downloadShifts('t9'), isEmpty);
  });
}
