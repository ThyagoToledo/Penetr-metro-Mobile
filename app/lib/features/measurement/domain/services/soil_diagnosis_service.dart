import '../entities/penetrometer_type.dart';

/// Diagnóstico e interpretação textual do solo a partir do coeficiente.
///
/// Porte fiel das regras dos controllers JavaFX (`getDiagnosis`) e do
/// `PDFGeneratorService` (`getInterpretation`). **Não alterar os limiares**
/// sem revisar a paridade com o sistema desktop (coberto por testes).
abstract final class SoilDiagnosisService {
  /// Diagnóstico textual — idêntico para impacto e pressão.
  ///
  /// Faixas (kgf/cm²): `<10` adequado · `<=20` moderada · `<=30` alta ·
  /// `<=40` compactado · `>40` extremamente compactado.
  static String diagnose(double coefficient) {
    if (coefficient < 10) {
      return 'Solo adequado para cultivo';
    } else if (coefficient <= 20) {
      return 'Solo com resistência moderada';
    } else if (coefficient <= 30) {
      return 'Solo com alta resistência';
    } else if (coefficient <= 40) {
      return 'Solo compactado';
    } else {
      return 'Solo extremamente compactado';
    }
  }

  /// Interpretação técnica detalhada (usada no relatório) — faixas
  /// específicas por tipo de penetrômetro (`getInterpretation`).
  static String interpret(double coefficient, PenetrometerType type) {
    if (type == PenetrometerType.impact) {
      if (coefficient < 10) {
        return 'Solo com baixa resistência à penetração. Condições favoráveis '
            'para desenvolvimento radicular. Recomenda-se atenção à erosão.';
      } else if (coefficient < 25) {
        return 'Solo com resistência moderada. Condições adequadas para a '
            'maioria das culturas. Monitorar compactação em áreas de tráfego.';
      } else if (coefficient < 40) {
        return 'Solo com resistência elevada. Pode haver restrição ao '
            'crescimento radicular. Considerar práticas de descompactação.';
      } else {
        return 'Solo altamente compactado. Provável impedimento ao '
            'desenvolvimento de raízes. Recomenda-se subsolagem ou escarificação.';
      }
    } else {
      if (coefficient < 5) {
        return 'Pressão baixa indicando solo com boa estrutura e porosidade. '
            'Favorável para infiltração de água e ar.';
      } else if (coefficient < 15) {
        return 'Pressão moderada indicando solo em condições normais de '
            'compactação. Adequado para culturas agrícolas.';
      } else if (coefficient < 30) {
        return 'Pressão alta indicando solo compactado. Pode limitar o '
            'desenvolvimento das plantas.';
      } else {
        return 'Pressão muito alta indicando solo severamente compactado. '
            'Necessita intervenção urgente.';
      }
    }
  }

  /// Análise geral por coeficiente médio (porte de `analyzeResults`).
  static String analyzeAverage(double averageCoefficient) {
    if (averageCoefficient < 10) {
      return 'Análise geral: Solo adequado para cultivo';
    } else if (averageCoefficient <= 20) {
      return 'Análise geral: Solo com resistência moderada';
    } else if (averageCoefficient <= 30) {
      return 'Análise geral: Solo com alta resistência';
    } else {
      return 'Análise geral: Solo extremamente compactado';
    }
  }
}
