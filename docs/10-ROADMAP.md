# Etapa 15 — Roadmap e Manutenção

## Concluído (F0–F9)
- Engenharia reversa + documentação (diagnóstico, arquitetura, plano).
- Domínio científico fiel (Stolf, conversão, diagnóstico) com testes.
- Persistência local Drift/SQLite + entidade Projeto.
- UI Material 3 (dashboard, cadastro impacto/pressão, lista/consulta, projetos), GPS.
- Relatórios: PDF, Excel, CSV, JSON, backup .zip.
- Gráficos interativos (fl_chart).
- Google Drive (serviço + UI; aguarda OAuth Client do cliente).
- Segurança: SQLCipher, backup AES-GCM, Keystore, auditoria.
- Build Android assinado (APK/AAB) + ícone/splash + docs de publicação.

## Próximas melhorias
- **Sincronização bidirecional** incremental + resolução automática de conflitos.
- **Sync em segundo plano** (`workmanager`) ao recuperar conexão.
- **Restauração de backup** (download + decrypt + importação) e exportação de chave.
- **Importar** CSV/JSON/backup pela UI (botão já previsto no FAB).
- **Vínculo medição↔projeto** na tela de cadastro (seleção de projeto).
- **Mapa** das medições (lat/long já coletados).
- **Calibração** (expor fator/offset de Stolf por perfil).
- **Biometria/PIN** para abrir o app.
- **i18n** completo (inglês/espanhol) + acessibilidade (a11y) ampliada.
- **iOS** (mesma base Flutter).
- **Testes**: ampliar widget/integração e adicionar testes de performance.

## Manutenção
- Atualizar dependências periodicamente (`flutter pub outdated`).
- Reexecutar `dart run build_runner build` ao alterar tabelas Drift.
- Incrementar `versionCode`/`versionName` a cada release.
- Reverificar `flutter analyze` + `flutter test` antes de publicar.
- Guardar o keystore e o `key.properties` com backup seguro.
