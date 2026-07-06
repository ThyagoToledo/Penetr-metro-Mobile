import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/measurement_card.dart';
import '../../measurement/application/measurement_providers.dart';
import '../../measurement/domain/entities/measurement.dart';
import '../../sync/application/sync_providers.dart';

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
        actions: const [_DriveStatusAction()],
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
          const _DriveStatusCard(),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Medições recentes',
                style: Theme.of(context).textTheme.titleMedium,
              ),
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
            ...recent.map((m) => MeasurementCard(measurement: m)),
        ],
      ),
    );
  }
}

/// Ícone do AppBar que reflete o estado real da conexão com o Drive.
class _DriveStatusAction extends ConsumerWidget {
  const _DriveStatusAction();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = ref.watch(driveConnectionProvider).valueOrNull;
    final connected = email != null;
    return IconButton(
      icon: Icon(
        connected ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
        color: connected ? Theme.of(context).colorScheme.primary : null,
      ),
      tooltip: connected ? 'Drive: $email' : 'Drive desconectado',
      onPressed: () => context.go('/settings'),
    );
  }
}

/// Cartão do Google Drive com estado real (conectar / conectado / erro).
class _DriveStatusCard extends ConsumerWidget {
  const _DriveStatusCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conn = ref.watch(driveConnectionProvider);

    return conn.when(
      loading: () => const Card(
        child: ListTile(
          leading: Icon(Icons.add_to_drive),
          title: Text('Google Drive'),
          trailing: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => Card(
        child: ListTile(
          leading: const Icon(Icons.cloud_off_outlined),
          title: const Text('Google Drive'),
          subtitle: const Text('Indisponível — veja Configurações'),
          trailing: TextButton(
            onPressed: () => context.go('/settings'),
            child: const Text('Abrir'),
          ),
        ),
      ),
      data: (email) {
        if (email == null) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.cloud_off_outlined),
              title: const Text('Google Drive'),
              subtitle: const Text('Faça backup na sua própria conta'),
              trailing: FilledButton.tonal(
                onPressed: () =>
                    ref.read(driveConnectionProvider.notifier).connect(),
                child: const Text('Conectar'),
              ),
            ),
          );
        }
        return Card(
          child: ListTile(
            leading: Icon(
              Icons.cloud_done_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(email),
            subtitle: const Text('Conectado ao Google Drive'),
            trailing: TextButton(
              onPressed: () => _backupNow(context, ref),
              child: const Text('Backup'),
            ),
          ),
        );
      },
    );
  }

  Future<void> _backupNow(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Enviando backup ao Drive...')),
    );
    try {
      await ref.read(driveConnectionProvider.notifier).backupNow();
      messenger.showSnackBar(
        const SnackBar(content: Text('Backup enviado com sucesso.')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Falha no backup: $e')));
    }
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
            Icon(
              Icons.straighten,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
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
