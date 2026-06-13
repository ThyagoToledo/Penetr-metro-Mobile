import '../../features/measurement/data/in_memory_measurement_repository.dart';
import '../../features/measurement/domain/repositories/measurement_repository.dart';
import '../../features/project/data/in_memory_project_repository.dart';
import '../../features/project/domain/project_repository.dart';

// Implementação web (preview no navegador): em memória, sem persistência.
final InMemoryMeasurementRepository _measurements =
    InMemoryMeasurementRepository();
final InMemoryProjectRepository _projects = InMemoryProjectRepository();

MeasurementRepository createMeasurementRepository() => _measurements;

ProjectRepository createProjectRepository() => _projects;
