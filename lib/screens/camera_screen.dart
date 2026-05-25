import 'dart:io';

import 'package:flutter/material.dart';

import '../utils/image_actions.dart';
import '../models/wellbeing_models.dart'; // Para acceder a nutritionInference

class CameraScreen extends StatefulWidget {
  final void Function(String action, String details) onRegisterSupportAction;

  const CameraScreen({required this.onRegisterSupportAction, super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  File? _imageFile;
  Map<String, dynamic>? _nutritionData;

  Future<void> _takePhoto() async {
    final xfile = await ImageActions.pickFromCamera();
    if (xfile == null) return;
    final saved = await ImageActions.saveToAppDir(xfile);
    if (saved == null) return;
    setState(() {
      _imageFile = saved;
      _nutritionData = null;
    });
    
    // Inferencia real usando el modelo ONNX
    final res = await nutritionInference.predictNutrition(saved);
    
    setState(() {
      _nutritionData = res;
    });
    
    final protein = res['protein']?.toStringAsFixed(1) ?? 'n/d';
    widget.onRegisterSupportAction(
        'camera_photo', 'Foto analizada. Proteína estimada: $protein g');
  }

  Future<void> _importPhoto() async {
    final xfile = await ImageActions.pickFromGallery();
    if (xfile == null) return;
    final saved = await ImageActions.saveToAppDir(xfile);
    if (saved == null) return;
    setState(() {
      _imageFile = saved;
      _nutritionData = null;
    });
    
    // Inferencia real usando el modelo ONNX
    final res = await nutritionInference.predictNutrition(saved);

    setState(() {
      _nutritionData = res;
    });
    
    final protein = res['protein']?.toStringAsFixed(1) ?? 'n/d';
    widget.onRegisterSupportAction('import_photo',
        'Foto importada y analizada. Proteína estimada: $protein g');
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cámara', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
              'Toma o importa una foto de tu comida. Aquí aparecerán estimaciones de proteínas y recomendaciones.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(height: 1.4)),
          const SizedBox(height: 18),
          Center(
            child: _imageFile == null
                ? Container(
                    width: 220,
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.camera_alt_outlined,
                        size: 48, color: Colors.grey),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_imageFile!,
                        width: 260, height: 180, fit: BoxFit.cover),
                  ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              FilledButton.icon(
                  onPressed: _takePhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Tomar foto')),
              OutlinedButton.icon(
                  onPressed: _importPhoto,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Importar')),
            ],
          ),
          const SizedBox(height: 18),
          if (_nutritionData != null && _nutritionData!['error'] == null) ...[
            Text('Análisis nutricional (IA)',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _NutritionRow(label: 'Calorías', value: '${_nutritionData!['calories'].toStringAsFixed(0)} kcal', icon: Icons.local_fire_department, color: Colors.orange),
                  const Divider(height: 20),
                  _NutritionRow(label: 'Proteínas', value: '${_nutritionData!['protein'].toStringAsFixed(1)} g', icon: Icons.fitness_center, color: Colors.blue),
                  const SizedBox(height: 8),
                  _NutritionRow(label: 'Carbohidratos', value: '${_nutritionData!['carbs'].toStringAsFixed(1)} g', icon: Icons.grain, color: Colors.green),
                  const SizedBox(height: 8),
                  _NutritionRow(label: 'Grasas', value: '${_nutritionData!['fat'].toStringAsFixed(1)} g', icon: Icons.opacity, color: Colors.red),
                  
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _nutritionData!['protein'] > 25 ? '💪' : (_nutritionData!['calories'] > 500 ? '🔋' : '🥗'),
                          style: const TextStyle(fontSize: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _nutritionData!['protein'] > 25 
                              ? '¡Menú de Atleta! Este plato es una bomba de aminoácidos.' 
                              : (_nutritionData!['calories'] > 500 
                                  ? 'Carga de energía completa para enfrentar el día.' 
                                  : 'Ligero y equilibrado, perfecto para mantener el ritmo.'),
                            style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Recomendación del Coach:',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 6),
                  Text(
                      _nutritionData!['protein'] < 15 
                        ? '• Tu comida parece baja en proteínas. Considera añadir legumbres, huevo o carne magra.'
                        : '• ¡Buen aporte de proteínas! Esto ayudará a mantener tu energía estable durante el día.',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ] else if (_nutritionData != null && _nutritionData!['error'] != null) ...[
            Text('Error en el análisis: ${_nutritionData!['error']}', 
                 style: const TextStyle(color: Colors.red)),
          ],
        ],
      ),
    );
  }
}

class _NutritionRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _NutritionRow({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
