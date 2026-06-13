import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_spacing.dart';
import '../../measurement/application/measurement_providers.dart';
import '../../measurement/domain/entities/measurement.dart';
import '../../../shared/widgets/diagnosis_visuals.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(measurementStatsProvider);
    final measurementsAsync = ref.watch(measurementsProvider);
    final recent = (measurementsAsync.valueOrNull ?? const <Measurement>[])
        .take(3)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Penetrômetro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_off_outlined),
            tooltip: 'Drive desconectado',
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.straighten,
                  label: 'Medições',
                  value: '${stats.total}',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _StatCard(
                  icon: Icons.functions,
                  label: 'Coef. médio',
                  value: stats.total == 0
                      ? '—'
                      : '${stats.average.toStringAsFixed(2)} kgf/cm²',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: ListTile(
              leading: const Icon(Icons.cloud_off_outlined),
              title: const Text('Google Drive'),
              subtitle: const Text('Desconectado · sincronização na fase F6'),
              trailing: TextButton(
                onPressed: () {},
                child: const Text('Conectar'),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Medições recentes',
                  style: Theme.of(context).textTheme.titleMedium,),
              if (recent.isNotEmpty)
                TextButton(
                  onPressed: () => context.go('/measurements'),
                  child: const Text('Ver todas'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (recent.isEmpty)
            _EmptyHint(onCreate: () => context.push('/measurement/new'))
          else
            ...recent.map((m) => _RecentTile(measurement: m)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: scheme.primary),
            const SizedBox(height: AppSpacing.sm),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _RecentTile extends StatelessWidget {
  const _RecentTile({required this.measurement});

  final Measurement measurement;

  @override
  Widget build(BuildContext context) {
    final date = measurement.meteringDate;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: diagnosisColor(measurement.coefficient),
          child: Icon(typeIcon(measurement.type), color: Colors.white),
        ),
        title: Text('${measurement.coefficient.toStringAsFixed(2)} kgf/cm²'),
        subtitle: Text(measurement.floorResistance),
        trailing: Text(
          date == null ? '' : DateFormat('dd/MM').format(date),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Icon(Icons.straighten,
                size: 48, color: Theme.of(context).colorScheme.outline,),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Nenhuma medição ainda.\nToque em + para registrar a primeira.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Nova Medição'),
            ),
          ],
        ),
      ),
    );
  }
}
