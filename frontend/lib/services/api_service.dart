import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/caller_info.dart';
import '../models/risk_assessment.dart';
import '../models/call_record.dart';
import '../models/transcript_entry.dart';

class ApiService {
  // Configurable base URL (can point to localhost, LAN IP, or Cloud deployment)
  static String baseUrl = 'http://10.0.2.2:8000'; // Default Android emulator loopback

  static void setBaseUrl(String url) {
    baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  // 1. Caller Lookup
  static Future<CallerInfo?> lookupCaller(String phoneNumber) async {
    try {
      final uri = Uri.parse('$baseUrl/api/caller/lookup?phone_number=${Uri.encodeComponent(phoneNumber)}');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return CallerInfo.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print('Error looking up caller: $e');
    }
    return null;
  }

  // 2. Report Spam
  static Future<bool> reportSpam({
    required String phoneNumber,
    required String category,
    String? description,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/caller/report-spam');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone_number': phoneNumber,
          'category': category,
          'description': description,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error reporting spam: $e');
      return false;
    }
  }

  // 3. Call History
  static Future<List<CallRecord>> getCallHistory({int limit = 50}) async {
    try {
      final uri = Uri.parse('$baseUrl/api/caller/history?limit=$limit');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => CallRecord.fromJson(item)).toList();
      }
    } catch (e) {
      print('Error fetching call history: $e');
    }
    return [];
  }

  // 4. Evaluate Dynamic Risk
  static Future<RiskAssessment?> evaluateRisk({
    required String phoneNumber,
    String? callerName,
    String? liveTranscript,
    bool? isDeepfake,
    double? deepfakeConfidence,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/risk/evaluate');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone_number': phoneNumber,
          'caller_name': callerName,
          'live_transcript': liveTranscript,
          'is_deepfake': isDeepfake,
          'deepfake_confidence': deepfakeConfidence,
        }),
      );
      if (response.statusCode == 200) {
        return RiskAssessment.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print('Error evaluating risk: $e');
    }
    return null;
  }

  // 5. Start AI Screening
  static Future<Map<String, dynamic>?> startScreening({
    required String phoneNumber,
    String? callerName,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/screening/start');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'caller_number': phoneNumber,
          'caller_name': callerName ?? 'Unknown Caller',
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error starting screening: $e');
    }
    return null;
  }

  // 6. Handle Screening Turn
  static Future<Map<String, dynamic>?> sendScreeningTurn({
    required String callId,
    required String transcript,
    String language = 'en',
    bool isDeepfake = false,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/screening/turn');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'call_id': callId,
          'caller_audio_transcript': transcript,
          'detected_language': language,
          'is_deepfake': isDeepfake,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error in screening turn: $e');
    }
    return null;
  }

  // 7. Get Full Transcript
  static Future<List<TranscriptEntry>> getTranscript(String callId) async {
    try {
      final uri = Uri.parse('$baseUrl/api/screening/$callId/transcript');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => TranscriptEntry.fromJson(item)).toList();
      }
    } catch (e) {
      print('Error fetching transcript: $e');
    }
    return [];
  }

  // 8. Security Stats
  static Future<Map<String, dynamic>?> getSecurityStats() async {
    try {
      final uri = Uri.parse('$baseUrl/api/risk/stats');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error fetching security stats: $e');
    }
    return null;
  }
}
