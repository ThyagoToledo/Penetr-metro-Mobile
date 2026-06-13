import 'package:flutter_test/flutter_test.dart';
import 'package:penetrometro/features/measurement/domain/entities/penetrometer_type.dart';
import 'package:penetrometro/features/measurement/domain/services/soil_diagnosis_service.dart';

void main() {
  group('Interpretação técnica — impacto', () {
    test('faixas <10/<25/<40/else', () {
      expect(SoilDiagnosisService.interpret(5, PenetrometerType.impact),
          contains('baixa resistência'),);
      expect(SoilDiagnosisService.interpret(20, PenetrometerType.impact),
          contains('moderada'),);
      expect(SoilDiagnosisService.interpret(30, PenetrometerType.impact),
          contains('elevada'),);
      expect(SoilDiagnosisService.interpret(50, PenetrometerType.impact),
          contains('altamente compactado'),);
    });
  });

  group('Interpretação técnica — pressão', () {
    test('faixas <5/<15/<30/else', () {
      expect(SoilDiagnosisService.interpret(3, PenetrometerType.pressure),
          contains('boa estrutura'),);
      expect(SoilDiagnosisService.interpret(10, PenetrometerType.pressure),
          contains('condições normais'),);
      expect(SoilDiagnosisService.interpret(20, PenetrometerType.pressure),
          contains('compactado'),);
      expect(SoilDiagnosisService.interpret(40, PenetrometerType.pressure),
          contains('severamente compactado'),);
    });
  });

  group('PenetrometerType.fromDbValue', () {
    test('mapeia textos e usa impact como fallback', () {
      expect(PenetrometerType.fromDbValue('IMPACT'), PenetrometerType.impact);
      expect(
          PenetrometerType.fromDbValue('PRESSURE'), PenetrometerType.pressure,);
      expect(PenetrometerType.fromDbValue(null), PenetrometerType.impact);
      expect(PenetrometerType.fromDbValue('xpto'), PenetrometerType.impact);
    });
  });

  group('Análise por média', () {
    test('faixas da média', () {
      expect(SoilDiagnosisService.analyzeAverage(5), contains('adequado'));
      expect(SoilDiagnosisService.analyzeAverage(15), contains('moderada'));
      expect(SoilDiagnosisService.analyzeAverage(25), contains('alta'));
      expect(SoilDiagnosisService.analyzeAverage(50), contains('extremamente'));
    });
  });
}
