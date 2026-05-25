import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:onnxruntime/onnxruntime.dart';

// ============================================================================
// 1. MOTOR DE INFERENCIA DE INTELIGENCIA ARTIFICIAL (ONNX)
// ============================================================================
class WellbeingInferenceService {
  OrtSession? _session;
  bool _isModelLoaded = false;

  bool get isModelLoaded => _isModelLoaded;

  /// Inicializa el modelo leyendo los bytes directamente de forma estable
  Future<void> initModel() async {
    if (_isModelLoaded) return;

    try {
      // Leer el archivo .onnx directamente desde los assets como bytes nativos
      final modelBytes = await rootBundle.load('assets/models/bilstm_wellbeing.onnx');
      final Uint8List rawBytes = modelBytes.buffer.asUint8List();

      // Crear la sesión directamente desde el buffer de memoria
      _session = OrtSession.fromBuffer(rawBytes, OrtSessionOptions());

      _isModelLoaded = true;
      print("[OK] Modelo BiLSTM inicializado con éxito desde la memoria RAM.");
    } catch (e) {
      print("[ERROR] Error al inicializar el modelo ONNX: $e");
    }
  }

  /// Ejecuta la inferencia pasando la matriz secuencial de datos [1, 30, 34]
  Future<Map<String, dynamic>> predictWellbeing(List<List<List<double>>> inputSequence) async {
    if (!_isModelLoaded || _session == null) {
      throw Exception("El modelo de predicción no ha sido inicializado correctamente.");
    }

    try {
      final shape = [1, 30, 34];
      final flattenedInput = inputSequence.expand((e) => e.expand((x) => x)).toList();
      final inputBuffer = Float32List.fromList(flattenedInput);

      final inputTensor = OrtValueTensor.createTensorWithDataList(inputBuffer, shape);
      final inputs = {'sequence': inputTensor};

      final runOptions = OrtRunOptions();
      final outputs = _session!.run(runOptions, inputs);
      inputTensor.release();

      final outputValue = outputs[0]?.value;
      if (outputValue == null) return {'error': 'No se obtuvo respuesta del modelo'};

      final List<List<double>> outputData = outputValue as List<List<double>>;
      final double riskProbability = outputData[0][0];

      final double baseScore = (1.0 - riskProbability) * 100;
      final double score = baseScore.clamp(0.0, 100.0);

      String riskLevel;
      String message;
      if (score >= 75) {
        riskLevel = 'stable';
        message = 'Tus patrones muestran un buen ritmo esta semana';
      } else if (score >= 55) {
        riskLevel = 'attention';
        message = 'Hay algunas variaciones en tus patrones recientes';
      } else if (score >= 35) {
        riskLevel = 'elevated_attention';
        message = 'Hemos notado cambios en varios de tus indicadores';
      } else {
        riskLevel = 'significant_change';
        message = 'Tus patrones han cambiado bastante respecto a tu habitual';
      }

      return {
        'wellbeing_score': double.parse(score.toStringAsFixed(1)),
        'risk_level': riskLevel,
        'message': message,
        'risk_probability': riskProbability,
      };
    } catch (e) {
      print("[ERROR] Error durante la inferencia: $e");
      return {'error': e.toString()};
    }
  }

  void dispose() {
    _session?.release();
    _isModelLoaded = false;
  }
}

// ============================================================================
// 2. ENUMS Y MODELOS DE DATOS REQUERIDOS POR TU INTERFAZ (UI)
// ============================================================================

enum RiskLevel { stable, watch, low, urgent }

class InsightItem {
  final String title;
  final String body;
  final String label;

  InsightItem({
    required this.title,
    required this.body,
    required this.label,
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

  CheckInRecord({
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

class CheckInDraft {
  final double mood;
  final double sleepHours;
  final double activityMinutes;
  final double socialMinutes;
  final double energy;
  final double stress;
  final String note;

  CheckInDraft({
    required this.mood,
    required this.sleepHours,
    required this.activityMinutes,
    required this.socialMinutes,
    required this.energy,
    required this.stress,
    required this.note,
  });
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

  WellbeingSnapshot({
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
    return WellbeingSnapshot(
      overallScore: 72.0,
      sleepScore: 75.0,
      activityScore: 68.0,
      socialScore: 80.0,
      stressLoad: 35.0,
      moodScore: 70.0,
      message: 'Inicializando baseline personal de bienestar...',
      riskLevel: RiskLevel.stable,
      supportTitle: 'Bienestar stable',
      supportBody: 'Tus métricas base están listas. El modelo monitorea desvíos analizando tus secuencias temporales.',
      trend: [70.0, 68.0, 71.0, 74.0, 70.0, 69.0, 72.0],
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