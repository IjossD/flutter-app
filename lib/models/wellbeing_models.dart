enum RiskLevel {
  stable,
  watch,
  low,
  urgent,
}

class WellbeingSnapshot {
  final double overallScore;
  final double sleepScore;
  final double activityScore;
  final double socialScore;
  final double stressLoad;
  final double moodScore;
  final String message;
  final RiskLevel riskLevel;
  final String supportTitle;
  final String supportBody;
  final List<double> trend;

  const WellbeingSnapshot({
    required this.overallScore,
    required this.sleepScore,
    required this.activityScore,
    required this.socialScore,
    required this.stressLoad,
    required this.moodScore,
    required this.message,
    required this.riskLevel,
    required this.supportTitle,
    required this.supportBody,
    required this.trend,
  });

  factory WellbeingSnapshot.initial() {
    return const WellbeingSnapshot(
      overallScore: 74,
      sleepScore: 78,
      activityScore: 68,
      socialScore: 72,
      stressLoad: 32,
      moodScore: 72,
      message:
          'Tu ritmo se mantiene estable. El baseline personal sigue siendo la referencia principal.',
      riskLevel: RiskLevel.stable,
      supportTitle: 'Bienestar estable',
      supportBody:
          'Mantén las rutinas que te están funcionando y sigue revisando tu baseline personal.',
      trend: [66, 67, 68, 69, 71, 73, 74],
    );
  }

  WellbeingSnapshot copyWith({
    double? overallScore,
    double? sleepScore,
    double? activityScore,
    double? socialScore,
    double? stressLoad,
    double? moodScore,
    String? message,
    RiskLevel? riskLevel,
    String? supportTitle,
    String? supportBody,
    List<double>? trend,
  }) {
    return WellbeingSnapshot(
      overallScore: overallScore ?? this.overallScore,
      sleepScore: sleepScore ?? this.sleepScore,
      activityScore: activityScore ?? this.activityScore,
      socialScore: socialScore ?? this.socialScore,
      stressLoad: stressLoad ?? this.stressLoad,
      moodScore: moodScore ?? this.moodScore,
      message: message ?? this.message,
      riskLevel: riskLevel ?? this.riskLevel,
      supportTitle: supportTitle ?? this.supportTitle,
      supportBody: supportBody ?? this.supportBody,
      trend: trend ?? this.trend,
    );
  }
}

class CheckInDraft {
  final double mood;
  final double sleepHours;
  final double activityMinutes;
  final double socialMinutes;
  final double energy;
  final double stress;
  final String note;

  const CheckInDraft({
    required this.mood,
    required this.sleepHours,
    required this.activityMinutes,
    required this.socialMinutes,
    required this.energy,
    required this.stress,
    required this.note,
  });
}

class CheckInRecord {
  final DateTime date;
  final double mood;
  final double sleepHours;
  final double activityMinutes;
  final double socialMinutes;
  final double energy;
  final double stress;
  final double score;
  final String note;
  final RiskLevel riskLevel;

  const CheckInRecord({
    required this.date,
    required this.mood,
    required this.sleepHours,
    required this.activityMinutes,
    required this.socialMinutes,
    required this.energy,
    required this.stress,
    required this.score,
    required this.note,
    required this.riskLevel,
  });
}

class InsightItem {
  final String title;
  final String body;
  final String label;

  const InsightItem({
    required this.title,
    required this.body,
    required this.label,
  });
}
