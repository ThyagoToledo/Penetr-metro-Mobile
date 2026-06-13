import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penetrometro/app.dart';
import 'package:penetrometro/features/measurement/application/measurement_providers.dart';
import 'package:penetrometro/features/measurement/data/in_memory_measurement_repository.dart';
import 'package:penetrometro/features/project/application/project_providers.dart';
import 'package:penetrometro/features/project/data/in_memory_project_repository.dart';

void main() {
  testWidgets('App inicia no dashboard com navegação', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          measurementRepositoryProvider
              .overrideWithValue(InMemoryMeasurementRepository()),
          projectRepositoryProvider
              .overrideWithValue(InMemoryProjectRepository()),
        ],
        child: const PenetrometroApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Título do dashboard (AppBar) e abas da barra inferior.
    expect(find.text('Penetrômetro'), findsOneWidget);
    expect(find.text('Projetos'), findsWidgets);
    expect(find.text('Relatórios'), findsWidgets);
  });
}
