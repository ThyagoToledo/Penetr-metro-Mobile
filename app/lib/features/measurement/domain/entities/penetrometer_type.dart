/// Tipos de medição de penetrômetro.
///
/// Porte fiel do enum Java `MeteringType`
/// (`br.edu.ifgoiano.penetrometerproject.model.MeteringType`).
/// O valor [dbValue] corresponde ao texto persistido na coluna
/// `TIPO_MEDICAO` (`IMPACT` / `PRESSURE`) — preservado para
/// interoperabilidade com bases do sistema desktop.
enum PenetrometerType {
  impact('IMPACT', 'Penetrômetro de Impacto'),
  pressure('PRESSURE', 'Penetrômetro de Pressão');

  const PenetrometerType(this.dbValue, this.description);

  /// Valor persistido no banco (compatível com o desktop).
  final String dbValue;

  /// Descrição legível (idêntica ao desktop).
  final String description;

  /// Converte o texto do banco no enum, com fallback para [impact]
  /// (o desktop usa IMPACT como tipo padrão).
  static PenetrometerType fromDbValue(String? value) {
    return PenetrometerType.values.firstWhere(
      (t) => t.dbValue == value,
      orElse: () => PenetrometerType.impact,
    );
  }
}
