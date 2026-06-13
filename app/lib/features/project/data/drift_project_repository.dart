import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/project.dart';
import '../domain/project_repository.dart';

/// Implementação do [ProjectRepository] sobre Drift/SQLite (exclusão lógica).
class DriftProjectRepository implements ProjectRepository {
  DriftProjectRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<Project>> getAll({bool includeArchived = true}) async {
    final query = _db.select(_db.projects);
    query.where((t) => t.deletedAt.isNull());
    if (!includeArchived) {
      query.where((t) => t.archived.equals(false));
    }
    query.orderBy([
      (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
    ]);
    final rows = await query.get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<Project?> getById(int id) async {
    final row = await (_db.select(_db.projects)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<Project> save(Project p) async {
    final now = DateTime.now();
    if (p.id == null) {
      final id = await _db.into(_db.projects).insert(
            ProjectsCompanion.insert(
              name: p.name,
              description: Value(p.description),
              owner: Value(p.owner),
              remoteId: Value(p.remoteId),
            ),
          );
      return p.copyWith(id: id, createdAt: now, updatedAt: now);
    } else {
      await (_db.update(_db.projects)..where((t) => t.id.equals(p.id!))).write(
        ProjectsCompanion(
          name: Value(p.name),
          description: Value(p.description),
          owner: Value(p.owner),
          updatedAt: Value(now),
        ),
      );
      return p.copyWith(updatedAt: now);
    }
  }

  @override
  Future<void> setArchived(int id, {required bool archived}) async {
    await (_db.update(_db.projects)..where((t) => t.id.equals(id))).write(
      ProjectsCompanion(
        archived: Value(archived),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<Project> duplicate(int id) async {
    final original = await getById(id);
    if (original == null) {
      throw StateError('Projeto $id não encontrado.');
    }
    return save(
      Project(
        name: '${original.name} (cópia)',
        description: original.description,
        owner: original.owner,
      ),
    );
  }

  @override
  Future<void> delete(int id) async {
    await (_db.update(_db.projects)..where((t) => t.id.equals(id))).write(
      ProjectsCompanion(deletedAt: Value(DateTime.now())),
    );
  }

  Project _toDomain(ProjectRow r) => Project(
        id: r.id,
        remoteId: r.remoteId,
        name: r.name,
        description: r.description,
        owner: r.owner,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
        archived: r.archived,
      );
}
