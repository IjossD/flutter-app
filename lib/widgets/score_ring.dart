import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ScoreRing extends StatelessWidget {
  final double score;
  final String label;
  final String subtitle;

  const ScoreRing({
    required this.score,
    required this.label,
    required this.subtitle,
    super.key,
  });

  Color _scoreColor(double value) {
    if (value >= 75) return AppTheme.sage;
    if (value >= 55) return AppTheme.amber;
    if (value >= 35) return AppTheme.terracotta;
    return AppTheme.mutedTerracotta;
  }

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(score);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.16), AppTheme.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: score),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return SizedBox(
                width: 210,
                height: 210,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 210,
                      height: 210,
                      child: CircularProgressIndicator(
                        value: value / 100,
                        strokeWidth: 16,
                        backgroundColor: color.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation(color),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          value.toStringAsFixed(0),
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                                fontSize: 54,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppTheme.textPrimary.withValues(alpha: 0.72),
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textPrimary.withValues(alpha: 0.78),
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }
}
