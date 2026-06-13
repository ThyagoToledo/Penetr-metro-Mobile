import 'package:flutter_test/flutter_test.dart';
import 'package:penetrometro/features/measurement/domain/calculators/impact_penetrometer_calculator.dart';
import 'package:penetrometro/features/measurement/domain/calculators/pressure_penetrometer_calculator.dart';
import 'package:penetrometro/features/measurement/domain/entities/measurement.dart';
import 'package:penetrometro/features/measurement/domain/entities/penetrometer_type.dart';
import 'package:penetrometro/features/measurement/domain/services/soil_diagnosis_service.dart';

/// Testes que travam a **paridade científica** com o sistema desktop Java.
/// Qualquer alteração de fórmula/limiar deve falhar aqui de propósito.
void main() {
  group('Equação de Stolf (impacto)', () {
    test('R = 5.6 + 6.89 * N', () {
      expect(ImpactPenetrometerCalculator.calculateCoefficient(1),
          closeTo(12.49, 1e-9),);
      expect(ImpactPenetrometerCalculator.calculateCoefficient(5),
          closeTo(40.05, 1e-9),);
      expect(ImpactPenetrometerCalculator.calculateCoefficient(10),
          closeTo(74.5, 1e-9),);
    });

    test('N <= 0 retorna 0.0 (regra de borda do original)', () {
      expect(ImpactPenetrometerCalculator.calculateCoefficient(0), 0.0);
      expect(ImpactPenetrometerCalculator.calculateCoefficient(-3), 0.0);
    });

    test('variante calibrável', () {
      expect(
        ImpactPenetrometerCalculator.calculateCoefficientCalibrated(4, 5.0, 7.0),
        closeTo(33.0, 1e-9),
      );
    });
  });

  group('Conversão de pressão', () {
    test('1 MPa = 10.1972 kgf/cm²', () {
      expect(PressurePenetrometerCalculator.calculateCoefficient(1.0),
          closeTo(10.1972, 1e-9),);
      expect(PressurePenetrometerCalculator.calculateCoefficient(2.5),
          closeTo(25.493, 1e-9),);
    });

    test('profundidades padrão', () {
      expect(PressurePenetrometerCalculator.standardDepths,
          [5, 10, 15, 20, 40],);
    });

    test('quirk de compatibilidade: MPa<->impactsQuantity (×100)', () {
      expect(PressurePenetrometerCalculator.encodePressureAsImpacts(2.5), 250);
      expect(
        PressurePenetrometerCalculator.decodePressureFromImpacts(250),
        closeTo(2.5, 1e-9),
      );
    });
  });

  group('Diagnóstico textual (controllers)', () {
    test('faixas exatas', () {
      expect(SoilDiagnosisService.diagnose(9.99), 'Solo adequado para cultivo');
      expect(SoilDiagnosisService.diagnose(10), 'Solo com resistência moderada');
      expect(SoilDiagnosisService.diagnose(20), 'Solo com resistência moderada');
      expect(SoilDiagnosisService.diagnose(20.01), 'Solo com alta resistência');
      expect(SoilDiagnosisService.diagnose(30), 'Solo com alta resistência');
      expect(SoilDiagnosisService.diagnose(30.01), 'Solo compactado');
      expect(SoilDiagnosisService.diagnose(40), 'Solo compactado');
      expect(SoilDiagnosisService.diagnose(40.01),
          'Solo extremamente compactado',);
    });
  });

  group('Fábricas de Measurement (paridade com save() dos controllers)', () {
    test('impacto calcula coeficiente e diagnóstico', () {
      final m = Measurement.impact(
        impacts: 5,
        deep: 20,
        latitude: -16.0,
        longitude: -49.0,
      );
      expect(m.type, PenetrometerType.impact);
      expect(m.coefficient, closeTo(40.05, 1e-9));
      expect(m.floorResistance, 'Solo extremamente compactado');
    });

    test('pressão converte, codifica impactsQuantity e diagnostica', () {
      final m = Measurement.pressure(
        pressureMpa: 2.5,
        deep: 10,
        latitude: -16.0,
        longitude: -49.0,
      );
      expect(m.type, PenetrometerType.pressure);
      expect(m.coefficient, closeTo(25.493, 1e-9));
      expect(m.impactsQuantity, 250);
      expect(m.effectivePressureMpa, closeTo(2.5, 1e-9));
      expect(m.floorResistance, 'Solo com alta resistência');
    });
  });
}
