import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../measurement/domain/entities/measurement.dart';
import '../data/pdf_report_generator.dart';
import '../data/report_builders.dart';

/// Orquestra a geração e o compartilhamento de relatórios/exportações.
class ExportService {
  /// Gera e compartilha o PDF de uma medição.
  Future<void> sharePdf(Measurement m) async {
    final bytes = await PdfReportGenerator.build(m);
    await _shareBytes(
      bytes,
      'Medicao_${m.id ?? 0}_${m.type.dbValue}.pdf',
      'application/pdf',
    );
  }

  Future<void> shareCsv(List<Measurement> items) =>
      _shareText(ReportBuilders.buildCsv(items), 'medicoes.csv', 'text/csv');

  Future<void> shareJson(List<Measurement> items) => _shareText(
        ReportBuilders.buildJson(items),
        'medicoes.json',
        'application/json',
      );

  Future<void> shareExcel(List<Measurement> items) => _shareBytes(
        ReportBuilders.buildExcel(items),
        'medicoes.xlsx',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );

  Future<void> shareBackup(List<Measurement> items) => _shareBytes(
        ReportBuilders.buildBackupZip(items),
        'backup_penetrometro.zip',
        'application/zip',
      );

  void _ensureSupported() {
    if (kIsWeb) {
      throw const ExportUnsupportedException();
    }
  }

  Future<void> _shareText(String content, String filename, String mime) async {
    _ensureSupported();
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, filename));
    await file.writeAsString(content);
    await Share.shareXFiles([XFile(file.path, mimeType: mime)]);
  }

  Future<void> _shareBytes(List<int> bytes, String filename, String mime) async {
    _ensureSupported();
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, filename));
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path, mimeType: mime)]);
  }
}

final exportServiceProvider = Provider<ExportService>((ref) => ExportService());

/// Lançada quando export/compartilhamento não é suportado (ex.: preview web).
class ExportUnsupportedException implements Exception {
  const ExportUnsupportedException();

  @override
  String toString() =>
      'Exportação e compartilhamento estão disponíveis apenas no app Android.';
}
