import 'package:flutter/foundation.dart';

class AppLogger {
  static void info(String tag, String message) {
    if (kDebugMode) {
      print('[$tag] $message');
    }
  }

  static void error(String tag, String message, [Object? error]) {
    if (kDebugMode) {
      print('[$tag] ERROR: $message${error != null ? ' | $error' : ''}');
    }
  }

  static void warning(String tag, String message) {
    if (kDebugMode) {
      print('[$tag] WARN: $message');
    }
  }
}
