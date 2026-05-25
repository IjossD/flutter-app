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
  final List<CheckInRecord> _history = _buildInitialHistory();
  final List<InsightItem> _insights = [
    InsightItem(
      title: 'Sueño estable con ligera mejora',
      body:
          'Tu descanso de los últimos días se mantiene por encima de tu baseline reciente.',
      label: 'Sueño',
    ),
    InsightItem(
      title: 'Actividad consistente',
      body:
          'La actividad diaria no cayó por debajo de tu rango normal y eso ayuda a sostener el score.',
      label: 'Actividad',
    ),
    InsightItem(
      title: 'Uso de redes contenido',
      body:
          'El tiempo en redes sigue dentro de un rango manejable y no está empujando el baseline hacia abajo.',
      label: 'Redes',
    ),
  ];

  static List<CheckInRecord> _buildInitialHistory() {
    final now = DateTime.now();
    return [
      CheckInRecord(
        date: now.subtract(const Duration(days: 3)),
        mood: 7,
        sleepHours: 7.5,
        activityMinutes: 52,
        socialMinutes: 110,
        energy: 6,
        stress: 4,
        score: 70,
        note: 'Sueño razonable y actividad constante.',
        riskLevel: RiskLevel.stable,
      ),
      CheckInRecord(
        date: now.subtract(const Duration(days: 2)),
        mood: 6,
        sleepHours: 6.4,
        activityMinutes: 34,
        socialMinutes: 185,
        energy: 6,
        stress: 5,
        score: 66,
        note: 'Más pantallas en la noche.',
        riskLevel: RiskLevel.watch,
      ),
      CheckInRecord(
        date: now.subtract(const Duration(days: 1)),
        mood: 7,
        sleepHours: 7.8,
        activityMinutes: 61,
        socialMinutes: 95,
        energy: 7,
        stress: 4,
        score: 73,
        note: 'Mejor recuperación del descanso.',
        riskLevel: RiskLevel.stable,
      ),
    ];
  }

  void _submitCheckIn(CheckInDraft draft) {
    final mood = draft.mood.clamp(1, 10).toDouble();
    final sleepHours = draft.sleepHours.clamp(0, 12).toDouble();
    final activityMinutes = draft.activityMinutes.clamp(0, 240).toDouble();
    final socialMinutes = draft.socialMinutes.clamp(0, 360).toDouble();
    final energy = draft.energy.clamp(1, 10).toDouble();
    final stress = draft.stress.clamp(1, 10).toDouble();

    final moodScore = mood * 10;
    final sleepInputScore =
        (100 - (sleepHours - 7.5).abs() * 18).clamp(0, 100).toDouble();
    final activityInputScore = (activityMinutes * 1.6).clamp(0, 100).toDouble();
    final socialInputScore =
        (100 - socialMinutes * 0.35).clamp(0, 100).toDouble();
    final sleepScore =
        ((_snapshot.sleepScore * 0.55) + (sleepInputScore * 0.45))
            .clamp(0, 100)
            .toDouble();
    final activityScore =
        ((_snapshot.activityScore * 0.55) + (activityInputScore * 0.45))
            .clamp(0, 100)
            .toDouble();
    final socialScore =
        ((_snapshot.socialScore * 0.55) + (socialInputScore * 0.45))
            .clamp(0, 100)
            .toDouble();
    final stressLoad = (100 - stress * 10).clamp(0, 100).toDouble();
    final overallScore = ((moodScore * 0.35) +
            (sleepScore * 0.25) +
            (activityScore * 0.2) +
            (socialScore * 0.15) +
            ((100 - stressLoad) * 0.05))
        .clamp(0, 100)
        .toDouble();

    final note = draft.note.trim();
    final habitSummary =
        'Sueño ${sleepHours.toStringAsFixed(1)} h, actividad ${activityMinutes.toStringAsFixed(0)} min y redes ${socialMinutes.toStringAsFixed(0)} min.';
    final riskLevel = overallScore >= 75
        ? RiskLevel.stable
        : overallScore >= 55
            ? RiskLevel.watch
            : overallScore >= 35
                ? RiskLevel.low
                : RiskLevel.urgent;

    final supportTitle = switch (riskLevel) {
      RiskLevel.stable => 'Bienestar estable',
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
        'Si sientes riesgo inmediato o ideas de hacerte daño, busca apoyo urgente: una persona de confianza, Línea 106 o urgencias.',
    };

    final message = mood >= 7
        ? 'Tu check-in sugiere un día bastante equilibrado. El baseline personal sigue apuntando a estabilidad.'
        : stress >= 7
            ? 'Hay algo de carga hoy. La app prioriza tu baseline personal para detectar desvíos sostenidos.'
            : 'Tu estado muestra variaciones leves, sin una ruptura clara del patrón normal.';

    setState(() {
      _snapshot = _snapshot.copyWith(
        overallScore: overallScore,
        sleepScore: sleepScore,
        activityScore: activityScore,
        socialScore: socialScore,
        stressLoad: stressLoad,
        moodScore: moodScore,
        message: note.isEmpty
            ? '$message $habitSummary'
            : '$message Nota guardada: $note. $habitSummary',
        riskLevel: riskLevel,
        supportTitle: supportTitle,
        supportBody: supportBody,
        trend: [..._snapshot.trend.sublist(1), overallScore]
            .map((value) => value.toDouble())
            .toList(),
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
      _insights.insert(
        0,
        InsightItem(
          title: 'Check-in actualizado',
          body:
              'Mood ${mood.toStringAsFixed(0)}/10, energía ${energy.toStringAsFixed(0)}/10 y estrés ${stress.toStringAsFixed(0)}/10. Se recalculó el score local.',
          label: 'Hoy',
        ),
      );
      if (_insights.length > 6) {
        _insights.removeLast();
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
        onOpenCamera: _openCameraStub,
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
          ((100 - _snapshot.stressLoad) / 10).clamp(1, 10).toDouble();
      final sleepHours =
          ((_snapshot.sleepScore / 100) * 4 + 5.0).clamp(0, 12).toDouble();
      final activityMinutes =
          ((_snapshot.activityScore / 100) * 120).clamp(0, 240).toDouble();
      final socialMinutes =
          ((100 - _snapshot.socialScore) * 2.4).clamp(0, 360).toDouble();
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
    // Placeholder: open camera via SupportActions in UI. Kept here for future wiring.
  }
}
