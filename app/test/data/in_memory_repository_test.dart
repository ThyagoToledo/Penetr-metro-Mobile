import 'package:flutter_test/flutter_test.dart';
import 'package:penetrometro/features/measurement/data/in_memory_measurement_repository.dart';
import 'package:penetrometro/features/measurement/domain/entities/measurement.dart';
import 'package:penetrometro/features/measurement/domain/entities/penetrometer_type.dart';

void main() {
  Measurement impact({DateTime? date}) => Measurement.impact(
        impacts: 4,
        deep: 10,
        latitude: -16,
        longitude: -49,
        meteringDate: date,
      );

  test('save atribui id incremental e count reflete', () async {
    final repo = InMemoryMeasurementRepository();
    final a = await repo.save(impact());
    final b = await repo.save(impact());
    expect(a.id, 1);
    expect(b.id, 2);
    expect(await repo.count(), 2);
  });

  test('getAll ordena por data desc', () async {
    final repo = InMemoryMeasurementRepository();
    await repo.save(impact(date: DateTime(2026, 1, 1)));
    await repo.save(impact(date: DateTime(2026, 6, 1)));
    final all = await repo.getAll();
    expect(all.first.meteringDate, DateTime(2026, 6, 1));
  });

  test('getByType filtra', () async {
    final repo = InMemoryMeasurementRepository();
    await repo.save(impact());
    await repo.save(
      Measurement.pressure(
        pressureMpa: 2,
        deep: 5,
        latitude: -16,
        longitude: -49,
      ),
    );
    expect((await repo.getByType(PenetrometerType.impact)).length, 1);
    expect((await repo.getByType(PenetrometerType.pressure)).length, 1);
  });

  test('delete remove e average calcula', () async {
    final repo = InMemoryMeasurementRepository();
    final a = await repo.save(impact());
    await repo.save(impact());
    await repo.delete(a.id!);
    expect(await repo.count(), 1);
    // impacto N=4 => 5.6 + 6.89*4 = 33.16
    expect(await repo.averageCoefficient(), closeTo(33.16, 1e-9));
  });
}
