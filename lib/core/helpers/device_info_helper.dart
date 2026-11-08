import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// Collects device information to send to the backend.
/// The backend stores this in the `devices` table for session management.
class DeviceInfoHelper {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Returns a map matching the backend's expected `deviceInfo` structure:
  /// { deviceName, deviceType, deviceId }
  static Future<Map<String, String>> getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        return {
          'deviceName': '${info.brand} ${info.model}',
          'deviceType': 'android',
          'deviceId': info.id, // Unique Android build ID
        };
      } else if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        return {
          'deviceName': info.name,
          'deviceType': 'ios',
          'deviceId': info.identifierForVendor ?? '',
        };
      }
    } catch (e) {
      if (kDebugMode) print('DeviceInfoHelper error: $e');
    }

    return {
      'deviceName': 'Unknown Device',
      'deviceType': Platform.operatingSystem,
      'deviceId': '',
    };
  }

  /// Stable identifier of this device used by the server to recognise it
  /// across sessions (Android build ID / iOS identifierForVendor). Returns
  /// null on other platforms.
  static Future<String?> getDeviceId() async {
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      return androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      return iosInfo.identifierForVendor;
    }
    return null;
  }
}
