import '../domain/entities/measurement.dart';
import '../domain/entities/penetrometer_type.dart';
import '../domain/repositories/measurement_repository.dart';

/// Implementação temporária em memória do [MeasurementRepository].
///
/// Permite o app funcionar de ponta a ponta (criar → listar → excluir) antes
/// da camada Drift/SQLite (F2). Os dados não persistem entre execuções.
class InMemoryMeasurementRepository implements MeasurementRepository {
  final List<Measurement> _items = [];
  int _nextId = 1;

  @override
  Future<List<Measurement>> getAll() async {
    final sorted = [..._items];
    sorted.sort((a, b) {
      final da = a.meteringDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      final db = b.meteringDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      return db.compareTo(da);
    });
    return sorted;
  }

  @override
  Future<List<Measurement>> getByType(PenetrometerType type) async {
    final all = await getAll();
    return all.where((m) => m.type == type).toList();
  }

  @override
  Future<Measurement?> getById(int id) async {
    for (final m in _items) {
      if (m.id == id) return m;
    }
    return null;
  }

  @override
  Future<Measurement> save(Measurement measurement) async {
    if (measurement.id == null) {
      final saved = measurement.copyWith(
        id: _nextId++,
        systemDate: DateTime.now(),
        meteringDate: measurement.meteringDate ?? DateTime.now(),
        systemInfo: 'Android',
      );
      _items.add(saved);
      return saved;
    } else {
      final index = _items.indexWhere((m) => m.id == measurement.id);
      if (index >= 0) {
        _items[index] = measurement;
      }
      return measurement;
    }
  }

  @override
  Future<void> delete(int id) async {
    _items.removeWhere((m) => m.id == id);
  }

  @override
  Future<int> count() async => _items.length;

  @override
  Future<double> averageCoefficient() async {
    if (_items.isEmpty) return 0.0;
    final sum = _items.fold<double>(0, (s, m) => s + m.coefficient);
    return sum / _items.length;
  }
}
