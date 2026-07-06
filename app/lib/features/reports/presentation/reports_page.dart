import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../measurement/application/measurement_providers.dart';
import '../application/export_service.dart';
import 'import_flow.dart';

class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(measurementsProvider).valueOrNull ?? const [];
    final hasData = items.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Relatórios')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary,),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      hasData
                          ? 'Exportar ${items.length} medição(ões). O PDF '
                              'individual está no detalhe de cada medição.'
                          : 'Nenhuma medição para exportar ainda.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _ExportTile(
            icon: Icons.file_download_outlined,
            title: 'Importar (JSON ou backup .zip)',
            enabled: true,
            onTap: () => runImportFlow(context, ref),
          ),
          const Divider(height: AppSpacing.xl),
          _ExportTile(
            icon: Icons.table_chart,
            title: 'Exportar Excel (.xlsx)',
            enabled: hasData,
            onTap: () => _run(context, ref, (s) => s.shareExcel(items)),
          ),
          _ExportTile(
            icon: Icons.grid_on,
            title: 'Exportar CSV',
            enabled: hasData,
            onTap: () => _run(context, ref, (s) => s.shareCsv(items)),
          ),
          _ExportTile(
            icon: Icons.data_object,
            title: 'Exportar JSON',
            enabled: hasData,
            onTap: () => _run(context, ref, (s) => s.shareJson(items)),
          ),
          _ExportTile(
            icon: Icons.archive,
            title: 'Backup compactado (.zip)',
            enabled: hasData,
            onTap: () => _run(context, ref, (s) => s.shareBackup(items)),
          ),
        ],
      ),
    );
  }

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function(ExportService) action,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action(ref.read(exportServiceProvider));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Falha ao exportar: $e')),
      );
    }
  }
}

class _ExportTile extends StatelessWidget {
  const _ExportTile({
    required this.icon,
    required this.title,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.ios_share),
        enabled: enabled,
        onTap: enabled ? onTap : null,
      ),
    );
  }
}
