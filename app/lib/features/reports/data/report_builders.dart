import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';

import '../../measurement/domain/entities/measurement.dart';
import '../../measurement/domain/entities/penetrometer_type.dart';

/// Construtores puros de exportações (sem IO/plataforma) — testáveis isoladamente.
abstract final class ReportBuilders {
  static const List<String> headers = [
    'id',
    'tipo',
    'impactos',
    'pressao_mpa',
    'profundidade_cm',
    'coeficiente_kgfcm2',
    'diagnostico',
    'latitude',
    'longitude',
    'local',
    'coletor',
    'data_medicao',
  ];

  static Map<String, dynamic> toMap(Measurement m) => {
        'id': m.id,
        'tipo': m.type.dbValue,
        'impactos':
            m.type == PenetrometerType.impact ? m.impactsQuantity : null,
        'pressao_mpa': m.type == PenetrometerType.pressure
            ? m.effectivePressureMpa
            : null,
        'profundidade_cm': m.deep,
        'coeficiente_kgfcm2': m.coefficient,
        'diagnostico': m.floorResistance,
        'latitude': m.latitude,
        'longitude': m.longitude,
        'local': m.place,
        'coletor': m.nameCollector,
        'data_medicao': m.meteringDate?.toIso8601String(),
      };

  static List<dynamic> _toRow(Measurement m) {
    final map = toMap(m);
    return headers.map((h) => map[h] ?? '').toList();
  }

  /// CSV (cabeçalho + uma linha por medição).
  static String buildCsv(List<Measurement> items) {
    final rows = <List<dynamic>>[
      headers,
      ...items.map(_toRow),
    ];
    return const ListToCsvConverter().convert(rows);
  }

  /// JSON com metadados + lista de medições.
  static String buildJson(List<Measurement> items) {
    final payload = {
      'app': 'penetrometro',
      'schema': 1,
      'exportedCount': items.length,
      'measurements': items.map(toMap).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Planilha Excel (.xlsx) das medições.
  static List<int> buildExcel(List<Measurement> items) {
    final excel = Excel.createExcel();
    final sheet = excel['Medicoes'];
    excel.setDefaultSheet('Medicoes');
    sheet.appendRow(headers.map<CellValue?>((h) => TextCellValue(h)).toList());
    for (final m in items) {
      sheet.appendRow(
        _toRow(m).map<CellValue?>((v) => TextCellValue('$v')).toList(),
      );
    }
    return excel.save() ?? <int>[];
  }

  /// Backup compactado (.zip) contendo o JSON completo.
  /// A criptografia do backup é aplicada na fase F7.
  static List<int> buildBackupZip(List<Measurement> items) {
    final json = buildJson(items);
    final jsonBytes = utf8.encode(json);
    final archive = Archive()
      ..addFile(ArchiveFile('backup.json', jsonBytes.length, jsonBytes));
    return ZipEncoder().encode(archive) ?? <int>[];
  }
}
