import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/security/backup_crypto.dart';
import '../../../core/security/key_manager.dart';
import '../../measurement/application/measurement_providers.dart';
import '../../reports/data/report_builders.dart';
import '../data/drive_service.dart';

/// Estado da conexão com o Google Drive (e-mail conectado ou null).
class DriveConnectionNotifier extends AsyncNotifier<String?> {
  DriveService get _svc => ref.read(driveServiceProvider);

  @override
  Future<String?> build() async {
    // Tenta restaurar uma sessão anterior silenciosamente.
    try {
      return await _svc.signInSilently();
    } catch (_) {
      return null;
    }
  }

  Future<void> connect() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _svc.signIn());
  }

  Future<void> disconnect() async {
    await _svc.signOut();
    state = const AsyncData(null);
  }

  /// Gera o backup das medições, **cifra (AES-GCM)** e envia ao Drive.
  Future<String> backupNow() async {
    final measurements =
        ref.read(measurementsProvider).valueOrNull ?? const [];
    final zip = ReportBuilders.buildBackupZip(measurements);
    final key = await KeyManager.instance.getOrCreateBackupKey();
    final encrypted = await BackupCrypto.encryptBytes(zip, key);
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    return _svc.uploadBackup(encrypted, 'backup_$stamp.zip.enc');
  }
}

final driveConnectionProvider =
    AsyncNotifierProvider<DriveConnectionNotifier, String?>(
  DriveConnectionNotifier.new,
);
