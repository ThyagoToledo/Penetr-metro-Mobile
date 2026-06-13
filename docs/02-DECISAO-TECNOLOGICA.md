# Etapa 2 — Decisão Tecnológica

## Escolha: **Flutter 3+ (Dart)**

Decisão tomada conforme permitido pelo prompt ("escolher a opção mais adequada justificando tecnicamente").

### Comparativo

| Critério | Flutter 3+ | React Native + Expo |
|---------|------------|---------------------|
| Renderização | Engine própria (Skia/Impeller) — UI consistente e fluida | Componentes nativos via bridge/JSI |
| Gráficos científicos | `fl_chart` / `syncfusion_flutter_charts` (zoom, pan, gestos) — fortes | Boas libs, mas menos integradas |
| Geração de PDF on-device | `pdf` + `printing` — excelentes, layout vetorial | `react-native-pdf`/`html-to-pdf` — mais limitado/«webview» |
| SQLite + ORM | `drift` (type-safe, reativo) + `sqflite` + **SQLCipher** | `op-sqlite`/`watermelondb` — bom, cripto menos direto |
| Estado | **Riverpod** (pedido no prompt) — maduro, testável | Zustand — bom, mas menos «full-stack» |
| Material 3 / temas | Suporte nativo de 1ª classe (claro/escuro, dynamic color) | Depende de libs de terceiros |
| Performance offline-first | Compilado AOT, sem bridge JS | Overhead de bridge em listas/sync grandes |
| Build Android (AAB/APK) | `flutter build appbundle/apk` — direto | Requer EAS/Expo ou bare workflow |
| Tamanho/distribuição | APK enxuto, controle total | Expo facilita, mas adiciona camadas |

### Por que Flutter aqui
- O app é **fortemente gráfico e científico** (formulários, cálculos, gráficos de perfil, PDF): a engine própria do Flutter entrega UI premium e consistente em qualquer Android.
- **Riverpod** é explicitamente solicitado e é o padrão de estado mais maduro do ecossistema Flutter.
- **PDF/Excel/CSV on-device** e **SQLite cifrado** têm libs Dart de 1ª linha (`pdf`, `excel`, `csv`, `drift`+`sqlcipher`).
- Build de **AAB/APK** é um comando único, sem dependências de serviços externos.
- Single codebase com caminho natural para iOS no futuro.

## Stack definitiva (mobile)

| Camada | Tecnologia |
|--------|-----------|
| Framework | Flutter 3.22+ / Dart 3.4+ |
| Estado / DI | **Riverpod** (+ `riverpod_annotation`/generator) |
| Navegação | `go_router` |
| Banco local | **Drift** (SQLite) + `sqlcipher_flutter_libs` (cripto) |
| Cloud | **Google Drive API** (`googleapis` + `google_sign_in` / `extension_google_sign_in_as_googleapis_auth`) |
| Secure storage | `flutter_secure_storage` (tokens/credenciais) |
| PDF | `pdf` + `printing` |
| Planilhas/dados | `excel`, `csv`, `archive` (backup .zip) |
| Gráficos | `fl_chart` (zoom/pan/gestos) |
| GPS | `geolocator` + `permission_handler` |
| Conectividade | `connectivity_plus` |
| Background sync | `workmanager` |
| Cripto | `cryptography` / `encrypt` (backups), SQLCipher (DB) |
| i18n | `flutter_localizations` + `intl` (pt-BR padrão) |
| Ícone/Splash | `flutter_launcher_icons` + `flutter_native_splash` |
| Testes | `flutter_test`, `mocktail`, `integration_test` |

## Arquitetura

**Clean Architecture + SOLID + Repository Pattern + DI (Riverpod)**, organizada por **feature**:

```
presentation → application(use cases/controllers) → domain ← infrastructure(data)
```

- **domain** (puro Dart, sem Flutter): entidades, value objects, **calculadoras científicas**, contratos de repositório. Independente de framework e testável isoladamente.
- **application**: casos de uso / controllers Riverpod (orquestram domínio + repositórios).
- **infrastructure (data)**: Drift (DAO local), Google Drive (remoto), mappers, exportadores (PDF/Excel/CSV/JSON).
- **presentation**: telas, widgets, design system, HUDs.
- **core / shared**: tema, constantes, erros, utils, resultado `Either`/`Result`, logger/auditoria, segurança.

### Conflitos com a Vault e adaptações necessárias
A Vault em `Brain-main` documenta **outros projetos** (PlantiumAI — Tauri/Rust; IgnisEngine — Java) e aponta para outro usuário (`vinic`/`FeronZerbana`, repo `URSoftware/Brain`). Portanto:
- **Regras de processo da Vault aplicadas:** documentação enxuta/atômica, "check local first", economia de tokens, padrão de README, e **isolamento de repositórios git** (Vault ≠ projeto).
- **Conteúdo de domínio da Vault (PlantiumAI/IgnisEngine):** não se aplica ao penetrômetro — adaptado/ignorado.
- **Identidade git:** para commits do projeto, usar **ThyagoToledo / thyago10a2007@gmail.com** (config LOCAL do repo), conforme skill `git-workflow-thyago` e a nota `setup-dev-windows` da Vault — **não** as credenciais `FeronZerbana` da Vault (essas são exclusivas do repo da Vault).
