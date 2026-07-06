import 'dart:convert';

import 'package:archive/archive.dart';

import '../../measurement/domain/calculators/pressure_penetrometer_calculator.dart';
import '../../measurement/domain/entities/measurement.dart';
import '../../measurement/domain/entities/penetrometer_type.dart';
import '../../measurement/domain/services/soil_diagnosis_service.dart';

/// Lê exportações do próprio app (JSON e backup .zip) de volta para o domínio.
/// Contraparte de `ReportBuilders` — funções puras, sem IO.
abstract final class BackupImporter {
  static List<Measurement> parseJsonExport(String jsonString) {
    final dynamic decoded = jsonDecode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Arquivo não é um export deste app.');
    }
    if (decoded['app'] != 'penetrometro') {
      throw const FormatException('Arquivo não é um export deste app.');
    }
    final items = decoded['measurements'];
    if (items is! List) {
      throw const FormatException('Export sem lista de medições.');
    }
    return items
        .whereType<Map<String, dynamic>>()
        .map(_measurementFromMap)
        .toList();
  }

  static List<Measurement> parseBackupZip(List<int> zipBytes) {
    final archive = ZipDecoder().decodeBytes(zipBytes);
    final entry = archive.files.where((f) => f.name == 'backup.json');
    if (entry.isEmpty) {
      throw const FormatException('Backup sem o arquivo backup.json.');
    }
    final jsonString = utf8.decode(entry.first.content as List<int>);
    return parseJsonExport(jsonString);
  }

  static Measurement _measurementFromMap(Map<String, dynamic> map) {
    final coefficient = (map['coeficiente_kgfcm2'] as num?)?.toDouble();
    if (coefficient == null) {
      throw const FormatException('Medição sem coeficiente.');
    }
    final type = PenetrometerType.fromDbValue(map['tipo'] as String?);
    final pressureMpa = (map['pressao_mpa'] as num?)?.toDouble();
    final impacts = (map['impactos'] as num?)?.toInt();
    final dateRaw = map['data_medicao'];

    return Measurement(
      type: type,
      impactsQuantity: impacts ??
          PressurePenetrometerCalculator.encodePressureAsImpacts(
            pressureMpa ?? 0,
          ),
      pressureMpa: pressureMpa,
      deep: (map['profundidade_cm'] as num?)?.toDouble() ?? 0,
      coefficient: coefficient,
      floorResistance: (map['diagnostico'] as String?) ??
          SoilDiagnosisService.diagnose(coefficient),
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
      place: map['local'] as String?,
      nameCollector: map['coletor'] as String?,
      meteringDate: dateRaw is String ? DateTime.tryParse(dateRaw) : null,
    );
  }
}
