import 'project.dart';

/// Contrato de persistência de projetos (Repository Pattern).
abstract interface class ProjectRepository {
  Future<List<Project>> getAll({bool includeArchived = true});
  Future<Project?> getById(int id);
  Future<Project> save(Project project);
  Future<void> setArchived(int id, {required bool archived});
  Future<Project> duplicate(int id);
  Future<void> delete(int id);
}
