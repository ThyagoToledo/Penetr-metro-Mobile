import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/diagnosis_visuals.dart';
import '../../../shared/widgets/measurement_card.dart';
import '../../measurement/application/measurement_providers.dart';
import '../../measurement/domain/entities/measurement.dart';
import '../../sync/application/sync_providers.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(measurementStatsProvider);
    final measurements =
        ref.watch(measurementsProvider).valueOrNull ?? const <Measurement>[];
    final recent = measurements.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/icon/app_icon.png',
                width: 28,
                height: 28,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Text('Penetrômetro'),
          ],
        ),
        actions: const [_DriveStatusAction()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const _HeroHeader(),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.straighten,
                  label: 'Medições',
                  value: '${stats.total}',
                  background:
                      Theme.of(context).colorScheme.primaryContainer,
                  foreground:
                      Theme.of(context).colorScheme.onPrimaryContainer,
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
                  background:
                      Theme.of(context).colorScheme.secondaryContainer,
                  foreground:
                      Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
            ],
          ),
          if (measurements.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _DiagnosisDistribution(measurements: measurements),
          ],
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

/// Cabeçalho com saudação e gradiente nas cores da marca (solo e vegetação).
class _HeroHeader extends StatelessWidget {
  const _HeroHeader();

  static const List<String> _weekdays = [
    'segunda-feira',
    'terça-feira',
    'quarta-feira',
    'quinta-feira',
    'sexta-feira',
    'sábado',
    'domingo',
  ];
  static const List<String> _months = [
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  String get _dateLine {
    final now = DateTime.now();
    final weekday = _weekdays[now.weekday - 1];
    final month = _months[now.month - 1];
    return '$weekday, ${now.day} de $month';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.green, AppColors.blue],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _greeting,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            _dateLine,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Pronto para medir a compactação do solo?',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

/// Distribuição das medições por faixa de diagnóstico (barra empilhada).
class _DiagnosisDistribution extends StatelessWidget {
  const _DiagnosisDistribution({required this.measurements});

  final List<Measurement> measurements;

  static const List<({String label, double sample})> _bands = [
    (label: 'Adequado', sample: 5),
    (label: 'Moderada', sample: 15),
    (label: 'Alta', sample: 25),
    (label: 'Compactado', sample: 35),
    (label: 'Extremo', sample: 45),
  ];

  int _countInBand(int index) {
    return measurements.where((m) {
      final c = m.coefficient;
      return switch (index) {
        0 => c < 10,
        1 => c >= 10 && c <= 20,
        2 => c > 20 && c <= 30,
        3 => c > 30 && c <= 40,
        _ => c > 40,
      };
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final counts = List.generate(_bands.length, _countInBand);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Distribuição do solo',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 12,
                child: Row(
                  children: [
                    for (var i = 0; i < _bands.length; i++)
                      if (counts[i] > 0)
                        Expanded(
                          flex: counts[i],
                          child: Container(
                            color: diagnosisColor(_bands[i].sample),
                          ),
                        ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.xs,
              children: [
                for (var i = 0; i < _bands.length; i++)
                  if (counts[i] > 0)
                    _LegendChip(
                      color: diagnosisColor(_bands[i].sample),
                      text: '${_bands[i].label} (${counts[i]})',
                    ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(text, style: Theme.of(context).textTheme.bodySmall),
      ],
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
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: background,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: foreground),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: foreground),
            ),
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: foreground),
            ),
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
