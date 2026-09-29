import 'package:flutter/material.dart';
import '../models/transcript_entry.dart';
import '../services/api_service.dart';
import '../widgets/live_transcript_list.dart';
import '../widgets/risk_badge.dart';

class AiScreeningScreen extends StatefulWidget {
  final String callId;
  final String phoneNumber;
  final String callerName;

  const AiScreeningScreen({
    Key? key,
    required this.callId,
    required this.phoneNumber,
    required this.callerName,
  }) : super(key: key);

  @override
  State<AiScreeningScreen> createState() => _AiScreeningScreenState();
}

class _AiScreeningScreenState extends State<AiScreeningScreen> {
  List<TranscriptEntry> _dialogues = [];
  bool _isLoading = true;
  String _selectedLanguage = 'en';
  double _riskScore = 15.0;
  String _riskLevel = 'LOW';
  String _decision = 'QUESTIONING';

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  Future<void> _startSession() async {
    final startRes = await ApiService.startScreening(
      phoneNumber: widget.phoneNumber,
      callerName: widget.callerName,
    );

    if (startRes != null) {
      setState(() {
        _dialogues.add(TranscriptEntry(
          speaker: 'assistant',
          text: startRes['initial_assistant_message'] ??
              'Hello, I am the VoxGuard AI Voice Assistant. Who is calling and what is the reason for your call?',
          language: _selectedLanguage,
          timestamp: DateTime.now(),
        ));
        _riskScore = (startRes['initial_risk_score'] as num?)?.toDouble() ?? 15.0;
        _riskLevel = startRes['risk_level'] ?? 'LOW';
        _isLoading = false;
      });
    }
  }

  Future<void> _simulateCallerReply(String text) async {
    setState(() {
      _dialogues.add(TranscriptEntry(
        speaker: 'caller',
        text: text,
        language: _selectedLanguage,
        timestamp: DateTime.now(),
      ));
    });

    final turnRes = await ApiService.sendScreeningTurn(
      callId: widget.callId,
      transcript: text,
      language: _selectedLanguage,
    );

    if (turnRes != null) {
      setState(() {
        _dialogues.add(TranscriptEntry(
          speaker: 'assistant',
          text: turnRes['assistant_reply'] ?? '',
          language: _selectedLanguage,
          timestamp: DateTime.now(),
          scamAlert: turnRes['scam_alert'],
        ));
        _riskScore = (turnRes['updated_risk_score'] as num?)?.toDouble() ?? _riskScore;
        _riskLevel = turnRes['risk_level'] ?? _riskLevel;
        _decision = turnRes['decision'] ?? 'QUESTIONING';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('AI Call Screening Assistant', style: TextStyle(color: Colors.white, fontSize: 18)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: RiskBadge(
              riskLevel: _riskLevel,
              score: _riskScore,
              size: 42,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Screening Status Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFF1E1B4B),
              child: Row(
                children: [
                  const Icon(Icons.smart_toy, color: Color(0xFF818CF8), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI screening active for ${widget.callerName} (${widget.phoneNumber})',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  DropdownButton<String>(
                    value: _selectedLanguage,
                    dropdownColor: const Color(0xFF1E293B),
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('🇺🇸 EN', style: TextStyle(color: Colors.white, fontSize: 12))),
                      DropdownMenuItem(value: 'es', child: Text('🇪🇸 ES', style: TextStyle(color: Colors.white, fontSize: 12))),
                      DropdownMenuItem(value: 'hi', child: Text('🇮🇳 HI', style: TextStyle(color: Colors.white, fontSize: 12))),
                      DropdownMenuItem(value: 'fr', child: Text('🇫🇷 FR', style: TextStyle(color: Colors.white, fontSize: 12))),
                      DropdownMenuItem(value: 'de', child: Text('🇩🇪 DE', style: TextStyle(color: Colors.white, fontSize: 12))),
                    ],
                    onChanged: (lang) {
                      if (lang != null) setState(() => _selectedLanguage = lang);
                    },
                  ),
                ],
              ),
            ),

            // Live Dialogues
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : LiveTranscriptList(transcript: _dialogues),
            ),

            // Interactive Caller Reply Simulation Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: const Color(0xFF1E293B),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Simulate Caller Spoken Response:', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildQuickReplyChip('🚨 "Send OTP immediately or warrant issued"'),
                        _buildQuickReplyChip('📦 "FedEx delivery driver at front lobby"'),
                        _buildQuickReplyChip('💳 "Bank security alert regarding unusual card charge"'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.phone, size: 18),
                          label: const Text('Take Over Call'),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.call_end, size: 18),
                          label: const Text('Terminate Scam'),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickReplyChip(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        backgroundColor: const Color(0xFF334155),
        label: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        onPressed: () => _simulateCallerReply(text),
      ),
    );
  }
}
