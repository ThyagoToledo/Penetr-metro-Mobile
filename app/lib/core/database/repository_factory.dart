import '../../features/measurement/domain/repositories/measurement_repository.dart';
import '../../features/project/domain/project_repository.dart';
// Seleciona a implementação por plataforma: nativo (Drift/SQLite cifrado) ou
// web (em memória — para preview no navegador). Em web não há dart:io/ffi.
import 'repository_factory_web.dart'
    if (dart.library.io) 'repository_factory_io.dart' as impl;

MeasurementRepository createMeasurementRepository() =>
    impl.createMeasurementRepository();

ProjectRepository createProjectRepository() => impl.createProjectRepository();
