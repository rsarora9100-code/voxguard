class CallerInfo {
  final String phoneNumber;
  final String nameTag;
  final String category;
  final int reportsCount;
  final double baseRiskScore;
  final String riskLevel;
  final String colorCode;
  final bool isWhitelisted;
  final String? contactName;
  final int callFrequencyRecent;
  final String recommendation;

  CallerInfo({
    required this.phoneNumber,
    required this.nameTag,
    required this.category,
    required this.reportsCount,
    required this.baseRiskScore,
    required this.riskLevel,
    required this.colorCode,
    required this.isWhitelisted,
    this.contactName,
    this.callFrequencyRecent = 0,
    required this.recommendation,
  });

  factory CallerInfo.fromJson(Map<String, dynamic> json) {
    return CallerInfo(
      phoneNumber: json['phone_number'] ?? '',
      nameTag: json['name_tag'] ?? 'Unknown Caller',
      category: json['category'] ?? 'General',
      reportsCount: json['reports_count'] ?? 0,
      baseRiskScore: (json['base_risk_score'] as num?)?.toDouble() ?? 0.0,
      riskLevel: json['risk_level'] ?? 'LOW',
      colorCode: json['color_code'] ?? '#10B981',
      isWhitelisted: json['is_whitelisted'] ?? false,
      contactName: json['contact_name'],
      callFrequencyRecent: json['call_frequency_recent'] ?? 0,
      recommendation: json['recommendation'] ?? 'ALLOW',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phone_number': phoneNumber,
      'name_tag': nameTag,
      'category': category,
      'reports_count': reportsCount,
      'base_risk_score': baseRiskScore,
      'risk_level': riskLevel,
      'color_code': colorCode,
      'is_whitelisted': isWhitelisted,
      'contact_name': contactName,
      'call_frequency_recent': callFrequencyRecent,
      'recommendation': recommendation,
    };
  }
}
