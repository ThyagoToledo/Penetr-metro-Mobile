import '../entities/measurement.dart';
import '../entities/penetrometer_type.dart';

/// Contrato de persistência de medições (Repository Pattern).
///
/// A implementação atual é em memória ([InMemoryMeasurementRepository]) e será
/// substituída por Drift/SQLite na fase F2 — sem impacto na camada de domínio.
abstract interface class MeasurementRepository {
  Future<List<Measurement>> getAll();
  Future<List<Measurement>> getByType(PenetrometerType type);
  Future<Measurement?> getById(int id);
  Future<Measurement> save(Measurement measurement);
  Future<void> delete(int id);
  Future<int> count();
  Future<double> averageCoefficient();
}
