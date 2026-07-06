import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../application/project_providers.dart';
import '../domain/project.dart';

/// Diálogo de criação/edição de projeto, reutilizado pela página de projetos
/// e pelo FAB global.
Future<void> showProjectEditDialog(
  BuildContext context,
  WidgetRef ref, {
  Project? existing,
}) async {
  final nameCtrl = TextEditingController(text: existing?.name ?? '');
  final descCtrl = TextEditingController(text: existing?.description ?? '');

  final saved = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(existing == null ? 'Novo Projeto' : 'Editar Projeto'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Nome'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: descCtrl,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration:
                const InputDecoration(labelText: 'Descrição (opcional)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(c, true),
          child: const Text('Salvar'),
        ),
      ],
    ),
  );

  if (saved == true && nameCtrl.text.trim().isNotEmpty) {
    final project = (existing ?? const Project(name: '')).copyWith(
      name: nameCtrl.text.trim(),
      description: descCtrl.text.trim(),
    );
    await ref.read(projectsProvider.notifier).save(project);
  }
  nameCtrl.dispose();
  descCtrl.dispose();
}
