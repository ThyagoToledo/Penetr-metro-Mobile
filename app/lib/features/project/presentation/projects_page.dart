import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../application/project_providers.dart';
import '../domain/project.dart';

class ProjectsPage extends ConsumerWidget {
  const ProjectsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(projectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projetos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Novo projeto',
            onPressed: () => _editDialog(context, ref),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (projects) {
          if (projects.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.folder_open,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline,),
                    const SizedBox(height: AppSpacing.md),
                    const Text('Nenhum projeto ainda.'),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton.icon(
                      onPressed: () => _editDialog(context, ref),
                      icon: const Icon(Icons.add),
                      label: const Text('Novo Projeto'),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: projects.length,
            itemBuilder: (context, i) =>
                _ProjectCard(project: projects[i]),
          );
        },
      ),
    );
  }
}

class _ProjectCard extends ConsumerWidget {
  const _ProjectCard({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: project.archived
              ? Theme.of(context).colorScheme.surfaceContainerHighest
              : Theme.of(context).colorScheme.primaryContainer,
          child: Icon(project.archived ? Icons.inventory_2_outlined
              : Icons.folder,),
        ),
        title: Text(project.name),
        subtitle: Text(
          project.description?.isNotEmpty == true
              ? project.description!
              : 'Sem descrição',
        ),
        onTap: project.id == null
            ? null
            : () => context.push('/project/${project.id}'),
        trailing: PopupMenuButton<String>(
          onSelected: (v) => _onAction(context, ref, v),
          itemBuilder: (c) => [
            const PopupMenuItem(value: 'edit', child: Text('Editar')),
            const PopupMenuItem(value: 'duplicate', child: Text('Duplicar')),
            PopupMenuItem(
              value: 'archive',
              child: Text(project.archived ? 'Desarquivar' : 'Arquivar'),
            ),
            const PopupMenuItem(value: 'delete', child: Text('Excluir')),
          ],
        ),
      ),
    );
  }

  Future<void> _onAction(
      BuildContext context, WidgetRef ref, String action,) async {
    final notifier = ref.read(projectsProvider.notifier);
    switch (action) {
      case 'edit':
        await _editDialog(context, ref, existing: project);
      case 'duplicate':
        await notifier.duplicate(project.id!);
      case 'archive':
        await notifier.setArchived(project.id!, archived: !project.archived);
      case 'delete':
        final ok = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Excluir projeto'),
            content: Text('Excluir "${project.name}"? '
                'As medições não são apagadas.'),
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
        if (ok == true) await notifier.remove(project.id!);
    }
  }
}

Future<void> _editDialog(
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
            decoration: const InputDecoration(labelText: 'Nome'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: descCtrl,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Descrição (opcional)'),
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
