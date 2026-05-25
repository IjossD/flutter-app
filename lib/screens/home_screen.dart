import 'package:flutter/material.dart';

import '../models/wellbeing_models.dart';
import '../theme/app_theme.dart';
import '../widgets/score_ring.dart';
import '../widgets/trend_sparkline.dart';
import '../utils/support_actions.dart';

class HomeScreen extends StatelessWidget {
  final WellbeingSnapshot snapshot;
  final List<InsightItem> insights;
  final List<CheckInRecord> history;
  final VoidCallback onOpenCheckIn;
  final void Function(String action, String details) onRegisterSupportAction;
  final VoidCallback onOpenCamera;

  const HomeScreen({
    required this.snapshot,
    required this.insights,
    required this.history,
    required this.onOpenCheckIn,
    required this.onRegisterSupportAction,
    required this.onOpenCamera,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final hasHistory = history.isNotEmpty;
    final trendValues = history
        .take(7)
        .map((record) => record.score.toDouble())
        .toList()
        .reversed
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(onOpenCheckIn: onOpenCheckIn),
          const SizedBox(height: 16),
          const _DisclaimerCard(),
          const SizedBox(height: 20),
          const _HealthConnectCard(),
          const SizedBox(height: 16),
          if (!hasHistory) ...[
            _EmptyDashboardCard(onOpenCheckIn: onOpenCheckIn),
          ] else ...[
            _WeeklySummaryCard(history: history),
            const SizedBox(height: 16),
            ScoreRing(
              score: snapshot.overallScore,
              label: 'Bienestar de hoy',
              subtitle: snapshot.message,
            ),
            const SizedBox(height: 18),
            _SupportEscalationCard(
              snapshot: snapshot,
              onRegister: onRegisterSupportAction,
              onOpenCamera: onOpenCamera,
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.45,
              children: [
                _MetricCard(
                    title: 'Sueño',
                    value: snapshot.sleepScore,
                    color: AppTheme.sage,
                    icon: Icons.nightlight_round),
                _MetricCard(
                    title: 'Actividad',
                    value: snapshot.activityScore,
                    color: AppTheme.amber,
                    icon: Icons.directions_walk),
                _MetricCard(
                    title: 'Redes',
                    value: snapshot.socialScore,
                    color: AppTheme.terracotta,
                    icon: Icons.smartphone_outlined),
                _MetricCard(
                    title: 'Carga',
                    value: snapshot.stressLoad,
                    color: AppTheme.terracotta,
                    icon: Icons.water_drop_outlined),
              ],
            ),
            const SizedBox(height: 18),
            Text('Tendencia de 7 días',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TrendSparkline(values: trendValues),
            const SizedBox(height: 18),
            Text('Últimos check-ins',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ...history.take(3).map(
                  (record) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _HistoryTile(record: record),
                  ),
                ),
            const SizedBox(height: 18),
            if (insights.isNotEmpty) ...[
              Text('Insight principal',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              _InsightHighlight(
                title: insights.first.title,
                body: insights.first.body,
                label: insights.first.label,
              ),
              const SizedBox(height: 14),
              if (insights.length > 1) ...[
                Text('Próximas señales a vigilar',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                ...insights.skip(1).map(
                      (insight) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _InsightListTile(item: insight),
                      ),
                    ),
              ],
            ] else ...[
              Text('Estado de tus patrones',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              const _InsightHighlight(
                title: 'Sin señales claras todavía',
                body:
                    'Aún no hay check-ins para comparar. Guarda tu primer registro y aquí empezará tu patrón personal.',
                label: 'Inicio',
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _EmptyDashboardCard extends StatelessWidget {
  final VoidCallback onOpenCheckIn;

  const _EmptyDashboardCard({required this.onOpenCheckIn});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.sage.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Todavía no hay registros',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Haz tu primer check-in para que la app empiece vacía y empiece a leer tu patrón personal desde cero.',
            style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 14),
          FilledButton.tonal(
            onPressed: onOpenCheckIn,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('Hacer primer check-in'),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onOpenCheckIn;

  const _Header({required this.onOpenCheckIn});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Buenos días'
        : hour < 18
            ? 'Buenas tardes'
            : 'Buenas noches';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 6),
              Text(
                'Tu ritmo personal es la referencia principal. La app se ajusta a tus cambios, no a promedios genéricos.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        FilledButton(
          onPressed: onOpenCheckIn,
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.textPrimary,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          child: const Text('Check-in'),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final double value;
  final Color color;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              Text(
                value.toStringAsFixed(0),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.textPrimary,
                    ),
              ),
            ],
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _InsightHighlight extends StatelessWidget {
  final String title;
  final String body;
  final String label;

  const _InsightHighlight({
    required this.title,
    required this.body,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.sage.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Chip(
            label: Text(label),
            side: BorderSide.none,
            backgroundColor: AppTheme.sage.withValues(alpha: 0.14),
            labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(body,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(height: 1.45)),
        ],
      ),
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.terracotta.withValues(alpha: 0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.terracotta.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.info_outline, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Esta app monitorea patrones de hábitos. No es una herramienta médica. Si sientes que necesitas apoyo, hablar con un profesional siempre es la mejor opción.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthConnectCard extends StatelessWidget {
  const _HealthConnectCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.sage.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.sage.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.health_and_safety_outlined, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Salud conectada',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      'Preparado para integrar Health Connect, sueño, actividad, pantalla y nutrición.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _DataChip('Health Connect'),
              _DataChip('Sueño'),
              _DataChip('Actividad'),
              _DataChip('Redes'),
              _DataChip('Comida + IA'),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton.tonalIcon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'La integración nativa con Health Connect se deja lista para la siguiente fase.'),
                ),
              );
            },
            icon: const Icon(Icons.link_outlined),
            label: const Text('Preparar permisos'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklySummaryCard extends StatelessWidget {
  final List<CheckInRecord> history;

  const _WeeklySummaryCard({required this.history});

  double get _averageScore {
    if (history.isEmpty) return 0;
    final total = history.map((record) => record.score).reduce((a, b) => a + b);
    return total / history.length;
  }

  String get _trendLabel {
    if (history.length < 2) return 'Aún construyendo tendencia';
    final latest = history.first.score;
    final previous = history[1].score;
    if (latest > previous + 2) return 'Va mejorando';
    if (latest < previous - 2) return 'Va bajando';
    return 'Estable';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.amber.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.amber.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.calendar_month_outlined, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Resumen semanal',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text('Promedio local de los últimos check-ins guardados.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(height: 1.35)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _DataChip('Promedio: ${_averageScore.toStringAsFixed(0)}'),
              _DataChip('Tendencia: $_trendLabel'),
              _DataChip('Registros: ${history.length}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final CheckInRecord record;

  const _HistoryTile({required this.record});

  String _formatDate(DateTime date) {
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  Color _riskColor() {
    switch (record.riskLevel) {
      case RiskLevel.stable:
        return AppTheme.sage;
      case RiskLevel.watch:
        return AppTheme.amber;
      case RiskLevel.low:
        return AppTheme.terracotta;
      case RiskLevel.urgent:
        return AppTheme.mutedTerracotta;
    }
  }

  String _riskLabel() {
    switch (record.riskLevel) {
      case RiskLevel.stable:
        return 'Estable';
      case RiskLevel.watch:
        return 'Vigilar';
      case RiskLevel.low:
        return 'Bajo';
      case RiskLevel.urgent:
        return 'Urgente';
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _riskColor();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.history, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    '${_formatDate(record.date)} · ${record.score.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(record.note.isEmpty ? 'Sin nota' : record.note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(height: 1.35)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Chip(
              label: Text(_riskLabel()),
              backgroundColor: accent.withValues(alpha: 0.14),
              side: BorderSide.none),
        ],
      ),
    );
  }
}

class _SupportEscalationCard extends StatelessWidget {
  final WellbeingSnapshot snapshot;
  final void Function(String action, String details) onRegister;
  final VoidCallback onOpenCamera;

  const _SupportEscalationCard(
      {required this.snapshot,
      required this.onRegister,
      required this.onOpenCamera});

  Color get _accent {
    switch (snapshot.riskLevel) {
      case RiskLevel.stable:
        return AppTheme.sage;
      case RiskLevel.watch:
        return AppTheme.amber;
      case RiskLevel.low:
        return AppTheme.terracotta;
      case RiskLevel.urgent:
        return AppTheme.mutedTerracotta;
    }
  }

  IconData get _icon {
    switch (snapshot.riskLevel) {
      case RiskLevel.stable:
        return Icons.verified_outlined;
      case RiskLevel.watch:
        return Icons.monitor_heart_outlined;
      case RiskLevel.low:
        return Icons.support_agent_outlined;
      case RiskLevel.urgent:
        return Icons.warning_amber_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _accent.withValues(alpha: 0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_icon, color: _accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(snapshot.supportTitle,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(snapshot.supportBody,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(height: 1.45)),
                const SizedBox(height: 10),
                if (snapshot.riskLevel == RiskLevel.low ||
                    snapshot.riskLevel == RiskLevel.urgent) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: const [
                      _DataChip('Habla con un profesional'),
                      _DataChip('Apoyo de confianza'),
                      _DataChip('Revisar descanso'),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Llamar ahora'),
                            content: const Text(
                                '¿Deseas llamar a la línea de emergencia local?'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: const Text('Cancelar')),
                              TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: const Text('Llamar')),
                            ],
                          ),
                        );
                        if (!context.mounted) return;
                        if (confirm == true) {
                          SupportActions.callNumber(context, '106');
                          onRegister(
                              'call_emergency', 'Llamada a número local 106');
                        }
                      },
                      child: const Text('Llamar ahora'),
                    ),
                    OutlinedButton(
                      onPressed: () async {
                        final consent = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Compartir con profesional'),
                            content: const Text(
                                'Se enviará un resumen mínimo con fechas, scores y notas. ¿Das consentimiento para abrir el cliente de correo?'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: const Text('Cancelar')),
                              TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: const Text('Aceptar')),
                            ],
                          ),
                        );
                        if (consent == true) {
                          if (!context.mounted) return;
                          final subject =
                              'Resumen de bienestar - ${DateTime.now().toLocal().toIso8601String().split('T').first}';
                          final body =
                              'Score: ${snapshot.overallScore.toStringAsFixed(0)}\nRiesgo: ${snapshot.supportTitle}\nNotas: ${snapshot.message}\n\nAdjunto: últimos registros locales.';
                          await SupportActions.sendEmail('', subject, body);
                          onRegister(
                              'email_professional', 'Email prellenado abierto');
                        }
                      },
                      child: const Text('Contactar profesional'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DataChip extends StatelessWidget {
  final String text;

  const _DataChip(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class _InsightListTile extends StatelessWidget {
  final InsightItem item;

  const _InsightListTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.amber.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.auto_awesome_outlined, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  item.body,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
