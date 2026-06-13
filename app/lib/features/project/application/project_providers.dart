import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/repository_factory.dart';
import '../domain/project.dart';
import '../domain/project_repository.dart';

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return createProjectRepository();
});

final projectsProvider =
    AsyncNotifierProvider<ProjectsNotifier, List<Project>>(ProjectsNotifier.new);

class ProjectsNotifier extends AsyncNotifier<List<Project>> {
  ProjectRepository get _repo => ref.read(projectRepositoryProvider);

  @override
  Future<List<Project>> build() => _repo.getAll();

  Future<Project> save(Project project) async {
    final saved = await _repo.save(project);
    ref.invalidateSelf();
    await future;
    return saved;
  }

  Future<void> setArchived(int id, {required bool archived}) async {
    await _repo.setArchived(id, archived: archived);
    ref.invalidateSelf();
    await future;
  }

  Future<void> duplicate(int id) async {
    await _repo.duplicate(id);
    ref.invalidateSelf();
    await future;
  }

  Future<void> remove(int id) async {
    await _repo.delete(id);
    ref.invalidateSelf();
    await future;
  }
}
