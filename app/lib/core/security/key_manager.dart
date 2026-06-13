import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Gerencia segredos do app (passphrase do banco e chave de backup) usando o
/// armazenamento seguro do sistema (Keystore no Android).
class KeyManager {
  KeyManager._();
  static final KeyManager instance = KeyManager._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _dbPassphraseKey = 'db_passphrase';
  static const _backupKeyKey = 'backup_key';

  /// Passphrase do SQLCipher (criada na primeira execução).
  Future<String> getOrCreateDbPassphrase() async {
    final existing = await _storage.read(key: _dbPassphraseKey);
    if (existing != null) return existing;
    final value = _randomBase64(32);
    await _storage.write(key: _dbPassphraseKey, value: value);
    return value;
  }

  /// Chave AES (32 bytes) para criptografia de backups.
  Future<List<int>> getOrCreateBackupKey() async {
    final existing = await _storage.read(key: _backupKeyKey);
    if (existing != null) return base64Decode(existing);
    final bytes = _randomBytes(32);
    await _storage.write(key: _backupKeyKey, value: base64Encode(bytes));
    return bytes;
  }

  List<int> _randomBytes(int length) {
    final rnd = Random.secure();
    return List<int>.generate(length, (_) => rnd.nextInt(256));
  }

  String _randomBase64(int length) => base64Encode(_randomBytes(length));
}
