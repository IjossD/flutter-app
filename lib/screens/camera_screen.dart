import 'dart:io';

import 'package:flutter/material.dart';

import '../utils/image_actions.dart';

class CameraScreen extends StatefulWidget {
  final void Function(String action, String details) onRegisterSupportAction;

  const CameraScreen({required this.onRegisterSupportAction, super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  File? _imageFile;
  String? _prediction;
  double? _confidence;

  Future<void> _takePhoto() async {
    final xfile = await ImageActions.pickFromCamera();
    if (xfile == null) return;
    final saved = await ImageActions.saveToAppDir(xfile);
    if (saved == null) return;
    setState(() {
      _imageFile = saved;
      _prediction = null;
      _confidence = null;
    });
    final res = await ImageActions.mockUpload(saved);
    setState(() {
      _prediction = res['prediction'] as String?;
      _confidence = (res['confidence'] as double?) ?? 0.0;
    });
    widget.onRegisterSupportAction(
        'camera_photo', 'Foto tomada y subida mock: ${_prediction ?? 'n/d'}');
  }

  Future<void> _importPhoto() async {
    final xfile = await ImageActions.pickFromGallery();
    if (xfile == null) return;
    final saved = await ImageActions.saveToAppDir(xfile);
    if (saved == null) return;
    setState(() {
      _imageFile = saved;
      _prediction = null;
      _confidence = null;
    });
    final res = await ImageActions.mockUpload(saved);
    setState(() {
      _prediction = res['prediction'] as String?;
      _confidence = (res['confidence'] as double?) ?? 0.0;
    });
    widget.onRegisterSupportAction('import_photo',
        'Foto importada y subida mock: ${_prediction ?? 'n/d'}');
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
          if (_prediction != null) ...[
            Text('Estimación automática',
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
                  Text('Proteínas: $_prediction',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                      'Confianza: ${(_confidence ?? 0 * 100).toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 10),
                  Text('Recomendaciones:',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 6),
                  Text(
                      '• Añade una porción de legumbres o una fuente de proteína magra si la estimación es baja.',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  Text(
                      '• Prioriza comidas con proteína en el desayuno para mantener energía.',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
