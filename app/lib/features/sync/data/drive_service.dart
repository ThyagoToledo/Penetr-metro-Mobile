import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

/// Metadados de um backup armazenado no Drive.
class DriveBackupInfo {
  const DriveBackupInfo({
    required this.id,
    required this.name,
    this.modified,
  });

  final String id;
  final String name;
  final DateTime? modified;
}

/// Integração com o Google Drive do usuário (OAuth + arquivos).
///
/// Escopo `drive.file`: acesso apenas a arquivos criados pelo app. Os backups
/// ficam numa pasta `Penetrometro` criada automaticamente na conta do usuário.
///
/// Observação: o login real exige um **OAuth Client ID** configurado no Google
/// Cloud (com o SHA-1 do app). Sem isso, [signIn] lança erro de plataforma —
/// tratado na UI. Ver `docs/06-GOOGLE-DRIVE.md`.
class DriveService {
  DriveService()
      : _googleSignIn = GoogleSignIn(
          scopes: const [drive.DriveApi.driveFileScope],
        );

  final GoogleSignIn _googleSignIn;
  static const String _folderName = 'Penetrometro';

  bool get isSignedIn => _googleSignIn.currentUser != null;
  String? get currentEmail => _googleSignIn.currentUser?.email;

  Future<String?> signIn() async {
    final account = await _googleSignIn.signIn();
    return account?.email;
  }

  Future<String?> signInSilently() async {
    final account = await _googleSignIn.signInSilently();
    return account?.email;
  }

  Future<void> signOut() => _googleSignIn.signOut();

  Future<drive.DriveApi> _api() async {
    final client = await _googleSignIn.authenticatedClient();
    if (client == null) {
      throw StateError('Não autenticado no Google Drive.');
    }
    return drive.DriveApi(client);
  }

  Future<String> _ensureFolder(drive.DriveApi api) async {
    final existing = await api.files.list(
      q: "mimeType='application/vnd.google-apps.folder' "
          "and name='$_folderName' and trashed=false",
      $fields: 'files(id,name)',
    );
    final files = existing.files;
    if (files != null && files.isNotEmpty) {
      return files.first.id!;
    }
    final folder = drive.File()
      ..name = _folderName
      ..mimeType = 'application/vnd.google-apps.folder';
    final created = await api.files.create(folder);
    return created.id!;
  }

  /// Envia um backup (bytes) para a pasta do app no Drive.
  Future<String> uploadBackup(List<int> bytes, String filename) async {
    final api = await _api();
    final folderId = await _ensureFolder(api);
    final media = drive.Media(Stream.value(bytes), bytes.length);
    final file = drive.File()
      ..name = filename
      ..parents = [folderId];
    final result = await api.files.create(file, uploadMedia: media);
    return result.id!;
  }

  Future<List<DriveBackupInfo>> listBackups() async {
    final api = await _api();
    final folderId = await _ensureFolder(api);
    final list = await api.files.list(
      q: "'$folderId' in parents and trashed=false",
      $fields: 'files(id,name,modifiedTime)',
      orderBy: 'modifiedTime desc',
    );
    return (list.files ?? [])
        .map(
          (f) => DriveBackupInfo(
            id: f.id!,
            name: f.name ?? 'sem nome',
            modified: f.modifiedTime,
          ),
        )
        .toList();
  }

  Future<List<int>> downloadBackup(String fileId) async {
    final api = await _api();
    final media = await api.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;
    final out = <int>[];
    await for (final chunk in media.stream) {
      out.addAll(chunk);
    }
    return out;
  }
}

final driveServiceProvider = Provider<DriveService>((ref) => DriveService());
