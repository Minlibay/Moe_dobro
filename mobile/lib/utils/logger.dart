import 'package:flutter/foundation.dart';

class Logger {
  static void info(String message, [dynamic data]) {
    if (kDebugMode) {
      print('[INFO] $message${data != null ? ': $data' : ''}');
    }
  }

  static void debug(String message, [dynamic data]) {
    if (kDebugMode) {
      print('[DEBUG] $message${data != null ? ': $data' : ''}');
    }
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('[ERROR] $message${error != null ? ': $error' : ''}');
      if (stackTrace != null) {
        print(stackTrace);
      }
    }
  }

  static void warning(String message, [dynamic data]) {
    if (kDebugMode) {
      print('[WARNING] $message${data != null ? ': $data' : ''}');
    }
  }
}
