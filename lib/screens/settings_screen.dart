import 'package:flutter/material.dart';

import '../models/wellbeing_models.dart';
import '../theme/app_theme.dart';
import '../utils/permissions.dart';

class SettingsScreen extends StatelessWidget {
  final WellbeingSnapshot snapshot;
  final VoidCallback onResetBaseline;

  const SettingsScreen({
    required this.snapshot,
    required this.onResetBaseline,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ajustes', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Privacidad, baseline y permisos. Esta primera versión trabaja con datos locales simulados.',
            style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 18),
          _SettingsCard(
            title: 'Baseline personal',
            subtitle:
                'El sistema compara tu día de hoy contra tu propio patrón reciente, no contra una media poblacional.',
            trailing: TextButton(
              onPressed: onResetBaseline,
              child: const Text('Restablecer'),
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
            title: 'Notificaciones suaves',
            subtitle:
                'Recordatorios y insights no invasivos, orientados a hábitos y no a diagnósticos.',
            trailing: Switch(value: true, onChanged: (_) {}),
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
            onPressed: () async {
              final results = await Permissions.requestAll();
              final summary = results.entries
                  .map((e) =>
                      '${e.key.toString().split('.').last}: ${e.value.toString().split('.').last}')
                  .join('\n');
              await showDialog<void>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Permisos solicitados'),
                  content: Text(summary),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('OK')),
                  ],
                ),
              );
              await Permissions.openSettingsIfNeeded(context, results);
            },
            icon: const Icon(Icons.file_download_outlined),
            label: const Text('Preparar exportación'),
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
