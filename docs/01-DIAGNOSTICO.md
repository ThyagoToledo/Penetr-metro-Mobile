# Etapa 1 — Diagnóstico do Sistema Desktop (Engenharia Reversa)

> Documento de diagnóstico do projeto **Penetrometer Project** (desktop) como base para a migração mobile.
> Fonte analisada: `https://github.com/ThyagoToledo/penetrometre` (branch `main`, clone em `_analysis/penetrometre-desktop`).
> Data da análise: 2026-06-13.

---

## 1. Visão Geral

| Item | Valor |
|------|-------|
| Nome | Penetrometer Project |
| Instituição | Instituto Federal Goiano — Campus Hidrolândia |
| Domínio | Medição e análise de **compactação do solo** (penetrometria) |
| Tipo | Aplicação **desktop** JavaFX (registro de software oficial — vide `docs/CertificadoRegistroProgramaComputador.pdf`) |
| Licença | MIT |
| Pacote raiz | `br.edu.ifgoiano.penetrometerproject` |

O sistema permite registrar medições de dois tipos de penetrômetro (impacto e pressão), calcular automaticamente o coeficiente de resistência do solo (kgf/cm²), emitir um diagnóstico textual e gerar relatórios em PDF.

---

## 2. Arquitetura Atual

Arquitetura desktop em camadas (MVC + DAO), com JavaFX/FXML na apresentação e Hibernate/JPA na persistência.

```
JavaFX (FXML + Controllers)   ← Apresentação
        │
   MeteringService            ← Aplicação/Serviço (singleton)
        │
   MeteringDAO (interface)    ← Acesso a dados (Factory + Strategy)
   ├─ HibernateMeteringDAO    (implementação padrão — JPA)
   ├─ JDBCMeteringDAO         (implementação alternativa)
   ├─ ImpactMeteringDAO / PressureMeteringDAO
        │
   HSQLDB (arquivo local)     ← Banco embarcado
```

Camadas/pacotes encontrados em `src/main/java/.../penetrometerproject/`:

- `controller/` — controladores JavaFX (`Impact...`, `Pressure...`, `MeteringList...`, `ConsultSelection...`, `PenetrometersSelection...`, `Template...`, `Base...`).
- `model/` — entidades JPA (`Metering`, `MeteringType`).
- `dao/` — DAOs (`MeteringDAO`, `HibernateMeteringDAO`, `JDBCMeteringDAO`, `Impact/PressureMeteringDAO`, `MeteringDAOFactory`).
- `db/` — conexões JDBC legadas (`DBConnection*`, factory).
- `service/` — `MeteringService`, `PDFGeneratorService`.
- `util/` — calculadoras (`ImpactPenetrometerCalculator`, `PressurePenetrometerCalculator`, `CoefficientCalculator`), `HibernateUtil`, `NavigationManager`, `ThemeManager`, `SystemInfo`, `DataUtil`, `DataMigrationUtil`, `AlertUtils`.

> Observação: há **duas trilhas de persistência** no repositório (Hibernate/JPA e JDBC puro). A trilha **ativa** é a Hibernate (`MeteringService` instancia `HibernateMeteringDAO`). A trilha JDBC/`db/` é legada e não será migrada.

---

## 3. Stack Tecnológica (desktop)

| Camada | Tecnologia | Versão |
|--------|-----------|--------|
| Linguagem | Java | 24 |
| UI | JavaFX (controls + fxml) | 21.0.3 |
| ORM | Hibernate Core + JPA | 5.6.15.Final / 2.2 |
| Banco | HSQLDB (modo arquivo) | 2.7.2 |
| PDF | iText 7 (kernel, layout, io) | 7.2.5 |
| Boilerplate | Lombok | 1.18.38 |
| Log | SLF4J + Logback | 1.4.14 |
| Build | Maven + javafx-maven-plugin | 3.13 / 0.0.8 |

---

## 4. Fluxo de Dados

```
Usuário → Formulário JavaFX (Impacto/Pressão)
   → validação de campos obrigatórios
   → cálculo do coeficiente (Calculator)
   → diagnóstico textual (getDiagnosis)
   → Metering (entidade)
   → MeteringService.save()
   → HibernateMeteringDAO.persist()
   → HSQLDB (arquivo dados_medicoes/medicoes)
   → (opcional) PDFGeneratorService → PDF em ~/PenetrometroReports
```

Consulta: `ConsultSelection` → escolhe tipo → `MeteringListController` lista via `findByType`, com filtros por local/coletor/coeficiente; duplo clique abre detalhes; permite excluir e gerar PDF individual.

---

## 5. Banco de Dados

- **Engine:** HSQLDB modo arquivo — `jdbc:hsqldb:file:dados_medicoes/medicoes`, usuário `sa`, sem senha.
- **DDL:** automático via `hibernate.hbm2ddl.auto=update` (a tabela é criada na 1ª execução).
- **Estado do snapshot analisado:** `medicoes.script` contém apenas o schema de sistema do HSQLDB — **sem a tabela `MEDICOES` populada e sem dados de usuário**. Nao ha dados legados a migrar nesta copia.

### Entidade `Metering` → tabela `MEDICOES`

| Coluna (DB) | Campo (Java) | Tipo | Observações |
|-------------|--------------|------|-------------|
| ID | id | Long (IDENTITY) | PK auto-incremento |
| QUANTIDADE_IMPACTOS | impactsQuantity | int (NOT NULL) | **Impacto:** nº de impactos. **Pressão:** armazena `MPa × 100` (centésimos) — *workaround* de compatibilidade |
| PROFUNDIDADE | deep | double (NOT NULL) | profundidade em cm |
| COEFICIENTE | coefficient | double (NOT NULL) | resultado em kgf/cm² |
| RESISTENCIA_SOLO | FloorResistance | String(255) | texto do diagnóstico |
| DATA_MEDICAO | MeteringDate | Timestamp | data da coleta |
| DATA_SISTEMA | SystemDate | Timestamp | data/hora do registro |
| INFO_SISTEMA | SystemInfo | String(255) | SO/host |
| LATITUDE | latitude | double (NOT NULL) | GPS |
| LONGITUDE | longitude | double (NOT NULL) | GPS |
| LOCAL_MEDICAO | place | String(255) | local da coleta |
| NOME_COLETOR | nameCollector | String(100) | responsável |
| TIPO_MEDICAO | meteringType | enum String(20) | `IMPACT` / `PRESSURE` |

> ATENCAO - Divergencia README × código: o README cita um campo `collectorCPF`; **o código real não possui CPF**. O modelo real é o desta tabela.

---

## 6. Lógica de Negócio / Cálculos Científicos (FIEL AO CÓDIGO)

Esta é a parte que **deve ser preservada 100%** na migração.

### 6.1 Penetrômetro de Impacto — Equação de Stolf
```
R = 5.6 + 6.89 × N
```
- `R` = resistência (kgf/cm²); `N` = número de impactos.
- Constantes: `DEFAULT_FACTOR = 5.6`, `DEFAULT_OFFSET = 6.89`.
- Regra de borda: `N ≤ 0 ⇒ R = 0.0`.
- A **profundidade não entra na fórmula** (é apenas registrada).
- Há sobrecarga calibrável: `R = factor + offset × N`.

> ATENCAO - Divergencia README × código: o README mostra `R = (5.6 + 6.89·N) / P`. **O código NÃO divide pela profundidade.** Vale o código.

### 6.2 Penetrômetro de Pressão — Conversão
```
coef = leituraMPa × 10.1972      (1 MPa = 10.1972 kgf/cm²)
```
- Profundidades padrão: **{5, 10, 15, 20, 40} cm** (ou valor customizado).
- Persistência: `impactsQuantity = (int)(leituraMPa × 100)` ⇒ para recuperar a leitura: `MPa = impactsQuantity / 100`.

### 6.3 Diagnóstico textual (idêntico para Impacto e Pressão — dos Controllers)
| Coeficiente (kgf/cm²) | Diagnóstico |
|---|---|
| `< 10` | Solo adequado para cultivo |
| `≤ 20` | Solo com resistência moderada |
| `≤ 30` | Solo com alta resistência |
| `≤ 40` | Solo compactado |
| `> 40` | Solo extremamente compactado |

> ATENCAO - Divergencia README × código: a tabela do README (Baixa 0–2.5, Média 2.5–5, …) **não corresponde ao código**. Vale a tabela acima.

### 6.4 Interpretação técnica (no PDF — faixas próprias por tipo)
- **Impacto:** `<10` baixa resistência · `<25` moderada · `<40` elevada · `≥40` altamente compactado.
- **Pressão:** `<5` boa estrutura · `<15` normal · `<30` compactado · `≥30` severamente compactado.

### 6.5 Estatísticas
- `count()`, `averageCoefficient()` (AVG), análise geral textual por faixas (`<10`, `≤20`, `≤30`, else).

### 6.6 `CoefficientCalculator` (legado)
- Fórmula distinta `deep × fator + offset` — aparenta ser **código morto/legado** (não usado pelos controllers ativos). Não será migrado.

---

## 7. Relatórios / Exportações Existentes

- **Único formato hoje: PDF** (iText 7), gerado por `PDFGeneratorService`.
- Saída: `~/PenetrometroReports/<nome>.pdf` (nome customizável; sanitização de caracteres inválidos).
- Conteúdo do PDF: cabeçalho institucional, dados do coletor, dados da medição, **"gráfico" ASCII** (barra `▓░` proporcional ao coeficiente, escala 0–100 impacto / 0–50 pressão), box de diagnóstico colorido, interpretação técnica, rodapé com info do sistema e disclaimer.
- **Não existem hoje:** Excel, CSV, JSON, backup compactado. (Serão **novas** funcionalidades no mobile.)

---

## 8. Gráficos Existentes

- Não há biblioteca de gráficos real no desktop. A "visualização gráfica" é uma **barra ASCII** dentro do PDF.
- No mobile isto será **substituído por gráficos reais** (perfil de resistência × profundidade, comparação de medições, zoom/pan/gestos).

---

## 9. Componentes Críticos (para a migração)

1. `ImpactPenetrometerCalculator` — Equação de Stolf. **Crítico (ciência).**
2. `PressurePenetrometerCalculator` — conversão MPa→kgf/cm² + profundidades padrão. **Crítico (ciência).**
3. Regras de `getDiagnosis` / `getInterpretation`. **Crítico (ciência).**
4. Modelo `Metering` + enum `MeteringType` (incl. o *quirk* de pressão). **Crítico (dados).**
5. `PDFGeneratorService` — layout/seções do relatório. **Crítico (saída).**
6. `MeteringService`/DAO — operações CRUD + buscas. **Crítico (dados).**

---

## 10. Diagnóstico Estruturado

### 10.1 Funcionalidades existentes
- Cadastro de medição de **Impacto** (Stolf) com cálculo automático e diagnóstico.
- Cadastro de medição de **Pressão** (MPa→kgf/cm²) com profundidades padrão/customizada.
- Captura de **coordenadas GPS** (lat/long), local, coletor e data.
- **Consulta/listagem** por tipo, com busca por local/coletor/faixa de coeficiente; detalhes; exclusão com confirmação.
- **Geração de PDF** individual com nome customizado.
- **Estatísticas** (total, coeficiente médio, análise geral).
- **Tema claro/escuro** e microanimações (foco/sucesso/erro).

### 10.2 Funcionalidades que serão **migradas** (1:1)
- Ambos os cálculos científicos (Stolf + conversão) e o diagnóstico textual — **byte a byte**.
- Modelo de dados `Metering`/`MeteringType` (preservando o *quirk* de pressão para interoperabilidade com bases desktop existentes).
- CRUD de medições + buscas (tipo, local, coletor, faixa de coeficiente).
- Geração de PDF (reconstruída nativamente com layout equivalente/superior).
- Tema claro/escuro.

### 10.3 Funcionalidades que precisam ser **adaptadas** para mobile
- **GPS:** no desktop é digitado manualmente; no mobile, **captura automática** via sensor do aparelho (com edição manual de fallback).
- **Navegação:** janelas/Stages JavaFX → navegação mobile (bottom bar + rotas + FAB).
- **Diálogos `Alert`/`TextInputDialog`:** → bottom sheets / dialogs Material 3 + HUDs.
- **Saída de arquivos:** `~/PenetrometroReports` → armazenamento de app + *share sheet* Android + Google Drive.
- **"Gráfico" ASCII** → gráficos reais interativos.
- **Tabela JavaFX** → listas/cards responsivos com busca.
- **Entrada numérica:** validação por regex de TextField → teclados numéricos + formatters + validação de domínio.

### 10.4 Melhorias recomendadas (novas)
- **Projetos**: agrupar medições por projeto/talhão (hoje não há entidade Projeto — apenas medições soltas).
- **Offline-first + Google Drive** (backup/sync por conta do usuário, versionamento, resolução de conflito).
- **Exportações novas:** Excel, CSV, JSON e backup `.zip` cifrado.
- **Gráficos** de perfil de resistência × profundidade e comparação de medições.
- **Segurança:** criptografia local (SQLCipher), Secure Storage para tokens, logs de auditoria.
- **Perfil de calibração** (expor `factor`/`offset` do Stolf, já suportado pela sobrecarga existente).
- **Mapa** das medições (lat/long já são capturados).
- **i18n** (pt-BR padrão; preparar para inglês/espanhol).

### 10.5 Riscos técnicos
| Risco | Severidade | Mitigação |
|-------|-----------|-----------|
| **Flutter SDK não instalado** nesta máquina | Alta | Documentar setup; o build de APK/AAB exige Flutter + Android SDK (ver Etapa 13). |
| *Quirk* de pressão (`MPa×100` em `impactsQuantity`) gera ambiguidade de dados | Média | Manter compatibilidade na importação e adicionar coluna explícita `pressure_mpa` no schema mobile. |
| Divergências README × código induzem fórmula errada | Média | **Usar sempre o código** (documentado na Etapa 1.6); cobrir com testes unitários. |
| Integração Google Drive exige credenciais OAuth do cliente | Média | Guia de configuração no Google Cloud; código pronto aguardando `client_id`. |
| Geração de PDF idêntica (emojis/fontes) no mobile | Baixa | Reconstruir layout com a lib `pdf` (Dart); fontes que suportem os glifos. |
| Sem dados legados no snapshot, mas bases reais podem existir | Baixa | Implementar importador (CSV/JSON/HSQLDB export) opcional. |

### 10.6 Estimativa de esforço (engenharia, ordem de grandeza)
| Fase | Escopo | Esforço |
|------|--------|---------|
| F0 | Setup, scaffold, design system, CI | 3–5 dias |
| F1 | Domínio + cálculos + testes (port fiel) | 2–3 dias |
| F2 | Persistência local (SQLite/Drift) + repositórios | 3–4 dias |
| F3 | UI: dashboard, cadastro impacto/pressão, lista/consulta, detalhes | 6–8 dias |
| F4 | Relatórios (PDF/Excel/CSV/JSON/backup) | 4–5 dias |
| F5 | Gráficos interativos | 3–4 dias |
| F6 | Google Drive (OAuth, sync, conflito, background) | 6–8 dias |
| F7 | Segurança (cripto, secure storage, auditoria) | 3–4 dias |
| F8 | Testes (unit/integ/UI/perf) + ajustes | 4–6 dias |
| F9 | Play Store (ícone, splash, assinatura, políticas, AAB) | 3–4 dias |
| | **Total** | **~7–9 semanas** (1 dev) |

---

## 11. Conclusão da Etapa 1

O desktop é um sistema **focado e bem delimitado**: duas calculadoras científicas, um modelo de dados único (`Metering`) e geração de PDF. A migração mobile **preserva integralmente a lógica de negócio** (cálculos + diagnóstico + modelo) e **expande** a experiência (projetos, offline-first, Google Drive, novas exportações, gráficos reais, segurança), conforme detalhado nas Etapas 2–15.
