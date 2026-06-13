import 'penetrometer_type.dart';
import '../calculators/impact_penetrometer_calculator.dart';
import '../calculators/pressure_penetrometer_calculator.dart';
import '../services/soil_diagnosis_service.dart';

/// Entidade de domínio que representa uma medição de penetrômetro.
///
/// Espelha a entidade Java `Metering` (tabela `MEDICOES`) e acrescenta
/// campos de suporte ao app mobile (projeto, sync, soft-delete). Imutável.
class Measurement {
  const Measurement({
    this.id,
    this.remoteId,
    this.projectId,
    required this.type,
    required this.impactsQuantity,
    this.pressureMpa,
    required this.deep,
    required this.coefficient,
    required this.floorResistance,
    required this.latitude,
    required this.longitude,
    this.place,
    this.nameCollector,
    this.meteringDate,
    this.systemDate,
    this.systemInfo,
  });

  final int? id;
  final String? remoteId;
  final int? projectId;

  final PenetrometerType type;

  /// Impacto: número de impactos (N). Pressão: MPa×100 (compat. desktop).
  final int impactsQuantity;

  /// Leitura explícita em MPa (apenas pressão; melhoria mobile).
  final double? pressureMpa;

  /// Profundidade em cm.
  final double deep;

  /// Coeficiente de resistência (kgf/cm²).
  final double coefficient;

  /// Diagnóstico textual (coluna `RESISTENCIA_SOLO`).
  final String floorResistance;

  final double latitude;
  final double longitude;
  final String? place;
  final String? nameCollector;

  final DateTime? meteringDate;
  final DateTime? systemDate;
  final String? systemInfo;

  /// Cria uma medição de **impacto** aplicando a Equação de Stolf e o
  /// diagnóstico — equivalente ao `save()` do `ImpactPenetrometerController`.
  factory Measurement.impact({
    required int impacts,
    required double deep,
    required double latitude,
    required double longitude,
    String? place,
    String? nameCollector,
    DateTime? meteringDate,
    int? projectId,
  }) {
    final coefficient = ImpactPenetrometerCalculator.calculateCoefficient(impacts);
    return Measurement(
      type: PenetrometerType.impact,
      impactsQuantity: impacts,
      deep: deep,
      coefficient: coefficient,
      floorResistance: SoilDiagnosisService.diagnose(coefficient),
      latitude: latitude,
      longitude: longitude,
      place: place,
      nameCollector: nameCollector,
      meteringDate: meteringDate,
      projectId: projectId,
    );
  }

  /// Cria uma medição de **pressão** convertendo MPa→kgf/cm² e aplicando o
  /// diagnóstico — equivalente ao `save()` do `PressurePenetrometerController`,
  /// inclusive o armazenamento de `impactsQuantity = MPa×100`.
  factory Measurement.pressure({
    required double pressureMpa,
    required double deep,
    required double latitude,
    required double longitude,
    String? place,
    String? nameCollector,
    DateTime? meteringDate,
    int? projectId,
  }) {
    final coefficient =
        PressurePenetrometerCalculator.calculateCoefficient(pressureMpa);
    return Measurement(
      type: PenetrometerType.pressure,
      impactsQuantity:
          PressurePenetrometerCalculator.encodePressureAsImpacts(pressureMpa),
      pressureMpa: pressureMpa,
      deep: deep,
      coefficient: coefficient,
      floorResistance: SoilDiagnosisService.diagnose(coefficient),
      latitude: latitude,
      longitude: longitude,
      place: place,
      nameCollector: nameCollector,
      meteringDate: meteringDate,
      projectId: projectId,
    );
  }

  /// Leitura em MPa: usa o campo explícito quando presente; caso contrário,
  /// decodifica do `impactsQuantity` (registros vindos do desktop).
  double get effectivePressureMpa =>
      pressureMpa ??
      PressurePenetrometerCalculator.decodePressureFromImpacts(impactsQuantity);

  /// Interpretação técnica para relatórios.
  String get interpretation =>
      SoilDiagnosisService.interpret(coefficient, type);

  Measurement copyWith({
    int? id,
    String? remoteId,
    int? projectId,
    PenetrometerType? type,
    int? impactsQuantity,
    double? pressureMpa,
    double? deep,
    double? coefficient,
    String? floorResistance,
    double? latitude,
    double? longitude,
    String? place,
    String? nameCollector,
    DateTime? meteringDate,
    DateTime? systemDate,
    String? systemInfo,
  }) {
    return Measurement(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      projectId: projectId ?? this.projectId,
      type: type ?? this.type,
      impactsQuantity: impactsQuantity ?? this.impactsQuantity,
      pressureMpa: pressureMpa ?? this.pressureMpa,
      deep: deep ?? this.deep,
      coefficient: coefficient ?? this.coefficient,
      floorResistance: floorResistance ?? this.floorResistance,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      place: place ?? this.place,
      nameCollector: nameCollector ?? this.nameCollector,
      meteringDate: meteringDate ?? this.meteringDate,
      systemDate: systemDate ?? this.systemDate,
      systemInfo: systemInfo ?? this.systemInfo,
    );
  }
}
