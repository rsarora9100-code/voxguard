import 'package:flutter/material.dart';

class CallActionBar extends StatelessWidget {
  final VoidCallback onReject;
  final VoidCallback onAnswer;
  final VoidCallback onScreenWithAI;
  final bool isScreeningActive;

  const CallActionBar({
    Key? key,
    required this.onReject,
    required this.onAnswer,
    required this.onScreenWithAI,
    this.isScreeningActive = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 1. Reject / Terminate Button
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                heroTag: 'btn_reject',
                onPressed: onReject,
                backgroundColor: const Color(0xFFEF4444),
                child: const Icon(Icons.call_end, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 6),
              const Text('Decline', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),

          // 2. AI Screen Assistant Button
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.5),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: FloatingActionButton(
                  heroTag: 'btn_ai_screen',
                  onPressed: onScreenWithAI,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  child: Icon(
                    isScreeningActive ? Icons.record_voice_over : Icons.smart_toy,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isScreeningActive ? 'Screening...' : 'AI Screen',
                style: const TextStyle(
                  color: Color(0xFFA5B4FC),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          // 3. Answer Call Button
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                heroTag: 'btn_answer',
                onPressed: onAnswer,
                backgroundColor: const Color(0xFF10B981),
                child: const Icon(Icons.call, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 6),
              const Text('Answer', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
