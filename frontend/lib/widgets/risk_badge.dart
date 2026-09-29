import 'package:flutter/material.dart';

class RiskBadge extends StatefulWidget {
  final String riskLevel; // LOW, MEDIUM, HIGH
  final double score;
  final bool isDeepfake;
  final bool animatePulse;
  final double size;

  const RiskBadge({
    Key? key,
    required this.riskLevel,
    required this.score,
    this.isDeepfake = false,
    this.animatePulse = true,
    this.size = 64.0,
  }) : super(key: key);

  @override
  State<RiskBadge> createState() => _RiskBadgeState();
}

class _RiskBadgeState extends State<RiskBadge> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color get _badgeColor {
    switch (widget.riskLevel.toUpperCase()) {
      case 'LOW':
        return const Color(0xFF10B981); // Emerald Green
      case 'MEDIUM':
        return const Color(0xFFF59E0B); // Amber Yellow
      case 'HIGH':
      default:
        return const Color(0xFFEF4444); // Crimson Red
    }
  }

  IconData get _badgeIcon {
    if (widget.isDeepfake) {
      return Icons.record_voice_over;
    }
    switch (widget.riskLevel.toUpperCase()) {
      case 'LOW':
        return Icons.verified_user;
      case 'MEDIUM':
        return Icons.warning_amber_rounded;
      case 'HIGH':
      default:
        return Icons.gpp_bad;
    }
  }

  String get _label {
    if (widget.isDeepfake) return 'DEEPFAKE';
    switch (widget.riskLevel.toUpperCase()) {
      case 'LOW':
        return 'SAFE';
      case 'MEDIUM':
        return 'SUSPICIOUS';
      case 'HIGH':
      default:
        return 'HIGH RISK';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _badgeColor;

    Widget badgeContent = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.18),
        border: Border.all(color: color, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_badgeIcon, color: color, size: widget.size * 0.38),
            const SizedBox(height: 2),
            Text(
              '${widget.score.toInt()}%',
              style: TextStyle(
                color: color,
                fontSize: widget.size * 0.22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );

    if (!widget.animatePulse) {
      return badgeContent;
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: child,
        );
      },
      child: badgeContent,
    );
  }
}
