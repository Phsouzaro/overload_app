# 💪 Overload — Workout Tracker

Aplicativo Android de gerenciamento de treinos desenvolvido em Flutter. Permite criar templates de treino reutilizáveis, registrar sessões com séries, pesos e repetições, acompanhar a evolução ao longo do tempo e detectar personal records automaticamente.

---

## Funcionalidades

### Treinos
- Criar, renomear e arquivar templates de treino
- Visualizar e restaurar treinos arquivados
- Reordenar treinos na tela inicial e exercícios dentro de um template via drag-and-drop
- Adicionar exercícios ao template a partir da biblioteca global (ou criar um novo direto no seletor)
- **Descanso por treino**: tocar num exercício do template define um descanso só para aquele treino, sem mudar o padrão do exercício
- **Compartilhar e importar templates** em arquivo `.overload` (JSON). A importação é tudo-ou-nada e reaproveita exercícios da biblioteca pelo nome

### Sessão Ativa
- Iniciar uma sessão a partir de um template
- Séries pré-criadas com base na última vez em que cada exercício foi feito (em qualquer treino), com os valores anteriores como sugestão
- Chip **"↑ X kg"** exibindo o peso máximo da sessão anterior por exercício
- Histórico completo do exercício em um bottom sheet, sem sair da sessão
- Suporte a três tipos de série: **carga** (peso × reps), **tempo** (segundos) e **peso corporal** (reps)
- Toggle de aquecimento e toggle de "até a falha" por série; série só é confirmada com os campos obrigatórios preenchidos
- Timer de descanso com countdown e barra de progresso ao confirmar cada série, com **notificação e vibração** ao terminar (funciona com o app em segundo plano)
- **Estimativa de 1RM** (Epley) exibida em tempo real para séries de carga
- **Detecção de Personal Record**: série confirmada com carga acima do histórico recebe destaque âmbar e ícone de troféu
- Cronômetro da sessão baseado no horário de início salvo, com tela sempre ligada (wakelock)
- Saída protegida: encerrar, **continuar depois** ou descartar. Um treino pausado aparece na tela inicial para ser retomado ou descartado
- Tela de resumo ao encerrar: duração, total de séries e volume total. Séries deixadas em branco são descartadas

### Histórico
- Lista de sessões finalizadas com duração
- Detalhe de cada sessão com todas as séries por exercício
- **Anotações** por sessão, escritas durante o treino (ícone de nota na barra) ou depois, no detalhe

### Biblioteca de Exercícios
- ~45 exercícios pré-cadastrados em 8 grupos musculares
- Busca por nome e filtro por grupo muscular
- Cadastro e edição de exercícios personalizados com nome, grupo muscular, tipo de série e tempo de descanso padrão
- Histórico de cargas por exercício
- Arquivamento de exercícios com verificação de histórico

### Perfil & Peso Corporal
- Registro, edição e exclusão de pesos com data
- Gráfico de evolução do peso com seleção de período (1 semana / 1 mês / 6 meses)

### Relatórios
- **Por exercício**: gráfico de carga máxima e volume total ao longo do tempo
- **Por treino**: gráfico de volume por sessão, séries por sessão e tabela de sessões recentes
- Filtro de período: 1 mês / 3 meses / 6 meses / tudo
- **Export CSV**: exporta todo o histórico de sessões (data, treino, exercício, carga, reps, volume, etc.) via compartilhamento nativo do Android

### Configurações
- Unidade de peso **kg ou lbs**, aplicada em todo o app (o banco sempre guarda kg)
- Descanso padrão para novos exercícios

---

## Stack

| Camada | Tecnologia |
|---|---|
| UI | Flutter 3.47 / Dart 3.13 |
| Estado | Riverpod 2 (`Provider`, `StateProvider`, `NotifierProvider`, `StreamProvider`, `FutureProvider`, `.family`, `.autoDispose`) |
| Banco de dados | Drift (SQLite) com geração de código via `build_runner` |
| Gráficos | fl_chart |
| Export / Import | csv, share_plus, file_picker |
| Notificações | flutter_local_notifications + timezone |
| Utilidades | intl, wakelock_plus, path_provider, shared_preferences, flutter_svg |

---

## Estrutura do Projeto

```
lib/
├── main.dart                        # Inicialização, locale pt_BR, SharedPreferences
├── app.dart                         # MaterialApp, tema, NavigationBar
│
├── core/
│   ├── constants/
│   │   └── muscle_groups.dart       # Lista de grupos musculares
│   ├── database/
│   │   ├── tables.dart              # Definição das tabelas Drift
│   │   ├── app_database.dart        # @DriftDatabase, migrations
│   │   ├── app_database.g.dart      # Gerado pelo build_runner
│   │   ├── seed_data.dart           # Exercícios pré-cadastrados (part of app_database)
│   │   ├── database_provider.dart   # Provider Riverpod do AppDatabase
│   │   └── repositories/
│   │       ├── workout_repository.dart       # Templates e exercícios do template
│   │       ├── exercise_repository.dart      # CRUD da biblioteca de exercícios
│   │       ├── session_repository.dart       # Sessões, séries, pré-população
│   │       ├── body_weight_repository.dart   # Registros de peso corporal
│   │       └── report_repository.dart        # Queries de progresso, histórico e PR
│   ├── services/
│   │   ├── export_service.dart              # CSV e compartilhamento de templates
│   │   ├── import_service.dart              # Importação de templates .overload
│   │   └── rest_notification_service.dart   # Notificação do fim do descanso
│   ├── theme/
│   │   └── app_theme.dart           # Tema escuro com seed color #6C63FF
│   └── utils/
│       ├── one_rm_calculator.dart   # Fórmula de Epley para 1RM
│       └── unit_converter.dart      # Conversão e formatação kg/lbs
│
└── features/
    ├── workout_templates/           # Lista, detalhe, seletor e arquivados
    ├── exercise_library/            # Biblioteca, cadastro e histórico por exercício
    ├── active_session/              # Sessão ativa, cards de exercício e resumo
    ├── session_history/             # Lista e detalhe de sessões finalizadas
    ├── reports/                     # Relatórios por exercício e por treino
    ├── profile/                     # Peso corporal + gráfico
    └── settings/                    # Unidade de peso e descanso padrão
```

Cada feature segue o padrão `providers/` + `screens/` (+ `widgets/` quando necessário).

---

## Banco de Dados

Schema gerenciado pelo Drift. Todas as tabelas estão definidas em `lib/core/database/tables.dart`.

```
Exercises
  id, name, muscleGroup, setType (weight|time|bodyweight),
  restSeconds, isArchived, createdAt

WorkoutTemplates
  id, name, isArchived, createdAt, position

TemplateExercises
  id, templateId → WorkoutTemplates, exerciseId → Exercises, position,
  restSecondsOverride

Sessions
  id, templateId → WorkoutTemplates, startedAt, finishedAt, notes

SessionExercises
  id, sessionId → Sessions, exerciseId → Exercises, position,
  restSeconds (descanso usado na sessão; v3)

SessionSets
  id, sessionExerciseId → SessionExercises, setType,
  weightKg, reps, durationSeconds,
  isWarmup, toFailure, position

BodyWeightEntries
  id, weightKg, recordedAt
```

> **Foreign keys** estão habilitadas via `PRAGMA foreign_keys = ON` no `beforeOpen` do Drift.

---

## Decisões de Arquitetura

### Repository Pattern
Cada domínio tem seu próprio repositório (`WorkoutRepository`, `SessionRepository`, etc.) que encapsula toda lógica de acesso ao banco. As telas interagem apenas com providers Riverpod, nunca com Drift diretamente.

### `seed_data.dart` como `part of`
Os dados iniciais precisam acessar as classes `Companion` geradas pelo Drift (ex: `ExercisesCompanion`), que só existem dentro do contexto do `app_database.dart`. Por isso, `seed_data.dart` usa `part of 'app_database.dart'` em vez de ser um arquivo independente.

### Pré-população de séries
Ao iniciar uma sessão, o `startSession` busca a última sessão finalizada em que cada exercício teve séries preenchidas (em qualquer template) e pré-cria o mesmo número de `SessionSets` vazios. Os valores anteriores chegam como "hints" via `previousSetsProvider` e preenchem os campos — o usuário ainda precisa confirmar cada série. Ao encerrar, as séries que ficaram vazias são apagadas, e todas as consultas usam `isFilledSet` para ignorá-las.

### Ciclo de vida da sessão
Só existe uma sessão ativa (sem `finishedAt`) por vez, exposta por `activeSessionProvider`. Ao iniciar outro treino com uma sessão em andamento, o app pergunta se deve retomá-la ou descartá-la; "Descartar" apaga a sessão com `discardSession`. Cronômetro e descanso são calculados a partir de horários absolutos (`startedAt`, fim do descanso), então continuam corretos com o app em segundo plano.

### Detecção de Personal Record
O `exercisePrWeightProvider` consulta o maior peso registrado em séries não-aquecimento de sessões **finalizadas**. Como a sessão atual não está finalizada, ela é automaticamente excluída da comparação. Qualquer série confirmada que supere esse valor (ou a primeira série de um exercício, quando não há histórico) é destacada.

### Estimativa de 1RM
Fórmula de Epley: `1RM = peso × (1 + reps / 30)`, arredondado para o múltiplo de 0,25 kg mais próximo. Aplicada apenas para séries com 3–20 repetições.

---

## Como Executar

### Pré-requisitos
- Flutter 3.47+ instalado e no PATH
- Android SDK configurado (`flutter doctor` sem erros críticos)
- Dispositivo Android físico ou emulador com API 21+

### Instalação

```bash
# Instalar dependências
flutter pub get

# Gerar código do Drift (necessário após mudanças nas tabelas)
dart run build_runner build --delete-conflicting-outputs

# Rodar no dispositivo conectado
flutter run
```

### Testes

Os testes unitários usam o Drift com banco SQLite em memória. No Windows, a `sqlite3.dll` ([sqlite.org/download](https://www.sqlite.org/download.html)) precisa estar no PATH.

```bash
flutter test
flutter analyze
```

### Build de release

```bash
flutter build apk --release
# APK gerado em: build/app/outputs/flutter-apk/app-release.apk
```

---

## Configuração Android

O `flutter_local_notifications` exige desugaring no `android/app/build.gradle.kts`:

```kotlin
android {
    compileOptions {
        isCoreLibraryDesugaringEnabled = true
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```

O `AndroidManifest.xml` declara o `ScheduledNotificationReceiver` do plugin e a permissão `SCHEDULE_EXACT_ALARM`. Sem essa permissão concedida, a notificação do descanso é agendada de forma inexata.

---

## Regenerar o banco após mudanças no schema

Sempre que as tabelas em `tables.dart` forem alteradas:

1. Incrementar `schemaVersion` em `app_database.dart`
2. Adicionar a migration correspondente no `MigrationStrategy`
3. Rodar `dart run build_runner build --delete-conflicting-outputs`

---

## Licença

MIT
