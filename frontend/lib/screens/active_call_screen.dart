import 'dart:async';
import 'package:flutter/material.dart';
import '../models/transcript_entry.dart';
import '../services/websocket_service.dart';
import '../services/api_service.dart';
import '../widgets/risk_badge.dart';
import '../widgets/audio_waveform_visualizer.dart';
import '../widgets/live_transcript_list.dart';
import '../widgets/call_action_bar.dart';
import 'ai_screening_screen.dart';

class ActiveCallScreen extends StatefulWidget {
  final String phoneNumber;
  final String callerName;
  final String initialRiskLevel;
  final double initialRiskScore;
  final bool isDeepfakeSimulation;
  final String simulationTranscript;

  const ActiveCallScreen({
    Key? key,
    required this.phoneNumber,
    required this.callerName,
    this.initialRiskLevel = 'LOW',
    this.initialRiskScore = 15.0,
    this.isDeepfakeSimulation = false,
    this.simulationTranscript = '',
  }) : super(key: key);

  @override
  State<ActiveCallScreen> createState() => _ActiveCallScreenState();
}

class _ActiveCallScreenState extends State<ActiveCallScreen> {
  final WebSocketAudioService _wsService = WebSocketAudioService();
  final ScrollController _scrollController = ScrollController();

  late String _riskLevel;
  late double _riskScore;
  bool _isDeepfake = false;
  double _deepfakeConfidence = 0.0;
  bool _isScreening = false;
  String _callId = '';
  List<TranscriptEntry> _transcripts = [];
  Timer? _simulationTimer;

  @override
  void initState() {
    super.initState();
    _riskLevel = widget.initialRiskLevel;
    _riskScore = widget.initialRiskScore;
    _isDeepfake = widget.isDeepfakeSimulation;
    _deepfakeConfidence = widget.isDeepfakeSimulation ? 91.5 : 5.0;
    _callId = 'call-${DateTime.now().millisecondsSinceEpoch}';

    _initWebSocket();
    _runSimulationTimeline();
  }

  void _initWebSocket() {
    _wsService.connectCallStream(_callId, phoneNumber: widget.phoneNumber);
    _wsService.eventStream.listen((event) {
      if (!mounted) return;
      setState(() {
        if (event.type == 'audio_classification') {
          _isDeepfake = event.data['is_synthetic'] ?? false;
          _deepfakeConfidence = (event.data['confidence'] as num?)?.toDouble() ?? 0.0;
        } else if (event.type == 'transcript_update') {
          _transcripts.add(TranscriptEntry(
            speaker: 'caller',
            text: event.data['text'] ?? '',
            language: event.data['language'] ?? 'en',
            timestamp: DateTime.now(),
            scamAlert: event.data['scam_alert'],
            matchedKeywords: List<String>.from(event.data['matched_keywords'] ?? []),
          ));
          _riskScore = (event.data['risk_score'] as num?)?.toDouble() ?? _riskScore;
          _riskLevel = event.data['risk_level'] ?? _riskLevel;
          _scrollToBottom();
        } else if (event.type == 'assistant_reply') {
          _transcripts.add(TranscriptEntry(
            speaker: 'assistant',
            text: event.data['text'] ?? '',
            language: 'en',
            timestamp: DateTime.now(),
          ));
          _riskScore = (event.data['risk_score'] as num?)?.toDouble() ?? _riskScore;
          _riskLevel = event.data['risk_level'] ?? _riskLevel;
          _scrollToBottom();

          if (event.data['decision'] == 'TERMINATE_CALL_SCAM') {
            _showCallTerminatedBanner();
          }
        }
      });
    });
  }

  void _runSimulationTimeline() {
    // Simulate real-time audio chunk and transcription arrivals
    _simulationTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;

      // Send speech text through WebSocket pipeline
      _wsService.sendCallerSpeech(
        widget.simulationTranscript,
        language: 'en',
        phoneNumber: widget.phoneNumber,
      );

      // If deepfake simulation, send simulated raw PCM bytes
      if (widget.isDeepfakeSimulation) {
        _wsService.sendAudioBytes(List<int>.generate(3200, (i) => i % 255).toList() as dynamic);
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showCallTerminatedBanner() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🛑 Call automatically terminated by VoxGuard AI to prevent fraud.'),
        backgroundColor: Color(0xFFEF4444),
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _startAiScreening() {
    setState(() => _isScreening = true);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AiScreeningScreen(
          callId: _callId,
          phoneNumber: widget.phoneNumber,
          callerName: widget.callerName,
        ),
      ),
    );
  }

  void _answerCall() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Call Connected. VoxGuard live audio monitoring active.'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  void _terminateCall() {
    _wsService.disconnect();
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    _wsService.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header with Floating Risk Badge
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                    onPressed: _terminateCall,
                  ),
                  Column(
                    children: [
                      Text(
                        _isScreening ? 'AI SCREENING ACTIVE' : 'INCOMING CALL',
                        style: const TextStyle(
                          color: Color(0xFF818CF8),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.phoneNumber,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                  RiskBadge(
                    riskLevel: _riskLevel,
                    score: _riskScore,
                    isDeepfake: _isDeepfake,
                    size: 50,
                  ),
                ],
              ),
            ),

            // 2. Caller Identity Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: const Color(0xFF1E293B),
                    child: Icon(
                      _isDeepfake ? Icons.record_voice_over : Icons.person,
                      size: 40,
                      color: _isDeepfake ? const Color(0xFFEF4444) : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.callerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 3. Deepfake Warning Banner
            if (_isDeepfake)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7F1D1D),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Color(0xFFEF4444), size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'WARNING: AI Deepfake Synthetic Voice Detected (${_deepfakeConfidence.toInt()}% confidence). Do not provide sensitive info!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // 4. Live Audio Waveform
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: AudioWaveformVisualizer(
                isStreaming: true,
                waveColor: _riskLevel == 'HIGH'
                    ? const Color(0xFFEF4444)
                    : (_riskLevel == 'MEDIUM' ? const Color(0xFFF59E0B) : const Color(0xFF6366F1)),
                height: 40,
              ),
            ),

            // 5. Live Speech-to-Text Transcription Feed
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: LiveTranscriptList(
                  transcript: _transcripts,
                  scrollController: _scrollController,
                ),
              ),
            ),

            // 6. Action Controls Bar
            CallActionBar(
              onReject: _terminateCall,
              onAnswer: _answerCall,
              onScreenWithAI: _startAiScreening,
              isScreeningActive: _isScreening,
            ),
          ],
        ),
      ),
    );
  }
}
