# Etapa 6/12 — Google Drive (Sincronização)

## O que está implementado
- Serviço `DriveService` (`features/sync/data/drive_service.dart`):
  - Login/logout Google (`google_sign_in`, escopo **`drive.file`** — acessa só arquivos criados pelo app).
  - Cria automaticamente a pasta **`Penetrometro`** na conta do usuário.
  - `uploadBackup`, `listBackups`, `downloadBackup`.
- Controlador `driveConnectionProvider` (`features/sync/application/sync_providers.dart`): conectar/desconectar, login silencioso ao abrir, e **backup cifrado** (AES-GCM) sob demanda.
- UI: cartão em **Configurações** (conectar/backup/desconectar) e status no Dashboard.

## Pre-requisito para o login real: OAuth Client ID
O `google_sign_in` no Android exige um **OAuth Client** configurado no Google Cloud. Sem isso, o "Conectar" falha (a UI mostra a mensagem e aponta para este doc).

### Passo a passo (Google Cloud Console)
1. Crie/selecione um projeto em https://console.cloud.google.com.
2. **APIs & Services → Enabled APIs** → habilite **Google Drive API**.
3. **OAuth consent screen** → tipo *External* → preencha app, e-mail de suporte, e adicione o escopo `.../auth/drive.file`. Adicione usuários de teste enquanto estiver em modo *Testing*.
4. **Credentials → Create Credentials → OAuth client ID → Android**:
   - Package name: `br.edu.ifgoiano.penetrometro`
   - SHA-1: obtenha com (na pasta `app/android`):
     ```bash
     "/c/Program Files/Java/jdk-25/bin/keytool.exe" -list -v \
       -keystore penetrometro-release.jks -alias penetrometro \
       -storepass penetrometro2026 | grep SHA1
     ```
     (gere também o SHA-1 de **debug** para testes: keystore em `~/.android/debug.keystore`, senha `android`.)
5. Não é preciso baixar JSON para o `google_sign_in` Android (a config é por package+SHA-1). Para publicar fora do modo *Testing*, envie o app para verificação do Google se usar escopos sensíveis.

## Fluxo de sincronização (offline-first)
```
Sem internet  → salva localmente (SQLite cifrado)
Com internet  → backup manual/automático para a pasta do Drive
Conflito      → resolução por versão (campo version + updatedAt)  [roadmap: merge automático]
```

## Roadmap de sync (próximos)
- Sincronização incremental bidirecional (push/pull por `dirty`/`version`).
- Resolução automática de conflitos (last-write-wins + histórico).
- Sincronização em segundo plano (`workmanager`) ao recuperar conexão.
