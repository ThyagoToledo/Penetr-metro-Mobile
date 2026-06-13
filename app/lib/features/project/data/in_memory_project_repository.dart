import '../domain/project.dart';
import '../domain/project_repository.dart';

/// Implementação em memória do [ProjectRepository] — usada em testes de widget.
class InMemoryProjectRepository implements ProjectRepository {
  final List<Project> _items = [];
  int _nextId = 1;

  @override
  Future<List<Project>> getAll({bool includeArchived = true}) async {
    return _items
        .where((p) => includeArchived || !p.archived)
        .toList()
        .reversed
        .toList();
  }

  @override
  Future<Project?> getById(int id) async {
    for (final p in _items) {
      if (p.id == id) return p;
    }
    return null;
  }

  @override
  Future<Project> save(Project project) async {
    if (project.id == null) {
      final saved = project.copyWith(
        id: _nextId++,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _items.add(saved);
      return saved;
    }
    final index = _items.indexWhere((p) => p.id == project.id);
    if (index >= 0) _items[index] = project;
    return project;
  }

  @override
  Future<void> setArchived(int id, {required bool archived}) async {
    final index = _items.indexWhere((p) => p.id == id);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(archived: archived);
    }
  }

  @override
  Future<Project> duplicate(int id) async {
    final original = await getById(id);
    if (original == null) throw StateError('Projeto $id não encontrado.');
    return save(
      Project(name: '${original.name} (cópia)', description: original.description),
    );
  }

  @override
  Future<void> delete(int id) async {
    _items.removeWhere((p) => p.id == id);
  }
}
