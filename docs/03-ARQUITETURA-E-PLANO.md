# Etapa 3 + 8 — Arquitetura do App e Plano de Implementação por Fases

## Estrutura de pastas (alvo)

```
app/
├── pubspec.yaml
├── analysis_options.yaml
├── lib/
│   ├── main.dart
│   ├── app.dart                      # MaterialApp.router + tema + i18n
│   ├── core/                         # transversal
│   │   ├── constants/                # constantes científicas, chaves
│   │   ├── error/                    # Failure, exceptions, Result/Either
│   │   ├── theme/                    # Design System (Material 3, claro/escuro)
│   │   ├── router/                   # go_router
│   │   ├── di/                       # providers raiz (Riverpod)
│   │   ├── security/                 # cripto, secure storage, auditoria
│   │   └── utils/                    # formatters, logger, extensions
│   ├── shared/                       # widgets reutilizáveis, HUDs
│   │   └── widgets/                  # AppCard, AppButton, Hud, etc.
│   └── features/
│       ├── measurement/              # medições (núcleo)
│       │   ├── domain/               # entidades, VOs, calculadoras, contratos
│       │   ├── application/          # use cases + controllers Riverpod
│       │   ├── data/                 # Drift DAO, mappers, repo impl
│       │   └── presentation/         # telas impacto/pressão/lista/detalhe
│       ├── project/                  # projetos (agrupador de medições — novo)
│       ├── reports/                  # PDF/Excel/CSV/JSON/backup
│       ├── charts/                   # gráficos interativos
│       ├── sync/                     # Google Drive (OAuth, sync, conflito)
│       ├── dashboard/                # home/dashboard
│       └── settings/                 # tema, conta, calibração, sobre
├── test/                             # unit + widget
├── integration_test/                 # testes de integração/UI
└── android/                          # config Android (icon, splash, signing)
```

## Mapa de camadas (Clean Architecture)

| Camada do prompt | Implementação |
|------------------|---------------|
| Presentation | `features/*/presentation` + `shared/widgets` + `core/theme` |
| Domain | `features/*/domain` (puro Dart) |
| Application | `features/*/application` (use cases, controllers Riverpod) |
| Infrastructure | `features/*/data` (Drift, Drive, exportadores) |
| Core | `core/` |
| Shared | `shared/` |
| Services | `application` + `core/security` + `sync` |
| Repositories | contratos em `domain`, impl em `data` |
| Models | entidades `domain` + tabelas Drift `data` |
| Storage | `core/security` + `features/*/data` (Drift) |
| Cloud | `features/sync` (Google Drive) |
| Analytics | `core/utils/logger` + auditoria |
| Security | `core/security` |
| Settings | `features/settings` |

## Modelo de dados local (SQLite/Drift) — alvo

`measurements` (espelha `MEDICOES` + melhorias):
- `id` INTEGER PK
- `remote_id` TEXT (id no Drive, p/ sync)
- `project_id` INTEGER FK → `projects` (novo, agrupamento)
- `metering_type` TEXT (`IMPACT`/`PRESSURE`)
- `impacts_quantity` INTEGER (impacto: nº; pressão: MPa×100 — compat desktop)
- `pressure_mpa` REAL (novo, explícito p/ pressão)
- `deep` REAL (profundidade cm)
- `coefficient` REAL (kgf/cm²)
- `floor_resistance` TEXT (diagnóstico)
- `latitude` REAL, `longitude` REAL
- `place` TEXT, `name_collector` TEXT
- `metering_date` INTEGER (epoch), `system_date` INTEGER, `system_info` TEXT
- `created_at`, `updated_at`, `deleted_at` (soft delete), `version` INTEGER, `sync_status` TEXT, `dirty` BOOLEAN

`projects` (novo): id, remote_id, name, description, owner, created_at, updated_at, archived, version, sync_status.

`audit_logs` (segurança): id, entity, entity_id, action, timestamp, detail.

## Plano de Implementação por Fases

> Estado atual: **F0, F1 e F2 concluídas**; UI núcleo (dashboard, cadastro, lista, projetos) já funcional.

- [x] **F0 — Fundação:** estrutura de pastas, `pubspec`, design system base, docs (Etapas 1–4).
- [x] **F1 — Domínio + Cálculos (FIEL):** entidades, calculadoras Stolf/pressão, diagnóstico, interpretação + **testes unitários** (Etapa 1.6 ↔ código).
- [x] **F2 — Persistência local:** Drift/SQLite (tabelas Measurements/Projects/AuditLogs), repositórios, mappers, soft-delete; entidade **Projeto** com CRUD (Etapas 6, 7). *SQLCipher fica para F7.*
- [x] **F3 — UI núcleo + GPS:** dashboard, cadastro impacto/pressão, lista/consulta, detalhe, navegação, **GPS automático** (geolocator) + permissões Android + smoke test (Etapas 5, 9-parcial). *HUDs avançados e refinos visuais continuam ao longo das próximas fases.*
- [x] **F4 — Relatórios:** PDF (reproduz o layout do desktop, com barra vetorial), Excel (.xlsx), CSV, JSON, backup `.zip`; serviço de exportação (share_plus/printing) + telas; testes dos geradores. *Cifra do backup fica para F7.*
- [x] **F5 — Gráficos:** dispersão resistência×profundidade + barras de comparação (fl_chart), zoom/pan (InteractiveViewer), legenda (Etapa 9).
- [x] **F6 — Google Drive:** serviço OAuth (`drive.file`), pasta automática, upload/download/list de backups, conectar/desconectar/backup na UI (Etapa 6, 12). *Login real exige OAuth Client ID do cliente (docs/06).*
- [x] **F7 — Segurança:** SQLCipher no banco, backup AES-GCM (testado), secure storage (Keystore), logs de auditoria nos repositórios (Etapa 10).
- [x] **F8 — Testes:** 25 testes (domínio/interpretação/relatórios/cripto/repositório/smoke), `analyze` limpo (Etapa 14). *Roadmap: integração/UI/perf.*
- [x] **F9 — Play Store:** ícone/splash gerados; assinatura (keystore); **APK release (87 MB) + AAB (77 MB) gerados e assinados**; políticas/termos/checklist (Etapas 11, 13, 15). *Pendências do cliente: trocar senha do keystore, criar OAuth Client, preencher a Play Console.*

## Bloqueios externos (precisam de insumo do cliente/ambiente)
1. **Flutter SDK + Android SDK** não instalados nesta máquina → necessários para compilar APK/AAB (F9). Guia em `docs/13-BUILD-E-PUBLICACAO.md` (a criar).
2. **Ícone/arte do cliente** ("fornecido posteriormente") → necessário para launcher icon e splash (F9).
3. **Credenciais OAuth Google** (Google Cloud Console + tela de consentimento) → necessárias para Drive real (F6). Código fica pronto aguardando `client_id`.
4. **Keystore de release** → gerar e guardar com segurança para assinar o AAB (F9).
