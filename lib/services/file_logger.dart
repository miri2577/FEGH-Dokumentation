import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';

class FileLogger {
  static final FileLogger _instance = FileLogger._internal();
  factory FileLogger() => _instance;
  FileLogger._internal();

  File? _logFile;

  Future<void> initialize() async {
    try {
      final directory = await getApplicationSupportDirectory();
      _logFile = File('${directory.path}/debug.log');
      await log('📝 FileLogger initialized at ${DateTime.now()}');
    } catch (e) {
      print('FileLogger init error: $e');
    }
  }

  Future<void> log(String message) async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      final logMessage = '[$timestamp] $message\n';

      // Also print for debug builds
      print(message);

      // Write to file
      if (_logFile != null) {
        await _logFile!.writeAsString(logMessage, mode: FileMode.append, flush: true);
      }
    } catch (e) {
      print('FileLogger write error: $e');
    }
  }

  Future<String> getLogContent() async {
    try {
      if (_logFile != null && await _logFile!.exists()) {
        return await _logFile!.readAsString();
      }
    } catch (e) {
      await log('Error reading log file: $e');
    }
    return 'No logs available';
  }

  Future<void> clearLog() async {
    try {
      if (_logFile != null && await _logFile!.exists()) {
        await _logFile!.delete();
      }
      await initialize();
      await log('Log file cleared');
    } catch (e) {
      print('Error clearing log: $e');
    }
  }
}