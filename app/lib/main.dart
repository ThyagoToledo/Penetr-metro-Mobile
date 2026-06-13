import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/database/repository_factory.dart';
import 'features/measurement/domain/entities/measurement.dart';
import 'features/project/domain/project.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await _seedWebDemo();
  }
  runApp(const ProviderScope(child: PenetrometroApp()));
}

/// Popula dados de exemplo para o preview web (não persiste; só demonstração).
Future<void> _seedWebDemo() async {
  final measurements = createMeasurementRepository();
  final projects = createProjectRepository();

  final project = await projects.save(
    const Project(name: 'Talhão Norte', description: 'Área de demonstração'),
  );
  await measurements.save(
    Measurement.impact(
      impacts: 3,
      deep: 20,
      latitude: -16.52,
      longitude: -49.21,
      place: 'Talhão Norte',
      nameCollector: 'Demonstração',
      meteringDate: DateTime(2026, 6, 10),
      projectId: project.id,
    ),
  );
  await measurements.save(
    Measurement.impact(
      impacts: 6,
      deep: 30,
      latitude: -16.52,
      longitude: -49.21,
      place: 'Talhão Norte',
      nameCollector: 'Demonstração',
      meteringDate: DateTime(2026, 6, 11),
      projectId: project.id,
    ),
  );
  await measurements.save(
    Measurement.pressure(
      pressureMpa: 2.0,
      deep: 10,
      latitude: -16.55,
      longitude: -49.25,
      place: 'Talhão Sul',
      nameCollector: 'Demonstração',
      meteringDate: DateTime(2026, 6, 12),
    ),
  );
}
