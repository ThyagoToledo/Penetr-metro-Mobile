# Build no Android Studio — Passo a Passo

> O projeto Flutter está em `app/`. Como o Flutter SDK não rodou na máquina onde
> o código foi gerado, a pasta de plataforma `app/android/` ainda **não existe** —
> ela é criada por um comando (passo 3). Isso é normal e não apaga o código em `lib/`.

## 1. Pré-requisitos
- **Android Studio** (com plugins **Flutter** e **Dart**).
- **Flutter SDK 3.27+** (inclui o Dart SDK). Verifique com:
  ```bash
  flutter --version
  flutter doctor
  ```
- Um **emulador Android** ou aparelho com depuração USB.

## 2. Abrir o projeto
- No Android Studio: **Open** → selecione a pasta `app/` (não a raiz `penetrometreMobile`).

## 3. Gerar as pastas de plataforma (uma única vez)
No terminal, dentro de `app/`:
```bash
flutter create . --platforms=android --org br.edu.ifgoiano --project-name penetrometro
```
Isso cria `app/android/` com o `applicationId` `br.edu.ifgoiano.penetrometro`,
**sem** alterar `lib/`, `test/` ou `pubspec.yaml`.

## 4. Dependências e geração de código
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```
O `build_runner` gera o código do Drift (`lib/core/database/app_database.g.dart`).
É **obrigatório** antes do primeiro `run`/`test` (a persistência F2 depende dele).
Reexecute sempre que alterar tabelas do banco.

## 5. Ícone e Splash
- Salve a arte do app em `app/assets/icon/app_icon.png` (1024×1024).
- Gere os recursos:
  ```bash
  dart run flutter_launcher_icons
  dart run flutter_native_splash:create
  ```

## 6. Rodar os testes (paridade científica com o desktop)
```bash
flutter test
```
Devem passar os testes de `test/domain/penetrometer_calculations_test.dart`
(Equação de Stolf, conversão de pressão, diagnóstico).

## 7. Executar o app
- Selecione o dispositivo/emulador e clique **Run** ▶, ou:
  ```bash
  flutter run
  ```
O app abre no **Dashboard**, com barra inferior (Início, Projetos, Medições,
Relatórios, Config.) e FAB **+** → **Nova Medição** (cálculo e diagnóstico ao vivo).

## 8. Gerar artefatos de distribuição
```bash
flutter build apk --debug         # APK de teste
flutter build apk --release       # APK release (não assinado p/ Play)
flutter build appbundle --release # AAB para a Play Store
```
Saídas em `app/build/app/outputs/`.

> **Assinatura de release** (keystore + `key.properties`) e checklist da Play
> Store são tratados na fase **F9** (documento de publicação a ser gerado).

## Observações
- `applicationId` definido como `br.edu.ifgoiano.penetrometro` (convenção do
  projeto original `br.edu.ifgoiano`).
- `minSdkVersion`: use 21+ (necessário p/ SQLCipher na fase F2). Se o
  `flutter create` definir um valor menor, ajuste em
  `app/android/app/build.gradle`.
- Estado atual: dados de medição ficam **em memória** (somem ao fechar) — a
  persistência local (Drift/SQLite) chega na fase **F2**.
