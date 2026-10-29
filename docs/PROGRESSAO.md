# Progressão Inteligente — Documento técnico

> Status: **Etapa 8 concluída (refinamento e integração final)**. Todas as etapas do plano (0–8) estão implementadas.
>
> **Parte I** (este início) descreve o mecanismo como ele é hoje. **Parte II** guarda o planejamento da Etapa 0 e o registro de cada etapa. Onde o planejamento diverge do código (ex: nomes como `SetEvaluator` e `ExerciseHistory`, que não existem), vale a Parte I.

---

# Parte I — Guia técnico

## A. Visão geral

O Overload **recomenda** progressões; nunca muda carga ou meta sozinho. Cada exercício pode ter uma estratégia (ou nenhuma: "Sem progressão automática"). Ao encerrar o treino, o motor avalia o histórico real do exercício e grava uma sugestão **pendente**, com justificativa e critérios. Só quando o usuário **aceita** ou **ajusta**, as metas entram nas séries do treino seguinte, uma única vez.

```
lib/core/progression/           Motor: Dart puro, sem Flutter, banco ou relógio
  progression_strategy.dart       Contrato ProgressionStrategy<C>, ProgressionConfig, ProgressionInput
  progression_models.dart         SetRecord, SessionRecord, ExerciseContext, SetTarget, Criterion, ProgressionResult
  progression_enums.dart          StrategyId, RecommendationStatus/Decision, ExecutionQuality, SetRole
  progression_rules.dart          Séries de trabalho, qualidade que comprova meta, arredondamento, pausa longa
  session_checks.dart             Verificações comuns (basics, longBreak, latest/mixedLoads, RIR, aviso de qualidade)
  progression_registry.dart       ProgressionRegistry.standard
  strategies/                     Uma classe por estratégia (config + estratégia)
lib/core/database/repositories/progression_repository.dart   Configs versionadas, recomendações, decisões, histórico
lib/core/services/progression_service.dart                   Liga o motor ao app (ao encerrar a sessão / reavaliar)
lib/features/progression/                                    Tela de configuração, card de sugestão, providers
```

## B. Estratégias disponíveis

| Estratégia (`StrategyId`) | Ideia | Estado entre sessões | Peso corporal | Seção |
|---|---|---|---|---|
| Progressão Dupla (`doubleProgression`) | Reps sobem na faixa; no topo, sobe a carga | — | Sim (carga adicional) | 11 |
| Progressão Linear (`linear`) | Meta fixa; sobe após N sessões bem-sucedidas; política de estagnação | Sequências (calculadas do histórico) | Sim | 12 |
| Por RIR (`rirBased`) | Topo da faixa + RIR registrado dentro do alvo ± tolerância | — | Sim | 13 |
| Por RPE (`rpeBased`) | Topo da faixa + RPE 6–10 dentro do alvo ± tolerância | — | Sim | 14 |
| Série Principal + Back-off (`topSetBackOff`) | Duas trilhas: principal e back-off (percentual da principal) | — | Não | 15 |
| Progressão em Ondas (`waveLoading`) | Ciclo de ondas, uma por sessão; avança só com a onda concluída | Posição no ciclo (`WaveState`) | Não | 16 |

Todas: incremento por exercício (digitado na unidade do usuário, guardado em kg), arredondamento (`nearest`/`down`/`up`), opção "exigir execução marcada como válida", e as verificações comuns de `SessionChecks` (sem incremento → revisão; sem histórico/séries → dados insuficientes; pausa > 21 dias → revisão).

## C. Fluxo de uma recomendação

1. **Configurar:** Biblioteca → exercício → *Estratégia de Progressão*. Salvar cria uma **versão nova** da config (a anterior ganha `supersededAt`, nunca é editada) e descarta a sugestão pendente da versão anterior (o app avisa).
2. **Iniciar o treino:** cada `SessionExercise` grava a config vigente (`progressionConfigId`). Se houver sugestão aceita/ajustada ainda não usada **da config vigente**, as metas viram `target*` (e `setRole`) nas séries pré-criadas; a sessão guarda `recommendationId`, então a meta é usada uma vez só.
3. **Encerrar:** `ProgressionService.evaluateFinishedSession` avalia cada exercício com config ativa (exercícios por tempo e marcados "não avaliar" ficam fora). Entrada: config validada, `ExerciseContext`, histórico (`loadHistory`, a partir da "nova referência"), estado anterior e o relógio injetado. Saída gravada como `pending`; a pendente anterior do exercício vira `superseded`.
4. **Decidir:** card com Aceitar · Manter carga atual · Ajustar · Justificativa, no resumo e de novo antes do próximo treino. Decisões são definitivas; recomendações nunca são reescritas.
5. **Reavaliar** (Histórico → corrigir RIR/RPE/qualidade): gera uma sugestão nova, partindo do estado de **antes** daquela sessão.

Erro numa estratégia é registrado no log e não impede o encerramento nem os demais exercícios.

## D. Integração com o histórico

- Só sessões **finalizadas**; séries vazias e aquecimento não contam; falha muscular (`toFailure`) ≠ falha técnica (`ExecutionQuality.technicalFailure`).
- Séries sem qualidade registrada contam como válidas (sinalizado na justificativa), a menos que a config exija marcação.
- Histórico antigo (sem RIR/RPE/qualidade/papel) é lido normalmente: estratégias que precisam desses dados devolvem `insufficientData` ou mantêm a carga, nunca chutam.
- "Nova referência" (`baselineFrom`) isola o histórico após troca de equipamento ou retorno de pausa.
- Cada recomendação guarda estratégia, `configId`, sessões analisadas, critérios, metas sugeridas e finais (auditoria).

## E. Decisões de modelagem

- **Config por exercício**, versionada e imutável; parâmetros em JSON (`paramsJson`), cada estratégia com sua classe de config. Configurações padrão por usuário foram avaliadas e **não** implementadas: o único padrão global hoje é o incremento inicial (2,5 kg / 5 lb pela unidade). Um "modelo padrão" poderia ser acrescentado sem mudar o banco (preferência + preenchimento inicial da tela).
- **Estado da estratégia** no próprio registro da recomendação (`strategyStateJson`), por versão de config: trocar parâmetros recomeça ciclos.
- **Papéis de série** (`SetRole`: `topSet`, `backOff`, `wave`) vêm das metas aceitas. Sem papéis (histórico ou registro manual), cada estratégia tem um fallback conservador (ex: principal = maior carga) ou pede revisão.
- **Sem índices extras no banco:** ver G.

## F. Como adicionar uma estratégia

1. Acrescentar o valor em `StrategyId` (gravado pelo nome: nunca renomear).
2. Criar `strategies/minha_estrategia.dart` com:
   - a config (`extends ProgressionConfig`): campos, `toJson`/`fromJson`, `summary` (linha da sessão), `usesRir`/`usesRpe` (o que a sessão pede ao usuário);
   - a estratégia (`extends ProgressionStrategy<MinhaConfig>`): `id`, `displayName`, `validate`, `evaluate` (pura e determinística) e, se não servir para peso corporal, `supportsLoadType`.
3. No `evaluate`, reaproveitar `SessionChecks` (`basics`, `longBreak` ou `latest`) e `ProgressionRules` em vez de reescrever regras. Se usar estado, preserve-o nas saídas antecipadas (ver `WaveLoadingStrategy._keep`).
4. Registrar em `ProgressionRegistry.standard`.
5. Interface: um formulário em `progression_config_screen.dart` (estado, `_load`, `_config`, `_strategyHint`) e cenários em `_Example._scenarios`, calculados pela própria estratégia. Títulos específicos de `reasonCode`, se precisar, em `recommendationHeadline`.
6. Testes: unitários com `SessionRecord` em memória (config válida/inválida, meta atingida/não, falha técnica, sem histórico, sem incremento, troca de config, abaixo do mínimo, sessão interrompida, dados opcionais ausentes, determinismo, parametrizados de carga/faixa/incremento) e um fluxo pelo `ProgressionService` com banco em memória.

## G. Performance

Medida num banco simulado de ~5 anos (1.000 sessões × 6 exercícios × 4 séries = 24 mil séries), no PC: avaliar uma sessão inteira leva ~20 ms; iniciar um treino com metas, ~19 ms; `loadHistory`, ~3 ms. A Etapa 8 tirou o N+1 de `loadHistory` (uma consulta por sessão → uma consulta para todas as séries). Índices em `session_sets(session_exercise_id)` e afins reduziriam para ~13 ms, ganho pequeno demais para justificar uma migration v7 (que também impediria restaurar backups novos em apps antigos). Fica registrado como opção se o volume crescer.

## H. Compatibilidade

- Migrations só aditivas; v6 criou as tabelas de progressão e colunas anuláveis/com padrão neutro.
- Backups das versões 3, 4 e 5 restauram pelo fluxo real (`BackupService.restore`), migram para v6 e já aceitam progressão sobre o histórico antigo (teste `legacy_backup_restore_test.dart`).
- Backup de versão mais nova que o app é recusado com mensagem.

## I. Exemplos de uso

- **Supino, Progressão Dupla 3 × 8–12, +2,5 kg:** 50 kg × 12/12/12 → "Progressão identificada! Próxima: 52,5 kg — 3 × 8–12". 50 kg × 12/11/10 → "Busque mais repetições".
- **Terra, Principal + Back-off 1 × 4–6 + 3 × 6–8 (−15%):** 70 kg × 6, back-off 60 kg × 8/8/8 → principal 72,5 kg, back-off 62,5 kg (72,5 × 0,85 = 61,6 → 62,5).
- **Agachamento, Ondas 3×8 @75% → 3×6 @80% → 3×4 @85%:** última sessão com 60 kg → referência 80 kg; onda 1 = 60 kg × 8; concluída → onda 2 = 65 kg × 6; uma rep a menos → "Repita a onda"; onda 3 concluída → referência 82,5 kg e novo ciclo.

## J. Limitações conhecidas

- Exercícios **unilaterais** e **equipamento** não são modelados (decisão 6); "nova referência" cobre a troca de equipamento.
- Exercícios **por tempo** ficam fora da progressão automática (decisão 5).
- Estratégias de faixa avaliam só a sessão mais recente; a Linear olha sequências no histórico.
- Trocar de estratégia não converte o histórico: a nova estratégia lê as sessões como foram feitas. Estruturas diferentes (ex: principal + back-off lidas pela Dupla) caem em `mixedLoads` e pedem revisão, de propósito.
- Ondas: a sessão é comparada ao plano guardado no estado; mantida ou ajustada para menos, a onda não conta como concluída.
- RPE é percepção: não há média entre sessões nem conversão RPE ↔ RIR.
- A carga adicional de peso corporal, uma vez salva numa série, só pode ser alterada (não apagada) pelo campo.

---

# Parte II — Planejamento (Etapa 0) e registro das etapas

> Base auditada na Etapa 0: `master` em `0a9d098` (v1.2.0+3, schema drift v5).

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

## 10. Etapa 1 — Infraestrutura (implementada)

### Arquivos

| Arquivo | Papel |
|---|---|
| `lib/core/progression/progression_enums.dart` | `StrategyId`, `RecommendationStatus`, `RecommendationDecision`, `ExecutionQuality`, `SetRole` (gravados pelo nome: renomear exige migration). |
| `lib/core/progression/progression_models.dart` | `SetRecord`, `SessionRecord`, `ExerciseContext`, `SetTarget`, `Criterion`, `ConfigIssue`, `ProgressionResult`. |
| `lib/core/progression/progression_strategy.dart` | Contrato `ProgressionStrategy<C>`, `ProgressionConfig`, `ProgressionInput`. |
| `lib/core/progression/progression_registry.dart` | `ProgressionRegistry.standard`, **vazio nesta etapa**. |
| `lib/core/progression/progression_rules.dart` | Regras compartilhadas: séries de trabalho, qualidade que comprova meta, arredondamento ao incremento, pausa longa (> 21 dias). |
| `lib/core/database/repositories/progression_repository.dart` | Configs versionadas, recomendações, decisões, metas a aplicar e histórico no formato do motor. |
| `lib/core/services/progression_service.dart` | Avalia a sessão finalizada e grava recomendações **pendentes**. |
| `lib/features/progression/providers/progression_providers.dart` | Providers do repositório e do serviço. |
| `tables.dart` / `app_database.dart` | Schema v6 (migration aditiva). |
| `session_repository.dart` | Início de sessão grava a config vigente e aplica metas aceitas (uma vez). |
| `active_session_screen.dart` | Encerrar a sessão chama o serviço. |

### Como adicionar uma estratégia

1. Criar a config (`extends ProgressionConfig`) com `toJson` e os parâmetros próprios.
2. Implementar `ProgressionStrategy<SuaConfig>`: `configFromJson`, `validate` e `evaluate` (pura, sem I/O, usando `ProgressionRules` para o que for comum).
3. Registrar em `ProgressionRegistry.standard`.
4. Testar com históricos simulados (`SessionRecord`) sem banco, e um teste de integração pelo `ProgressionService`.

### Comportamento garantido nesta etapa

- Nenhuma estratégia registrada: encerrar uma sessão não grava nada e o app se comporta como antes.
- Recomendação nasce `pending`; só `accepted`/`adjusted` viram metas, e uma única vez (sessão descartada libera de novo).
- Metas vão para `target*` das séries; os campos registrados (`weightKg`, `reps`) continuam vazios até o usuário confirmar.
- Erro dentro de uma estratégia é registrado no log e não impede o encerramento.

## 11. Etapa 2 — Progressão Dupla (implementada)

### Parâmetros (`DoubleProgressionConfig`)

| Parâmetro | Padrão | Observação |
|---|---|---|
| `sets` | 3 | 1–10 séries de trabalho. |
| `repsMin` / `repsMax` | 8 / 12 | 1–50; mínimo ≤ máximo. |
| `targetRir` | nenhum | 0–5. Com RIR-alvo, o RIR passa a ser pedido na sessão. |
| `criterion` | `allSets` | `mainSet` exige só a série principal no topo (demais ≥ mínimo). |
| `mainSetNumber` | 1 | Usado com `mainSet`; validado contra `sets`. |
| `rounding` | `nearest` | `down`/`up`: como arredondar a carga nova ao incremento. |
| `requireMarkedValid` | false | Exige qualidade marcada como válida. |
| incremento | 2,5 kg / 5 lb | Coluna da config, em kg; digitado na unidade do usuário. |

**Decisão de modelagem:** "comportamento após aumentar a carga" é **fixo** (regra 7): a meta mantém a faixa e o campo de repetições começa no mínimo. Não virou parâmetro porque a outra opção (manter as repetições altas com mais carga) contraria a própria definição da estratégia.

### Decisão (ordem de avaliação, só a sessão mais recente)

1. Sem incremento → `manualReview`. Sem histórico ou sem séries de trabalho → `insufficientData`.
2. Cargas diferentes entre as séries consideradas → `manualReview` (`mixedLoads`). A estratégia não presume qual carga é a de trabalho.
3. Mais de 21 dias desde a última sessão → `manualReview` (`longBreak`).
4. Menos séries que o configurado → `maintain` (`incompleteSession`).
5. Série com falha técnica, inválida ou sem marcação (quando exigida) → `maintain` (`invalidExecution`).
6. Alguma série abaixo do mínimo → `maintain` (`belowMinimum`). Nunca reduz.
7. Topo atingido, mas sem RIR registrado → `maintain` (`rirMissing`); RIR abaixo do alvo (falha muscular = RIR 0) → `maintain` (`effortAboveTarget`).
8. Topo atingido → `increaseWeight`: carga + incremento, arredondada, faixa recomeçando no mínimo.
9. Caso contrário → `increaseReps`: mesma carga, buscar mais repetições.

Peso corporal: a carga adicional começa em 0 (sem carga) e sobe pelo incremento.

### Interface

- **Biblioteca → exercício → Progressão:** método, parâmetros, "nova referência", exemplo calculado pela própria estratégia e recomendações anteriores. Exercícios por tempo mostram um aviso e não oferecem estratégia.
- **Sessão:** linha "Progressão Dupla · 3 × 8–12 · Meta 52,5 kg" e "Topo da faixa: x/3"; campos preenchidos com a meta aceita; botão de detalhes (qualidade e RIR) só quando o exercício tem estratégia (o RIR só aparece se ela usa RIR) ou com "Sempre registrar RIR" ligado (Configurações). Séries de peso corporal ganham campo de carga adicional (`+kg`).
- **Resumo pós-treino:** cards "Progressão identificada!" etc. com Aceitar · Manter carga atual · Ajustar · Justificativa.
- **Antes de iniciar um treino:** sugestões ainda pendentes reaparecem; dá para decidir ou iniciar sem decidir (o treino segue como sempre).

### Limitações conhecidas

- A estratégia avalia só a sessão mais recente (suficiente para a Progressão Dupla). As estratégias com "N sessões bem-sucedidas" (Linear) usarão o `state`.
- A carga adicional de peso corporal, uma vez salva numa série, não pode ser apagada pelo campo (só alterada), porque `updateSet` ignora valores vazios. Isso já era assim para os demais campos.
- O RPE fica para a Etapa 5.

## 12. Etapa 3 — Progressão Linear (implementada)

### Verificações compartilhadas (`session_checks.dart`)

As verificações iniciais saíram da Progressão Dupla e agora valem para qualquer estratégia baseada em carga (`SessionChecks.latest`): incremento definido, histórico, séries de trabalho, mesma carga em todas as séries e pausa longa. O mesmo arquivo concentra séries inválidas, verificação de RIR (falha muscular = RIR 0), o aviso de "qualidade não marcada" e a descrição da carga em peso corporal. A Progressão Dupla foi migrada para ele sem mudar comportamento (os 64 testes dela continuam passando).

### Parâmetros (`LinearProgressionConfig`)

| Parâmetro | Padrão | Observação |
|---|---|---|
| `sets` / `targetReps` | 3 / 5 | Meta fixa: 1–10 séries, 1–50 reps. |
| `successesRequired` | 1 | 1–5 sessões bem-sucedidas **seguidas na mesma carga** para subir. |
| `failureTolerance` | 3 | 1–10 tentativas malsucedidas seguidas antes da política de estagnação. |
| `stallPolicy` | `reduce` | `maintain` (manter) · `review` (revisão manual) · `reduce` (sugere reduzir). |
| `deloadPercent` | 10 | 5–30%, só com `reduce`; arredonda **para baixo** ao incremento. |
| `targetRir` | nenhum | 0–5. |
| `rounding`, `requireMarkedValid` | — | Iguais aos da Progressão Dupla. |

### Como cada sessão conta

| Resultado | Quando |
|---|---|
| **Sucesso** | Todas as séries com a meta de reps, execução válida e, se houver, RIR ≥ alvo. |
| **Falha** (tentativa malsucedida) | Faltou repetição, falha técnica/execução inválida, ou RIR abaixo do alvo. |
| **Inconclusiva** (não conta) | Sessão interrompida (séries a menos), cargas diferentes, ou meta atingida sem RIR registrado. |

**Decisão de modelagem:** as sequências de sucesso e falha são **recalculadas a partir do histórico real** a cada avaliação (da mais recente para trás, na carga atual, pulando as inconclusivas), em vez de um contador guardado. Assim a recomendação é reproduzível a partir dos registros e não depende de uma avaliação anterior ter sido gravada. O `state` da recomendação guarda `successStreak`, `failStreak` e `loadKg` apenas para auditoria. Sessões antigas são avaliadas pelos critérios da config atual.

### Decisão

1. Verificações compartilhadas (acima).
2. Sessão interrompida → `maintain` (`incompleteSession`), sem contar como falha. Meta atingida sem RIR → `maintain` (`rirMissing`).
3. Sucesso e sequência ≥ `successesRequired` → `increaseWeight` (`successStreakReached`). Senão → `maintain` (`needMoreSuccesses`).
4. Falha e sequência < `failureTolerance` → `maintain` (`failedAttempt`, "Falha x de N").
5. Falha e sequência ≥ `failureTolerance` → política: `maintain` (`stalledMaintain`), `manualReview` (`stalledReview`) ou `decreaseWeight` (`stalledReduce`). Sem carga para reduzir (ex: peso corporal sem extra) → `manualReview` (`stalledCannotReduce`).

A redução é **sempre uma sugestão pendente**: só vira meta se o usuário aceitar (regra 7).

### Limitações conhecidas

- RPE como critério de sucesso fica para a Etapa 5 (o prompt lista "RIR/RPE opcional"; nesta etapa só RIR).

## 13. Etapa 4 — Progressão por RIR (implementada)

### Parâmetros (`RirBasedConfig`)

| Parâmetro | Padrão | Observação |
|---|---|---|
| `sets`, `repsMin`, `repsMax` | 3, 8, 12 | Faixa de repetições, como na Dupla. |
| `targetRir` | 2 | 0–5, obrigatório. |
| `rirTolerance` | 1 | 0–2. A carga só sobe com RIR ≥ alvo − tolerância. |
| `criterion` | `allSets` | `lastSet`: avalia o RIR só da última série de trabalho. |
| `rounding`, `requireMarkedValid` | — | Iguais às demais. |

### Decisão (sessão mais recente)

1. Verificações compartilhadas (`SessionChecks`).
2. Séries a menos → `maintain` (`incompleteSession`).
3. Falha técnica/execução inválida → `maintain` (`invalidExecution`). **Falha técnica não é RIR 0**: a série não conta. Falha muscular (⚡) conta como RIR 0.
4. RIR ausente em alguma série avaliada → `insufficientData` (`rirMissing`), com a mesma carga como sugestão conservadora. **O RIR nunca é estimado a partir de carga e repetições.**
5. Menor RIR < alvo − tolerância → `maintain` (`effortAboveTarget`). Nunca sugere redução automática.
6. Alguma série abaixo do mínimo → `maintain` (`belowMinimum`).
7. Todas no topo da faixa e RIR dentro do limite → `increaseWeight` (`topOfRangeWithinRir`).
8. Fora do topo com RIR acima de alvo + tolerância → `increaseReps` (`easierThanTarget`): **RIR alto sozinho não sobe a carga**.
9. Caso contrário → `increaseReps` (`withinRange`).

A variação de percepção entre sessões é tratada pela tolerância; usa-se o **menor** RIR entre as séries avaliadas (o esforço mais alto da sessão).

### Correção manual do RIR (regra 7)

- **Durante o treino:** botão de detalhes da série (já existia), agora sempre com RIR para esta estratégia.
- **Depois do treino:** Histórico → sessão → tocar numa série corrige RIR e qualidade. Aparece a ação **Reavaliar**, que gera uma nova recomendação pendente com os dados corrigidos. Nada é reavaliado sozinho, e recomendações já decididas não são reescritas (a pendente anterior vira `superseded`).

## 14. Etapa 5 — Progressão por RPE (implementada)

### Captura de RPE

- Escala de força **6–10 em passos de 0,5** (`rpeScale`), registrada na folha de detalhes da série (durante o treino e na correção pelo histórico).
- Aparece quando a estratégia usa RPE (`ProgressionConfig.usesRpe`) ou com **Configurações → Sempre registrar RPE**.
- `SessionRepository.updateSetDetails` grava RIR, RPE e qualidade de forma independente. **RPE e RIR nunca são convertidos um no outro**; uma série só com RIR conta como "RPE não registrado".
- A folha de detalhes passou a ter Cancelar/Salvar fixos no rodapé (o conteúdo rola), para não esconder o botão em telas pequenas.
- `EffortCriterion` (todas as séries / última série) passou a ser compartilhado por RIR e RPE. Os valores gravados no JSON não mudaram.

### Parâmetros (`RpeBasedConfig`)

| Parâmetro | Padrão | Observação |
|---|---|---|
| `sets`, `repsMin`, `repsMax` | 3, 8, 12 | Faixa de repetições. |
| `targetRpe` | 8 | 6–10, passos de 0,5. |
| `rpeTolerance` | 0,5 | 0, 0,5 ou 1. A carga só sobe com RPE ≤ alvo + tolerância. |
| `criterion` | `allSets` | `lastSet`: avalia só a última série. |
| `rounding`, `requireMarkedValid` | — | Iguais às demais. |

### Decisão (sessão mais recente)

Espelho da Progressão por RIR com a escala invertida (RPE alto = esforço alto), usando o **maior** RPE das séries avaliadas:

1. Verificações compartilhadas → séries a menos (`incompleteSession`) → execução comprometida (`invalidExecution`).
2. RPE ausente → `insufficientData` (`rpeMissing`), mesma carga como sugestão conservadora.
3. RPE > alvo + tolerância → `maintain` (`effortAboveTarget`); nunca reduz sozinho.
4. Abaixo do mínimo → `maintain` (`belowMinimum`).
5. Topo da faixa com RPE dentro ou abaixo do planejado → `increaseWeight` (`topOfRangeWithinRpe`).
6. Fora do topo com RPE < alvo − tolerância → `increaseReps` (`easierThanTarget`); senão `increaseReps` (`withinRange`).

**Única regra explícita de equivalência:** falha muscular (⚡) vale **RPE 10**, por definição do topo da escala. Não é uma conversão de RIR.

### Limitação conhecida

- O RPE é tratado como percepção (não medida objetiva) pela tolerância e pela exigência de repetições; não há média entre sessões.

## 15. Etapa 6 — Série Principal + Back-off (implementada)

### Modelagem

Conforme a observação do prompt, Top Set + Back-off é tratado como **estrutura** com **duas políticas de progressão independentes**, ambas no formato da Progressão Dupla:

- **Série principal** (`SetRole.topSet`): faixa própria; sobe pelo incremento quando chega ao topo com execução válida e, se configurado, RIR ≥ alvo e/ou RPE ≤ alvo.
- **Back-off** (`SetRole.backOff`): carga = principal × (1 − percentual), **arredondada ao incremento do equipamento**. Ele:
  - acompanha a principal quando ela sobe (se o back-off foi cumprido);
  - sobe sozinho quando todas as séries chegam ao topo da faixa dele;
  - **nunca sobe** se ficar abaixo do mínimo, tiver execução comprometida ou séries a menos.
- Pela regra 6, a redução planejada **não** passa pela verificação de "cargas diferentes" das outras estratégias. Para isso, `SessionChecks` foi dividido em `basics()` e `longBreak()`, que a estratégia reaproveita sem o `mixedLoads`.

### Identificação da série principal (regra 1)

1. Com papéis gravados nas séries (metas aceitas): usa `setRole`.
2. Sem papéis (primeira sessão, registro manual): a principal é a primeira série com a **maior carga** e o back-off são as mais leves.
3. Sem papéis e todas com a mesma carga: `manualReview` (`topSetNotIdentified`), sem chutar.

Só faz sentido com carga externa: `ProgressionStrategy.supportsLoadType` foi adicionado ao contrato, e a tela não oferece a estratégia para exercícios de peso corporal.

### Parâmetros (`TopSetBackOffConfig`)

| Parâmetro | Padrão | Observação |
|---|---|---|
| `topRepsMin` / `topRepsMax` | 4 / 6 | Faixa da principal (até 20). |
| `topTargetRir` / `topTargetRpe` | — | Opcionais, só para a principal. |
| `backOffSets` | 3 | 1–6. |
| `backOffPercent` | 15 | 5–40%. |
| `backOffRepsMin` / `backOffRepsMax` | 6 / 8 | Faixa do back-off (até 30). |
| `rounding`, `requireMarkedValid` | — | Iguais às demais. |

Motivos: `topSetUp`, `backOffUp` (meta própria do back-off), `bothUp`, `hold`, `withinRange`, além dos compartilhados.

### Interface

- **Sessão:** a série principal aparece como **"P"** no lugar do número, e a linha mostra "Meta principal X · back-off Y".
- **Sugestão:** metas agrupadas por papel ("Principal: 72.5 kg × 4–6 · Back-off: 3 × 62.5 kg × 8–10").
- **Ajustar (regra 7):** um grupo de campos por papel. A estrutura é preservada, e o RIR/RPE-alvo de cada papel também. Antes, o ajuste perdia o RPE-alvo; corrigido nesta etapa.

## 16. Etapa 7 — Progressão em Ondas (implementada)

### Modelagem

- **Onda = uma sessão.** O ciclo é a sequência de ondas configuradas; cada onda tem as **próprias séries**, cada uma com repetições e percentual da **carga de referência (100%)**. As ondas não precisam ser iguais (regra 2): número de séries, reps e percentuais variam livremente, inclusive dentro da onda (ex: 85% × 5, 90% × 3, 95% × 1).
- Cargas = referência × percentual, **arredondadas ao incremento** (`WaveLoadingStrategy.planFor`). As metas saem com `SetRole.wave`, na ordem planejada (regra 6).
- **Estado do ciclo** em `ProgressionResult.state` (`WaveState`): `cycle`, `wave` (próxima onda), `baseKg`, `failStreak` e `results` — o resultado de cada onda (`completed`, `failed`, `incomplete`, `interrupted`), com ciclo e sessão, limitado aos 12 mais recentes (regra 7). O estado é por versão da config: salvar uma config nova recomeça o ciclo.

### Avaliação da sessão

1. **Sem ciclo em andamento:** `cycleStart`. A referência vem de `baseKg` da config ou é deduzida da carga mais pesada da última sessão, de modo que a onda 1 comece na carga já usada. Sem carga registrada: `noLoad`.
2. As séries de trabalho (só as de papel `wave`, se houver) são comparadas **série a série, na ordem**, com o plano da onda: carga ≥ planejada, reps ≥ planejadas e execução válida. Um critério por série vai para a justificativa.
3. Transições:
   - **Concluída:** avança para a próxima onda (`waveCompleted`); a última fecha o ciclo (`cycleCompleted`), sobe a referência em `cycleIncrements` × incremento e recomeça pela onda 1.
   - **Malsucedida** (reps ou carga abaixo do planejado, execução inválida): repete a mesma onda com as mesmas metas (`waveFailed`) — **a intensidade nunca sobe depois dela** (regra 5). Ao atingir `failureTolerance` tentativas seguidas: `manualReview` (`waveStalled`).
   - **Incompleta** (séries a menos): repete, sem contar como falha (`waveIncomplete`).
   - **Falha técnica** em qualquer série interrompe a sequência (regra 4): repete a onda (`waveInterrupted`) ou recomeça o ciclo com a mesma referência (`cycleRestarted`), conforme `onTechnicalFailure`. Falha muscular (`toFailure`) não é falha técnica.
4. Validação de cargas (regra 3): percentuais de 30% a 120% em passos de 0,5, reps de 1 a 30, até 6 ondas de até 8 séries; uma onda cuja carga arredondada fique zerada gera `invalidLoads`.
5. Pausa longa e sessão sem séries de trabalho usam as verificações comuns, **sem perder a posição no ciclo**.
6. **Reavaliar** uma sessão (Histórico → corrigir série) parte do estado de **antes** da primeira avaliação dela (`ProgressionRepository.latestState(beforeSession:)`), para o ciclo não avançar duas vezes pela mesma sessão. A correção vale para qualquer estratégia que use estado.

### Parâmetros (`WaveLoadingConfig`)

| Parâmetro | Padrão | Observação |
|---|---|---|
| `waves` | 3×8 @75% → 3×6 @80% → 3×4 @85% | Lista de ondas; cada série com `reps` e `percent`. |
| `baseKg` | — | Referência do 1º ciclo; vazio = deduzida da última sessão. |
| `cycleIncrements` | 1 | Incrementos somados à referência por ciclo (1–5). |
| `failureTolerance` | 2 | Tentativas seguidas sem concluir a onda antes da revisão (1–5). |
| `onTechnicalFailure` | `repeatWave` | Ou `restartCycle`. |
| `rounding`, `requireMarkedValid` | — | Iguais às demais. |

Só carga externa (`supportsLoadType`), como na Etapa 6.

### Interface

- **Configuração:** cada onda num cartão com as séries (− / + de reps e de percentual, em passos de 2,5%), adicionar/remover séries e ondas (a nova onda copia a última, 5% mais pesada). Exemplos calculados pelo motor: onda 1 completa, com 1 rep a menos, com falha técnica, e a última onda completa.
- **Sessão:** a linha mostra o resumo das ondas, a faixa de cargas da onda ("Onda 60–72.5 kg") e o avanço ("Onda: 2/3").
- **Sugestão:** títulos próprios ("Início do ciclo de ondas", "Onda concluída!", "Ciclo concluído!", "Repita a onda", "Ciclo reiniciado") e as cargas em sequência ("65.0 kg × 5 · 67.5 kg × 3 · 72.5 kg × 1").
- **Ajustar:** o diálogo agora agrupa séries **seguidas com a mesma meta** (antes, por papel), então cada carga diferente da onda tem o próprio campo e a ordem é mantida. Principal + back-off continua igual.

### Limitação conhecida

- A sessão é avaliada contra o plano guardado no estado. Se a sugestão foi mantida ou ajustada para cargas menores, a onda não conta como concluída (conservador: a intensidade não sobe sem a onda planejada feita).

## 17. Etapa 8 — Refinamento e integração final (implementada)

### Troca de estratégia (inclusive no meio de um ciclo)

- **Corrigido:** salvar uma config nova deixava a sugestão pendente da versão anterior aberta. Aceitá-la mostrava "vale para o próximo treino", mas as metas eram ignoradas (só valem com a config vigente). Agora `saveConfig` marca essa pendente como `superseded`, e a tela avisa "A sugestão pendente da configuração anterior foi descartada". A recomendação antiga continua no histórico, intacta.
- **Corrigido:** Série Principal + Back-off travava em `topSetNotIdentified` quando a última sessão tinha papéis de outra estrutura (ex: séries de onda). Agora só os papéis `topSet`/`backOff` são usados; os demais caem no fallback pela maior carga.
- Comportamento conferido em `strategy_switch_test.dart`: dupla → linear, dupla → principal + back-off (meta aceita antiga não vale), ondas → principal + back-off, principal + back-off → dupla (revisão por `mixedLoads`), dupla → ondas (ciclo do zero), ondas → ondas com outros parâmetros (estado não vaza), desativar no meio do ciclo.

### UX e consistência visual

- O histórico da tela de configuração usa o **mesmo título e ícone** do card de sugestão (`recommendationHeadline`, antes duplicado com rótulos diferentes, como "Manter carga" para "Início do ciclo de ondas") e passa a mostrar a **estratégia** que gerou cada sugestão.

### Performance

- `loadHistory` sem N+1 (ver Parte I, G). Medição registrada; índices avaliados e não adotados.

### Compatibilidade e migrações

- Revisadas as migrations v1→v6: todas aditivas. Novo teste restaura backups v3, v4 e v5 pelo `BackupService`, migra e gera sugestão sobre o histórico antigo. O rebaixamento de versão usado nos testes virou helper (`test/helpers/legacy_db.dart`), compartilhado com o teste de migração.

### Documentação

- Parte I deste arquivo: guia técnico atual (arquitetura, estratégias, fluxo, histórico, decisões, como adicionar estratégia, performance, compatibilidade, exemplos, limitações).

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
