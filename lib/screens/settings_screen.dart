import 'package:flutter/material.dart';

import '../models/wellbeing_models.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  final WellbeingSnapshot snapshot;
  final VoidCallback onResetBaseline;
  final bool notificationsEnabled;
  final TimeOfDay reminderTime;
  final ValueChanged<bool> onNotificationsChanged;
  final ValueChanged<TimeOfDay> onReminderTimeChanged;
  final VoidCallback onClearData;

  const SettingsScreen({
    required this.snapshot,
    required this.onResetBaseline,
    required this.notificationsEnabled,
    required this.reminderTime,
    required this.onNotificationsChanged,
    required this.onReminderTimeChanged,
    required this.onClearData,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final reminderLabel = reminderTime.format(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ajustes', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Privacidad, recordatorios y permisos. Esta primera versión trabaja con datos locales simulados.',
            style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 18),
          _SettingsCard(
            title: 'Baseline personal',
            subtitle:
                'La app compara tu día de hoy contra tu patrón reciente, no contra una media poblacional.',
            trailing: TextButton(
              onPressed: onResetBaseline,
              child: const Text('Restablecer'),
            ),
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            title: 'Recordatorios suaves',
            subtitle: notificationsEnabled
                ? 'Te recordaremos hacer tu check-in a una hora tranquila.'
                : 'Actívalos si quieres un recordatorio amable para registrar cómo va tu día.',
            trailing: Switch(
              value: notificationsEnabled,
              onChanged: onNotificationsChanged,
            ),
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            title: 'Hora de recordatorio',
            subtitle:
                'Elige un momento que te resulte cómodo y no te interrumpa demasiado.',
            trailing: FilledButton.tonal(
              onPressed: notificationsEnabled
                  ? () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: reminderTime,
                      );
                      if (!context.mounted) return;
                      if (picked != null) {
                        onReminderTimeChanged(picked);
                      }
                    }
                  : null,
              child: Text(reminderLabel),
            ),
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            title: 'Health Connect / HealthKit',
            subtitle:
                'Fuente prevista para sueño, actividad y métricas de bienestar cuando integres permisos nativos.',
            trailing: const Chip(
              label: Text('Planificado'),
              side: BorderSide.none,
            ),
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            title: 'Seguimiento amable',
            subtitle:
                'Recordatorios y señales útiles, pensados para acompañarte sin ponerse encima.',
            trailing: const Icon(Icons.notifications_active_outlined),
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            title: 'Privacidad',
            subtitle:
                'No se suben datos brutos en esta base. Los cambios de score se calculan localmente por ahora.',
            trailing: const Icon(Icons.lock_outline),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Estado actual',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                Text('Score: ${snapshot.overallScore.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text('Mensaje: ${snapshot.message}',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(height: 1.4)),
                const SizedBox(height: 8),
                Text('Apoyo: ${snapshot.supportTitle}',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(snapshot.supportBody,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(height: 1.4)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'La parte de permisos nativos se puede preparar más adelante desde este bloque.'),
                ),
              );
            },
            icon: const Icon(Icons.file_download_outlined),
            label: const Text('Preparar exportación'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Borrar datos'),
                  content: const Text(
                      'Esto eliminará tu historial local y restablecerá la configuración. ¿Estás seguro?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancelar')),
                    FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Borrar')),
                  ],
                ),
              );
              if (confirmed == true) {
                onClearData();
                messenger.showSnackBar(
                    const SnackBar(content: Text('Datos borrados.')));
              }
            },
            icon: const Icon(Icons.delete_outline),
            label: const Text('Borrar datos'),
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
}

class _SettingsCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget trailing;

  const _SettingsCard({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}
