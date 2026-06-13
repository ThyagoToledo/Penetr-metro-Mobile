# Etapa 10 — Segurança

## Camadas implementadas

| Item | Implementação | Onde |
|------|---------------|------|
| Banco local cifrado | **SQLCipher** (`PRAGMA key`) | `core/database/app_database.dart` |
| Passphrase do banco | Gerada aleatória e guardada no **Keystore** do Android | `core/security/key_manager.dart` |
| Backup cifrado | **AES-GCM 256** (nonce+cipher+mac) | `core/security/backup_crypto.dart` |
| Chave de backup | 32 bytes aleatórios no Secure Storage | `core/security/key_manager.dart` |
| Credenciais OAuth | Tokens gerenciados pelo `google_sign_in` (Keystore) | `features/sync` |
| Logs de auditoria | Tabela `audit_logs` (create/update/delete) | repositórios Drift |
| Validação de entrada | Validação de campos + formatters numéricos | telas de medição |
| Proteção contra corrupção | Soft-delete + `version`/`sync_status` + transações Drift | camada de dados |

## Detalhes

### Banco cifrado (SQLCipher)
- Em Android, o `sqlite3` é substituído por SQLCipher (`openCipherOnAndroid`) e a abertura aplica `PRAGMA key` com a passphrase do Keystore.
- A passphrase é criada na 1ª execução (`Random.secure`, 32 bytes, base64) e nunca sai do dispositivo.
- **Requer verificação em dispositivo real** (não roda em `flutter test`, que usa repositórios em memória).

### Backups (AES-GCM)
- O backup `.zip` é cifrado antes de subir ao Drive (`.zip.enc`).
- Round-trip coberto por teste: `test/security/backup_crypto_test.dart`.
- A chave de backup fica no Secure Storage do aparelho — para restaurar em outro dispositivo, será necessário um mecanismo de exportação de chave (roadmap).

### Auditoria
- Cada operação de escrita registra `entity`, `entityId`, `action`, `timestamp` em `audit_logs`.

## Recomendações de hardening (roadmap)
- Bloqueio por biometria/PIN para abrir o app.
- Exportação segura da chave de backup (para restauração multi-dispositivo).
- Rotação de passphrase do banco.
- Ofuscação do código (`flutter build --obfuscate --split-debug-info`).
