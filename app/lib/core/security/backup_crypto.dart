import 'package:cryptography/cryptography.dart';

/// Criptografia simétrica (AES-GCM 256) para backups.
///
/// Formato do payload: `nonce(12) || ciphertext || mac(16)` (concatenation),
/// permitindo decriptar com a mesma chave de 32 bytes.
abstract final class BackupCrypto {
  static final _algorithm = AesGcm.with256bits();

  static Future<List<int>> encryptBytes(List<int> data, List<int> key) async {
    final secretKey = await _algorithm.newSecretKeyFromBytes(key);
    final box = await _algorithm.encrypt(data, secretKey: secretKey);
    return box.concatenation();
  }

  static Future<List<int>> decryptBytes(
    List<int> encrypted,
    List<int> key,
  ) async {
    final secretKey = await _algorithm.newSecretKeyFromBytes(key);
    final box = SecretBox.fromConcatenation(
      encrypted,
      nonceLength: 12,
      macLength: 16,
    );
    return _algorithm.decrypt(box, secretKey: secretKey);
  }
}
