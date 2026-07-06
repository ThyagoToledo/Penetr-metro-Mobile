import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../measurement/application/measurement_providers.dart';
import '../../measurement/domain/entities/measurement.dart';
import '../data/backup_importer.dart';

/// Fluxo completo de importação: escolher arquivo (JSON ou backup .zip),
/// validar, confirmar com o usuário e gravar as medições.
Future<void> runImportFlow(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);

  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['json', 'zip'],
    withData: true,
  );
  if (result == null) return;

  final file = result.files.single;
  final bytes = file.bytes;
  if (bytes == null) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Não foi possível ler o arquivo.')),
    );
    return;
  }

  final List<Measurement> parsed;
  try {
    parsed = file.extension?.toLowerCase() == 'zip'
        ? BackupImporter.parseBackupZip(bytes)
        : BackupImporter.parseJsonExport(utf8.decode(bytes));
  } on FormatException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
    return;
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Arquivo inválido. Use um export JSON ou backup .zip '
            'gerado por este app.'),
      ),
    );
    return;
  }

  if (parsed.isEmpty) {
    messenger.showSnackBar(
      const SnackBar(content: Text('O arquivo não contém medições.')),
    );
    return;
  }

  if (!context.mounted) return;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('Importar medições'),
      content: Text(
        'Encontradas ${parsed.length} medição(ões) em "${file.name}". '
        'Elas serão adicionadas às existentes. Continuar?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(c, true),
          child: const Text('Importar'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  final count =
      await ref.read(measurementsProvider.notifier).importAll(parsed);
  messenger.showSnackBar(
    SnackBar(content: Text('$count medição(ões) importada(s).')),
  );
}
