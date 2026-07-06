import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/legend_sheet.dart';
import '../../../shared/widgets/measurement_card.dart';
import '../application/measurement_providers.dart';
import '../domain/entities/measurement.dart';
import '../domain/entities/penetrometer_type.dart';

/// Lista de medições com busca (coletor/local/data) e filtro por tipo —
/// paridade com a consulta do sistema desktop.
class MeasurementsPage extends ConsumerStatefulWidget {
  const MeasurementsPage({super.key});

  @override
  ConsumerState<MeasurementsPage> createState() => _MeasurementsPageState();
}

class _MeasurementsPageState extends ConsumerState<MeasurementsPage> {
  final _searchCtrl = TextEditingController();
  PenetrometerType? _typeFilter;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Measurement> _applyFilters(List<Measurement> items) {
    final query = _searchCtrl.text.trim().toLowerCase();
    return items.where((m) {
      if (_typeFilter != null && m.type != _typeFilter) return false;
      if (query.isEmpty) return true;
      final date = m.meteringDate == null
          ? ''
          : DateFormat('dd/MM/yyyy').format(m.meteringDate!);
      final haystack = [
        m.place ?? '',
        m.nameCollector ?? '',
        date,
        m.floorResistance,
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
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
            return _EmptyState(
              onCreate: () => context.push('/measurement/new'),
            );
          }
          final filtered = _applyFilters(items);
          return Column(
            children: [
              _buildFilterBar(items.length, filtered.length),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text('Nenhuma medição encontrada com '
                            'esses filtros.'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          0,
                          AppSpacing.lg,
                          96,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) =>
                            MeasurementCard(measurement: filtered[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterBar(int total, int shown) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Buscar por local, coletor ou data',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchCtrl.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () =>
                          setState(() => _searchCtrl.clear()),
                    ),
              isDense: true,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    FilterChip(
                      label: const Text('Todos'),
                      selected: _typeFilter == null,
                      onSelected: (_) => setState(() => _typeFilter = null),
                    ),
                    FilterChip(
                      label: const Text('Impacto'),
                      selected: _typeFilter == PenetrometerType.impact,
                      onSelected: (_) => setState(
                        () => _typeFilter = PenetrometerType.impact,
                      ),
                    ),
                    FilterChip(
                      label: const Text('Pressão'),
                      selected: _typeFilter == PenetrometerType.pressure,
                      onSelected: (_) => setState(
                        () => _typeFilter = PenetrometerType.pressure,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$shown/$total',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.straighten,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('Nenhuma medição registrada.'),
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
