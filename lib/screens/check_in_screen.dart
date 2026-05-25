import 'package:flutter/material.dart';

import '../models/wellbeing_models.dart';
import '../theme/app_theme.dart';

class CheckInScreen extends StatefulWidget {
  final WellbeingSnapshot snapshot;
  final ValueChanged<CheckInDraft> onSubmit;

  const CheckInScreen({
    required this.snapshot,
    required this.onSubmit,
    super.key,
  });

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  double _mood = 7;
  double _sleepHours = 7.5;
  double _activityMinutes = 45;
  double _socialMinutes = 120;
  double _energy = 6;
  double _stress = 4;
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Check-in diario',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Toma unos segundos. Estos datos ayudan a comparar tu estado de hoy contra tu baseline personal.',
            style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 18),
          _SliderCard(
            title: 'Mood',
            subtitle: _moodLabel,
            value: _mood,
            min: 1,
            max: 10,
            divisions: 9,
            activeColor: AppTheme.sage,
            onChanged: (value) => setState(() => _mood = value),
          ),
          const SizedBox(height: 14),
          _SliderCard(
            title: 'Sueño',
            subtitle: _sleepLabel,
            value: _sleepHours,
            min: 0,
            max: 12,
            divisions: 24,
            activeColor: AppTheme.sage,
            onChanged: (value) => setState(() => _sleepHours = value),
          ),
          const SizedBox(height: 16),
          _SliderCard(
            title: 'Actividad diaria',
            subtitle: _activityLabel,
            value: _activityMinutes,
            min: 0,
            max: 240,
            divisions: 24,
            activeColor: AppTheme.amber,
            onChanged: (value) => setState(() => _activityMinutes = value),
          ),
          const SizedBox(height: 14),
          _SliderCard(
            title: 'Uso de redes',
            subtitle: _socialLabel,
            value: _socialMinutes,
            min: 0,
            max: 360,
            divisions: 36,
            activeColor: AppTheme.terracotta,
            onChanged: (value) => setState(() => _socialMinutes = value),
          ),
          const SizedBox(height: 14),
          _SliderCard(
            title: 'Energía',
            subtitle: _energyLabel,
            value: _energy,
            min: 1,
            max: 10,
            divisions: 9,
            activeColor: AppTheme.amber,
            onChanged: (value) => setState(() => _energy = value),
          ),
          const SizedBox(height: 14),
          _SliderCard(
            title: 'Estrés',
            subtitle: _stressLabel,
            value: _stress,
            min: 1,
            max: 10,
            divisions: 9,
            activeColor: AppTheme.terracotta,
            onChanged: (value) => setState(() => _stress = value),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nota opcional',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                TextField(
                  controller: _noteController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText:
                        'Ejemplo: dormí poco, caminé 30 min y pasé mucho tiempo en redes...',
                    filled: true,
                    fillColor: AppTheme.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: AppTheme.textPrimary.withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vista previa',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'El sistema comparará este registro contra tu baseline personal y actualizará el score del día.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(height: 1.4),
                ),
                const SizedBox(height: 12),
                Text(
                  'Score estimado: ${_estimatedScore.toStringAsFixed(0)}',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: AppTheme.sage),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Guardar check-in'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
            ),
          ),
        ],
      ),
    );
  }

  double get _estimatedScore {
    final moodScore = _mood * 10;
    final sleepInputScore =
        (100 - (_sleepHours - 7.5).abs() * 18).clamp(0.0, 100.0);
    final activityInputScore = (_activityMinutes * 1.6).clamp(0.0, 100.0);
    final socialInputScore = (100 - _socialMinutes * 0.35).clamp(0.0, 100.0);
    final energyScore = (_energy * 10).clamp(0.0, 100.0);
    final stressLoad = (100.0 - _stress * 10).clamp(0.0, 100.0);

    final sleepScore =
        ((widget.snapshot.sleepScore * 0.55) + (sleepInputScore * 0.45))
            .clamp(0.0, 100.0);
    final activityScore =
        ((widget.snapshot.activityScore * 0.55) + (activityInputScore * 0.45))
            .clamp(0.0, 100.0);
    final socialScore =
        ((widget.snapshot.socialScore * 0.55) + (socialInputScore * 0.45))
            .clamp(0.0, 100.0);

    final score = (moodScore * 0.3) +
        (sleepScore * 0.22) +
        (activityScore * 0.15) +
        (socialScore * 0.13) +
        (energyScore * 0.10) +
        (stressLoad * 0.10);
    return score.clamp(0.0, 100.0);
  }

  String get _moodLabel =>
      _labelFor(_mood, ['Bajo', 'Tranquilo', 'Bien', 'Muy bien', 'Excelente']);
  String get _sleepLabel => '${_sleepHours.toStringAsFixed(1)} h';
  String get _activityLabel => '${_activityMinutes.toStringAsFixed(0)} min';
  String get _socialLabel => '${(_socialMinutes / 60).toStringAsFixed(1)} h';
  String get _energyLabel =>
      '${_energy.toStringAsFixed(0)}/10 · ${_labelFor(_energy, [
            'Agotado',
            'Bajo',
            'Regular',
            'Activo',
            'Muy activo'
          ])}';
  String get _stressLabel =>
      _labelFor(_stress, ['Bajo', 'Leve', 'Moderado', 'Elevado', 'Alto']);

  String _labelFor(double value, List<String> labels) {
    if (value <= 2) return labels[0];
    if (value <= 4) return labels[1];
    if (value <= 6) return labels[2];
    if (value <= 8) return labels[3];
    return labels[4];
  }

  // CORRECCIÓN AQUÍ: Convertimos los double de la vista a los int que espera CheckInDraft usando .toInt()
  Future<void> _submit() async {
    // Mostrar indicador de carga opcional si se desea
    widget.onSubmit(
      CheckInDraft(
        mood: _mood,
        sleepHours: _sleepHours,
        activityMinutes: _activityMinutes,
        socialMinutes: _socialMinutes,
        energy: _energy,
        stress: _stress,
        note: _noteController.text,
      ),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Check-in guardado y score actualizado con IA.')),
      );
    }
  }
}

class _SliderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final Color activeColor;
  final ValueChanged<double> onChanged;

  const _SliderCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.activeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              Text(subtitle,
                  style: TextStyle(
                      color: activeColor, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: activeColor,
              inactiveTrackColor: activeColor.withValues(alpha: 0.16),
              thumbColor: activeColor,
              overlayColor: activeColor.withValues(alpha: 0.12),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
