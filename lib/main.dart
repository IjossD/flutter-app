import 'package:flutter/material.dart';
import 'package:wellbeing_app/models/wellbeing_models.dart';
import 'app.dart';

// Instancia global del servicio de inferencia
final WellbeingInferenceService wellbeingInference = WellbeingInferenceService();

void main() async {
  // Asegura que los canales nativos de Flutter estén listos antes de cargar el modelo
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar el modelo ONNX de forma segura desde la memoria
  await wellbeingInference.initModel();

  // NOTA: Si 'WellbeingApp' te sigue saliendo en rojo, cámbialo por 'App' o 'MyApp'
  // dependiendo de cómo se llame la clase principal dentro de tu archivo app.dart
  runApp(const WellbeingApp());
}