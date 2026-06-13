import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:penetrometro/features/measurement/domain/entities/measurement.dart';
import 'package:penetrometro/features/reports/data/pdf_report_generator.dart';
import 'package:penetrometro/features/reports/data/report_builders.dart';

void main() {
  final sample = <Measurement>[
    Measurement.impact(
      impacts: 5,
      deep: 20,
      latitude: -16.5,
      longitude: -49.2,
      place: 'Talhao 1',
      nameCollector: 'Ana',
      meteringDate: DateTime(2026, 6, 13),
    ).copyWith(id: 1),
    Measurement.pressure(
      pressureMpa: 2.5,
      deep: 10,
      latitude: -16.6,
      longitude: -49.3,
      place: 'Talhao 2',
      nameCollector: 'Beto',
      meteringDate: DateTime(2026, 6, 12),
    ).copyWith(id: 2),
  ];

  test('CSV contém cabeçalho e dados', () {
    final csv = ReportBuilders.buildCsv(sample);
    expect(csv, contains('coeficiente_kgfcm2'));
    expect(csv, contains('40.05')); // impacto N=5
    expect(csv, contains('Ana'));
    expect(csv, contains('PRESSURE'));
  });

  test('JSON é válido e completo', () {
    final json = ReportBuilders.buildJson(sample);
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    expect(decoded['exportedCount'], 2);
    final list = decoded['measurements'] as List;
    expect(list.length, 2);
    expect((list.first as Map)['tipo'], 'IMPACT');
  });

  test('Excel gera um arquivo .xlsx (zip, magic PK)', () {
    final bytes = ReportBuilders.buildExcel(sample);
    expect(bytes.length, greaterThan(0));
    expect(bytes[0], 0x50); // 'P'
    expect(bytes[1], 0x4B); // 'K'
  });

  test('Backup .zip é gerado (magic PK)', () {
    final bytes = ReportBuilders.buildBackupZip(sample);
    expect(bytes.length, greaterThan(0));
    expect(bytes[0], 0x50);
    expect(bytes[1], 0x4B);
  });

  test('PDF é gerado com cabeçalho %PDF', () async {
    final bytes = await PdfReportGenerator.build(sample.first);
    expect(bytes.length, greaterThan(0));
    expect(String.fromCharCodes(bytes.sublist(0, 4)), '%PDF');
  });
}
