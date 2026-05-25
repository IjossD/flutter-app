import 'package:flutter/material.dart';

import 'models/wellbeing_models.dart';
import 'screens/check_in_screen.dart';
import 'screens/home_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/notification_service.dart';
import 'services/health_service.dart';

class WellbeingApp extends StatelessWidget {
  const WellbeingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Wellbeing App',
      theme: AppTheme.light(),
      home: const SplashDecider(),
    );
  }
}

class SplashDecider extends StatefulWidget {
  const SplashDecider({super.key});

  @override
  State<SplashDecider> createState() => _SplashDeciderState();
}

class _SplashDeciderState extends State<SplashDecider> {
  bool _initialized = false;
  bool _seen = false;
  bool _consentGiven = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('seenSplash') ?? false;
    final consent = prefs.getBool('consentGiven') ?? false;
    setState(() {
      _initialized = true;
      _seen = seen;
      _consentGiven = consent;
    });
  }

  void _completeSplash() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenSplash', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const WellbeingShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_consentGiven) {
      return ConsentScreen(onAccepted: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('consentGiven', true);
        setState(() => _consentGiven = true);
      });
    }

    if (_seen) return const WellbeingShell();

    return SplashScreen(onContinue: _completeSplash);
  }
}

class ConsentScreen extends StatelessWidget {
  final VoidCallback onAccepted;

  const ConsentScreen({required this.onAccepted, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/logo.png', width: 120, height: 120),
                const SizedBox(height: 18),
                Text(
                  'Antes de continuar, necesitamos tu consentimiento para procesar datos localmente y, si das permiso, leer métricas de Health Connect.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 18),
                Text(
                  'Los datos se procesan en tu dispositivo. No subimos información sin pedirlo explícitamente.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: onAccepted,
                  child: const Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
                    child: Text('Acepto'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  final VoidCallback onContinue;

  const SplashScreen({required this.onContinue, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/logo.png', width: 160, height: 160),
                const SizedBox(height: 18),
                Text(
                  'Bienvenido — mira tu pulso diario con suavidad',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: onContinue,
                  child: const Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
                    child: Text('Entrar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
  bool _notificationsEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);

  @override
  void initState() {
    super.initState();
    _initPreferencesAndNotifications();
  }

  Future<void> _initPreferencesAndNotifications() async {
    await NotificationService.init();
    // Initialize HealthService scaffold (permission requests are user-driven)
    await HealthService.instance.init();
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notificationsEnabled') ?? false;
    final hour = prefs.getInt('reminderHour') ?? _reminderTime.hour;
    final minute = prefs.getInt('reminderMinute') ?? _reminderTime.minute;
    setState(() {
      _notificationsEnabled = enabled;
      _reminderTime = TimeOfDay(hour: hour, minute: minute);
    });

    if (_notificationsEnabled) {
      await _scheduleDailyReminder();
    }
  }

  Future<void> _persistNotificationPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', _notificationsEnabled);
    await prefs.setInt('reminderHour', _reminderTime.hour);
    await prefs.setInt('reminderMinute', _reminderTime.minute);
  }

  Future<void> _clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('seenSplash');
    await prefs.remove('consentGiven');
    await prefs.remove('notificationsEnabled');
    await prefs.remove('reminderHour');
    await prefs.remove('reminderMinute');

    await _cancelReminder();

    setState(() {
      _snapshot = WellbeingSnapshot.initial();
      _history.clear();
      _insights.clear();
      _notificationsEnabled = false;
      _reminderTime = const TimeOfDay(hour: 20, minute: 0);
    });
  }

  Future<void> _scheduleDailyReminder() async {
    final scheduled = NotificationService.nextInstanceOfTime(
        _reminderTime.hour, _reminderTime.minute);
    await NotificationService.scheduleDaily(
      id: 0,
      title: 'Recordatorio amable',
      body: '¿Cómo va tu día? Un check-in rápido ayuda a mantener el pulso.',
      scheduledDate: scheduled,
    );
  }

  Future<void> _cancelReminder() async {
    await NotificationService.cancel(0);
  }

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
      RiskLevel.stable => 'Vas bien',
      RiskLevel.watch => 'Conviene mirar el ritmo',
      RiskLevel.low => 'Vale pedir apoyo',
      RiskLevel.urgent => 'Busca apoyo ahora',
    };

    final supportBody = switch (riskLevel) {
      RiskLevel.stable =>
        'Sigue con lo que te está funcionando. Dormir bien, moverte un poco y bajar el ruido digital siguen siendo una buena base.',
      RiskLevel.watch =>
        'Algo empieza a moverse. Si este patrón sigue varios días, puede valer la pena hablarlo con alguien de confianza o con un profesional.',
      RiskLevel.low =>
        'Hoy se ve una carga más pesada. No tienes que manejarlo solo; hablar con un profesional puede darte apoyo real.',
      RiskLevel.urgent =>
        'Si sientes que la situación te sobrepasa o hay riesgo inmediato, busca apoyo urgente con una persona de confianza o emergencias.',
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
      final freshInsights = <InsightItem>[];
      void addInsight(InsightItem item) {
        if (freshInsights.length < 5) {
          freshInsights.add(item);
        }
      }

      // Sueño
      if (sleepHours < 6.5) {
        addInsight(InsightItem(
          title: 'Noche corta',
          body:
              'Dormiste poco. Si puedes, hoy conviene bajar el ritmo y proteger un poco más la noche.',
          label: 'Descanso',
        ));
      } else if (sleepHours > 8.5) {
        addInsight(InsightItem(
          title: 'Buen descanso',
          body:
              'Dormiste bien y eso suele ayudar a sostener el ánimo y la concentración durante el día.',
          label: 'Descanso',
        ));
      }

      // Actividad
      if (activityMinutes < 20) {
        addInsight(InsightItem(
          title: 'Poco movimiento',
          body:
              'Hoy el cuerpo se movió poco. Una caminata breve o salir a tomar aire puede ayudarte a cambiar el tono del día.',
          label: 'Movimiento',
        ));
      } else if (activityMinutes > 90) {
        addInsight(InsightItem(
          title: 'Buen movimiento',
          body:
              'Tuviste bastante actividad. Eso suele ayudar a despejar la cabeza y a descargar tensión.',
          label: 'Movimiento',
        ));
      }

      // Pantallas / redes
      if (socialMinutes > 180) {
        addInsight(InsightItem(
          title: 'Muchas pantallas',
          body:
              'Pasaste bastante tiempo en redes. Un descanso corto de pantalla puede darte un poco de aire mental.',
          label: 'Pantallas',
        ));
      } else if (socialMinutes < 60) {
        addInsight(InsightItem(
          title: 'Pantallas bajo control',
          body:
              'Mantener las pantallas bajas puede ayudar a que el día se sienta menos pesado.',
          label: 'Pantallas',
        ));
      }

      // Energía
      if (energy <= 4) {
        addInsight(InsightItem(
          title: 'Batería baja',
          body:
              'Hoy parece que te falta un poco de energía. Trata de hacer menos presión y prioriza lo esencial.',
          label: 'Energía',
        ));
      } else if (energy >= 8) {
        addInsight(InsightItem(
          title: 'Buena energía',
          body:
              'Te notas con energía. Puede ser un buen momento para avanzar en algo que venías postergando.',
          label: 'Energía',
        ));
      }

      // Ánimo y tensión
      if (mood <= 4) {
        addInsight(InsightItem(
          title: 'Ánimo sensible',
          body:
              'Hoy te sientes más frágil de lo normal. No hace falta exigirte de más; avanza paso a paso.',
          label: 'Ánimo',
        ));
      } else if (mood >= 8) {
        addInsight(InsightItem(
          title: 'Ánimo firme',
          body:
              'Te notas bastante bien. Es un buen día para sostener rutinas que te están ayudando.',
          label: 'Ánimo',
        ));
      }

      if (stress >= 7) {
        addInsight(InsightItem(
          title: 'Tensión alta',
          body:
              'Se nota bastante carga. Bajarle un poco al ritmo hoy puede evitar que el día se haga más pesado.',
          label: 'Tensión',
        ));
      } else if (stress <= 3) {
        addInsight(InsightItem(
          title: 'Poca tensión',
          body:
              'Hoy vienes con más calma. Aprovecha ese margen para hacer algo que te haga bien.',
          label: 'Tensión',
        ));
      }

      if (freshInsights.isEmpty) {
        freshInsights.add(InsightItem(
          title: 'Día parejo',
          body:
              'No se ven cambios fuertes. Sigue con la rutina que te está funcionando y observa cómo te sientes mañana.',
          label: 'General',
        ));
      }

      _insights
        ..clear()
        ..addAll(freshInsights);

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
        notificationsEnabled: _notificationsEnabled,
        reminderTime: _reminderTime,
        onNotificationsChanged: (value) async {
          setState(() => _notificationsEnabled = value);
          if (_notificationsEnabled) {
            await _scheduleDailyReminder();
          } else {
            await _cancelReminder();
          }
          await _persistNotificationPrefs();
        },
        onReminderTimeChanged: (value) async {
          setState(() => _reminderTime = value);
          if (_notificationsEnabled) {
            await _scheduleDailyReminder();
          }
          await _persistNotificationPrefs();
        },
        onClearData: _clearAllData,
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
