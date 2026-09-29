import 'dart:async';
import 'package:flutter/services.dart';

typedef CallScreeningCallback = void Function(String phoneNumber, String callerName);

class CallScreeningService {
  static const MethodChannel _channel = MethodChannel('com.voxguard.app/call_screening');

  static CallScreeningCallback? onIncomingCallIntercepted;

  static void initialize() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onCallIntercepted':
          final String phoneNumber = call.arguments['phoneNumber'] ?? '';
          final String callerName = call.arguments['callerName'] ?? 'Unknown Caller';
          if (onIncomingCallIntercepted != null) {
            onIncomingCallIntercepted!(phoneNumber, callerName);
          }
          break;
        default:
          print('Unhandled native method: ${call.method}');
      }
    });
  }

  /// Prompts user to set VoxGuard as the default Android Call Screening application
  static Future<bool> requestScreeningRole() async {
    try {
      final bool granted = await _channel.invokeMethod('requestScreeningRole');
      return granted;
    } on PlatformException catch (e) {
      print('Failed to request call screening role: ${e.message}');
      return false;
    }
  }

  /// Checks if VoxGuard currently holds the Call Screening Role
  static Future<bool> isScreeningRoleHeld() async {
    try {
      final bool held = await _channel.invokeMethod('isScreeningRoleHeld');
      return held;
    } on PlatformException catch (e) {
      print('Failed to check screening role: ${e.message}');
      return false;
    }
  }

  /// Tells the native screening service how to treat the incoming call
  static Future<void> respondToCall({
    required String phoneNumber,
    required bool disallowCall,
    required bool rejectCall,
    required bool skipCallLog,
    required bool skipNotification,
  }) async {
    try {
      await _channel.invokeMethod('respondToCall', {
        'phoneNumber': phoneNumber,
        'disallowCall': disallowCall,
        'rejectCall': rejectCall,
        'skipCallLog': skipCallLog,
        'skipNotification': skipNotification,
      });
    } on PlatformException catch (e) {
      print('Failed to respond to native call: ${e.message}');
    }
  }
}
