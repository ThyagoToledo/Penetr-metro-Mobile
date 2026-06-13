import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:penetrometro/core/security/backup_crypto.dart';

void main() {
  test('AES-GCM cifra e decifra (round-trip)', () async {
    final key = List<int>.generate(32, (i) => (i * 7) % 256);
    final original = utf8.encode('conteúdo confidencial do backup • 1234');

    final encrypted = await BackupCrypto.encryptBytes(original, key);
    expect(encrypted, isNot(equals(original)));
    expect(encrypted.length, greaterThan(original.length)); // nonce + mac

    final decrypted = await BackupCrypto.decryptBytes(encrypted, key);
    expect(decrypted, equals(original));
  });

  test('chave errada falha ao decifrar', () async {
    final key = List<int>.generate(32, (i) => i);
    final wrong = List<int>.generate(32, (i) => 255 - i);
    final enc = await BackupCrypto.encryptBytes(utf8.encode('x'), key);
    expect(
      () => BackupCrypto.decryptBytes(enc, wrong),
      throwsA(isA<Exception>()),
    );
  });
}
