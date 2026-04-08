#!/usr/bin/env dart

import 'dart:io';
import 'dart:typed_data';
import 'package:webdav_client/webdav_client.dart' as webdav;

Future<void> main(List<String> args) async {
  if (args.length != 2) {
    print('Usage: dart hidrive_test2.dart <username> <password>');
    exit(1);
  }

  final username = args[0];
  final password = args[1];

  print('🔄 Testing HiDrive write permissions...');
  print('Username: $username');
  print('');

  try {
    final client = webdav.newClient(
      'https://webdav.hidrive.strato.com/users/$username',
      user: username.trim(),
      password: password,
      debug: false,
    );

    client.setConnectTimeout(15000);
    client.setReceiveTimeout(30000);

    // Test 1: List root directory
    print('📂 1. Root directory contents:');
    final rootFiles = await client.readDir('/');
    for (final file in rootFiles) {
      print('  - ${file.name} (${(file.isDir ?? false) ? 'DIR' : 'FILE'})');
    }
    print('');

    // Test 2: Try to list users directory
    print('📂 2. Trying to access user base ...');
    try {
      final userFiles = await client.readDir('/');
      print('✅ User base accessible, found ${userFiles.length} items:');
      for (final file in userFiles.take(5)) {
        print('  - ${file.name} (${(file.isDir ?? false) ? 'DIR' : 'FILE'})');
      }

      // Test 3: Try to create folder in users directory
      print('');
      print('📁 3. Testing folder creation in user base ...');
      try {
        await client.mkdir('/eingliederungshilfe');
        print('✅ Successfully created /eingliederungshilfe');

        // Test 4: Try to write a file
        print('📝 4. Testing file upload in users directory...');
        final testData = '''{"test": true, "timestamp": "${DateTime.now().toIso8601String()}"}''';
        await client.write('/eingliederungshilfe/test.json', Uint8List.fromList(testData.codeUnits));
        print('✅ Successfully uploaded test file');

        print('');
        print('🎉 SUCCESS! User has write permissions');
        print('💡 Use path: /eingliederungshilfe/organizations/<org-id>/ ... for app data');

      } catch (e) {
        if (e.toString().contains('405') || e.toString().contains('409')) {
          print('ℹ️  Folder already exists, trying file upload...');
          try {
            final testData = '''{"test": true, "timestamp": "${DateTime.now().toIso8601String()}"}''';
            await client.write('/eingliederungshilfe/test.json', Uint8List.fromList(testData.codeUnits));
            print('✅ Successfully uploaded test file');
            print('🎉 SUCCESS! User has write permissions');
          } catch (e2) {
            print('❌ Cannot write files in user base: $e2');
          }
        } else {
          print('❌ Cannot create folders in user base: $e');
        }
      }

    } catch (e) {
      print('❌ Cannot access user base: $e');
    }

    // Test 5: Check user's home directory
    print('');
    print('📂 5. Trying app structure under user base ...');
    try {
      final baseFiles = await client.readDir('/eingliederungshilfe');
      print('✅ App base accessible: /eingliederungshilfe');
      print('Found ${baseFiles.length} items');

      // Try to create folder in home
      try {
        await client.mkdir('/eingliederungshilfe/organizations');
        print('✅ Created organizations folder');
        print('🎉 BEST OPTION: Use /eingliederungshilfe/organizations/<org-id>/');
      } catch (e) {
        if (e.toString().contains('405') || e.toString().contains('409')) {
          print('ℹ️  Folder already exists');
          print('🎉 BEST OPTION: Use /eingliederungshilfe/organizations/<org-id>/');
        } else {
          print('❌ Cannot create base folders: $e');
        }
      }
    } catch (e) {
      print('❌ Cannot access /eingliederungshilfe: $e');
    }

    print('');
    print('📋 SUMMARY:');
    print('- Recommended base: /eingliederungshilfe/organizations/<org-id>/');

  } catch (e) {
    print('❌ CONNECTION FAILED: $e');
    exit(1);
  }
}
