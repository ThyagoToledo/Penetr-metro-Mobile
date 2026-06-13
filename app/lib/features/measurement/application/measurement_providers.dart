import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/repository_factory.dart';
import '../domain/entities/measurement.dart';
import '../domain/repositories/measurement_repository.dart';

/// Provider do repositório de medições.
///
/// A implementação é escolhida por plataforma (Drift/SQLite no celular,
/// em memória na web) via [createMeasurementRepository] — DI por Riverpod.
final measurementRepositoryProvider = Provider<MeasurementRepository>((ref) {
  return createMeasurementRepository();
});

/// Lista reativa de medições.
final measurementsProvider =
    AsyncNotifierProvider<MeasurementsNotifier, List<Measurement>>(
  MeasurementsNotifier.new,
);

class MeasurementsNotifier extends AsyncNotifier<List<Measurement>> {
  MeasurementRepository get _repo => ref.read(measurementRepositoryProvider);

  @override
  Future<List<Measurement>> build() => _repo.getAll();

  Future<Measurement> add(Measurement measurement) async {
    final saved = await _repo.save(measurement);
    ref.invalidateSelf();
    await future;
    return saved;
  }

  Future<void> remove(int id) async {
    await _repo.delete(id);
    ref.invalidateSelf();
    await future;
  }
}

/// Estatísticas simples derivadas da lista (total + coeficiente médio).
final measurementStatsProvider = Provider<({int total, double average})>((ref) {
  final async = ref.watch(measurementsProvider);
  final list = async.valueOrNull ?? const [];
  if (list.isEmpty) return (total: 0, average: 0.0);
  final sum = list.fold<double>(0, (s, m) => s + m.coefficient);
  return (total: list.length, average: sum / list.length);
});
