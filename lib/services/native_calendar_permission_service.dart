import 'dart:io';
import 'package:flutter/services.dart';

class NativeCalendarPermissionService {
  static const platform = MethodChannel('com.inthebiz.app/calendar');

  /// Request calendar permissions using native iOS 17+ API
  static Future<bool> requestCalendarPermission() async {
    if (!Platform.isIOS) {
      throw UnsupportedError('This service only works on iOS');
    }

    try {
      final bool granted = await platform.invokeMethod('requestCalendarPermission');
      print('[NativeCalendarPermission] Permission granted: $granted');
      return granted;
    } on PlatformException catch (e) {
      print('[NativeCalendarPermission] Error: ${e.message}');
      return false;
    }
  }

  /// Check current calendar permission status
  static Future<String> checkCalendarPermission() async {
    if (!Platform.isIOS) {
      throw UnsupportedError('This service only works on iOS');
    }

    try {
      final String status = await platform.invokeMethod('checkCalendarPermission');
      print('[NativeCalendarPermission] Current status: $status');
      return status;
    } on PlatformException catch (e) {
      print('[NativeCalendarPermission] Error checking status: ${e.message}');
      return 'error';
    }
  }
}
