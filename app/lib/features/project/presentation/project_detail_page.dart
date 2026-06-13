import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/legend_sheet.dart';
import '../../../shared/widgets/measurement_card.dart';
import '../../measurement/application/measurement_providers.dart';
import '../../measurement/domain/entities/measurement.dart';
import '../application/project_providers.dart';

/// Detalhe de um projeto: mostra suas medições e permite criar novas nele.
class ProjectDetailPage extends ConsumerWidget {
  const ProjectDetailPage({super.key, required this.projectId});

  final int projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = (ref.watch(projectsProvider).valueOrNull ?? [])
        .firstWhereOrNull((p) => p.id == projectId);
    final measurements =
        (ref.watch(measurementsProvider).valueOrNull ?? <Measurement>[])
            .where((m) => m.projectId == projectId)
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(project?.name ?? 'Projeto'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Legenda',
            onPressed: () => showLegendSheet(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/measurement/new', extra: projectId),
        icon: const Icon(Icons.add),
        label: const Text('Nova medição'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 96,),
        children: [
          if (project?.description != null &&
              project!.description!.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(project.description!),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Text(
            '${measurements.length} medição(ões) neste projeto',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (measurements.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  children: [
                    Icon(Icons.straighten,
                        size: 48,
                        color: Theme.of(context).colorScheme.outline,),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'Nenhuma medição neste projeto ainda.\n'
                      'Toque em "Nova medição" para adicionar.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ...measurements.map((m) => MeasurementCard(measurement: m)),
        ],
      ),
    );
  }
}
