import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/legend_sheet.dart';
import '../../../shared/widgets/measurement_card.dart';
import '../application/measurement_providers.dart';

class MeasurementsPage extends ConsumerWidget {
  const MeasurementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(measurementsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medições'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Legenda dos símbolos',
            onPressed: () => showLegendSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Gráficos',
            onPressed: () => context.push('/charts'),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.straighten,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline,),
                    const SizedBox(height: AppSpacing.md),
                    const Text('Nenhuma medição registrada.'),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton.icon(
                      onPressed: () => context.push('/measurement/new'),
                      icon: const Icon(Icons.add),
                      label: const Text('Nova Medição'),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: items.length,
            itemBuilder: (context, i) => MeasurementCard(measurement: items[i]),
          );
        },
      ),
    );
  }
}
