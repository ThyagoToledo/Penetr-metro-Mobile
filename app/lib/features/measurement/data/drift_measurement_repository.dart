import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/entities/measurement.dart';
import '../domain/entities/penetrometer_type.dart';
import '../domain/repositories/measurement_repository.dart';

/// Implementação do [MeasurementRepository] sobre Drift/SQLite.
///
/// Exclusão é lógica (soft delete via `deletedAt`) para preservar histórico e
/// permitir sincronização/versionamento com o Google Drive (F6).
class DriftMeasurementRepository implements MeasurementRepository {
  DriftMeasurementRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<Measurement>> getAll() async {
    final rows = await (_db.select(_db.measurements)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.meteringDate,
                  mode: OrderingMode.desc,
                ),
          ]))
        .get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<List<Measurement>> getByType(PenetrometerType type) async {
    final rows = await (_db.select(_db.measurements)
          ..where((t) =>
              t.meteringType.equals(type.dbValue) & t.deletedAt.isNull(),)
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.meteringDate,
                  mode: OrderingMode.desc,
                ),
          ]))
        .get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<Measurement?> getById(int id) async {
    final row = await (_db.select(_db.measurements)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<Measurement> save(Measurement m) async {
    final now = DateTime.now();
    if (m.id == null) {
      final id = await _db.into(_db.measurements).insert(
            MeasurementsCompanion.insert(
              meteringType: m.type.dbValue,
              deep: m.deep,
              coefficient: m.coefficient,
              latitude: m.latitude,
              longitude: m.longitude,
              impactsQuantity: Value(m.impactsQuantity),
              pressureMpa: Value(m.pressureMpa),
              floorResistance: Value(m.floorResistance),
              place: Value(m.place),
              nameCollector: Value(m.nameCollector),
              meteringDate: Value(m.meteringDate ?? now),
              systemDate: Value(m.systemDate ?? now),
              systemInfo: Value(m.systemInfo ?? 'Android'),
              projectId: Value(m.projectId),
            ),
          );
      await _audit('create', id);
      return m.copyWith(id: id, systemDate: m.systemDate ?? now);
    } else {
      await (_db.update(_db.measurements)..where((t) => t.id.equals(m.id!)))
          .write(
        MeasurementsCompanion(
          meteringType: Value(m.type.dbValue),
          deep: Value(m.deep),
          coefficient: Value(m.coefficient),
          latitude: Value(m.latitude),
          longitude: Value(m.longitude),
          impactsQuantity: Value(m.impactsQuantity),
          pressureMpa: Value(m.pressureMpa),
          floorResistance: Value(m.floorResistance),
          place: Value(m.place),
          nameCollector: Value(m.nameCollector),
          meteringDate: Value(m.meteringDate),
          projectId: Value(m.projectId),
          updatedAt: Value(now),
          dirty: const Value(true),
        ),
      );
      await _audit('update', m.id);
      return m;
    }
  }

  @override
  Future<void> delete(int id) async {
    await (_db.update(_db.measurements)..where((t) => t.id.equals(id))).write(
      MeasurementsCompanion(
        deletedAt: Value(DateTime.now()),
        dirty: const Value(true),
      ),
    );
    await _audit('delete', id);
  }

  Future<void> _audit(String action, int? entityId) async {
    await _db.into(_db.auditLogs).insert(
          AuditLogsCompanion.insert(
            entity: 'measurement',
            action: action,
            entityId: Value(entityId),
          ),
        );
  }

  @override
  Future<int> count() async => (await getAll()).length;

  @override
  Future<double> averageCoefficient() async {
    final all = await getAll();
    if (all.isEmpty) return 0;
    final sum = all.fold<double>(0, (s, m) => s + m.coefficient);
    return sum / all.length;
  }

  Measurement _toDomain(MeasurementRow r) => Measurement(
        id: r.id,
        remoteId: r.remoteId,
        projectId: r.projectId,
        type: PenetrometerType.fromDbValue(r.meteringType),
        impactsQuantity: r.impactsQuantity,
        pressureMpa: r.pressureMpa,
        deep: r.deep,
        coefficient: r.coefficient,
        floorResistance: r.floorResistance ?? '',
        latitude: r.latitude,
        longitude: r.longitude,
        place: r.place,
        nameCollector: r.nameCollector,
        meteringDate: r.meteringDate,
        systemDate: r.systemDate,
        systemInfo: r.systemInfo,
      );
}
