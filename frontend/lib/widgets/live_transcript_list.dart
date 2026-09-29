import 'package:flutter/material.dart';
import '../models/transcript_entry.dart';

class LiveTranscriptList extends StatelessWidget {
  final List<TranscriptEntry> transcript;
  final ScrollController? scrollController;

  const LiveTranscriptList({
    Key? key,
    required this.transcript,
    this.scrollController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (transcript.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mic_none, size: 48, color: Colors.white.withOpacity(0.3)),
            const SizedBox(height: 8),
            Text(
              'Listening and transcribing audio in real time...',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: transcript.length,
      itemBuilder: (context, index) {
        final entry = transcript[index];
        final isAssistant = entry.isAssistant;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: isAssistant ? MainAxisAlignment.start : MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isAssistant) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF6366F1),
                  child: const Icon(Icons.smart_toy, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isAssistant
                        ? const Color(0xFF1E293B)
                        : (entry.hasScamAlert ? const Color(0xFF7F1D1D) : const Color(0xFF334155)),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isAssistant ? Radius.zero : const Radius.circular(16),
                      bottomRight: isAssistant ? const Radius.circular(16) : Radius.zero,
                    ),
                    border: entry.hasScamAlert
                        ? Border.all(color: const Color(0xFFEF4444), width: 1.5)
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        isAssistant ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isAssistant ? 'VoxGuard AI' : 'Caller',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isAssistant ? const Color(0xFF818CF8) : const Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              entry.language.toUpperCase(),
                              style: const TextStyle(fontSize: 9, color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.text,
                        style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.3),
                      ),
                      if (entry.hasScamAlert) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFEF4444), width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.warning, color: Color(0xFFEF4444), size: 14),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  entry.scamAlert!,
                                  style: const TextStyle(
                                    color: Color(0xFFEF4444),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (!isAssistant) ...[
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: entry.hasScamAlert ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                  child: Icon(
                    entry.hasScamAlert ? Icons.report_problem : Icons.person,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
