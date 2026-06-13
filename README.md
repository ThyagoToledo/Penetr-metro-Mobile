# Penetrômetro Mobile

App Android (Flutter) para medição e análise de **compactação do solo**, migrado do sistema desktop [Penetrometer Project](https://github.com/ThyagoToledo/penetrometre) (IF Goiano — Campus Hidrolândia). Offline-first, integrado ao Google Drive do usuário, pronto para a Play Store.

## Estrutura

```
penetrometreMobile/
├── 📂 docs/        # Diagnóstico, decisão técnica, arquitetura, plano
├── 📂 app/         # Projeto Flutter (lib/, test/)
├── 📂 _analysis/   # Clone do desktop p/ engenharia reversa (não versionado)
└── 📄 instruções.md
```

## Hub de Documentação

- **[Diagnóstico do Desktop](docs/01-DIAGNOSTICO.md)**: engenharia reversa, lógica de negócio fiel, riscos e esforço.
- **[Decisão Tecnológica](docs/02-DECISAO-TECNOLOGICA.md)**: Flutter vs React Native, stack definitiva.
- **[Arquitetura e Plano](docs/03-ARQUITETURA-E-PLANO.md)**: Clean Architecture, modelo de dados, fases F0–F9.

## Estado atual

- ✅ Etapa 1 (Diagnóstico) · ✅ Etapa 2 (Decisão) · ✅ Etapa 3/8 (Arquitetura/Plano)
- 🔄 F1 — domínio científico portado (`app/lib/features/measurement/domain/`) com testes de paridade.

## Pré-requisitos para build (ainda não disponíveis nesta máquina)

- **Flutter SDK 3.22+** e **Android SDK** (para `flutter run` / `flutter test` / `flutter build`).
- Ícone/arte do cliente, credenciais OAuth Google (Drive) e keystore de release.

## Quick Start (após instalar o Flutter)

```bash
cd app
flutter pub get
flutter test          # roda os testes de paridade científica
flutter run           # executa em emulador/dispositivo
```

---

Sob licença MIT (mantida do projeto original).
