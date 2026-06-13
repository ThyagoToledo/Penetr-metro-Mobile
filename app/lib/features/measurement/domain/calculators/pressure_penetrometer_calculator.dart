/// Calculadora do penetrômetro de pressão.
///
/// Porte fiel de `PressurePenetrometerCalculator.java`. Converte a leitura
/// do manômetro (MPa) em coeficiente de resistência (kgf/cm²):
///
/// ```
/// coef = leituraMPa × 10.1972      (1 MPa = 10.1972 kgf/cm²)
/// ```
abstract final class PressurePenetrometerCalculator {
  /// Fator de conversão de MPa para kgf/cm².
  static const double mpaToKgfCm2 = 10.1972;

  /// Profundidades padrão (cm) oferecidas pelo desktop (`getStandardDepths`).
  static const List<int> standardDepths = [5, 10, 15, 20, 40];

  /// Converte a leitura em MPa para o coeficiente em kgf/cm².
  static double calculateCoefficient(double pressureReadingMpa) {
    return pressureReadingMpa * mpaToKgfCm2;
  }

  /// Workaround de compatibilidade com o desktop: a leitura em MPa é
  /// persistida em `QUANTIDADE_IMPACTOS` como centésimos de MPa
  /// (`impactsQuantity = (int)(MPa * 100)`).
  static int encodePressureAsImpacts(double pressureReadingMpa) {
    return (pressureReadingMpa * 100).toInt();
  }

  /// Recupera a leitura original em MPa a partir do valor persistido.
  static double decodePressureFromImpacts(int impactsQuantity) {
    return impactsQuantity / 100.0;
  }
}
