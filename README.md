# 💪 Overload — Workout Tracker

Aplicativo Android de gerenciamento de treinos desenvolvido em Flutter. Permite criar templates de treino reutilizáveis, registrar sessões com séries, pesos e repetições, acompanhar a evolução ao longo do tempo e detectar personal records automaticamente.

---

## Funcionalidades

### Treinos
- Criar, renomear e arquivar templates de treino
- Visualizar e restaurar treinos arquivados
- Reordenar exercícios dentro de um template via drag-and-drop
- Adicionar exercícios ao template a partir da biblioteca global

### Sessão Ativa
- Iniciar uma sessão a partir de um template
- Séries pré-preenchidas com os pesos e repetições da última sessão para referência imediata
- Chip **"↑ X kg"** exibindo o peso máximo da sessão anterior por exercício
- Suporte a três tipos de série: **carga** (kg × reps), **tempo** (segundos) e **peso corporal** (reps)
- Toggle de aquecimento e toggle de "até a falha" por série
- Timer de descanso com countdown e barra de progresso ao confirmar cada série
- **Estimativa de 1RM** (Epley) exibida em tempo real para séries de carga
- **Detecção de Personal Record**: série confirmada com carga acima do histórico recebe destaque âmbar e ícone de troféu
- Timer global da sessão com tela sempre ligada (wakelock)
- Navegação de saída protegida (continuar, encerrar ou descartar)
- Tela de resumo ao encerrar: duração, total de séries e volume total

### Biblioteca de Exercícios
- ~45 exercícios pré-cadastrados em 8 grupos musculares
- Busca por nome e filtro por grupo muscular
- Cadastro de exercícios personalizados com nome, grupo muscular, tipo de série e tempo de descanso padrão
- Arquivamento de exercícios com verificação de histórico

### Perfil & Peso Corporal
- Registro de peso com data
- Edição de registros existentes (peso e data)
- Exclusão de registros
- Gráfico de evolução do peso com seleção de período (1 semana / 1 mês / 6 meses)

### Relatórios
- **Por exercício**: gráfico de carga máxima e volume total ao longo do tempo
- **Por treino**: gráfico de volume por sessão, séries por sessão e tabela de sessões recentes
- Filtro de período: 1 mês / 3 meses / 6 meses / tudo
- **Export CSV**: exporta todo o histórico de sessões (data, treino, exercício, carga, reps, volume, etc.) via compartilhamento nativo do Android

---

## Stack

| Camada | Tecnologia |
|---|---|
| UI | Flutter 3.44 / Dart 3.12 |
| Estado | Riverpod 2 (`Provider`, `StateProvider`, `StreamProvider`, `FutureProvider`, `.family`, `.autoDispose`) |
| Banco de dados | Drift (SQLite) com geração de código via `build_runner` |
| Gráficos | fl_chart |
| Export | csv + share_plus |
| Utilidades | intl, wakelock_plus, path_provider |

---

## Estrutura do Projeto

```
lib/
├── main.dart                        # Inicialização, locale pt_BR
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
│   │       └── report_repository.dart        # Queries de progresso e PR
│   ├── services/
│   │   └── export_service.dart      # Geração e compartilhamento do CSV
│   ├── theme/
│   │   └── app_theme.dart           # Tema escuro com seed color #6C63FF
│   └── utils/
│       └── one_rm_calculator.dart   # Fórmula de Epley para 1RM
│
└── features/
    ├── workout_templates/
    │   ├── providers/workout_providers.dart
    │   └── screens/
    │       ├── workout_list_screen.dart      # Lista com swipe-to-archive
    │       ├── workout_detail_screen.dart    # Reorder + gerenciar exercícios
    │       ├── exercise_picker_screen.dart   # Seletor da biblioteca
    │       └── archived_workouts_screen.dart # Treinos arquivados + restaurar
    │
    ├── exercise_library/
    │   ├── providers/exercise_providers.dart
    │   └── screens/
    │       ├── exercise_library_screen.dart  # Busca e filtros
    │       └── add_exercise_screen.dart      # Formulário de cadastro
    │
    ├── active_session/
    │   ├── providers/session_providers.dart
    │   └── screens/
    │   │   ├── active_session_screen.dart    # Tela principal da sessão
    │   │   └── session_summary_screen.dart   # Resumo pós-treino
    │   └── widgets/
    │       ├── exercise_session_card.dart    # Card por exercício com hints e PR
    │       └── set_row_widget.dart           # Linha de série com inputs e PR badge
    │
    ├── reports/
    │   ├── providers/report_providers.dart
    │   ├── screens/reports_screen.dart       # Tabs por exercício e por treino
    │   └── widgets/report_chart.dart         # Componente de gráfico reutilizável
    │
    └── profile/
        ├── providers/profile_providers.dart
        └── screens/profile_screen.dart       # Peso corporal + gráfico
```

---

## Banco de Dados

Schema gerenciado pelo Drift. Todas as tabelas estão definidas em `lib/core/database/tables.dart`.

```
Exercises
  id, name, muscleGroup, setType (weight|time|bodyweight),
  restSeconds, isArchived, createdAt

WorkoutTemplates
  id, name, isArchived, createdAt

TemplateExercises
  id, templateId → WorkoutTemplates, exerciseId → Exercises, position

Sessions
  id, templateId → WorkoutTemplates, startedAt, finishedAt

SessionExercises
  id, sessionId → Sessions, exerciseId → Exercises, position

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
Ao iniciar uma nova sessão, o `startSession` consulta as séries da última sessão finalizada para aquele template e pré-cria o mesmo número de `SessionSets` vazios (sem valores no banco). Os valores da sessão anterior chegam como "hints" via `previousSetsProvider` e preenchem os controllers de texto — o usuário ainda precisa confirmar cada série explicitamente. O `didUpdateWidget` garante que os campos sejam preenchidos mesmo quando o provider resolve após a renderização inicial.

### Detecção de Personal Record
O `exercisePrWeightProvider` consulta o maior peso registrado em séries não-aquecimento de sessões **finalizadas**. Como a sessão atual não está finalizada, ela é automaticamente excluída da comparação. Qualquer série confirmada que supere esse valor (ou a primeira série de um exercício, quando não há histórico) é destacada.

### Estimativa de 1RM
Fórmula de Epley: `1RM = peso × (1 + reps / 30)`, arredondado para o múltiplo de 0,25 kg mais próximo. Aplicada apenas para séries com 3–20 repetições.

---

## Como Executar

### Pré-requisitos
- Flutter 3.44+ instalado e no PATH
- Android SDK configurado (`flutter doctor` sem erros críticos)
- Dispositivo Android físico ou emulador com API 21+

### Instalação

```bash
# Clonar o repositório
git clone https://github.com/seu-usuario/overload.git
cd overload

# Instalar dependências
flutter pub get

# Gerar código do Drift (necessário após mudanças nas tabelas)
dart run build_runner build --delete-conflicting-outputs

# Rodar no dispositivo conectado
flutter run
```

### Build de release

```bash
flutter build apk --release
# APK gerado em: build/app/outputs/flutter-apk/app-release.apk
```

---

## Configuração Android

O arquivo `android/app/build.gradle.kts` requer as seguintes configurações para compatibilidade com `flutter_local_notifications`:

```kotlin
android {
    compileOptions {
        isCoreLibraryDesugaringEnabled = true
    }
    defaultConfig {
        minSdk = 21
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```

---

## Regenerar o banco após mudanças no schema

Sempre que as tabelas em `tables.dart` forem alteradas:

1. Incrementar `schemaVersion` em `app_database.dart`
2. Adicionar a migration correspondente no `MigrationStrategy`
3. Rodar `dart run build_runner build --delete-conflicting-outputs`

---

## Licença

MIT
