# Etapa 13 — Build e Publicação (Play Store)

## Identidade do app
- **applicationId:** `br.edu.ifgoiano.penetrometro`
- **minSdk:** 23 · **compileSdk/targetSdk:** padrão do Flutter (34/35)
- **Nome:** Penetrômetro · **Ícone/Splash:** gerados de `assets/icon/app_icon.png`

## Assinatura (release)
- Keystore: `app/android/penetrometro-release.jks` (alias `penetrometro`).
- Config: `app/android/key.properties` (NÃO versionado — está no `.gitignore`).
- O Gradle (`app/android/app/build.gradle.kts`) carrega o `key.properties` e assina o release.

> IMPORTANTE: o keystore e as senhas controlam a identidade do app na Play Store. **Guarde o `.jks` e o `key.properties` em local seguro e faça backup.** Se perder, não será possível atualizar o app publicado. A senha atual (`penetrometro2026`) é um placeholder — **troque por uma senha forte** antes de publicar (gere um novo keystore com `keytool` e atualize o `key.properties`).

## Comandos de build (na pasta `app/`)
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter build apk --debug                 # APK de teste
flutter build apk --release               # APK release assinado
flutter build appbundle --release         # AAB para a Play Store
```
Saídas:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

Recomendado para produção (menor + ofuscado):
```bash
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
```

## Configuração da Play Console (checklist)
1. Criar app na Play Console (idioma pt-BR, categoria *Ferramentas*/*Produtividade*).
2. Enviar o **.aab** em *Production* (ou *Internal testing* primeiro).
3. **Política de Privacidade** (URL pública) — ver `docs/08-POLITICA-DE-PRIVACIDADE.md`.
4. **Data safety**: declarar coleta de localização (GPS) e que dados ficam no dispositivo/Drive do usuário.
5. Ficha da loja: nome, descrição curta/completa, ícone 512×512, feature graphic 1024×500, screenshots.
6. Classificação de conteúdo (questionário).
7. Público-alvo e conteúdo.
8. Preço e distribuição (países).
9. Revisar e publicar.

## Checklist técnico de release
- [ ] `flutter analyze` sem erros · `flutter test` verde
- [ ] Senha do keystore trocada e keystore com backup
- [ ] `versionCode`/`versionName` incrementados (no `pubspec.yaml`)
- [ ] OAuth Client configurado (se for usar Drive) com SHA-1 do keystore de release
- [ ] Ícone/splash conferidos no dispositivo
- [ ] Teste em dispositivo real: cadastro, PDF, backup, tema, GPS
- [ ] AAB gerado e validado (bundletool ou *Internal testing*)
