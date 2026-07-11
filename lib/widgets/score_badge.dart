import 'package:flutter/material.dart';
import 'package:workout_journal/theme/app_theme.dart';

class ScoreBadge extends StatelessWidget {
  final int value;
  final int maxValue;
  final String label;
  final String emoji;
  final bool invertColors;

  const ScoreBadge({
    super.key,
    required this.value,
    required this.maxValue,
    required this.label,
    required this.emoji,
    this.invertColors = false,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = value / maxValue.clamp(1, 10);
    final color = AppTheme.scoreColor(normalized, invert: !invertColors);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.8), color.withValues(alpha: 0.4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
