# Checklist Final de Qualidade

## Qualidade de código (verificado)
- [x] `flutter analyze` → **No issues found!**
- [x] `flutter test` → **25 testes passando**
- [x] Arquitetura Clean (domain/application/data/presentation) por feature
- [x] DI/estado com Riverpod · navegação com go_router
- [x] Lints estritos (flutter_lints + regras extras) sem violações

## Cobertura de testes
- [x] Domínio científico: Stolf, conversão de pressão, quirk MPa×100, diagnóstico, fábricas
- [x] Interpretação técnica (impacto/pressão) e mapeamento de tipo
- [x] Relatórios: CSV/JSON/Excel/zip/PDF (geração válida)
- [x] Criptografia de backup (round-trip AES-GCM + chave errada falha)
- [x] Repositório em memória (CRUD/ordenação/média)
- [x] Smoke test do app (inicia no dashboard com navegação)
- [ ] (roadmap) testes de integração de UI e performance

## Funcionalidades (paridade + expansão)
- [x] Cálculo de impacto (Stolf) e pressão (MPa→kgf/cm²) — fiel ao desktop
- [x] Diagnóstico e interpretação idênticos ao desktop
- [x] CRUD de medições + consulta/filtro + detalhe
- [x] Projetos (criar/editar/duplicar/arquivar/excluir)
- [x] GPS automático
- [x] Relatórios PDF/Excel/CSV/JSON/backup
- [x] Gráficos interativos
- [x] Google Drive (serviço + UI) — requer OAuth Client do cliente
- [x] Segurança: SQLCipher, backup cifrado, secure storage, auditoria
- [x] Tema claro/escuro (Material 3)

## Build & publicação
- [x] Projeto Android gerado (`android/`), `applicationId br.edu.ifgoiano.penetrometro`, minSdk 24
- [x] Ícone + splash a partir do PNG do cliente
- [x] Keystore de release + assinatura configurada no Gradle
- [x] APK release e AAB gerados (ver `build/app/outputs/`)
- [ ] Senha do keystore trocada por uma forte (placeholder atual)
- [ ] OAuth Client do Google configurado (para login Drive real)
- [ ] Ficha da Play Store (textos, screenshots, data safety) preenchida

## Documentação (Entregáveis)
- [x] Diagnóstico, Arquitetura/Plano, Decisão técnica
- [x] Segurança, Google Drive, Build/Publicação
- [x] Política de Privacidade, Termos de Uso, Roadmap
- [x] Guia de build no Android Studio
- [x] Vault atualizada (conceitos + MOC)

## Pendências do cliente (fora do meu alcance técnico)
1. Trocar senha do keystore e guardar `.jks` com backup seguro.
2. Criar OAuth Client ID no Google Cloud (package + SHA-1) para o Drive.
3. Preencher a ficha da Play Console e publicar.
4. Validar em dispositivo real: GPS, PDF, backup cifrado, Drive, SQLCipher.
