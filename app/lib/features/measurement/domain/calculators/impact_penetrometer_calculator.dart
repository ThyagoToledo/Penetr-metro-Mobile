/// Calculadora do penetrômetro de impacto — **Equação de Stolf**.
///
/// Porte fiel de `ImpactPenetrometerCalculator.java`. A fórmula é:
///
/// ```
/// R = 5.6 + 6.89 × N
/// ```
///
/// onde `R` é a resistência à penetração (kgf/cm²) e `N` o número de
/// impactos. A profundidade **não** entra na equação (é apenas registrada).
///
/// Regra de borda preservada do original: `N <= 0` ⇒ retorna `0.0`.
abstract final class ImpactPenetrometerCalculator {
  /// Constante aditiva da Equação de Stolf (`DEFAULT_FACTOR`).
  static const double defaultFactor = 5.6;

  /// Constante multiplicativa da Equação de Stolf (`DEFAULT_OFFSET`).
  static const double defaultOffset = 6.89;

  /// Calcula o coeficiente (kgf/cm²) a partir do número de impactos.
  static double calculateCoefficient(int impactsQuantity) {
    if (impactsQuantity <= 0) return 0.0;
    // Equação de Stolf: R = 5.6 + 6.89 * N
    return defaultFactor + defaultOffset * impactsQuantity;
  }

  /// Variante calibrável (sobrecarga do original) usando fator/offset
  /// personalizados. Útil para perfis de calibração no app.
  static double calculateCoefficientCalibrated(
    int impactsQuantity,
    double factor,
    double offset,
  ) {
    if (impactsQuantity <= 0) return 0.0;
    return factor + offset * impactsQuantity;
  }
}
