import 'package:flutter/material.dart';

import '../models/wellbeing_models.dart';
import '../theme/app_theme.dart';

class InsightsScreen extends StatelessWidget {
  final WellbeingSnapshot snapshot;
  final List<InsightItem> insights;
  final List<CheckInRecord> history;
  final void Function(String action, String details) onRegisterSupportAction;

  const InsightsScreen({
    required this.snapshot,
    required this.insights,
    required this.history,
    required this.onRegisterSupportAction,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Insights', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Resumen en lenguaje simple. El foco está en cambios respecto a tu ritmo habitual.',
            style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 18),
          _NarrativeCard(snapshot: snapshot),
          const SizedBox(height: 16),
          _SupportRouteCard(snapshot: snapshot),
          const SizedBox(height: 16),
          Text('Historial local',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ...history.take(5).map(
                (record) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _HistoryCard(record: record),
                ),
              ),
          const SizedBox(height: 8),
          Text('Lo más relevante hoy',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (insights.isNotEmpty)
            ...insights.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _InsightCard(item: item),
              ),
            )
          else
            const _EmptyInsightsCard(),
        ],
      ),
    );
  }
}

class _NarrativeCard extends StatelessWidget {
  final WellbeingSnapshot snapshot;

  const _NarrativeCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final statusText = snapshot.overallScore >= 75
        ? 'Estabilidad buena'
        : snapshot.overallScore >= 55
            ? 'Requiere atención suave'
            : 'Cambios relevantes';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.sage.withValues(alpha: 0.12), AppTheme.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Chip(
            label: Text(statusText),
            backgroundColor: AppTheme.sage.withValues(alpha: 0.14),
            side: BorderSide.none,
          ),
          const SizedBox(height: 10),
          Text(
            'Hoy tu score refleja más continuidad que ruptura. Si un indicador se separa de tu patrón normal durante varios días, la app le da más peso que a un valor aislado.',
            style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _Tag('Sueño: ${snapshot.sleepScore.toStringAsFixed(0)}'),
              _Tag('Actividad: ${snapshot.activityScore.toStringAsFixed(0)}'),
              _Tag('Estrés: ${snapshot.stressLoad.toStringAsFixed(0)}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final InsightItem item;

  const _InsightCard({required this.item});

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
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.amber.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.auto_graph, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(item.body,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyInsightsCard extends StatelessWidget {
  const _EmptyInsightsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        'Por ahora no hay señales fuertes. Eso también cuenta: significa que hoy no aparece nada que merezca más peso que el resto.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45),
      ),
    );
  }
}

class _SupportRouteCard extends StatelessWidget {
  final WellbeingSnapshot snapshot;

  const _SupportRouteCard({required this.snapshot});

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
                Text(
                  snapshot.supportBody,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final CheckInRecord record;

  const _HistoryCard({required this.record});

  String _label() {
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

  Color _color() {
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

  @override
  Widget build(BuildContext context) {
    final accent = _color();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.event_note_outlined, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    '${record.date.day}/${record.date.month} · ${record.score.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(record.note.isEmpty ? 'Sin nota' : record.note,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Chip(
              label: Text(_label()),
              backgroundColor: accent.withValues(alpha: 0.14),
              side: BorderSide.none),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;

  const _Tag(this.text);

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
