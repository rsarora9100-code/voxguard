import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voxguard/models/caller_info.dart';
import 'package:voxguard/models/risk_assessment.dart';
import 'package:voxguard/models/transcript_entry.dart';
import 'package:voxguard/widgets/risk_badge.dart';

void main() {
  group('VoxGuard Models Tests', () {
    test('CallerInfo JSON serialization', () {
      final info = CallerInfo.fromJson({
        'phone_number': '+18005550199',
        'name_tag': 'IRS Tax Relief Scam',
        'category': 'Government Impersonation',
        'reports_count': 428,
        'base_risk_score': 95.0,
        'risk_level': 'HIGH',
        'color_code': '#EF4444',
        'is_whitelisted': false,
        'recommendation': 'BLOCK'
      });

      expect(info.phoneNumber, '+18005550199');
      expect(info.riskLevel, 'HIGH');
      expect(info.baseRiskScore, 95.0);
    });

    test('RiskAssessment JSON serialization and getters', () {
      final risk = RiskAssessment.fromJson({
        'phone_number': '+14155552671',
        'final_score': 12.0,
        'risk_level': 'LOW',
        'color_code': '#10B981',
        'recommendation': 'ALLOW',
        'breakdown': {'database_score': 10.0, 'whitelist_discount': 85.0},
        'flags': ['Verified Contact: Mom'],
        'is_deepfake': false,
        'scam_intent_detected': false,
      });

      expect(risk.isSafe, isTrue);
      expect(risk.isDangerous, isFalse);
      expect(risk.colorCode, '#10B981');
    });

    test('TranscriptEntry scam alert identification', () {
      final entry = TranscriptEntry(
        speaker: 'caller',
        text: 'Give me your OTP immediately or you will be arrested',
        timestamp: DateTime.now(),
        scamAlert: 'OTP_AND_CREDENTIAL_THEFT',
      );

      expect(entry.isAssistant, isFalse);
      expect(entry.hasScamAlert, isTrue);
      expect(entry.scamAlert, 'OTP_AND_CREDENTIAL_THEFT');
    });
  });

  group('VoxGuard Widget Tests', () {
    testWidgets('RiskBadge renders high risk score and crimson badge', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: RiskBadge(
                riskLevel: 'HIGH',
                score: 94.0,
                isDeepfake: false,
                animatePulse: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('94%'), findsOneWidget);
      expect(find.byIcon(Icons.gpp_bad), findsOneWidget);
    });

    testWidgets('RiskBadge renders safe green badge for low risk', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: RiskBadge(
                riskLevel: 'LOW',
                score: 15.0,
                animatePulse: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('15%'), findsOneWidget);
      expect(find.byIcon(Icons.verified_user), findsOneWidget);
    });
  });
}
