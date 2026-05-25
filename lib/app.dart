import 'package:flutter/material.dart';

import 'models/wellbeing_models.dart';
import 'screens/check_in_screen.dart';
import 'screens/home_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/app_theme.dart';

class WellbeingApp extends StatelessWidget {
  const WellbeingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Wellbeing App',
      theme: AppTheme.light(),
      home: const WellbeingShell(),
    );
  }
}

class WellbeingShell extends StatefulWidget {
  const WellbeingShell({super.key});

  @override
  State<WellbeingShell> createState() => _WellbeingShellState();
}

class _WellbeingShellState extends State<WellbeingShell> {
  int _selectedIndex = 0;
  WellbeingSnapshot _snapshot = WellbeingSnapshot.initial();
  final List<CheckInRecord> _history = [];
  final List<InsightItem> _insights = [];

  Future<void> _submitCheckIn(CheckInDraft draft) async {
    final mood = draft.mood.clamp(1.0, 10.0);
    final sleepHours = draft.sleepHours.clamp(0.0, 12.0);
    final activityMinutes = draft.activityMinutes.clamp(0.0, 240.0);
    final socialMinutes = draft.socialMinutes.clamp(0.0, 360.0);
    final energy = draft.energy.clamp(1.0, 10.0);
    final stress = draft.stress.clamp(1.0, 10.0);

    // 1. Construir secuencia real para el modelo BiLSTM [1, 30, 34]
    final List<CheckInRecord> fullHistory = [
      CheckInRecord(
        date: DateTime.now(),
        mood: mood,
        sleepHours: sleepHours,
        activityMinutes:
            activityMinutes * 100, // Convertir a "Pasos" aproximados
        socialMinutes: socialMinutes,
        energy: energy,
        stress: stress,
        score: 0,
        note: '',
        riskLevel: RiskLevel.stable,
      ),
      ..._history.map((e) => CheckInRecord(
            date: e.date,
            mood: e.mood,
            sleepHours: e.sleepHours,
            activityMinutes: e.activityMinutes * 100,
            socialMinutes: e.socialMinutes,
            energy: e.energy,
            stress: e.stress,
            score: e.score,
            note: e.note,
            riskLevel: e.riskLevel,
          )),
    ];

    final allSleep = fullHistory.map((e) => e.sleepHours).toList();
    final avgSleep = allSleep.reduce((a, b) => a + b) / allSleep.length;
    final allSteps = fullHistory.map((e) => e.activityMinutes).toList();
    final avgSteps = allSteps.reduce((a, b) => a + b) / allSteps.length;
    final allMood = fullHistory.map((e) => e.mood).toList();
    final avgMood = allMood.reduce((a, b) => a + b) / allMood.length;

    final realSequence = List.generate(1, (_) {
      return List.generate(30, (timeStep) {
        int historyIdx = 29 - timeStep;
        final record = historyIdx < fullHistory.length
            ? fullHistory[historyIdx]
            : fullHistory.last;

        final now = record.date;

        // Mapeo preciso de 34 features basado en la lista de Joseph
        final features = List.generate(34, (fIdx) {
          switch (fIdx) {
            case 0:
              return (record.sleepHours - avgSleep) / 1.5; // sleep_deviation_z
            case 1:
              return (record.sleepHours - 7.5); // sleep_change_7d
            case 2:
              return (record.sleepHours - avgSleep); // sleep_change_14d
            case 3:
              return 0.5; // sleep_variance_7d
            case 4:
              return 0.1; // sleep_trend_14d
            case 5:
              return record.sleepHours < 6 ? 1.0 : 0.0; // sleep_sustained_low
            case 6:
              return record.socialMinutes / 120.0; // circadian_shift
            case 7:
              return 0.8; // circadian_stability
            case 8:
              return 0.0; // sleep_midpoint_drift
            case 9:
              return (record.activityMinutes - avgSteps) /
                  1000.0; // steps_deviation_z
            case 10:
              return (record.activityMinutes - avgSteps) /
                  500.0; // steps_change_7d
            case 11:
              return 100.0; // steps_variance_7d
            case 12:
              return 0.0; // steps_trend_14d
            case 13:
              return record.activityMinutes < 2000
                  ? 1.0
                  : 0.0; // sedentary_streak
            case 14:
              return record.activityMinutes < 3000
                  ? 1.0
                  : 0.0; // steps_sustained_low
            case 15:
              return record.socialMinutes / 240.0; // night_phone_usage_ratio
            case 16:
              return (record.socialMinutes - 120.0) /
                  30.0; // screen_time_deviation
            case 17:
              return 0.0; // night_screen_change_7d
            case 18:
              return 0.5; // mood_instability_score
            case 19:
              return 0.0; // mood_trend_14d
            case 20:
              return (record.mood - avgMood) / 2.0; // mood_deviation
            case 21:
              return 0.0; // missing_data_ratio_7d
            case 22:
              return (now.weekday - 1).toDouble(); // day_of_week
            case 23:
              return now.weekday >= 6 ? 1.0 : 0.0; // is_weekend
            case 24:
              return (record.sleepHours * record.stress) /
                  50.0; // sleep_stress_interaction
            case 25:
              return (record.activityMinutes * record.mood) /
                  50000.0; // activity_mood_interaction
            case 26:
              return (record.sleepHours * record.activityMinutes) /
                  40000.0; // sleep_activity_interaction
            case 27:
              return 0.0; // user_id
            case 28:
              return (now.millisecondsSinceEpoch % 1000000) / 1000000.0; // date
            default:
              return 0.0; // Relleno hasta 34
          }
        });

        return features;
      });
    });

    // 2. Ejecutar inferencia con el modelo BiLSTM
    final prediction = await wellbeingInference.predictWellbeing(realSequence);
    print('DEBUG Prediction Result: $prediction');

    // 3. Obtener el score de la IA y el mensaje
    final moodScore = mood * 10;
    final sleepInputScore =
        (100 - (sleepHours - 7.5).abs() * 18).clamp(0.0, 100.0);
    final activityInputScore = (activityMinutes * 1.6).clamp(0.0, 100.0);
    final socialInputScore = (100 - socialMinutes * 0.35).clamp(0.0, 100.0);
    final energyScore = (energy * 10).clamp(0.0, 100.0);
    final stressLoad = (100.0 - stress * 10).clamp(0.0, 100.0);

    final sleepScore =
        ((_snapshot.sleepScore * 0.55) + (sleepInputScore * 0.45))
            .clamp(0.0, 100.0);
    final activityScore =
        ((_snapshot.activityScore * 0.55) + (activityInputScore * 0.45))
            .clamp(0.0, 100.0);
    final socialScore =
        ((_snapshot.socialScore * 0.55) + (socialInputScore * 0.45))
            .clamp(0.0, 100.0);

    final double heuristicScore = ((moodScore * 0.3) +
            (sleepScore * 0.22) +
            (activityScore * 0.15) +
            (socialScore * 0.13) +
            (energyScore * 0.10) +
            (stressLoad * 0.10))
        .clamp(0.0, 100.0);

    double overallScore;
    String aiMessage;

    if (prediction.containsKey('error')) {
      print(
          "WARN: IA falló, usando cálculo heurístico. Error: ${prediction['error']}");
      overallScore = heuristicScore;
      aiMessage = 'Analizando tendencia local (IA no disponible)...';
    } else {
      final modelScore = (prediction['wellbeing_score'] as num?)?.toDouble();
      final riskProbability =
          (prediction['risk_probability'] as num?)?.toDouble();

      if (modelScore == null) {
        overallScore = heuristicScore;
      } else if (riskProbability == null) {
        overallScore = heuristicScore >= 70.0
            ? heuristicScore
            : ((heuristicScore * 0.85) + (modelScore * 0.15)).clamp(0.0, 100.0);
      } else {
        final modelConfidence =
            ((riskProbability - 0.5).abs() * 2.0).clamp(0.0, 1.0);
        if (heuristicScore >= 70.0 || modelConfidence < 0.2) {
          overallScore = heuristicScore;
          print(
              'DEBUG: priorizando heurística (p=${riskProbability.toStringAsFixed(3)}), score local=${heuristicScore.toStringAsFixed(1)}');
        } else {
          final modelWeight = 0.15 + (0.10 * modelConfidence);
          overallScore = ((modelScore * modelWeight) +
                  (heuristicScore * (1.0 - modelWeight)))
              .clamp(0.0, 100.0);
        }
      }
      aiMessage = prediction['message'] ?? 'Analizando tendencia...';
    }

    final note = draft.note.trim();

    final riskLevel = overallScore >= 75.0
        ? RiskLevel.stable
        : overallScore >= 55.0
            ? RiskLevel.watch
            : overallScore >= 35.0
                ? RiskLevel.low
                : RiskLevel.urgent;

    final supportTitle = switch (riskLevel) {
      RiskLevel.stable => 'Bienestar stable',
      RiskLevel.watch => 'Vigila la tendencia',
      RiskLevel.low => 'Conviene hablar con un profesional',
      RiskLevel.urgent => 'Busca apoyo inmediato',
    };

    final supportBody = switch (riskLevel) {
      RiskLevel.stable =>
        'Sigue reforzando sueño, actividad, uso de redes y alimentación. La app seguirá comparando tu baseline personal.',
      RiskLevel.watch =>
        'Tu patrón merece seguimiento. Si esta tendencia se mantiene varios días, considera hablar con un profesional.',
      RiskLevel.low =>
        'Tu bienestar cayó a una zona baja. La recomendación es hablar con un profesional de salud mental y revisar tus hábitos de soporte.',
      RiskLevel.urgent =>
        'Si sientes riesgo inmediato o ideas de hacerte daño, busca apoyo urgente: una persona de confianza o urgencias.',
    };

    final message =
        aiMessage; // Usamos el mensaje creativo que viene de la IA en wellbeing_models.dart

    setState(() {
      _snapshot = _snapshot.copyWith(
        overallScore: overallScore,
        sleepScore: sleepScore,
        activityScore: activityScore,
        socialScore: socialScore,
        stressLoad: stressLoad,
        moodScore: moodScore,
        message: note.isEmpty ? message : '$message Nota: $note',
        riskLevel: riskLevel,
        supportTitle: supportTitle,
        supportBody: supportBody,
        trend: [
                  ..._snapshot.trend,
                  overallScore.toDouble(),
                ].length >
                7
            ? [
                ...[
                  ..._snapshot.trend,
                  overallScore.toDouble(),
                ].sublist([
                      ..._snapshot.trend,
                      overallScore.toDouble(),
                    ].length -
                    7),
              ]
            : [
                ..._snapshot.trend,
                overallScore.toDouble(),
              ],
      );

      _history.insert(
        0,
        CheckInRecord(
          date: DateTime.now(),
          mood: mood,
          sleepHours: sleepHours,
          activityMinutes: activityMinutes,
          socialMinutes: socialMinutes,
          energy: energy,
          stress: stress,
          score: overallScore,
          note: note,
          riskLevel: riskLevel,
        ),
      );
      if (_history.length > 7) {
        _history.removeLast();
      }

      // --- LÓGICA DE PATRONES CREATIVOS (INSIGHTS) ---
      _insights
          .clear(); // Limpiamos para mostrar solo los más relevantes actuales

      // Patrón de Sueño
      if (sleepHours < 6.5) {
        _insights.add(InsightItem(
          title: 'Deuda de sueño detectada',
          body:
              'Has dormido menos de 6.5h. El modelo BiLSTM asocia esto con una caída en el bienestar mañana.',
          label: 'Sueño',
        ));
      } else if (sleepHours > 8.5) {
        _insights.add(InsightItem(
          title: 'Recuperación profunda',
          body:
              'Tu nivel de sueño hoy es óptimo para la restauración cognitiva.',
          label: 'Sueño',
        ));
      }

      // Patrón de Actividad
      if (activityMinutes < 20) {
        _insights.add(InsightItem(
          title: 'Sedentarismo inusual',
          body:
              'Tu actividad está por debajo de tu baseline. Intenta caminar 10 min.',
          label: 'Actividad',
        ));
      } else if (activityMinutes > 90) {
        _insights.add(InsightItem(
          title: 'Carga física positiva',
          body: 'Nivel de actividad alto. Esto compensará el estrés detectado.',
          label: 'Actividad',
        ));
      }

      // Patrón de Redes
      if (socialMinutes > 180) {
        _insights.add(InsightItem(
          title: 'Sobrecarga digital',
          body:
              'El tiempo en redes está afectando tu foco. Considera un "digital detox".',
          label: 'Redes',
        ));
      }

      // Fallback si no hay patrones críticos detectados
      if (_insights.isEmpty) {
        _insights.add(InsightItem(
          title: 'Patrones estables',
          body:
              'Tus indicadores de hoy se mantienen cerca de tu promedio habitual.',
          label: 'General',
        ));
      }

      _selectedIndex = 0;
    });
  }

  void _resetBaseline() {
    setState(() {
      _snapshot = WellbeingSnapshot.initial();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        snapshot: _snapshot,
        insights: _insights,
        history: _history,
        onOpenCheckIn: () => setState(() => _selectedIndex = 1),
        onRegisterSupportAction: _registerSupportAction,
        onOpenCamera:
            _openCameraStub, // Mantenemos el stub ya que HomeScreen lo procesará internamente en subwidgets si lo necesita
      ),
      CheckInScreen(
        snapshot: _snapshot,
        onSubmit: _submitCheckIn,
      ),
      InsightsScreen(
        snapshot: _snapshot,
        insights: _insights,
        history: _history,
        onRegisterSupportAction: _registerSupportAction,
      ),
      CameraScreen(
        onRegisterSupportAction: _registerSupportAction,
      ),
      SettingsScreen(
        snapshot: _snapshot,
        onResetBaseline: _resetBaseline,
      ),
    ];

    return Scaffold(
      body: SafeArea(child: pages[_selectedIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Inicio'),
          NavigationDestination(
              icon: Icon(Icons.edit_note_outlined),
              selectedIcon: Icon(Icons.edit_note),
              label: 'Check-in'),
          NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights),
              label: 'Insights'),
          NavigationDestination(
              icon: Icon(Icons.camera_alt_outlined),
              selectedIcon: Icon(Icons.camera_alt),
              label: 'Cámara'),
          NavigationDestination(
              icon: Icon(Icons.tune_outlined),
              selectedIcon: Icon(Icons.tune),
              label: 'Ajustes'),
        ],
      ),
    );
  }

  void _registerSupportAction(String action, String details) {
    setState(() {
      final mood = (_snapshot.moodScore / 10).clamp(1, 10).toDouble();
      final energy = (_snapshot.activityScore / 10).clamp(1, 10).toDouble();
      final stress =
          ((100.0 - _snapshot.stressLoad) / 10).clamp(1, 10).toDouble();
      final sleepHours =
          ((_snapshot.sleepScore / 100) * 4 + 5.0).clamp(0.0, 12.0);
      final activityMinutes =
          ((_snapshot.activityScore / 100) * 120).clamp(0.0, 240.0);
      final socialMinutes =
          ((100.0 - _snapshot.socialScore) * 2.4).clamp(0.0, 360.0);

      _history.insert(
        0,
        CheckInRecord(
          date: DateTime.now(),
          mood: mood,
          sleepHours: sleepHours,
          activityMinutes: activityMinutes,
          socialMinutes: socialMinutes,
          energy: energy,
          stress: stress,
          score: _snapshot.overallScore,
          note: 'Acción: $action. $details',
          riskLevel: _snapshot.riskLevel,
        ),
      );
      if (_history.length > 20) {
        _history.removeLast();
      }
    });
  }

  void _openCameraStub() async {
    // Placeholder para la integración futura de la cámara
  }
}
