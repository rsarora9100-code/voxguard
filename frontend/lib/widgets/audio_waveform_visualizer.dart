import 'dart:math';
import 'package:flutter/material.dart';

class AudioWaveformVisualizer extends StatefulWidget {
  final bool isStreaming;
  final Color waveColor;
  final int barCount;
  final double height;

  const AudioWaveformVisualizer({
    Key? key,
    required this.isStreaming,
    this.waveColor = const Color(0xFF6366F1),
    this.barCount = 28,
    this.height = 48.0,
  }) : super(key: key);

  @override
  State<AudioWaveformVisualizer> createState() => _AudioWaveformVisualizerState();
}

class _AudioWaveformVisualizerState extends State<AudioWaveformVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          height: widget.height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(widget.barCount, (index) {
              double factor = widget.isStreaming
                  ? (0.15 + 0.85 * (_random.nextDouble() * 0.8 + 0.2))
                  : 0.12;

              // Smooth edges
              double edgeFalloff = sin((index / widget.barCount) * pi);
              double barHeight = widget.height * factor * edgeFalloff;
              barHeight = max(barHeight, 4.0);

              return Container(
                width: 3.5,
                height: barHeight,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  color: widget.waveColor.withOpacity(widget.isStreaming ? 0.9 : 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
