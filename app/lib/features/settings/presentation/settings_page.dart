import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../sync/application/sync_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Center(
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radius),
                  child: Image.asset(
                    'assets/icon/app_icon.png',
                    width: 88,
                    height: 88,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('Penetrômetro',
                    style: Theme.of(context).textTheme.titleLarge,),
                Text(
                  'IF Goiano — Campus Hidrolândia',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Divider(height: AppSpacing.xxl),
          Text('Aparência', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('Sistema'),
                icon: Icon(Icons.brightness_auto),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('Claro'),
                icon: Icon(Icons.light_mode),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('Escuro'),
                icon: Icon(Icons.dark_mode),
              ),
            ],
            selected: {mode},
            onSelectionChanged: (s) =>
                ref.read(themeModeProvider.notifier).state = s.first,
          ),
          const Divider(height: AppSpacing.xxl),
          Text('Conta e Nuvem',
              style: Theme.of(context).textTheme.titleMedium,),
          const SizedBox(height: AppSpacing.sm),
          const _DriveSection(),
          const Divider(height: AppSpacing.xxl),
          Text('Sobre', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          const Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.tag),
                  title: Text('Versão'),
                  subtitle: Text('1.0.0 (1)'),
                ),
                ListTile(
                  leading: Icon(Icons.privacy_tip_outlined),
                  title: Text('Política de Privacidade'),
                  subtitle: Text('Ver docs/08-POLITICA-DE-PRIVACIDADE.md'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Seção reativa do Google Drive (conectar / backup / desconectar).
class _DriveSection extends ConsumerWidget {
  const _DriveSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conn = ref.watch(driveConnectionProvider);
    return conn.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Icon(Icons.add_to_drive),
              SizedBox(width: AppSpacing.md),
              Expanded(child: Text('Google Drive')),
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ),
        ),
      ),
      error: (e, _) => _DriveCard(
        icon: Icons.error_outline,
        title: 'Não foi possível conectar',
        subtitle: 'Configure o OAuth do Google (ver docs/06-GOOGLE-DRIVE.md).',
        buttonLabel: 'Tentar novamente',
        onPressed: () => ref.read(driveConnectionProvider.notifier).connect(),
      ),
      data: (email) {
        if (email == null) {
          return _DriveCard(
            icon: Icons.add_to_drive,
            title: 'Conectar Google Drive',
            subtitle: 'Backup e sincronização na sua própria conta.',
            buttonLabel: 'Conectar',
            onPressed:
                () => ref.read(driveConnectionProvider.notifier).connect(),
          );
        }
        return Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.account_circle),
                title: Text(email),
                subtitle: const Text('Conectado ao Google Drive'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.backup_outlined),
                title: const Text('Fazer backup agora'),
                onTap: () => _backup(context, ref),
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Desconectar'),
                onTap: () =>
                    ref.read(driveConnectionProvider.notifier).disconnect(),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _backup(BuildContext context, WidgetRef ref) async {
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

/// Cartão de ação do Drive com layout robusto (sem squish de texto).
class _DriveCard extends StatelessWidget {
  const _DriveCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: Theme.of(context).textTheme.titleMedium,),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: Theme.of(context).textTheme.bodySmall,),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onPressed,
                child: Text(buttonLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
