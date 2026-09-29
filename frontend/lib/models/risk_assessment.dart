class RiskAssessment {
  final String phoneNumber;
  final double finalScore;
  final String riskLevel; // LOW, MEDIUM, HIGH
  final String colorCode; // #10B981, #F59E0B, #EF4444
  final String recommendation; // ALLOW, SCREEN_WITH_AI, BLOCK
  final Map<String, double> breakdown;
  final List<String> flags;
  final bool isDeepfake;
  final bool scamIntentDetected;
  final String? scamCategory;
  final String callerName;

  RiskAssessment({
    required this.phoneNumber,
    required this.finalScore,
    required this.riskLevel,
    required this.colorCode,
    required this.recommendation,
    required this.breakdown,
    required this.flags,
    this.isDeepfake = false,
    this.scamIntentDetected = false,
    this.scamCategory,
    this.callerName = 'Unknown Caller',
  });

  factory RiskAssessment.fromJson(Map<String, dynamic> json) {
    final rawBreakdown = json['breakdown'] as Map<String, dynamic>? ?? {};
    final mappedBreakdown = rawBreakdown.map(
      (k, v) => MapEntry(k, (v as num?)?.toDouble() ?? 0.0),
    );

    return RiskAssessment(
      phoneNumber: json['phone_number'] ?? '',
      finalScore: (json['final_score'] as num?)?.toDouble() ?? 0.0,
      riskLevel: json['risk_level'] ?? 'LOW',
      colorCode: json['color_code'] ?? '#10B981',
      recommendation: json['recommendation'] ?? 'ALLOW',
      breakdown: mappedBreakdown,
      flags: List<String>.from(json['flags'] ?? []),
      isDeepfake: json['is_deepfake'] ?? false,
      scamIntentDetected: json['scam_intent_detected'] ?? false,
      scamCategory: json['scam_category'],
      callerName: json['caller_name'] ?? 'Unknown Caller',
    );
  }

  bool get isSafe => riskLevel == 'LOW';
  bool get isSuspicious => riskLevel == 'MEDIUM';
  bool get isDangerous => riskLevel == 'HIGH';
}
