part of 'app_database.dart';

List<ExercisesCompanion> get seedExercises => [
      // Peito
      _ex('Supino Reto', 'Peito', SetType.weight),
      _ex('Supino Inclinado', 'Peito', SetType.weight),
      _ex('Supino Declinado', 'Peito', SetType.weight),
      _ex('Crucifixo', 'Peito', SetType.weight),
      _ex('Crossover', 'Peito', SetType.weight),
      _ex('Flexão de Braço', 'Peito', SetType.bodyweight),

      // Costas
      _ex('Barra Fixa', 'Costas', SetType.bodyweight),
      _ex('Puxada Frente', 'Costas', SetType.weight),
      _ex('Puxada Triângulo', 'Costas', SetType.weight),
      _ex('Remada Curvada', 'Costas', SetType.weight),
      _ex('Remada Unilateral', 'Costas', SetType.weight),
      _ex('Remada Máquina', 'Costas', SetType.weight),

      // Pernas
      _ex('Agachamento', 'Pernas', SetType.weight),
      _ex('Leg Press', 'Pernas', SetType.weight),
      _ex('Extensão de Pernas', 'Pernas', SetType.weight),
      _ex('Flexão de Pernas', 'Pernas', SetType.weight),
      _ex('Stiff', 'Pernas', SetType.weight),
      _ex('Afundo', 'Pernas', SetType.weight),
      _ex('Cadeira Adutora', 'Pernas', SetType.weight),
      _ex('Panturrilha em Pé', 'Pernas', SetType.weight),

      // Ombros
      _ex('Desenvolvimento com Halteres', 'Ombros', SetType.weight),
      _ex('Desenvolvimento com Barra', 'Ombros', SetType.weight),
      _ex('Elevação Lateral', 'Ombros', SetType.weight),
      _ex('Elevação Frontal', 'Ombros', SetType.weight),
      _ex('Crucifixo Invertido', 'Ombros', SetType.weight),
      _ex('Encolhimento', 'Ombros', SetType.weight),

      // Bíceps
      _ex('Rosca Direta', 'Bíceps', SetType.weight),
      _ex('Rosca Alternada', 'Bíceps', SetType.weight),
      _ex('Rosca Martelo', 'Bíceps', SetType.weight),
      _ex('Rosca Concentrada', 'Bíceps', SetType.weight),
      _ex('Rosca Scott', 'Bíceps', SetType.weight),

      // Tríceps
      _ex('Tríceps Pulley', 'Tríceps', SetType.weight),
      _ex('Tríceps Corda', 'Tríceps', SetType.weight),
      _ex('Tríceps Francês', 'Tríceps', SetType.weight),
      _ex('Tríceps Testa', 'Tríceps', SetType.weight),
      _ex('Mergulho', 'Tríceps', SetType.bodyweight),

      // Core
      _ex('Prancha', 'Core', SetType.time, restSeconds: 60),
      _ex('Abdominal Crunch', 'Core', SetType.bodyweight),
      _ex('Abdominal Oblíquo', 'Core', SetType.bodyweight),
      _ex('Elevação de Pernas', 'Core', SetType.bodyweight),
      _ex('Russian Twist', 'Core', SetType.bodyweight),

      // Cardio
      _ex('Esteira', 'Cardio', SetType.time, restSeconds: 0),
      _ex('Bicicleta', 'Cardio', SetType.time, restSeconds: 0),
      _ex('Elíptico', 'Cardio', SetType.time, restSeconds: 0),
      _ex('Pular Corda', 'Cardio', SetType.time, restSeconds: 30),
    ];

ExercisesCompanion _ex(
  String name,
  String muscleGroup,
  SetType setType, {
  int restSeconds = 90,
}) {
  return ExercisesCompanion.insert(
    name: name,
    muscleGroup: muscleGroup,
    setType: setType,
    restSeconds: Value(restSeconds),
  );
}
