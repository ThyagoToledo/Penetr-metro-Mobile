import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart';

import '../security/key_manager.dart';

part 'app_database.g.dart';

/// Tabela de projetos (agrupador de medições — melhoria sobre o desktop).
@DataClassName('ProjectRow')
class Projects extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get remoteId => text().nullable()();
  TextColumn get name => text().withLength(min: 1, max: 120)();
  TextColumn get description => text().nullable()();
  TextColumn get owner => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get syncStatus => text().withDefault(const Constant('local'))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

/// Tabela de medições — espelha `MEDICOES` do desktop + campos de suporte.
@DataClassName('MeasurementRow')
class Measurements extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get remoteId => text().nullable()();
  IntColumn get projectId =>
      integer().nullable().references(Projects, #id)();
  TextColumn get meteringType => text()(); // IMPACT / PRESSURE
  IntColumn get impactsQuantity => integer().withDefault(const Constant(0))();
  RealColumn get pressureMpa => real().nullable()();
  RealColumn get deep => real()();
  RealColumn get coefficient => real()();
  TextColumn get floorResistance => text().nullable()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  TextColumn get place => text().nullable()();
  TextColumn get nameCollector => text().nullable()();
  DateTimeColumn get meteringDate => dateTime().nullable()();
  DateTimeColumn get systemDate => dateTime().nullable()();
  TextColumn get systemInfo => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get syncStatus => text().withDefault(const Constant('local'))();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();
}

/// Log de auditoria (Etapa 10 — segurança).
@DataClassName('AuditLogRow')
class AuditLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entity => text()();
  IntColumn get entityId => integer().nullable()();
  TextColumn get action => text()();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  TextColumn get detail => text().nullable()();
}

@DriftDatabase(tables: [Projects, Measurements, AuditLogs])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _open());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async => m.createAll(),
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  /// Abre o banco cifrado com SQLCipher.
  ///
  /// A passphrase é gerada e guardada no armazenamento seguro do dispositivo
  /// (Keystore) via [KeyManager]. Em Android, o sqlite3 é substituído pela
  /// variante SQLCipher antes da abertura.
  ///
  /// Nota: a cifra exige verificação em dispositivo real (não roda em
  /// `flutter test`, que usa repositórios em memória).
  static LazyDatabase _open() {
    return LazyDatabase(() async {
      if (Platform.isAndroid) {
        await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();
        open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
      }
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'penetrometro.db'));
      final passphrase = await KeyManager.instance.getOrCreateDbPassphrase();
      return NativeDatabase(
        file,
        setup: (rawDb) {
          rawDb.execute("PRAGMA key = '$passphrase';");
        },
      );
    });
  }
}
