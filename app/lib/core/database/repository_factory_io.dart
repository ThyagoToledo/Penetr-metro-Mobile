import '../../features/measurement/data/drift_measurement_repository.dart';
import '../../features/measurement/domain/repositories/measurement_repository.dart';
import '../../features/project/data/drift_project_repository.dart';
import '../../features/project/domain/project_repository.dart';
import 'app_database.dart';

// Implementação nativa (Android/desktop): Drift/SQLite cifrado.
// Uma única instância do banco compartilhada pelos repositórios.
AppDatabase? _db;
AppDatabase _database() => _db ??= AppDatabase();

MeasurementRepository createMeasurementRepository() =>
    DriftMeasurementRepository(_database());

ProjectRepository createProjectRepository() =>
    DriftProjectRepository(_database());
