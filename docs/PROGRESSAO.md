# Progressão Inteligente — Etapa 0: Auditoria e Planejamento

> Status: **decisões registradas (2026-10-24)**; aguardando autorização para a Etapa 1.
> Base auditada: `master` em `0a9d098` (v1.2.0+3, schema drift v5).

---

## 1. Resumo da arquitetura encontrada

| Aspecto | O que existe hoje |
|---|---|
| Plataforma | App Flutter **Android-only**, 100% local/offline. Não há backend nem sincronização. |
| Estado | Riverpod 2 (`Provider`, `StreamProvider`, `FutureProvider.family`, `NotifierProvider`). |
| Persistência | Drift (SQLite), schema **v5**, migrations incrementais em `app_database.dart` (`if (from < N) addColumn`). Todas não destrutivas. |
| Camadas | `core/` (database, repositories, services, utils) + `features/<domínio>/{providers,screens,widgets}`. As telas falam só com providers → repositórios. |
| Unidades | Banco sempre em **kg**; `UnitConverter` converte para lbs na exibição/entrada (`settingsProvider.unit`). |
| Testes | 114 testes: unitários com `AppDatabase.forTesting(NativeDatabase.memory())` (repositórios/serviços) e testes de widget pontuais. `flutter analyze` sem avisos. |
| Dependências | Nenhuma nova é necessária para a progressão (JSON via `dart:convert`; sem codegen extra além do drift). |

**Consequência para o requisito "cálculos críticos fora do frontend":** como não há servidor, o equivalente aqui é **não colocar regra em widget**. O motor de progressão será Dart puro em `lib/core/progression/`, sem depender de Flutter, Riverpod nem drift. Isso o torna determinístico, offline e testável isoladamente.

---

## 2. Diagnóstico das funcionalidades existentes

### 2.1 Modelo de dados atual (relevante)

```
Exercises         id, name, muscleGroup, setType(weight|time|bodyweight), restSeconds, isArchived
WorkoutTemplates  id, name, position, groupName, isArchived
TemplateExercises id, templateId, exerciseId, position, restSecondsOverride
Sessions          id, templateId, startedAt, finishedAt?, notes?
SessionExercises  id, sessionId, exerciseId, position, restSeconds?, isExtra
SessionSets       id, sessionExerciseId, setType, weightKg?, reps?, durationSeconds?,
                  isWarmup, toFailure, position
```

### 2.2 O que já existe e será reaproveitado

| Recurso existente | Onde | Uso na progressão |
|---|---|---|
| Séries de aquecimento (`isWarmup`) | `SessionSets` | Excluídas das metas (regra comum a todas as estratégias). |
| "Até a falha" (`toFailure`) | `SessionSets` | É **falha muscular**, e não técnica. Serve de sinal de esforço (≈ RIR 0), mas não prova execução válida. |
| Séries vazias ignoradas (`isFilledSet`) | `session_repository.dart` | Séries não preenchidas não contam como tentativa. |
| Só sessões finalizadas contam | consultas de histórico/PR | Sessões interrompidas ou descartadas já ficam fora do histórico. |
| Histórico por exercício, independente do treino | `getPreviousSets`, `ReportRepository.getExerciseHistory` | É a base de entrada do motor. |
| Pré-criação de séries e "hints" | `startSession` + `previousSetsProvider` + `SetRowWidget` | Ponto de integração: com sugestão **aceita**, os campos vêm com a carga/reps sugeridas; sem sugestão, continua o comportamento atual (valores da última vez). O usuário sempre confirma cada série. |
| Validação ao confirmar série | `SetRowWidget._confirm` | Base para capturar RIR/RPE/qualidade sem mudar o fluxo. |
| Tela de resumo pós-treino | `SessionSummaryScreen` | Local do "Progressão identificada!" com Aceitar / Manter / Ajustar / Justificativa. |
| Edição de exercício e histórico | `AddExerciseScreen` (modo edição), `ExerciseHistoryScreen` | Ponto de entrada da área "Estratégia de Progressão" e de "recomendações anteriores". |
| Configurações globais | `settingsProvider` (SharedPreferences) | Estratégia/incremento padrão do usuário (opcional). |
| Backup/restore com migrations | `BackupService` | Backups antigos continuam restauráveis: as tabelas novas nascem vazias. |
| `UnitConverter`, `OneRmCalculator`, `formatRest` | `core/utils` | Arredondamento e exibição por unidade; 1RM fica só como informação. |

### 2.3 O que não existe (lacunas)

- RIR e RPE por série.
- Qualidade da execução (válida / falha técnica / inválida / não registrada).
- Papel da série além de aquecimento (série principal, back-off, onda).
- Metas planejadas por série (carga e repetições alvo).
- Configuração de progressão, recomendações e auditoria das decisões.
- Incremento de carga por exercício/equipamento. Também não existem equipamento nem marcação de exercício unilateral.

---

## 3. Proposta arquitetural do mecanismo

### 3.1 Camadas

```
┌──────────────── UI (features/progression, active_session, summary) ─────────────┐
│ Tela "Estratégia de Progressão" · metas na sessão · card de sugestão no resumo   │
└───────────────▲──────────────────────────────────────────────────────────────────┘
                │ providers Riverpod
┌───────────────┴──────────── Aplicação (core/services/progression_service.dart) ──┐
│ Monta a entrada a partir do histórico, chama o motor, persiste a recomendação,   │
│ registra a decisão do usuário e entrega as metas da próxima sessão.               │
└───────▲────────────────────────────────────────────────▲─────────────────────────┘
        │ repositórios (drift)                            │ Dart puro
┌───────┴─────────── Persistência ───────────┐  ┌─────────┴──── Motor (core/progression/) ─────────┐
│ ProgressionRepository: configs versionadas, │  │ ProgressionStrategy (contrato) + registry        │
│ recomendações, decisões                     │  │ Configs tipadas por estratégia (JSON)            │
│ SessionRepository: histórico + metas        │  │ Avaliação de séries (elegibilidade/qualidade)    │
└─────────────────────────────────────────────┘  │ Arredondamento de carga · explicação             │
                                                 └──────────────────────────────────────────────────┘
```

As responsabilidades pedidas ficam separadas assim:
- **Configuração:** classes de config por estratégia.
- **Dados de execução:** `ExerciseHistory`.
- **Avaliação:** `SetEvaluator`.
- **Decisão:** cada `ProgressionStrategy`.
- **Recomendação:** `ProgressionResult`.
- **Apresentação:** os widgets.
- **Auditoria:** tabela de recomendações e decisões.

### 3.2 Contrato (Strategy Pattern + registry)

```dart
// Conceitual: os nomes finais seguem o padrão do projeto.
abstract class ProgressionStrategy<C extends ProgressionConfig> {
  StrategyId get id;                               // doubleProgression, linear, ...
  C configFromJson(Map<String, Object?> json);
  List<ConfigIssue> validate(C config);            // configuração válida/ inválida
  ProgressionResult evaluate(ProgressionInput<C> input); // determinístico, sem I/O
}

class ProgressionInput<C> {
  final C config;
  final ExerciseContext exercise;          // setType, unidade, incremento, peso corporal?
  final List<SessionRecord> history;       // sessões finalizadas, mais recente primeiro
  final StrategyState? previousState;      // ex: onda atual, sessões bem-sucedidas seguidas
  final DateTime now;                      // injetado → resultado reproduzível
}

class ProgressionResult {
  final RecommendationStatus status;       // increaseWeight, increaseReps, maintain,
                                           // decreaseWeight, deloadSuggested,
                                           // insufficientData, manualReview
  final List<SetTarget> nextTargets;       // carga/reps/RIR-RPE/papel por série
  final List<Criterion> met, unmet;        // critérios atendidos / não atendidos
  final String reasonCode;                 // estável, para testes e i18n
  final List<int> analyzedSessionIds;
  final StrategyState newState;
}
```

- **Registry:** `Map<StrategyId, ProgressionStrategy>`. Para adicionar uma estratégia, basta criar uma classe e registrá-la; nenhuma outra muda.
- **Blocos compartilhados:** elegibilidade de séries, política para qualidade não registrada, arredondamento ao incremento, detecção de pausa longa e geração do texto explicativo. Isso evita duplicar regras entre estratégias (regra 7 do prompt).
- **Top Set + Back-off** é modelado como **estrutura de séries** (`SetTarget.role`) mais uma **política de progressão** reaproveitada (por exemplo, dupla ou linear para o top set e outra para o back-off), conforme a observação do prompt.
- **Wave Loading** guarda a posição no ciclo em `StrategyState`, persistido junto da recomendação.

### 3.3 Princípios garantidos pelo desenho

1. **O motor nunca grava nada.** Ele só devolve um resultado; quem persiste é o serviço, e a recomendação nasce como `pending`.
2. **Nada é aplicado sem ação do usuário.** A meta da próxima sessão só usa a sugestão quando ela foi **aceita** ou **ajustada**. "Manter carga" e "ignorar" mantêm o comportamento atual.
3. **Redução e deload nunca são automáticos.** São sugestões que pedem confirmação, como todo o resto.
4. **Configuração versionada e imutável.** Editar uma config cria uma versão nova; as recomendações antigas continuam apontando para a versão que as gerou.

---

## 4. Modelo de dados proposto (migrations aditivas, schema v6)

Todas as mudanças são `createTable` / `addColumn` com valores nulos ou padrão. Nenhum dado existente é alterado ou apagado.

### 4.1 Colunas novas em tabelas existentes

```
SessionSets
  + rir               INTEGER  NULL   -- 0–5 (5 = "5 ou mais"); nulo = não informado
  + rpe               REAL     NULL   -- 6.0–10.0 em passos de 0,5; nulo = não informado
  + executionQuality  TEXT     NULL   -- valid | technicalFailure | invalid; nulo = NOT_RECORDED
  + setRole           TEXT     NULL   -- work | topSet | backOff | wave; nulo = derivar de isWarmup
  + targetWeightKg    REAL     NULL   -- meta planejada (snapshot no início da sessão)
  + targetRepsMin     INTEGER  NULL
  + targetRepsMax     INTEGER  NULL

SessionExercises
  + progressionConfigId    INTEGER NULL → ProgressionConfigs  -- estratégia usada nesta sessão
  + recommendationId       INTEGER NULL → ProgressionRecommendations -- meta aplicada
  + excludeFromProgression BOOL DEFAULT false -- deload planejado / sessão atípica
```

### 4.2 Tabelas novas

```
ProgressionConfigs            -- versionada: editar = inserir nova linha
  id, exerciseId → Exercises, strategy TEXT, paramsJson TEXT,
  incrementKg REAL, createdAt, supersededAt NULL,
  baselineFrom DATETIME NULL   -- "nova referência" (troca de equipamento, retorno após pausa)

ProgressionRecommendations    -- auditoria completa
  id, exerciseId, configId → ProgressionConfigs, strategy TEXT,
  generatedAt, sourceSessionId, analyzedSessionIdsJson,
  status TEXT, reasonCode TEXT, explanation TEXT,
  criteriaMetJson, criteriaUnmetJson,
  currentWeightKg NULL, recommendedTargetsJson, strategyStateJson,
  decision TEXT  -- pending | accepted | kept | adjusted | dismissed | superseded
  decidedAt NULL, finalTargetsJson NULL
```

- A config ativa de um exercício é a linha mais recente sem `supersededAt`. Desativar a estratégia equivale a marcar `supersededAt` sem criar uma substituta. Ou seja, **"Sem progressão automática" é o padrão**.
- Os parâmetros ficam em JSON tipado por estratégia, porque cada estratégia tem parâmetros diferentes (o prompt pede que o motor não assuma parâmetros comuns). A validação é feita no código por `validate()`.

### 4.3 Compatibilidade com o histórico

- Séries antigas têm `rir`, `rpe` e `executionQuality` nulos. Elas são tratadas como **não registradas** e **nunca descartadas**.
- `isWarmup` continua sendo a fonte de verdade para aquecimento; `setRole` só acrescenta informação.
- Backups v1 a v5 continuam restauráveis, porque as migrations criam as tabelas e colunas novas vazias.
- O arquivo `.overload` de compartilhamento de treino continua igual na Etapa 1. Incluir a config de progressão nele fica como decisão para depois.

---

## 5. Fluxo de integração com o app

1. **Configurar** (opcional): Biblioteca → exercício → *Estratégia de Progressão*. Ali você escolhe o método, preenche os parâmetros e vê um exemplo calculado pelo próprio motor com dados fictícios. Ao salvar, cria-se uma nova versão da config.
2. **Iniciar a sessão:** `startSession` grava em cada `SessionExercise` o `progressionConfigId` vigente. Se existe recomendação **aceita ou ajustada** e ainda não usada, as metas viram `target*` nas séries pré-criadas e os campos vêm preenchidos com elas. Sem isso, o comportamento atual não muda.
3. **Durante o treino:** uma linha compacta por exercício mostra, por exemplo, "Meta: 52,5 kg · 3 × 8–12 · RIR 2", com o progresso na faixa. Os campos de RIR/RPE e a qualidade da execução só aparecem quando a estratégia do exercício usa esses dados (ou se você ligar a opção global). Assim a tela continua enxuta.
4. **Encerrar:** `finishSession` termina como hoje. Em seguida, o `ProgressionService` avalia cada exercício com config ativa e grava uma recomendação `pending`, que substitui (`superseded`) qualquer `pending` antiga daquele exercício.
5. **Resumo:** para cada recomendação, um card com o título ("Progressão identificada!", "Manter", "Dados insuficientes"...), a próxima sessão sugerida e as ações **Aceitar · Manter carga atual · Ajustar · Ver justificativa**. Fechar o resumo sem decidir deixa a recomendação `pending`, e ela reaparece ao abrir o treino seguinte.
6. **Histórico:** em *Exercício → Recomendações anteriores*, cada decisão aparece com a estratégia e a versão da config que a gerou.

---

## 6. Planejamento das etapas seguintes

| Etapa | Entrega | Principais testes |
|---|---|---|
| **1. Infraestrutura** | Migration v6. `ProgressionRepository` (configs versionadas, recomendações, decisões). Contrato e registry. Avaliação de séries (elegibilidade, política de "não registrado"). Arredondamento ao incremento (kg/lbs). Montagem do histórico a partir do banco. `ProgressionService` integrado ao `finishSession`, mas **sem nenhuma estratégia ativa**: o app se comporta exatamente como hoje. | Migration v5→v6 com dados, configs versionadas, imutabilidade de recomendações antigas, arredondamento parametrizado, elegibilidade (aquecimento, vazias, inválidas), sessões interrompidas ignoradas, nenhuma escrita sem estratégia ativa. |
| **2. Progressão Dupla** | Estratégia completa (regras 1–10). Tela "Estratégia de Progressão". Metas na sessão. Card no resumo com aceitar/manter/ajustar/justificativa. Lista de recomendações anteriores. **Primeira entrega ponta a ponta.** | Exemplo 8/8/8 → 12/12/12 → 52,5 kg; faixa não atingida; série inválida bloqueia; RIR-alvo; regra alternativa pela série principal; cargas diferentes entre séries; testes parametrizados de faixas e incrementos; widget test do fluxo de aceitação. |
| **3. Progressão Linear** | Sessões bem-sucedidas necessárias, tolerância a falhas e política de estagnação (manter / revisar / reduzir **sugerido**). Tentativas malsucedidas registradas. | N sessões consecutivas, falhas seguidas → sugestão de redução sem aplicar, troca de incremento. |
| **4. RIR** | Captura de RIR na série (com correção manual). Estratégia com tolerância. Retorno conservador quando falta RIR. | RIR alto sem atingir as reps não progride; RIR ausente → `insufficientData`; falha técnica ≠ RIR 0. |
| **5. RPE** | Captura de RPE (escala 6–10). Estratégia. Sem conversão RPE↔RIR implícita. | Acima do alvo → manter; abaixo do alvo com a meta atingida → progredir; registros ausentes. |
| **6. Top Set + Back-off** | Papéis de série, cálculo do back-off por percentual com arredondamento e políticas separadas para top set e back-off. | 70 kg × 6, −15% → 59,5 arredondado ao incremento; top set progride e back-off não, e vice-versa; ajuste manual. |
| **7. Wave Loading** | Ondas configuráveis, estado do ciclo, interrupção por falha técnica, resultados por onda. | Ondas diferentes entre si; onda falhada não avança; ordem preservada; validação de cargas. |
| **8. Refinamento** | Revisão de UX e consistência visual, troca de estratégia no meio do ciclo, performance das consultas, regressão completa, documentação (este arquivo vira o documento técnico: arquitetura, parâmetros, como criar uma estratégia). | Suíte completa, migração de backups antigos, teste no aparelho. |

Cada etapa termina com: `flutter test` + `flutter analyze` executados de verdade, relatório no formato da seção 15 do prompt, e parada para a sua validação.

---

## 7. Riscos, dependências e compatibilidade

| Risco | Mitigação |
|---|---|
| A tela da sessão ficar carregada | Campos de RIR/RPE/qualidade só aparecem quando a estratégia exige. A meta cabe numa linha compacta. |
| Histórico antigo sem RIR/RPE/qualidade bloquear progressão | Política configurável para "não registrado" (ver pergunta 2). Estratégias por RIR/RPE devolvem `insufficientData` em vez de chutar. |
| Configs mudando e invalidando a auditoria | Configs versionadas e imutáveis; a recomendação guarda o `configId` e um snapshot das metas. |
| Mesmo exercício com objetivos diferentes em treinos diferentes | Ver pergunta 1. O modelo permite vincular a config ao treino depois, sem quebrar nada. |
| Troca de equipamento ou retorno após pausa distorcer comparações | `baselineFrom` ("nova referência") e detecção de pausa longa → `manualReview`. |
| lbs × kg | Incremento definido na unidade do usuário e arredondamento feito na unidade de exibição; o banco continua em kg. |
| Migration mal feita corromper o banco do celular | Só migrations aditivas, teste de v5→v6 com dados reais simulados, backup antes de atualizar (já disponível no app). |
| Escopo grande | As entregas por etapa já são usáveis; nenhuma etapa depende de uma etapa futura. |

**Dependências novas:** nenhuma.

---

## 8. Critérios de aceitação (globais)

1. Exercícios **sem** estratégia funcionam exatamente como hoje. Todos os testes atuais continuam passando.
2. Nenhuma carga ou meta muda sem ação explícita do usuário.
3. A mesma entrada (histórico + config + data) sempre gera a mesma recomendação.
4. Toda recomendação mostra estado, motivo, critérios atendidos e não atendidos, sessões analisadas e a versão da config.
5. Séries de aquecimento, vazias, com falha técnica ou inválidas nunca justificam um aumento.
6. Trocar ou desativar a estratégia não apaga nem reescreve recomendações e histórico antigos.
7. Backups anteriores à v6 restauram sem erro.
8. Em cada etapa, `flutter test` e `flutter analyze` passam sem avisos.

---

## 9. Decisões do proprietário (2026-10-24)

| # | Tema | Decisão |
|---|---|---|
| 1 | Escopo da configuração | **Por exercício** (vale em qualquer treino). |
| 2 | Séries sem qualidade registrada | Contam como **válidas** para metas de repetição, sinalizado na justificativa; opção por config "exigir execução válida marcada". |
| 3 | Captura de RIR/RPE/qualidade na sessão | Só nos exercícios cuja estratégia usa esses dados, mais opção global "sempre registrar RIR/RPE". |
| 4 | Peso corporal | Progride em repetições **e em carga adicional** (colete, anilha no cinto): séries `bodyweight` passam a aceitar `weightKg` opcional = carga extra. |
| 5 | Exercícios por tempo | **Fora** da progressão automática (o usuário progride o tempo manualmente). |
| 6 | Unilateral / equipamento | **Depois.** Por enquanto, "nova referência" (`baselineFrom`) cobre troca de equipamento e retorno após pausa. |
| 7 | Escalas | RIR 0–5 (5 = "5 ou mais"); RPE 6–10 em passos de 0,5. |
| 8 | Commits | Autorizado commitar ao fim de cada etapa aprovada, **sem** a linha `Co-Authored-By`. |
