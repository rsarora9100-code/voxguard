import 'dart:async';
import 'package:flutter/services.dart';

class OverlayService {
  static const MethodChannel _channel = MethodChannel('com.voxguard.app/call_overlay');

  /// Checks if SYSTEM_ALERT_WINDOW permission is granted
  static Future<bool> hasPermission() async {
    try {
      final bool granted = await _channel.invokeMethod('hasOverlayPermission');
      return granted;
    } on PlatformException catch (e) {
      print('Overlay permission check error: ${e.message}');
      return false;
    }
  }

  /// Requests the user to grant SYSTEM_ALERT_WINDOW permission in Android Settings
  static Future<void> requestPermission() async {
    try {
      await _channel.invokeMethod('requestOverlayPermission');
    } on PlatformException catch (e) {
      print('Request overlay error: ${e.message}');
    }
  }

  /// Displays the floating color-coded risk badge overlay over the native Android phone screen
  static Future<void> showOverlay({
    required String phoneNumber,
    required String callerName,
    required String riskLevel, // LOW, MEDIUM, HIGH
    required double riskScore,
    required String colorCode,
    String? recommendation,
  }) async {
    try {
      await _channel.invokeMethod('showOverlay', {
        'phoneNumber': phoneNumber,
        'callerName': callerName,
        'riskLevel': riskLevel,
        'riskScore': riskScore,
        'colorCode': colorCode,
        'recommendation': recommendation ?? 'EVALUATING',
      });
    } on PlatformException catch (e) {
      print('Show overlay error: ${e.message}');
    }
  }

  /// Updates the existing overlay live with new transcript text or elevated risk level
  static Future<void> updateOverlay({
    required String riskLevel,
    required double riskScore,
    required String colorCode,
    String? latestTranscript,
    bool? isDeepfake,
  }) async {
    try {
      await _channel.invokeMethod('updateOverlay', {
        'riskLevel': riskLevel,
        'riskScore': riskScore,
        'colorCode': colorCode,
        'latestTranscript': latestTranscript,
        'isDeepfake': isDeepfake ?? false,
      });
    } on PlatformException catch (e) {
      print('Update overlay error: ${e.message}');
    }
  }

  /// Closes and removes the floating overlay window
  static Future<void> closeOverlay() async {
    try {
      await _channel.invokeMethod('closeOverlay');
    } on PlatformException catch (e) {
      print('Close overlay error: ${e.message}');
    }
  }
}
