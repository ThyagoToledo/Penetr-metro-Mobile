import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_spacing.dart';
import '../../features/measurement/application/measurement_providers.dart';
import '../../features/measurement/domain/entities/measurement.dart';
import '../../features/measurement/domain/entities/penetrometer_type.dart';
import '../../features/reports/application/export_service.dart';
import 'diagnosis_visuals.dart';

/// Card reutilizável de medição (lista geral e detalhe de projeto).
/// Abre o detalhe em bottom sheet (com "Gerar PDF") e permite excluir.
class MeasurementCard extends ConsumerWidget {
  const MeasurementCard({super.key, required this.measurement});

  final Measurement measurement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = measurement;
    final date = m.meteringDate;
    final subtitle = [
      m.type.description,
      if (m.place != null && m.place!.isNotEmpty) m.place!,
      if (date != null) DateFormat('dd/MM/yyyy').format(date),
    ].join(' · ');

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: diagnosisColor(m.coefficient),
          child: Icon(typeIcon(m.type), color: Colors.white),
        ),
        title: Text('${m.coefficient.toStringAsFixed(2)} kgf/cm² · '
            '${m.floorResistance}'),
        subtitle: Text(subtitle),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Excluir',
          onPressed: () => _confirmDelete(context, ref),
        ),
        onTap: () => _showDetails(context, ref),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Excluir medição'),
        content: const Text('Esta ação não pode ser desfeita. Continuar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok == true && measurement.id != null) {
      await ref.read(measurementsProvider.notifier).remove(measurement.id!);
    }
  }

  void _showDetails(BuildContext context, WidgetRef ref) {
    final m = measurement;
    final isImpact = m.type == PenetrometerType.impact;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (c) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (c, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: diagnosisColor(m.coefficient),
                  child: Icon(typeIcon(m.type), color: Colors.white),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text('Medição #${m.id}',
                      style: Theme.of(c).textTheme.titleLarge,),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _row('Tipo', m.type.description),
            _row('Coletor', m.nameCollector ?? '—'),
            _row('Local', m.place ?? '—'),
            _row('GPS',
                'Lat ${m.latitude.toStringAsFixed(6)}, Long ${m.longitude.toStringAsFixed(6)}',),
            if (isImpact)
              _row('Impactos', '${m.impactsQuantity}')
            else
              _row('Pressão', '${m.effectivePressureMpa.toStringAsFixed(2)} MPa'),
            _row('Profundidade', '${m.deep.toStringAsFixed(2)} cm'),
            _row('Coeficiente', '${m.coefficient.toStringAsFixed(4)} kgf/cm²'),
            _row('Diagnóstico', m.floorResistance),
            const SizedBox(height: AppSpacing.md),
            Text('Interpretação', style: Theme.of(c).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(m.interpretation),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(c);
                try {
                  await ref.read(exportServiceProvider).sharePdf(m);
                } catch (e) {
                  messenger.showSnackBar(SnackBar(content: Text('$e')));
                }
              },
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Gerar PDF'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w600),),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
