import 'transcript_entry.dart';

class CallRecord {
  final String id;
  final String callerNumber;
  final String callerName;
  final String callType; // incoming, screened, blocked, answered
  final String status;
  final DateTime timestamp;
  final int durationSeconds;
  final double finalRiskScore;
  final String riskLevel; // LOW, MEDIUM, HIGH
  final bool isDeepfake;
  final double deepfakeConfidence;
  final bool scamDetected;
  final String? scamCategory;
  final String? transcriptSummary;
  final List<TranscriptEntry> dialogues;

  CallRecord({
    required this.id,
    required this.callerNumber,
    required this.callerName,
    required this.callType,
    required this.status,
    required this.timestamp,
    required this.durationSeconds,
    required this.finalRiskScore,
    required this.riskLevel,
    required this.isDeepfake,
    required this.deepfakeConfidence,
    required this.scamDetected,
    this.scamCategory,
    this.transcriptSummary,
    this.dialogues = const [],
  });

  factory CallRecord.fromJson(Map<String, dynamic> json) {
    var rawDialogues = json['dialogues'] as List<dynamic>? ?? [];
    List<TranscriptEntry> parsedDialogues = rawDialogues
        .map((d) => TranscriptEntry.fromJson(d as Map<String, dynamic>))
        .toList();

    return CallRecord(
      id: json['id'] ?? '',
      callerNumber: json['caller_number'] ?? '',
      callerName: json['caller_name'] ?? 'Unknown Caller',
      callType: json['call_type'] ?? 'incoming',
      status: json['status'] ?? 'completed',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp']) ?? DateTime.now()
          : DateTime.now(),
      durationSeconds: json['duration_seconds'] ?? 0,
      finalRiskScore: (json['final_risk_score'] as num?)?.toDouble() ?? 0.0,
      riskLevel: json['risk_level'] ?? 'LOW',
      isDeepfake: json['is_deepfake'] ?? false,
      deepfakeConfidence: (json['deepfake_confidence'] as num?)?.toDouble() ?? 0.0,
      scamDetected: json['scam_detected'] ?? false,
      scamCategory: json['scam_category'],
      transcriptSummary: json['transcript_summary'],
      dialogues: parsedDialogues,
    );
  }
}
