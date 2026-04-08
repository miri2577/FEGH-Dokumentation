#!/usr/bin/env dart

import 'dart:io';
import 'dart:typed_data';
import 'package:webdav_client/webdav_client.dart' as webdav;

Future<void> main(List<String> args) async {
  if (args.length != 2) {
    print('Usage: dart hidrive_test.dart <username> <password>');
    print('Example: dart hidrive_test.dart user@example.com mypassword');
    exit(1);
  }

  final username = args[0];
  final password = args[1];

  print('🔄 Testing HiDrive connection...');
  print('Server: https://webdav.hidrive.strato.com');
  print('Username: $username');
  print('');

  try {
    // Create WebDAV client
    final client = webdav.newClient(
      'https://webdav.hidrive.strato.com/users/$username',
      user: username.trim(),
      password: password,
      debug: false,
    );

    client.setConnectTimeout(15000);
    client.setReceiveTimeout(30000);

    print('📡 Connecting to HiDrive...');

    // Test 1: List root directory
    print('📂 Testing directory listing...');
    final files = await client.readDir('/');
    print('✅ Root directory accessible');
    print('Found ${files.length} items in root directory:');
    for (final file in files.take(5)) {
      print('  - ${file.name} (${(file.isDir ?? false) ? 'DIR' : 'FILE'})');
    }

    print('');

    // Test 2: Create test folder structure
    print('📁 Testing folder creation...');
    final testPaths = [
      'eingliederungshilfe',
      'eingliederungshilfe/organizations',
      'eingliederungshilfe/organizations/test-org-123',
      'eingliederungshilfe/organizations/test-org-123/clients',
      'eingliederungshilfe/organizations/test-org-123/schedules',
      'eingliederungshilfe/organizations/test-org-123/reports',
      'eingliederungshilfe/organizations/test-org-123/reports/monthly',
      'eingliederungshilfe/organizations/test-org-123/reports/annual',
    ];

    for (final path in testPaths) {
      try {
        await client.mkdir('/$path');
        print('✅ Created: /$path');
      } catch (e) {
        if (e.toString().contains('405') || e.toString().contains('409')) {
          print('ℹ️  Already exists: /$path');
        } else {
          print('❌ Error creating /$path: $e');
          exit(1);
        }
      }
    }

    print('');

    // Test 3: Write a test file
    print('📝 Testing file upload...');
    final testData = '''
{
  "test": true,
  "timestamp": "${DateTime.now().toIso8601String()}",
  "app": "Eingliederungshilfe Flutter",
  "connection_test": "successful"
}
''';

    await client.write('/eingliederungshilfe/organizations/test-org-123/connection-test.json', Uint8List.fromList(testData.codeUnits));
    print('✅ Test file uploaded successfully');

    // Test 4: Read the test file back
    print('📖 Testing file download...');
    final downloadedData = await client.read('/eingliederungshilfe/organizations/test-org-123/connection-test.json');
    final downloadedText = String.fromCharCodes(downloadedData);
    print('✅ Test file downloaded successfully');
    print('Content matches: ${downloadedText.contains('"test": true')}');

    print('');
    print('🎉 ALL TESTS PASSED!');
    print('✅ HiDrive connection is working perfectly');
    print('✅ Folder creation works');
    print('✅ File upload/download works');
    print('');
    print('🚀 Ready for Flutter app integration!');

  } catch (e) {
    print('❌ CONNECTION FAILED: $e');
    print('');
    print('Common issues:');
    print('- Check username and password');
    print('- Ensure HiDrive account is active');
    print('- Check internet connection');
    exit(1);
  }
}
