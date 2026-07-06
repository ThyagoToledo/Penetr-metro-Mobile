import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penetrometro/app.dart';
import 'package:penetrometro/features/measurement/application/measurement_providers.dart';
import 'package:penetrometro/features/measurement/data/in_memory_measurement_repository.dart';
import 'package:penetrometro/features/project/application/project_providers.dart';
import 'package:penetrometro/features/project/data/in_memory_project_repository.dart';
import 'package:penetrometro/features/sync/application/sync_providers.dart';

/// Drive falso: estado "desconectado" imediato (sem plugin nativo em testes).
class _FakeDriveConnection extends DriveConnectionNotifier {
  @override
  Future<String?> build() async => null;
}

void main() {
  testWidgets('App inicia no dashboard com navegação', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          measurementRepositoryProvider
              .overrideWithValue(InMemoryMeasurementRepository()),
          projectRepositoryProvider
              .overrideWithValue(InMemoryProjectRepository()),
          driveConnectionProvider.overrideWith(_FakeDriveConnection.new),
        ],
        child: const PenetrometroApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Penetrômetro'), findsOneWidget);
    expect(find.text('Projetos'), findsWidgets);
    expect(find.text('Relatórios'), findsWidgets);
    expect(find.text('Conectar'), findsOneWidget);
  });
}
