import 'package:webdav_client/webdav_client.dart' as webdav;

class SimpleWebDAVTest {
  static Future<bool> testHiDriveConnection({
    required String username,
    required String password,
  }) async {
    print('🔄 SimpleWebDAVTest: Starte HiDrive-Verbindungstest...');
    print('🔄 Server: https://webdav.hidrive.strato.com');
    print('🔄 Username: $username');
    print('🔄 Password: ${password.replaceAll(RegExp(r'.'), '*')}');

    try {
      print('🔄 Erstelle WebDAV-Client...');
      final client = webdav.newClient(
        'https://webdav.hidrive.strato.com/users/$username',
        user: username.trim(),
        password: password,
        debug: true,
      );

      client.setConnectTimeout(15000);
      client.setReceiveTimeout(30000);
      print('🔄 Timeouts gesetzt (15s/30s)');

      print('🔄 Starte readDir("/")...');
      final files = await client.readDir('/');
      print('🔄 readDir erfolgreich, ${files.length} Dateien gefunden');

      for (int i = 0; i < files.length && i < 3; i++) {
        print('🔄 Datei $i: ${files[i].name} (${(files[i].isDir ?? false) ? 'DIR' : 'FILE'})');
      }

      print('✅ HiDrive-Verbindung erfolgreich getestet');
      return true;

    } catch (e, stackTrace) {
      print('❌ HiDrive Verbindungsfehler: $e');
      print('❌ StackTrace: $stackTrace');
      return false;
    }
  }

  static Future<bool> testFolderCreation({
    required String username,
    required String password,
    required String organizationId,
  }) async {
    print('🔄 SimpleWebDAVTest: Starte Ordner-Test...');
    print('🔄 Organization ID: $organizationId');

    try {
      print('🔄 Erstelle WebDAV-Client für Ordner-Test...');
      final client = webdav.newClient(
        'https://webdav.hidrive.strato.com/users/$username',
        user: username.trim(),
        password: password,
        debug: true,
      );

      client.setConnectTimeout(15000);
      client.setReceiveTimeout(30000);
      print('🔄 Client erstellt, teste Ordnerstruktur...');

      // Teste Ordnerstruktur-Erstellung (ohne Daten) - Admin-Struktur
      // Produktive Struktur unter "eingliederungshilfe/organizations/..."
      final basePath = 'eingliederungshilfe/organizations/$organizationId';
      final testPaths = [
        'eingliederungshilfe',
        'eingliederungshilfe/organizations',
        basePath,
        '$basePath/teams',
        '$basePath/employees',
        '$basePath/administration',
        '$basePath/shared',
        '$basePath/shared/calendar-sync',
        '$basePath/shared/messages',
      ];

      print('🔄 Teste ${testPaths.length} Ordner...');

      for (final path in testPaths) {
        print('🔄 Teste Ordner: /$path');
        try {
          await client.mkdir('/$path');
          print('📁 Ordner erstellt: /$path');
        } catch (e) {
          print('🔄 mkdir-Fehler für /$path: $e');
          // Bei WebDAV können Fehler 405/409 bedeuten, dass der Ordner bereits existiert
          if (e.toString().contains('405') || e.toString().contains('409')) {
            print('📁 Ordner existiert bereits: /$path');
          } else {
            print('❌ Echter Fehler bei Ordner /$path: $e');
            return false;
          }
        }
      }

      print('✅ Ordnerstruktur erfolgreich erstellt/validiert');
      return true;

    } catch (e, stackTrace) {
      print('❌ Ordner-Test fehlgeschlagen: $e');
      print('❌ StackTrace: $stackTrace');
      return false;
    }
  }
}
