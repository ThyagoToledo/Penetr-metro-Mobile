import 'package:flutter_test/flutter_test.dart';
import 'package:penetrometro/features/measurement/domain/entities/measurement.dart';
import 'package:penetrometro/features/measurement/domain/entities/penetrometer_type.dart';
import 'package:penetrometro/features/reports/data/backup_importer.dart';
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

  test('round-trip JSON: export -> import preserva os dados', () {
    final json = ReportBuilders.buildJson(sample);
    final imported = BackupImporter.parseJsonExport(json);

    expect(imported.length, 2);
    final impact = imported[0];
    expect(impact.type, PenetrometerType.impact);
    expect(impact.impactsQuantity, 5);
    expect(impact.coefficient, closeTo(40.05, 1e-9));
    expect(impact.nameCollector, 'Ana');
    expect(impact.meteringDate, DateTime(2026, 6, 13));

    final pressure = imported[1];
    expect(pressure.type, PenetrometerType.pressure);
    expect(pressure.effectivePressureMpa, closeTo(2.5, 1e-9));
    expect(pressure.impactsQuantity, 250);
    expect(pressure.floorResistance, 'Solo com alta resistência');
  });

  test('round-trip ZIP: backup -> import preserva os dados', () {
    final zip = ReportBuilders.buildBackupZip(sample);
    final imported = BackupImporter.parseBackupZip(zip);
    expect(imported.length, 2);
    expect(imported[0].coefficient, closeTo(40.05, 1e-9));
  });

  test('rejeita JSON que não é export do app', () {
    expect(
      () => BackupImporter.parseJsonExport('{"foo": 1}'),
      throwsFormatException,
    );
    expect(
      () => BackupImporter.parseJsonExport('[1,2]'),
      throwsFormatException,
    );
  });
}
