import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Abre uma legenda explicando os símbolos/cores usados nas medições.
Future<void> showLegendSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (c) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (c, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('Legenda', style: Theme.of(c).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),

          const _SectionTitle('Tipo de penetrômetro (ícone do círculo)'),
          const _IconRow(
            icon: Icons.hardware,
            title: 'Impacto',
            description:
                'Equação de Stolf: R = 5,6 + 6,89 × N (N = nº de impactos).',
          ),
          const _IconRow(
            icon: Icons.compress,
            title: 'Pressão',
            description: 'Conversão da leitura do manômetro: 1 MPa = 10,1972 kgf/cm².',
          ),
          const Divider(height: AppSpacing.xxl),

          const _SectionTitle('Cor do círculo = diagnóstico (coeficiente em kgf/cm²)'),
          const _ColorRow(AppColors.diagAdequate, 'Verde',
              'Solo adequado para cultivo (< 10).',),
          const _ColorRow(AppColors.diagModerate, 'Verde-claro',
              'Resistência moderada (10 a 20).',),
          const _ColorRow(AppColors.diagHigh, 'Amarelo',
              'Alta resistência (20 a 30).',),
          const _ColorRow(AppColors.diagCompacted, 'Laranja',
              'Solo compactado (30 a 40).',),
          const _ColorRow(AppColors.diagExtreme, 'Vermelho',
              'Extremamente compactado (> 40).',),
          const Divider(height: AppSpacing.xxl),

          const _SectionTitle('O que é o coeficiente'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Text(
              'O coeficiente é a resistência do solo à penetração, em kgf/cm². '
              'Quanto maior, mais compactado está o solo — o que pode dificultar '
              'o crescimento das raízes e a infiltração de água.',
            ),
          ),

          const _SectionTitle('Ícones de ação'),
          const _IconRow(
            icon: Icons.bar_chart,
            title: 'Gráficos',
            description: 'Abre os gráficos (resistência × profundidade e comparação).',
          ),
          const _IconRow(
            icon: Icons.delete_outline,
            title: 'Excluir',
            description: 'Remove a medição (pede confirmação).',
          ),
          const _IconRow(
            icon: Icons.picture_as_pdf,
            title: 'Gerar PDF',
            description: 'Cria o relatório em PDF da medição (no app Android).',
          ),
        ],
      ),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _IconRow extends StatelessWidget {
  const _IconRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Icon(icon, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w600),),
                Text(description,
                    style: Theme.of(context).textTheme.bodySmall,),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorRow extends StatelessWidget {
  const _ColorRow(this.color, this.name, this.description);

  final Color color;
  final String name;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(fontWeight: FontWeight.w600),),
                Text(description,
                    style: Theme.of(context).textTheme.bodySmall,),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
