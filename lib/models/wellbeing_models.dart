import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:onnxruntime_v2/onnxruntime_v2.dart';
import 'package:image/image.dart' as img;

// Instancias globales
final WellbeingInferenceService wellbeingInference =
    WellbeingInferenceService();
final NutritionInferenceService nutritionInference =
    NutritionInferenceService();

// ============================================================================
// 1. MOTOR DE INFERENCIA DE INTELIGENCIA ARTIFICIAL (ONNX)
// ============================================================================
class WellbeingInferenceService {
  OrtSession? _session;
  bool _isModelLoaded = false;

  bool get isModelLoaded => _isModelLoaded;

  /// Inicializa el modelo copiando los archivos a disco local para soportar external data (.data)
  Future<void> initModel() async {
    if (_isModelLoaded) return;

    try {
      final docDir = await getApplicationDocumentsDirectory();

      // 1. Copiar el archivo .onnx
      final modelPath = '${docDir.path}/bilstm_wellbeing.onnx';
      final modelFile = File(modelPath);
      final modelData =
          await rootBundle.load('assets/models/bilstm_wellbeing.onnx');
      await modelFile.writeAsBytes(modelData.buffer.asUint8List());

      // 2. Copiar el archivo .onnx.data (REQUERIDO para modelos grandes)
      final dataPath = '${docDir.path}/bilstm_wellbeing.onnx.data';
      final dataFile = File(dataPath);
      final externalData =
          await rootBundle.load('assets/models/bilstm_wellbeing.onnx.data');
      await dataFile.writeAsBytes(externalData.buffer.asUint8List());

      // Crear la sesión desde el archivo físico para que ONNX encuentre el .data automáticamente
      _session = OrtSession.fromFile(modelFile, OrtSessionOptions());

      _isModelLoaded = true;
      print('[OK] Modelo BiLSTM inicializado con éxito desde disco local.');
    } catch (e) {
      print('[ERROR] Error al inicializar el modelo ONNX: $e');
    }
  }

  /// Ejecuta la inferencia pasando la matriz secuencial de datos [1, 30, 34]
  Future<Map<String, dynamic>> predictWellbeing(
      List<List<List<double>>> inputSequence) async {
    if (!_isModelLoaded || _session == null) {
      return {'error': 'Modelo de bienestar no cargado'};
    }

    try {
      final shape = [1, 30, 34];
      final flattenedInput =
          inputSequence.expand((e) => e.expand((x) => x)).toList();
      final inputBuffer = Float32List.fromList(flattenedInput);

      final values = inputBuffer;
      final mean =
          values.isEmpty ? 0.0 : values.reduce((a, b) => a + b) / values.length;
      final minValue =
          values.isEmpty ? 0.0 : values.reduce((a, b) => a < b ? a : b);
      final maxValue =
          values.isEmpty ? 0.0 : values.reduce((a, b) => a > b ? a : b);
      print(
          'DEBUG: input stats => len=${values.length}, mean=${mean.toStringAsFixed(4)}, min=${minValue.toStringAsFixed(4)}, max=${maxValue.toStringAsFixed(4)}');
      if (inputSequence.isNotEmpty) {
        final firstStep = inputSequence.first.isNotEmpty
            ? inputSequence.first.first
            : const <double>[];
        print('DEBUG: first step sample => ${firstStep.take(12).toList()}');
      }

      print('DEBUG: inputNames = ${_session!.inputNames}');
      print('DEBUG: outputNames = ${_session!.outputNames}');

      // Detectar el nombre de la entrada dinámicamente
      final inputName = _session!.inputNames.first;
      final inputTensor =
          OrtValueTensor.createTensorWithDataList(inputBuffer, shape);
      final inputs = {inputName: inputTensor};

      final runOptions = OrtRunOptions();
      final outputs = _session!.run(runOptions, inputs);
      inputTensor.release();

      if (outputs.isEmpty || outputs[0] == null) {
        return {'error': 'No se obtuvo respuesta del modelo'};
      }

      final outputValue = outputs[0]?.value;
      print('DEBUG: outputValue type = ${outputValue.runtimeType}');

      double riskProbability = 0.0;

      // Manejo ultra-seguro de diferentes formatos de salida de ONNX
      try {
        if (outputValue is List) {
          var firstElement = outputValue[0];
          if (firstElement is List) {
            // Caso [[0.123]] (2D)
            riskProbability = (firstElement[0] as num).toDouble();
          } else if (firstElement is num) {
            // Caso [0.123] (1D)
            riskProbability = firstElement.toDouble();
          }
        } else if (outputValue is Float32List) {
          riskProbability = outputValue[0];
        }
      } catch (e) {
        print('Error al decodificar salida: $e');
        return {'error': 'Error al decodificar salida: $e'};
      }

      // El modelo devuelve Riesgo (0=Excelente, 1=Peligro)
      final double score = ((1.0 - riskProbability) * 100).clamp(0.0, 100.0);

      String riskLevel;
      String message;

      if (score >= 70) {
        riskLevel = 'stable';
        message = [
          'Vas con buen ritmo hoy. Se nota bastante equilibrio en cómo vienes.',
          'Tu día se ve bien armado. Sigue cuidando lo que ya te está funcionando.',
          'Hoy tus hábitos están bastante de tu lado. Buen trabajo sosteniendo eso.'
        ][Random().nextInt(3)];
      } else if (score >= 45) {
        riskLevel = 'attention';
        message = [
          'Hoy hay algunos cambios pequeños. No es grave, pero conviene darte un poco de margen.',
          'Se nota un día algo movido. Un descanso corto puede ayudarte a recomponerte.',
          'Hay señales suaves de cansancio o tensión. Bajar un poco el ritmo puede venir bien.'
        ][Random().nextInt(3)];
      } else if (score >= 25) {
        riskLevel = 'elevated_attention';
        message = [
          'Hoy la carga se nota bastante. Vale la pena ir más despacio y pedir apoyo si hace falta.',
          'Parece un día pesado. No tienes que empujarte de más; ve paso a paso.',
          'Tu energía y tu ánimo están pidiendo más cuidado. Tomar aire y parar un poco puede ayudar.'
        ][Random().nextInt(3)];
      } else {
        riskLevel = 'significant_change';
        message = [
          'Se ve un bajón importante. No lo cargues solo; busca apoyo cuanto antes.',
          'Hoy estás en una zona delicada. Hablar con alguien de confianza puede hacer diferencia.',
          'El día se ve bastante cuesta arriba. Si te sientes sobrepasado, busca ayuda ahora.'
        ][Random().nextInt(3)];
      }

      return {
        'wellbeing_score': double.parse(score.toStringAsFixed(1)),
        'risk_level': riskLevel,
        'message': message,
        'risk_probability': riskProbability,
      };
    } catch (e) {
      print('[ERROR] Error durante la inferencia: $e');
      return {'error': e.toString()};
    }
  }

  void dispose() {
    _session?.release();
    _isModelLoaded = false;
  }
}

class NutritionInferenceService {
  OrtSession? _session;
  bool _isModelLoaded = false;

  bool get isModelLoaded => _isModelLoaded;

  Future<void> initModel() async {
    if (_isModelLoaded) return;
    try {
      final modelBytes =
          await rootBundle.load('assets/models/nutrition_model.onnx');
      final Uint8List rawBytes = modelBytes.buffer.asUint8List();
      _session = OrtSession.fromBuffer(rawBytes, OrtSessionOptions());
      _isModelLoaded = true;
      print('[OK] Modelo de Nutrición inicializado con éxito.');
    } catch (e) {
      print('[ERROR] Error al inicializar el modelo de Nutrición: $e');
    }
  }

  Future<Map<String, dynamic>> predictNutrition(File imageFile) async {
    if (!_isModelLoaded || _session == null) {
      return {'error': 'Modelo de nutrición no cargado'};
    }

    try {
      // 1. Preprocesamiento de la imagen
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) {
        return {'error': 'No se pudo decodificar la imagen'};
      }

      // Redimensionar a 224x224
      final img.Image resizedImage =
          img.copyResize(originalImage, width: 224, height: 224);

      // Normalización: (pixel/255 - mean) / std
      // mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]
      final Float32List inputBuffer = Float32List(1 * 3 * 224 * 224);

      const means = [0.485, 0.456, 0.406];
      const stds = [0.229, 0.224, 0.225];

      // PyTorch usa orden NCHW (Canal primero)
      for (int y = 0; y < 224; y++) {
        for (int x = 0; x < 224; x++) {
          final pixel = resizedImage.getPixel(x, y);

          // Extraer componentes R, G, B y normalizar
          // Nota: getPixel en la v4 de 'image' devuelve un objeto Pixel
          inputBuffer[0 * 224 * 224 + y * 224 + x] =
              ((pixel.r / 255.0) - means[0]) / stds[0];
          inputBuffer[1 * 224 * 224 + y * 224 + x] =
              ((pixel.g / 255.0) - means[1]) / stds[1];
          inputBuffer[2 * 224 * 224 + y * 224 + x] =
              ((pixel.b / 255.0) - means[2]) / stds[2];
        }
      }

      final shape = [1, 3, 224, 224];
      final inputName = _session!.inputNames.first;
      final inputTensor =
          OrtValueTensor.createTensorWithDataList(inputBuffer, shape);
      final inputs = {inputName: inputTensor};

      final runOptions = OrtRunOptions();
      final outputs = _session!.run(runOptions, inputs);
      inputTensor.release();

      if (outputs.isEmpty || outputs[0] == null) {
        return {'error': 'Sin respuesta del modelo'};
      }

      final outputValue = outputs[0]!.value;
      List<double> results = [];

      // Manejo ultra-seguro de diferentes formatos de salida de ONNX
      if (outputValue is List) {
        var firstElement = outputValue[0];
        if (firstElement is List) {
          // Caso [[cal, fat, carb, prot]]
          results = firstElement.map((e) => (e as num).toDouble()).toList();
        } else if (firstElement is num) {
          // Caso [cal, fat, carb, prot]
          results = outputValue.map((e) => (e as num).toDouble()).toList();
        }
      } else if (outputValue is Float32List) {
        results = outputValue.toList();
      }

      if (results.length < 4) {
        return {
          'error':
              'El modelo devolvió menos de 4 valores (recibidos: ${results.length})'
        };
      }

      // 2. Postprocesamiento (Desnormalización)
      // [0] calorías  → * 387.3885 + 197.8238
      // [1] grasa (g) → * 33.1099  + 10.4556
      // [2] carbos (g)→ * 35.0561  + 15.6311
      // [3] proteína  → * 17.1404  + 12.8807

      final calories = results[0] * 387.3885 + 197.8238;
      final fat = results[1] * 33.1099 + 10.4556;
      final carbs = results[2] * 35.0561 + 15.6311;
      final protein = results[3] * 17.1404 + 12.8807;

      return {
        'calories': max(0.0, calories),
        'fat': max(0.0, fat),
        'carbs': max(0.0, carbs),
        'protein': max(0.0, protein),
      };
    } catch (e) {
      print('[ERROR] Error en inferencia de nutrición: $e');
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
      overallScore: 0.0,
      sleepScore: 0.0,
      activityScore: 0.0,
      socialScore: 0.0,
      stressLoad: 0.0,
      moodScore: 0.0,
      message:
          'Aún no hay registros. Haz tu primer check-in para empezar a ver tu propio patrón.',
      riskLevel: RiskLevel.stable,
      supportTitle: 'Todavía no hay datos',
      supportBody:
          'Cuando guardes tu primer check-in, la app empezará a leer tu ritmo personal.',
      trend: const [],
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
