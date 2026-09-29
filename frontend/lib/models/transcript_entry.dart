class TranscriptEntry {
  final String speaker; // "assistant" or "caller"
  final String text;
  final String language;
  final double confidence;
  final DateTime timestamp;
  final String? scamAlert;
  final List<String> matchedKeywords;

  TranscriptEntry({
    required this.speaker,
    required this.text,
    this.language = 'en',
    this.confidence = 1.0,
    required this.timestamp,
    this.scamAlert,
    this.matchedKeywords = const [],
  });

  factory TranscriptEntry.fromJson(Map<String, dynamic> json) {
    return TranscriptEntry(
      speaker: json['speaker'] ?? 'caller',
      text: json['text'] ?? '',
      language: json['language'] ?? 'en',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp']) ?? DateTime.now()
          : DateTime.now(),
      scamAlert: json['scam_alert'],
      matchedKeywords: List<String>.from(json['matched_keywords'] ?? []),
    );
  }

  bool get isAssistant => speaker == 'assistant';
  bool get hasScamAlert => scamAlert != null && scamAlert!.isNotEmpty;
}
