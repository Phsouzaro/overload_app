// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ExercisesTable extends Exercises
    with TableInfo<$ExercisesTable, Exercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _muscleGroupMeta = const VerificationMeta(
    'muscleGroup',
  );
  @override
  late final GeneratedColumn<String> muscleGroup = GeneratedColumn<String>(
    'muscle_group',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SetType, String> setType =
      GeneratedColumn<String>(
        'set_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SetType>($ExercisesTable.$convertersetType);
  static const VerificationMeta _restSecondsMeta = const VerificationMeta(
    'restSeconds',
  );
  @override
  late final GeneratedColumn<int> restSeconds = GeneratedColumn<int>(
    'rest_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(90),
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    muscleGroup,
    setType,
    restSeconds,
    isArchived,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercises';
  @override
  VerificationContext validateIntegrity(
    Insertable<Exercise> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('muscle_group')) {
      context.handle(
        _muscleGroupMeta,
        muscleGroup.isAcceptableOrUnknown(
          data['muscle_group']!,
          _muscleGroupMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_muscleGroupMeta);
    }
    if (data.containsKey('rest_seconds')) {
      context.handle(
        _restSecondsMeta,
        restSeconds.isAcceptableOrUnknown(
          data['rest_seconds']!,
          _restSecondsMeta,
        ),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Exercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Exercise(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      muscleGroup: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}muscle_group'],
      )!,
      setType: $ExercisesTable.$convertersetType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}set_type'],
        )!,
      ),
      restSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rest_seconds'],
      )!,
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ExercisesTable createAlias(String alias) {
    return $ExercisesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SetType, String, String> $convertersetType =
      const EnumNameConverter<SetType>(SetType.values);
}

class Exercise extends DataClass implements Insertable<Exercise> {
  final int id;
  final String name;
  final String muscleGroup;
  final SetType setType;
  final int restSeconds;
  final bool isArchived;
  final DateTime createdAt;
  const Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.setType,
    required this.restSeconds,
    required this.isArchived,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['muscle_group'] = Variable<String>(muscleGroup);
    {
      map['set_type'] = Variable<String>(
        $ExercisesTable.$convertersetType.toSql(setType),
      );
    }
    map['rest_seconds'] = Variable<int>(restSeconds);
    map['is_archived'] = Variable<bool>(isArchived);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ExercisesCompanion toCompanion(bool nullToAbsent) {
    return ExercisesCompanion(
      id: Value(id),
      name: Value(name),
      muscleGroup: Value(muscleGroup),
      setType: Value(setType),
      restSeconds: Value(restSeconds),
      isArchived: Value(isArchived),
      createdAt: Value(createdAt),
    );
  }

  factory Exercise.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Exercise(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      muscleGroup: serializer.fromJson<String>(json['muscleGroup']),
      setType: $ExercisesTable.$convertersetType.fromJson(
        serializer.fromJson<String>(json['setType']),
      ),
      restSeconds: serializer.fromJson<int>(json['restSeconds']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'muscleGroup': serializer.toJson<String>(muscleGroup),
      'setType': serializer.toJson<String>(
        $ExercisesTable.$convertersetType.toJson(setType),
      ),
      'restSeconds': serializer.toJson<int>(restSeconds),
      'isArchived': serializer.toJson<bool>(isArchived),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Exercise copyWith({
    int? id,
    String? name,
    String? muscleGroup,
    SetType? setType,
    int? restSeconds,
    bool? isArchived,
    DateTime? createdAt,
  }) => Exercise(
    id: id ?? this.id,
    name: name ?? this.name,
    muscleGroup: muscleGroup ?? this.muscleGroup,
    setType: setType ?? this.setType,
    restSeconds: restSeconds ?? this.restSeconds,
    isArchived: isArchived ?? this.isArchived,
    createdAt: createdAt ?? this.createdAt,
  );
  Exercise copyWithCompanion(ExercisesCompanion data) {
    return Exercise(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      muscleGroup: data.muscleGroup.present
          ? data.muscleGroup.value
          : this.muscleGroup,
      setType: data.setType.present ? data.setType.value : this.setType,
      restSeconds: data.restSeconds.present
          ? data.restSeconds.value
          : this.restSeconds,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Exercise(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('muscleGroup: $muscleGroup, ')
          ..write('setType: $setType, ')
          ..write('restSeconds: $restSeconds, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    muscleGroup,
    setType,
    restSeconds,
    isArchived,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Exercise &&
          other.id == this.id &&
          other.name == this.name &&
          other.muscleGroup == this.muscleGroup &&
          other.setType == this.setType &&
          other.restSeconds == this.restSeconds &&
          other.isArchived == this.isArchived &&
          other.createdAt == this.createdAt);
}

class ExercisesCompanion extends UpdateCompanion<Exercise> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> muscleGroup;
  final Value<SetType> setType;
  final Value<int> restSeconds;
  final Value<bool> isArchived;
  final Value<DateTime> createdAt;
  const ExercisesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.muscleGroup = const Value.absent(),
    this.setType = const Value.absent(),
    this.restSeconds = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ExercisesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String muscleGroup,
    required SetType setType,
    this.restSeconds = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : name = Value(name),
       muscleGroup = Value(muscleGroup),
       setType = Value(setType);
  static Insertable<Exercise> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? muscleGroup,
    Expression<String>? setType,
    Expression<int>? restSeconds,
    Expression<bool>? isArchived,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (muscleGroup != null) 'muscle_group': muscleGroup,
      if (setType != null) 'set_type': setType,
      if (restSeconds != null) 'rest_seconds': restSeconds,
      if (isArchived != null) 'is_archived': isArchived,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ExercisesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? muscleGroup,
    Value<SetType>? setType,
    Value<int>? restSeconds,
    Value<bool>? isArchived,
    Value<DateTime>? createdAt,
  }) {
    return ExercisesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      setType: setType ?? this.setType,
      restSeconds: restSeconds ?? this.restSeconds,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (muscleGroup.present) {
      map['muscle_group'] = Variable<String>(muscleGroup.value);
    }
    if (setType.present) {
      map['set_type'] = Variable<String>(
        $ExercisesTable.$convertersetType.toSql(setType.value),
      );
    }
    if (restSeconds.present) {
      map['rest_seconds'] = Variable<int>(restSeconds.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExercisesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('muscleGroup: $muscleGroup, ')
          ..write('setType: $setType, ')
          ..write('restSeconds: $restSeconds, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $WorkoutTemplatesTable extends WorkoutTemplates
    with TableInfo<$WorkoutTemplatesTable, WorkoutTemplate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _groupNameMeta = const VerificationMeta(
    'groupName',
  );
  @override
  late final GeneratedColumn<String> groupName = GeneratedColumn<String>(
    'group_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    isArchived,
    createdAt,
    position,
    groupName,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkoutTemplate> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    if (data.containsKey('group_name')) {
      context.handle(
        _groupNameMeta,
        groupName.isAcceptableOrUnknown(data['group_name']!, _groupNameMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutTemplate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutTemplate(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      groupName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_name'],
      ),
    );
  }

  @override
  $WorkoutTemplatesTable createAlias(String alias) {
    return $WorkoutTemplatesTable(attachedDatabase, alias);
  }
}

class WorkoutTemplate extends DataClass implements Insertable<WorkoutTemplate> {
  final int id;
  final String name;
  final bool isArchived;
  final DateTime createdAt;
  final int position;
  final String? groupName;
  const WorkoutTemplate({
    required this.id,
    required this.name,
    required this.isArchived,
    required this.createdAt,
    required this.position,
    this.groupName,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['is_archived'] = Variable<bool>(isArchived);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['position'] = Variable<int>(position);
    if (!nullToAbsent || groupName != null) {
      map['group_name'] = Variable<String>(groupName);
    }
    return map;
  }

  WorkoutTemplatesCompanion toCompanion(bool nullToAbsent) {
    return WorkoutTemplatesCompanion(
      id: Value(id),
      name: Value(name),
      isArchived: Value(isArchived),
      createdAt: Value(createdAt),
      position: Value(position),
      groupName: groupName == null && nullToAbsent
          ? const Value.absent()
          : Value(groupName),
    );
  }

  factory WorkoutTemplate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutTemplate(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      position: serializer.fromJson<int>(json['position']),
      groupName: serializer.fromJson<String?>(json['groupName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'isArchived': serializer.toJson<bool>(isArchived),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'position': serializer.toJson<int>(position),
      'groupName': serializer.toJson<String?>(groupName),
    };
  }

  WorkoutTemplate copyWith({
    int? id,
    String? name,
    bool? isArchived,
    DateTime? createdAt,
    int? position,
    Value<String?> groupName = const Value.absent(),
  }) => WorkoutTemplate(
    id: id ?? this.id,
    name: name ?? this.name,
    isArchived: isArchived ?? this.isArchived,
    createdAt: createdAt ?? this.createdAt,
    position: position ?? this.position,
    groupName: groupName.present ? groupName.value : this.groupName,
  );
  WorkoutTemplate copyWithCompanion(WorkoutTemplatesCompanion data) {
    return WorkoutTemplate(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      position: data.position.present ? data.position.value : this.position,
      groupName: data.groupName.present ? data.groupName.value : this.groupName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutTemplate(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('position: $position, ')
          ..write('groupName: $groupName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, isArchived, createdAt, position, groupName);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutTemplate &&
          other.id == this.id &&
          other.name == this.name &&
          other.isArchived == this.isArchived &&
          other.createdAt == this.createdAt &&
          other.position == this.position &&
          other.groupName == this.groupName);
}

class WorkoutTemplatesCompanion extends UpdateCompanion<WorkoutTemplate> {
  final Value<int> id;
  final Value<String> name;
  final Value<bool> isArchived;
  final Value<DateTime> createdAt;
  final Value<int> position;
  final Value<String?> groupName;
  const WorkoutTemplatesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.position = const Value.absent(),
    this.groupName = const Value.absent(),
  });
  WorkoutTemplatesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.isArchived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.position = const Value.absent(),
    this.groupName = const Value.absent(),
  }) : name = Value(name);
  static Insertable<WorkoutTemplate> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<bool>? isArchived,
    Expression<DateTime>? createdAt,
    Expression<int>? position,
    Expression<String>? groupName,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (isArchived != null) 'is_archived': isArchived,
      if (createdAt != null) 'created_at': createdAt,
      if (position != null) 'position': position,
      if (groupName != null) 'group_name': groupName,
    });
  }

  WorkoutTemplatesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<bool>? isArchived,
    Value<DateTime>? createdAt,
    Value<int>? position,
    Value<String?>? groupName,
  }) {
    return WorkoutTemplatesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      position: position ?? this.position,
      groupName: groupName ?? this.groupName,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (groupName.present) {
      map['group_name'] = Variable<String>(groupName.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('position: $position, ')
          ..write('groupName: $groupName')
          ..write(')'))
        .toString();
  }
}

class $TemplateExercisesTable extends TemplateExercises
    with TableInfo<$TemplateExercisesTable, TemplateExercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TemplateExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<int> templateId = GeneratedColumn<int>(
    'template_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<int> exerciseId = GeneratedColumn<int>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _restSecondsOverrideMeta =
      const VerificationMeta('restSecondsOverride');
  @override
  late final GeneratedColumn<int> restSecondsOverride = GeneratedColumn<int>(
    'rest_seconds_override',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    templateId,
    exerciseId,
    position,
    restSecondsOverride,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'template_exercises';
  @override
  VerificationContext validateIntegrity(
    Insertable<TemplateExercise> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    } else if (isInserting) {
      context.missing(_templateIdMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('rest_seconds_override')) {
      context.handle(
        _restSecondsOverrideMeta,
        restSecondsOverride.isAcceptableOrUnknown(
          data['rest_seconds_override']!,
          _restSecondsOverrideMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TemplateExercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TemplateExercise(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}template_id'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}exercise_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      restSecondsOverride: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rest_seconds_override'],
      ),
    );
  }

  @override
  $TemplateExercisesTable createAlias(String alias) {
    return $TemplateExercisesTable(attachedDatabase, alias);
  }
}

class TemplateExercise extends DataClass
    implements Insertable<TemplateExercise> {
  final int id;
  final int templateId;
  final int exerciseId;
  final int position;
  final int? restSecondsOverride;
  const TemplateExercise({
    required this.id,
    required this.templateId,
    required this.exerciseId,
    required this.position,
    this.restSecondsOverride,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['template_id'] = Variable<int>(templateId);
    map['exercise_id'] = Variable<int>(exerciseId);
    map['position'] = Variable<int>(position);
    if (!nullToAbsent || restSecondsOverride != null) {
      map['rest_seconds_override'] = Variable<int>(restSecondsOverride);
    }
    return map;
  }

  TemplateExercisesCompanion toCompanion(bool nullToAbsent) {
    return TemplateExercisesCompanion(
      id: Value(id),
      templateId: Value(templateId),
      exerciseId: Value(exerciseId),
      position: Value(position),
      restSecondsOverride: restSecondsOverride == null && nullToAbsent
          ? const Value.absent()
          : Value(restSecondsOverride),
    );
  }

  factory TemplateExercise.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TemplateExercise(
      id: serializer.fromJson<int>(json['id']),
      templateId: serializer.fromJson<int>(json['templateId']),
      exerciseId: serializer.fromJson<int>(json['exerciseId']),
      position: serializer.fromJson<int>(json['position']),
      restSecondsOverride: serializer.fromJson<int?>(
        json['restSecondsOverride'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'templateId': serializer.toJson<int>(templateId),
      'exerciseId': serializer.toJson<int>(exerciseId),
      'position': serializer.toJson<int>(position),
      'restSecondsOverride': serializer.toJson<int?>(restSecondsOverride),
    };
  }

  TemplateExercise copyWith({
    int? id,
    int? templateId,
    int? exerciseId,
    int? position,
    Value<int?> restSecondsOverride = const Value.absent(),
  }) => TemplateExercise(
    id: id ?? this.id,
    templateId: templateId ?? this.templateId,
    exerciseId: exerciseId ?? this.exerciseId,
    position: position ?? this.position,
    restSecondsOverride: restSecondsOverride.present
        ? restSecondsOverride.value
        : this.restSecondsOverride,
  );
  TemplateExercise copyWithCompanion(TemplateExercisesCompanion data) {
    return TemplateExercise(
      id: data.id.present ? data.id.value : this.id,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      position: data.position.present ? data.position.value : this.position,
      restSecondsOverride: data.restSecondsOverride.present
          ? data.restSecondsOverride.value
          : this.restSecondsOverride,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TemplateExercise(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('position: $position, ')
          ..write('restSecondsOverride: $restSecondsOverride')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, templateId, exerciseId, position, restSecondsOverride);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TemplateExercise &&
          other.id == this.id &&
          other.templateId == this.templateId &&
          other.exerciseId == this.exerciseId &&
          other.position == this.position &&
          other.restSecondsOverride == this.restSecondsOverride);
}

class TemplateExercisesCompanion extends UpdateCompanion<TemplateExercise> {
  final Value<int> id;
  final Value<int> templateId;
  final Value<int> exerciseId;
  final Value<int> position;
  final Value<int?> restSecondsOverride;
  const TemplateExercisesCompanion({
    this.id = const Value.absent(),
    this.templateId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.position = const Value.absent(),
    this.restSecondsOverride = const Value.absent(),
  });
  TemplateExercisesCompanion.insert({
    this.id = const Value.absent(),
    required int templateId,
    required int exerciseId,
    required int position,
    this.restSecondsOverride = const Value.absent(),
  }) : templateId = Value(templateId),
       exerciseId = Value(exerciseId),
       position = Value(position);
  static Insertable<TemplateExercise> custom({
    Expression<int>? id,
    Expression<int>? templateId,
    Expression<int>? exerciseId,
    Expression<int>? position,
    Expression<int>? restSecondsOverride,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (templateId != null) 'template_id': templateId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (position != null) 'position': position,
      if (restSecondsOverride != null)
        'rest_seconds_override': restSecondsOverride,
    });
  }

  TemplateExercisesCompanion copyWith({
    Value<int>? id,
    Value<int>? templateId,
    Value<int>? exerciseId,
    Value<int>? position,
    Value<int?>? restSecondsOverride,
  }) {
    return TemplateExercisesCompanion(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      exerciseId: exerciseId ?? this.exerciseId,
      position: position ?? this.position,
      restSecondsOverride: restSecondsOverride ?? this.restSecondsOverride,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<int>(templateId.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<int>(exerciseId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (restSecondsOverride.present) {
      map['rest_seconds_override'] = Variable<int>(restSecondsOverride.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TemplateExercisesCompanion(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('position: $position, ')
          ..write('restSecondsOverride: $restSecondsOverride')
          ..write(')'))
        .toString();
  }
}

class $SessionsTable extends Sessions with TableInfo<$SessionsTable, Session> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<int> templateId = GeneratedColumn<int>(
    'template_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _finishedAtMeta = const VerificationMeta(
    'finishedAt',
  );
  @override
  late final GeneratedColumn<DateTime> finishedAt = GeneratedColumn<DateTime>(
    'finished_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    templateId,
    startedAt,
    finishedAt,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Session> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    } else if (isInserting) {
      context.missing(_templateIdMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('finished_at')) {
      context.handle(
        _finishedAtMeta,
        finishedAt.isAcceptableOrUnknown(data['finished_at']!, _finishedAtMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Session map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Session(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}template_id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      finishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}finished_at'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class Session extends DataClass implements Insertable<Session> {
  final int id;
  final int templateId;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final String? notes;
  const Session({
    required this.id,
    required this.templateId,
    required this.startedAt,
    this.finishedAt,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['template_id'] = Variable<int>(templateId);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<DateTime>(finishedAt);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      templateId: Value(templateId),
      startedAt: Value(startedAt),
      finishedAt: finishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAt),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory Session.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Session(
      id: serializer.fromJson<int>(json['id']),
      templateId: serializer.fromJson<int>(json['templateId']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      finishedAt: serializer.fromJson<DateTime?>(json['finishedAt']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'templateId': serializer.toJson<int>(templateId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'finishedAt': serializer.toJson<DateTime?>(finishedAt),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  Session copyWith({
    int? id,
    int? templateId,
    DateTime? startedAt,
    Value<DateTime?> finishedAt = const Value.absent(),
    Value<String?> notes = const Value.absent(),
  }) => Session(
    id: id ?? this.id,
    templateId: templateId ?? this.templateId,
    startedAt: startedAt ?? this.startedAt,
    finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
    notes: notes.present ? notes.value : this.notes,
  );
  Session copyWithCompanion(SessionsCompanion data) {
    return Session(
      id: data.id.present ? data.id.value : this.id,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      finishedAt: data.finishedAt.present
          ? data.finishedAt.value
          : this.finishedAt,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Session(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, templateId, startedAt, finishedAt, notes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Session &&
          other.id == this.id &&
          other.templateId == this.templateId &&
          other.startedAt == this.startedAt &&
          other.finishedAt == this.finishedAt &&
          other.notes == this.notes);
}

class SessionsCompanion extends UpdateCompanion<Session> {
  final Value<int> id;
  final Value<int> templateId;
  final Value<DateTime> startedAt;
  final Value<DateTime?> finishedAt;
  final Value<String?> notes;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.templateId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.notes = const Value.absent(),
  });
  SessionsCompanion.insert({
    this.id = const Value.absent(),
    required int templateId,
    required DateTime startedAt,
    this.finishedAt = const Value.absent(),
    this.notes = const Value.absent(),
  }) : templateId = Value(templateId),
       startedAt = Value(startedAt);
  static Insertable<Session> custom({
    Expression<int>? id,
    Expression<int>? templateId,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? finishedAt,
    Expression<String>? notes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (templateId != null) 'template_id': templateId,
      if (startedAt != null) 'started_at': startedAt,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (notes != null) 'notes': notes,
    });
  }

  SessionsCompanion copyWith({
    Value<int>? id,
    Value<int>? templateId,
    Value<DateTime>? startedAt,
    Value<DateTime?>? finishedAt,
    Value<String?>? notes,
  }) {
    return SessionsCompanion(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      notes: notes ?? this.notes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<int>(templateId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<DateTime>(finishedAt.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }
}

class $SessionExercisesTable extends SessionExercises
    with TableInfo<$SessionExercisesTable, SessionExercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<int> exerciseId = GeneratedColumn<int>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _restSecondsMeta = const VerificationMeta(
    'restSeconds',
  );
  @override
  late final GeneratedColumn<int> restSeconds = GeneratedColumn<int>(
    'rest_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isExtraMeta = const VerificationMeta(
    'isExtra',
  );
  @override
  late final GeneratedColumn<bool> isExtra = GeneratedColumn<bool>(
    'is_extra',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_extra" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _progressionConfigIdMeta =
      const VerificationMeta('progressionConfigId');
  @override
  late final GeneratedColumn<int> progressionConfigId = GeneratedColumn<int>(
    'progression_config_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recommendationIdMeta = const VerificationMeta(
    'recommendationId',
  );
  @override
  late final GeneratedColumn<int> recommendationId = GeneratedColumn<int>(
    'recommendation_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _excludeFromProgressionMeta =
      const VerificationMeta('excludeFromProgression');
  @override
  late final GeneratedColumn<bool> excludeFromProgression =
      GeneratedColumn<bool>(
        'exclude_from_progression',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("exclude_from_progression" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    exerciseId,
    position,
    restSeconds,
    isExtra,
    progressionConfigId,
    recommendationId,
    excludeFromProgression,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'session_exercises';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionExercise> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('rest_seconds')) {
      context.handle(
        _restSecondsMeta,
        restSeconds.isAcceptableOrUnknown(
          data['rest_seconds']!,
          _restSecondsMeta,
        ),
      );
    }
    if (data.containsKey('is_extra')) {
      context.handle(
        _isExtraMeta,
        isExtra.isAcceptableOrUnknown(data['is_extra']!, _isExtraMeta),
      );
    }
    if (data.containsKey('progression_config_id')) {
      context.handle(
        _progressionConfigIdMeta,
        progressionConfigId.isAcceptableOrUnknown(
          data['progression_config_id']!,
          _progressionConfigIdMeta,
        ),
      );
    }
    if (data.containsKey('recommendation_id')) {
      context.handle(
        _recommendationIdMeta,
        recommendationId.isAcceptableOrUnknown(
          data['recommendation_id']!,
          _recommendationIdMeta,
        ),
      );
    }
    if (data.containsKey('exclude_from_progression')) {
      context.handle(
        _excludeFromProgressionMeta,
        excludeFromProgression.isAcceptableOrUnknown(
          data['exclude_from_progression']!,
          _excludeFromProgressionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionExercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionExercise(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}exercise_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      restSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rest_seconds'],
      ),
      isExtra: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_extra'],
      )!,
      progressionConfigId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}progression_config_id'],
      ),
      recommendationId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recommendation_id'],
      ),
      excludeFromProgression: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}exclude_from_progression'],
      )!,
    );
  }

  @override
  $SessionExercisesTable createAlias(String alias) {
    return $SessionExercisesTable(attachedDatabase, alias);
  }
}

class SessionExercise extends DataClass implements Insertable<SessionExercise> {
  final int id;
  final int sessionId;
  final int exerciseId;
  final int position;
  final int? restSeconds;
  final bool isExtra;
  final int? progressionConfigId;
  final int? recommendationId;
  final bool excludeFromProgression;
  const SessionExercise({
    required this.id,
    required this.sessionId,
    required this.exerciseId,
    required this.position,
    this.restSeconds,
    required this.isExtra,
    this.progressionConfigId,
    this.recommendationId,
    required this.excludeFromProgression,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<int>(sessionId);
    map['exercise_id'] = Variable<int>(exerciseId);
    map['position'] = Variable<int>(position);
    if (!nullToAbsent || restSeconds != null) {
      map['rest_seconds'] = Variable<int>(restSeconds);
    }
    map['is_extra'] = Variable<bool>(isExtra);
    if (!nullToAbsent || progressionConfigId != null) {
      map['progression_config_id'] = Variable<int>(progressionConfigId);
    }
    if (!nullToAbsent || recommendationId != null) {
      map['recommendation_id'] = Variable<int>(recommendationId);
    }
    map['exclude_from_progression'] = Variable<bool>(excludeFromProgression);
    return map;
  }

  SessionExercisesCompanion toCompanion(bool nullToAbsent) {
    return SessionExercisesCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      exerciseId: Value(exerciseId),
      position: Value(position),
      restSeconds: restSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(restSeconds),
      isExtra: Value(isExtra),
      progressionConfigId: progressionConfigId == null && nullToAbsent
          ? const Value.absent()
          : Value(progressionConfigId),
      recommendationId: recommendationId == null && nullToAbsent
          ? const Value.absent()
          : Value(recommendationId),
      excludeFromProgression: Value(excludeFromProgression),
    );
  }

  factory SessionExercise.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionExercise(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<int>(json['sessionId']),
      exerciseId: serializer.fromJson<int>(json['exerciseId']),
      position: serializer.fromJson<int>(json['position']),
      restSeconds: serializer.fromJson<int?>(json['restSeconds']),
      isExtra: serializer.fromJson<bool>(json['isExtra']),
      progressionConfigId: serializer.fromJson<int?>(
        json['progressionConfigId'],
      ),
      recommendationId: serializer.fromJson<int?>(json['recommendationId']),
      excludeFromProgression: serializer.fromJson<bool>(
        json['excludeFromProgression'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<int>(sessionId),
      'exerciseId': serializer.toJson<int>(exerciseId),
      'position': serializer.toJson<int>(position),
      'restSeconds': serializer.toJson<int?>(restSeconds),
      'isExtra': serializer.toJson<bool>(isExtra),
      'progressionConfigId': serializer.toJson<int?>(progressionConfigId),
      'recommendationId': serializer.toJson<int?>(recommendationId),
      'excludeFromProgression': serializer.toJson<bool>(excludeFromProgression),
    };
  }

  SessionExercise copyWith({
    int? id,
    int? sessionId,
    int? exerciseId,
    int? position,
    Value<int?> restSeconds = const Value.absent(),
    bool? isExtra,
    Value<int?> progressionConfigId = const Value.absent(),
    Value<int?> recommendationId = const Value.absent(),
    bool? excludeFromProgression,
  }) => SessionExercise(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    exerciseId: exerciseId ?? this.exerciseId,
    position: position ?? this.position,
    restSeconds: restSeconds.present ? restSeconds.value : this.restSeconds,
    isExtra: isExtra ?? this.isExtra,
    progressionConfigId: progressionConfigId.present
        ? progressionConfigId.value
        : this.progressionConfigId,
    recommendationId: recommendationId.present
        ? recommendationId.value
        : this.recommendationId,
    excludeFromProgression:
        excludeFromProgression ?? this.excludeFromProgression,
  );
  SessionExercise copyWithCompanion(SessionExercisesCompanion data) {
    return SessionExercise(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      position: data.position.present ? data.position.value : this.position,
      restSeconds: data.restSeconds.present
          ? data.restSeconds.value
          : this.restSeconds,
      isExtra: data.isExtra.present ? data.isExtra.value : this.isExtra,
      progressionConfigId: data.progressionConfigId.present
          ? data.progressionConfigId.value
          : this.progressionConfigId,
      recommendationId: data.recommendationId.present
          ? data.recommendationId.value
          : this.recommendationId,
      excludeFromProgression: data.excludeFromProgression.present
          ? data.excludeFromProgression.value
          : this.excludeFromProgression,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionExercise(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('position: $position, ')
          ..write('restSeconds: $restSeconds, ')
          ..write('isExtra: $isExtra, ')
          ..write('progressionConfigId: $progressionConfigId, ')
          ..write('recommendationId: $recommendationId, ')
          ..write('excludeFromProgression: $excludeFromProgression')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    exerciseId,
    position,
    restSeconds,
    isExtra,
    progressionConfigId,
    recommendationId,
    excludeFromProgression,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionExercise &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.exerciseId == this.exerciseId &&
          other.position == this.position &&
          other.restSeconds == this.restSeconds &&
          other.isExtra == this.isExtra &&
          other.progressionConfigId == this.progressionConfigId &&
          other.recommendationId == this.recommendationId &&
          other.excludeFromProgression == this.excludeFromProgression);
}

class SessionExercisesCompanion extends UpdateCompanion<SessionExercise> {
  final Value<int> id;
  final Value<int> sessionId;
  final Value<int> exerciseId;
  final Value<int> position;
  final Value<int?> restSeconds;
  final Value<bool> isExtra;
  final Value<int?> progressionConfigId;
  final Value<int?> recommendationId;
  final Value<bool> excludeFromProgression;
  const SessionExercisesCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.position = const Value.absent(),
    this.restSeconds = const Value.absent(),
    this.isExtra = const Value.absent(),
    this.progressionConfigId = const Value.absent(),
    this.recommendationId = const Value.absent(),
    this.excludeFromProgression = const Value.absent(),
  });
  SessionExercisesCompanion.insert({
    this.id = const Value.absent(),
    required int sessionId,
    required int exerciseId,
    required int position,
    this.restSeconds = const Value.absent(),
    this.isExtra = const Value.absent(),
    this.progressionConfigId = const Value.absent(),
    this.recommendationId = const Value.absent(),
    this.excludeFromProgression = const Value.absent(),
  }) : sessionId = Value(sessionId),
       exerciseId = Value(exerciseId),
       position = Value(position);
  static Insertable<SessionExercise> custom({
    Expression<int>? id,
    Expression<int>? sessionId,
    Expression<int>? exerciseId,
    Expression<int>? position,
    Expression<int>? restSeconds,
    Expression<bool>? isExtra,
    Expression<int>? progressionConfigId,
    Expression<int>? recommendationId,
    Expression<bool>? excludeFromProgression,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (position != null) 'position': position,
      if (restSeconds != null) 'rest_seconds': restSeconds,
      if (isExtra != null) 'is_extra': isExtra,
      if (progressionConfigId != null)
        'progression_config_id': progressionConfigId,
      if (recommendationId != null) 'recommendation_id': recommendationId,
      if (excludeFromProgression != null)
        'exclude_from_progression': excludeFromProgression,
    });
  }

  SessionExercisesCompanion copyWith({
    Value<int>? id,
    Value<int>? sessionId,
    Value<int>? exerciseId,
    Value<int>? position,
    Value<int?>? restSeconds,
    Value<bool>? isExtra,
    Value<int?>? progressionConfigId,
    Value<int?>? recommendationId,
    Value<bool>? excludeFromProgression,
  }) {
    return SessionExercisesCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      exerciseId: exerciseId ?? this.exerciseId,
      position: position ?? this.position,
      restSeconds: restSeconds ?? this.restSeconds,
      isExtra: isExtra ?? this.isExtra,
      progressionConfigId: progressionConfigId ?? this.progressionConfigId,
      recommendationId: recommendationId ?? this.recommendationId,
      excludeFromProgression:
          excludeFromProgression ?? this.excludeFromProgression,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<int>(exerciseId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (restSeconds.present) {
      map['rest_seconds'] = Variable<int>(restSeconds.value);
    }
    if (isExtra.present) {
      map['is_extra'] = Variable<bool>(isExtra.value);
    }
    if (progressionConfigId.present) {
      map['progression_config_id'] = Variable<int>(progressionConfigId.value);
    }
    if (recommendationId.present) {
      map['recommendation_id'] = Variable<int>(recommendationId.value);
    }
    if (excludeFromProgression.present) {
      map['exclude_from_progression'] = Variable<bool>(
        excludeFromProgression.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionExercisesCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('position: $position, ')
          ..write('restSeconds: $restSeconds, ')
          ..write('isExtra: $isExtra, ')
          ..write('progressionConfigId: $progressionConfigId, ')
          ..write('recommendationId: $recommendationId, ')
          ..write('excludeFromProgression: $excludeFromProgression')
          ..write(')'))
        .toString();
  }
}

class $SessionSetsTable extends SessionSets
    with TableInfo<$SessionSetsTable, SessionSet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionSetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sessionExerciseIdMeta = const VerificationMeta(
    'sessionExerciseId',
  );
  @override
  late final GeneratedColumn<int> sessionExerciseId = GeneratedColumn<int>(
    'session_exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SetType, String> setType =
      GeneratedColumn<String>(
        'set_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SetType>($SessionSetsTable.$convertersetType);
  static const VerificationMeta _weightKgMeta = const VerificationMeta(
    'weightKg',
  );
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'weight_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
    'reps',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isWarmupMeta = const VerificationMeta(
    'isWarmup',
  );
  @override
  late final GeneratedColumn<bool> isWarmup = GeneratedColumn<bool>(
    'is_warmup',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_warmup" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _toFailureMeta = const VerificationMeta(
    'toFailure',
  );
  @override
  late final GeneratedColumn<bool> toFailure = GeneratedColumn<bool>(
    'to_failure',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("to_failure" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rirMeta = const VerificationMeta('rir');
  @override
  late final GeneratedColumn<int> rir = GeneratedColumn<int>(
    'rir',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rpeMeta = const VerificationMeta('rpe');
  @override
  late final GeneratedColumn<double> rpe = GeneratedColumn<double>(
    'rpe',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ExecutionQuality?, String>
  executionQuality =
      GeneratedColumn<String>(
        'execution_quality',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<ExecutionQuality?>(
        $SessionSetsTable.$converterexecutionQualityn,
      );
  @override
  late final GeneratedColumnWithTypeConverter<SetRole?, String> setRole =
      GeneratedColumn<String>(
        'set_role',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<SetRole?>($SessionSetsTable.$convertersetRolen);
  static const VerificationMeta _targetWeightKgMeta = const VerificationMeta(
    'targetWeightKg',
  );
  @override
  late final GeneratedColumn<double> targetWeightKg = GeneratedColumn<double>(
    'target_weight_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetRepsMinMeta = const VerificationMeta(
    'targetRepsMin',
  );
  @override
  late final GeneratedColumn<int> targetRepsMin = GeneratedColumn<int>(
    'target_reps_min',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetRepsMaxMeta = const VerificationMeta(
    'targetRepsMax',
  );
  @override
  late final GeneratedColumn<int> targetRepsMax = GeneratedColumn<int>(
    'target_reps_max',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionExerciseId,
    setType,
    weightKg,
    reps,
    durationSeconds,
    isWarmup,
    toFailure,
    position,
    rir,
    rpe,
    executionQuality,
    setRole,
    targetWeightKg,
    targetRepsMin,
    targetRepsMax,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'session_sets';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionSet> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_exercise_id')) {
      context.handle(
        _sessionExerciseIdMeta,
        sessionExerciseId.isAcceptableOrUnknown(
          data['session_exercise_id']!,
          _sessionExerciseIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sessionExerciseIdMeta);
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    }
    if (data.containsKey('reps')) {
      context.handle(
        _repsMeta,
        reps.isAcceptableOrUnknown(data['reps']!, _repsMeta),
      );
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('is_warmup')) {
      context.handle(
        _isWarmupMeta,
        isWarmup.isAcceptableOrUnknown(data['is_warmup']!, _isWarmupMeta),
      );
    }
    if (data.containsKey('to_failure')) {
      context.handle(
        _toFailureMeta,
        toFailure.isAcceptableOrUnknown(data['to_failure']!, _toFailureMeta),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('rir')) {
      context.handle(
        _rirMeta,
        rir.isAcceptableOrUnknown(data['rir']!, _rirMeta),
      );
    }
    if (data.containsKey('rpe')) {
      context.handle(
        _rpeMeta,
        rpe.isAcceptableOrUnknown(data['rpe']!, _rpeMeta),
      );
    }
    if (data.containsKey('target_weight_kg')) {
      context.handle(
        _targetWeightKgMeta,
        targetWeightKg.isAcceptableOrUnknown(
          data['target_weight_kg']!,
          _targetWeightKgMeta,
        ),
      );
    }
    if (data.containsKey('target_reps_min')) {
      context.handle(
        _targetRepsMinMeta,
        targetRepsMin.isAcceptableOrUnknown(
          data['target_reps_min']!,
          _targetRepsMinMeta,
        ),
      );
    }
    if (data.containsKey('target_reps_max')) {
      context.handle(
        _targetRepsMaxMeta,
        targetRepsMax.isAcceptableOrUnknown(
          data['target_reps_max']!,
          _targetRepsMaxMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionSet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionSet(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sessionExerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_exercise_id'],
      )!,
      setType: $SessionSetsTable.$convertersetType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}set_type'],
        )!,
      ),
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      ),
      reps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reps'],
      ),
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      ),
      isWarmup: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_warmup'],
      )!,
      toFailure: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}to_failure'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      rir: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rir'],
      ),
      rpe: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rpe'],
      ),
      executionQuality: $SessionSetsTable.$converterexecutionQualityn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}execution_quality'],
        ),
      ),
      setRole: $SessionSetsTable.$convertersetRolen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}set_role'],
        ),
      ),
      targetWeightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_weight_kg'],
      ),
      targetRepsMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_reps_min'],
      ),
      targetRepsMax: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_reps_max'],
      ),
    );
  }

  @override
  $SessionSetsTable createAlias(String alias) {
    return $SessionSetsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SetType, String, String> $convertersetType =
      const EnumNameConverter<SetType>(SetType.values);
  static JsonTypeConverter2<ExecutionQuality, String, String>
  $converterexecutionQuality = const EnumNameConverter<ExecutionQuality>(
    ExecutionQuality.values,
  );
  static JsonTypeConverter2<ExecutionQuality?, String?, String?>
  $converterexecutionQualityn = JsonTypeConverter2.asNullable(
    $converterexecutionQuality,
  );
  static JsonTypeConverter2<SetRole, String, String> $convertersetRole =
      const EnumNameConverter<SetRole>(SetRole.values);
  static JsonTypeConverter2<SetRole?, String?, String?> $convertersetRolen =
      JsonTypeConverter2.asNullable($convertersetRole);
}

class SessionSet extends DataClass implements Insertable<SessionSet> {
  final int id;
  final int sessionExerciseId;
  final SetType setType;
  final double? weightKg;
  final int? reps;
  final int? durationSeconds;
  final bool isWarmup;
  final bool toFailure;
  final int position;
  final int? rir;
  final double? rpe;
  final ExecutionQuality? executionQuality;
  final SetRole? setRole;
  final double? targetWeightKg;
  final int? targetRepsMin;
  final int? targetRepsMax;
  const SessionSet({
    required this.id,
    required this.sessionExerciseId,
    required this.setType,
    this.weightKg,
    this.reps,
    this.durationSeconds,
    required this.isWarmup,
    required this.toFailure,
    required this.position,
    this.rir,
    this.rpe,
    this.executionQuality,
    this.setRole,
    this.targetWeightKg,
    this.targetRepsMin,
    this.targetRepsMax,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_exercise_id'] = Variable<int>(sessionExerciseId);
    {
      map['set_type'] = Variable<String>(
        $SessionSetsTable.$convertersetType.toSql(setType),
      );
    }
    if (!nullToAbsent || weightKg != null) {
      map['weight_kg'] = Variable<double>(weightKg);
    }
    if (!nullToAbsent || reps != null) {
      map['reps'] = Variable<int>(reps);
    }
    if (!nullToAbsent || durationSeconds != null) {
      map['duration_seconds'] = Variable<int>(durationSeconds);
    }
    map['is_warmup'] = Variable<bool>(isWarmup);
    map['to_failure'] = Variable<bool>(toFailure);
    map['position'] = Variable<int>(position);
    if (!nullToAbsent || rir != null) {
      map['rir'] = Variable<int>(rir);
    }
    if (!nullToAbsent || rpe != null) {
      map['rpe'] = Variable<double>(rpe);
    }
    if (!nullToAbsent || executionQuality != null) {
      map['execution_quality'] = Variable<String>(
        $SessionSetsTable.$converterexecutionQualityn.toSql(executionQuality),
      );
    }
    if (!nullToAbsent || setRole != null) {
      map['set_role'] = Variable<String>(
        $SessionSetsTable.$convertersetRolen.toSql(setRole),
      );
    }
    if (!nullToAbsent || targetWeightKg != null) {
      map['target_weight_kg'] = Variable<double>(targetWeightKg);
    }
    if (!nullToAbsent || targetRepsMin != null) {
      map['target_reps_min'] = Variable<int>(targetRepsMin);
    }
    if (!nullToAbsent || targetRepsMax != null) {
      map['target_reps_max'] = Variable<int>(targetRepsMax);
    }
    return map;
  }

  SessionSetsCompanion toCompanion(bool nullToAbsent) {
    return SessionSetsCompanion(
      id: Value(id),
      sessionExerciseId: Value(sessionExerciseId),
      setType: Value(setType),
      weightKg: weightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(weightKg),
      reps: reps == null && nullToAbsent ? const Value.absent() : Value(reps),
      durationSeconds: durationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSeconds),
      isWarmup: Value(isWarmup),
      toFailure: Value(toFailure),
      position: Value(position),
      rir: rir == null && nullToAbsent ? const Value.absent() : Value(rir),
      rpe: rpe == null && nullToAbsent ? const Value.absent() : Value(rpe),
      executionQuality: executionQuality == null && nullToAbsent
          ? const Value.absent()
          : Value(executionQuality),
      setRole: setRole == null && nullToAbsent
          ? const Value.absent()
          : Value(setRole),
      targetWeightKg: targetWeightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(targetWeightKg),
      targetRepsMin: targetRepsMin == null && nullToAbsent
          ? const Value.absent()
          : Value(targetRepsMin),
      targetRepsMax: targetRepsMax == null && nullToAbsent
          ? const Value.absent()
          : Value(targetRepsMax),
    );
  }

  factory SessionSet.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionSet(
      id: serializer.fromJson<int>(json['id']),
      sessionExerciseId: serializer.fromJson<int>(json['sessionExerciseId']),
      setType: $SessionSetsTable.$convertersetType.fromJson(
        serializer.fromJson<String>(json['setType']),
      ),
      weightKg: serializer.fromJson<double?>(json['weightKg']),
      reps: serializer.fromJson<int?>(json['reps']),
      durationSeconds: serializer.fromJson<int?>(json['durationSeconds']),
      isWarmup: serializer.fromJson<bool>(json['isWarmup']),
      toFailure: serializer.fromJson<bool>(json['toFailure']),
      position: serializer.fromJson<int>(json['position']),
      rir: serializer.fromJson<int?>(json['rir']),
      rpe: serializer.fromJson<double?>(json['rpe']),
      executionQuality: $SessionSetsTable.$converterexecutionQualityn.fromJson(
        serializer.fromJson<String?>(json['executionQuality']),
      ),
      setRole: $SessionSetsTable.$convertersetRolen.fromJson(
        serializer.fromJson<String?>(json['setRole']),
      ),
      targetWeightKg: serializer.fromJson<double?>(json['targetWeightKg']),
      targetRepsMin: serializer.fromJson<int?>(json['targetRepsMin']),
      targetRepsMax: serializer.fromJson<int?>(json['targetRepsMax']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionExerciseId': serializer.toJson<int>(sessionExerciseId),
      'setType': serializer.toJson<String>(
        $SessionSetsTable.$convertersetType.toJson(setType),
      ),
      'weightKg': serializer.toJson<double?>(weightKg),
      'reps': serializer.toJson<int?>(reps),
      'durationSeconds': serializer.toJson<int?>(durationSeconds),
      'isWarmup': serializer.toJson<bool>(isWarmup),
      'toFailure': serializer.toJson<bool>(toFailure),
      'position': serializer.toJson<int>(position),
      'rir': serializer.toJson<int?>(rir),
      'rpe': serializer.toJson<double?>(rpe),
      'executionQuality': serializer.toJson<String?>(
        $SessionSetsTable.$converterexecutionQualityn.toJson(executionQuality),
      ),
      'setRole': serializer.toJson<String?>(
        $SessionSetsTable.$convertersetRolen.toJson(setRole),
      ),
      'targetWeightKg': serializer.toJson<double?>(targetWeightKg),
      'targetRepsMin': serializer.toJson<int?>(targetRepsMin),
      'targetRepsMax': serializer.toJson<int?>(targetRepsMax),
    };
  }

  SessionSet copyWith({
    int? id,
    int? sessionExerciseId,
    SetType? setType,
    Value<double?> weightKg = const Value.absent(),
    Value<int?> reps = const Value.absent(),
    Value<int?> durationSeconds = const Value.absent(),
    bool? isWarmup,
    bool? toFailure,
    int? position,
    Value<int?> rir = const Value.absent(),
    Value<double?> rpe = const Value.absent(),
    Value<ExecutionQuality?> executionQuality = const Value.absent(),
    Value<SetRole?> setRole = const Value.absent(),
    Value<double?> targetWeightKg = const Value.absent(),
    Value<int?> targetRepsMin = const Value.absent(),
    Value<int?> targetRepsMax = const Value.absent(),
  }) => SessionSet(
    id: id ?? this.id,
    sessionExerciseId: sessionExerciseId ?? this.sessionExerciseId,
    setType: setType ?? this.setType,
    weightKg: weightKg.present ? weightKg.value : this.weightKg,
    reps: reps.present ? reps.value : this.reps,
    durationSeconds: durationSeconds.present
        ? durationSeconds.value
        : this.durationSeconds,
    isWarmup: isWarmup ?? this.isWarmup,
    toFailure: toFailure ?? this.toFailure,
    position: position ?? this.position,
    rir: rir.present ? rir.value : this.rir,
    rpe: rpe.present ? rpe.value : this.rpe,
    executionQuality: executionQuality.present
        ? executionQuality.value
        : this.executionQuality,
    setRole: setRole.present ? setRole.value : this.setRole,
    targetWeightKg: targetWeightKg.present
        ? targetWeightKg.value
        : this.targetWeightKg,
    targetRepsMin: targetRepsMin.present
        ? targetRepsMin.value
        : this.targetRepsMin,
    targetRepsMax: targetRepsMax.present
        ? targetRepsMax.value
        : this.targetRepsMax,
  );
  SessionSet copyWithCompanion(SessionSetsCompanion data) {
    return SessionSet(
      id: data.id.present ? data.id.value : this.id,
      sessionExerciseId: data.sessionExerciseId.present
          ? data.sessionExerciseId.value
          : this.sessionExerciseId,
      setType: data.setType.present ? data.setType.value : this.setType,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      reps: data.reps.present ? data.reps.value : this.reps,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      isWarmup: data.isWarmup.present ? data.isWarmup.value : this.isWarmup,
      toFailure: data.toFailure.present ? data.toFailure.value : this.toFailure,
      position: data.position.present ? data.position.value : this.position,
      rir: data.rir.present ? data.rir.value : this.rir,
      rpe: data.rpe.present ? data.rpe.value : this.rpe,
      executionQuality: data.executionQuality.present
          ? data.executionQuality.value
          : this.executionQuality,
      setRole: data.setRole.present ? data.setRole.value : this.setRole,
      targetWeightKg: data.targetWeightKg.present
          ? data.targetWeightKg.value
          : this.targetWeightKg,
      targetRepsMin: data.targetRepsMin.present
          ? data.targetRepsMin.value
          : this.targetRepsMin,
      targetRepsMax: data.targetRepsMax.present
          ? data.targetRepsMax.value
          : this.targetRepsMax,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionSet(')
          ..write('id: $id, ')
          ..write('sessionExerciseId: $sessionExerciseId, ')
          ..write('setType: $setType, ')
          ..write('weightKg: $weightKg, ')
          ..write('reps: $reps, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('isWarmup: $isWarmup, ')
          ..write('toFailure: $toFailure, ')
          ..write('position: $position, ')
          ..write('rir: $rir, ')
          ..write('rpe: $rpe, ')
          ..write('executionQuality: $executionQuality, ')
          ..write('setRole: $setRole, ')
          ..write('targetWeightKg: $targetWeightKg, ')
          ..write('targetRepsMin: $targetRepsMin, ')
          ..write('targetRepsMax: $targetRepsMax')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionExerciseId,
    setType,
    weightKg,
    reps,
    durationSeconds,
    isWarmup,
    toFailure,
    position,
    rir,
    rpe,
    executionQuality,
    setRole,
    targetWeightKg,
    targetRepsMin,
    targetRepsMax,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionSet &&
          other.id == this.id &&
          other.sessionExerciseId == this.sessionExerciseId &&
          other.setType == this.setType &&
          other.weightKg == this.weightKg &&
          other.reps == this.reps &&
          other.durationSeconds == this.durationSeconds &&
          other.isWarmup == this.isWarmup &&
          other.toFailure == this.toFailure &&
          other.position == this.position &&
          other.rir == this.rir &&
          other.rpe == this.rpe &&
          other.executionQuality == this.executionQuality &&
          other.setRole == this.setRole &&
          other.targetWeightKg == this.targetWeightKg &&
          other.targetRepsMin == this.targetRepsMin &&
          other.targetRepsMax == this.targetRepsMax);
}

class SessionSetsCompanion extends UpdateCompanion<SessionSet> {
  final Value<int> id;
  final Value<int> sessionExerciseId;
  final Value<SetType> setType;
  final Value<double?> weightKg;
  final Value<int?> reps;
  final Value<int?> durationSeconds;
  final Value<bool> isWarmup;
  final Value<bool> toFailure;
  final Value<int> position;
  final Value<int?> rir;
  final Value<double?> rpe;
  final Value<ExecutionQuality?> executionQuality;
  final Value<SetRole?> setRole;
  final Value<double?> targetWeightKg;
  final Value<int?> targetRepsMin;
  final Value<int?> targetRepsMax;
  const SessionSetsCompanion({
    this.id = const Value.absent(),
    this.sessionExerciseId = const Value.absent(),
    this.setType = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.reps = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.isWarmup = const Value.absent(),
    this.toFailure = const Value.absent(),
    this.position = const Value.absent(),
    this.rir = const Value.absent(),
    this.rpe = const Value.absent(),
    this.executionQuality = const Value.absent(),
    this.setRole = const Value.absent(),
    this.targetWeightKg = const Value.absent(),
    this.targetRepsMin = const Value.absent(),
    this.targetRepsMax = const Value.absent(),
  });
  SessionSetsCompanion.insert({
    this.id = const Value.absent(),
    required int sessionExerciseId,
    required SetType setType,
    this.weightKg = const Value.absent(),
    this.reps = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.isWarmup = const Value.absent(),
    this.toFailure = const Value.absent(),
    required int position,
    this.rir = const Value.absent(),
    this.rpe = const Value.absent(),
    this.executionQuality = const Value.absent(),
    this.setRole = const Value.absent(),
    this.targetWeightKg = const Value.absent(),
    this.targetRepsMin = const Value.absent(),
    this.targetRepsMax = const Value.absent(),
  }) : sessionExerciseId = Value(sessionExerciseId),
       setType = Value(setType),
       position = Value(position);
  static Insertable<SessionSet> custom({
    Expression<int>? id,
    Expression<int>? sessionExerciseId,
    Expression<String>? setType,
    Expression<double>? weightKg,
    Expression<int>? reps,
    Expression<int>? durationSeconds,
    Expression<bool>? isWarmup,
    Expression<bool>? toFailure,
    Expression<int>? position,
    Expression<int>? rir,
    Expression<double>? rpe,
    Expression<String>? executionQuality,
    Expression<String>? setRole,
    Expression<double>? targetWeightKg,
    Expression<int>? targetRepsMin,
    Expression<int>? targetRepsMax,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionExerciseId != null) 'session_exercise_id': sessionExerciseId,
      if (setType != null) 'set_type': setType,
      if (weightKg != null) 'weight_kg': weightKg,
      if (reps != null) 'reps': reps,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (isWarmup != null) 'is_warmup': isWarmup,
      if (toFailure != null) 'to_failure': toFailure,
      if (position != null) 'position': position,
      if (rir != null) 'rir': rir,
      if (rpe != null) 'rpe': rpe,
      if (executionQuality != null) 'execution_quality': executionQuality,
      if (setRole != null) 'set_role': setRole,
      if (targetWeightKg != null) 'target_weight_kg': targetWeightKg,
      if (targetRepsMin != null) 'target_reps_min': targetRepsMin,
      if (targetRepsMax != null) 'target_reps_max': targetRepsMax,
    });
  }

  SessionSetsCompanion copyWith({
    Value<int>? id,
    Value<int>? sessionExerciseId,
    Value<SetType>? setType,
    Value<double?>? weightKg,
    Value<int?>? reps,
    Value<int?>? durationSeconds,
    Value<bool>? isWarmup,
    Value<bool>? toFailure,
    Value<int>? position,
    Value<int?>? rir,
    Value<double?>? rpe,
    Value<ExecutionQuality?>? executionQuality,
    Value<SetRole?>? setRole,
    Value<double?>? targetWeightKg,
    Value<int?>? targetRepsMin,
    Value<int?>? targetRepsMax,
  }) {
    return SessionSetsCompanion(
      id: id ?? this.id,
      sessionExerciseId: sessionExerciseId ?? this.sessionExerciseId,
      setType: setType ?? this.setType,
      weightKg: weightKg ?? this.weightKg,
      reps: reps ?? this.reps,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      isWarmup: isWarmup ?? this.isWarmup,
      toFailure: toFailure ?? this.toFailure,
      position: position ?? this.position,
      rir: rir ?? this.rir,
      rpe: rpe ?? this.rpe,
      executionQuality: executionQuality ?? this.executionQuality,
      setRole: setRole ?? this.setRole,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      targetRepsMin: targetRepsMin ?? this.targetRepsMin,
      targetRepsMax: targetRepsMax ?? this.targetRepsMax,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionExerciseId.present) {
      map['session_exercise_id'] = Variable<int>(sessionExerciseId.value);
    }
    if (setType.present) {
      map['set_type'] = Variable<String>(
        $SessionSetsTable.$convertersetType.toSql(setType.value),
      );
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (isWarmup.present) {
      map['is_warmup'] = Variable<bool>(isWarmup.value);
    }
    if (toFailure.present) {
      map['to_failure'] = Variable<bool>(toFailure.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rir.present) {
      map['rir'] = Variable<int>(rir.value);
    }
    if (rpe.present) {
      map['rpe'] = Variable<double>(rpe.value);
    }
    if (executionQuality.present) {
      map['execution_quality'] = Variable<String>(
        $SessionSetsTable.$converterexecutionQualityn.toSql(
          executionQuality.value,
        ),
      );
    }
    if (setRole.present) {
      map['set_role'] = Variable<String>(
        $SessionSetsTable.$convertersetRolen.toSql(setRole.value),
      );
    }
    if (targetWeightKg.present) {
      map['target_weight_kg'] = Variable<double>(targetWeightKg.value);
    }
    if (targetRepsMin.present) {
      map['target_reps_min'] = Variable<int>(targetRepsMin.value);
    }
    if (targetRepsMax.present) {
      map['target_reps_max'] = Variable<int>(targetRepsMax.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionSetsCompanion(')
          ..write('id: $id, ')
          ..write('sessionExerciseId: $sessionExerciseId, ')
          ..write('setType: $setType, ')
          ..write('weightKg: $weightKg, ')
          ..write('reps: $reps, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('isWarmup: $isWarmup, ')
          ..write('toFailure: $toFailure, ')
          ..write('position: $position, ')
          ..write('rir: $rir, ')
          ..write('rpe: $rpe, ')
          ..write('executionQuality: $executionQuality, ')
          ..write('setRole: $setRole, ')
          ..write('targetWeightKg: $targetWeightKg, ')
          ..write('targetRepsMin: $targetRepsMin, ')
          ..write('targetRepsMax: $targetRepsMax')
          ..write(')'))
        .toString();
  }
}

class $BodyWeightEntriesTable extends BodyWeightEntries
    with TableInfo<$BodyWeightEntriesTable, BodyWeightEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BodyWeightEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _weightKgMeta = const VerificationMeta(
    'weightKg',
  );
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'weight_kg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, weightKg, recordedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'body_weight_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<BodyWeightEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    } else if (isInserting) {
      context.missing(_weightKgMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BodyWeightEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BodyWeightEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
    );
  }

  @override
  $BodyWeightEntriesTable createAlias(String alias) {
    return $BodyWeightEntriesTable(attachedDatabase, alias);
  }
}

class BodyWeightEntry extends DataClass implements Insertable<BodyWeightEntry> {
  final int id;
  final double weightKg;
  final DateTime recordedAt;
  const BodyWeightEntry({
    required this.id,
    required this.weightKg,
    required this.recordedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['weight_kg'] = Variable<double>(weightKg);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    return map;
  }

  BodyWeightEntriesCompanion toCompanion(bool nullToAbsent) {
    return BodyWeightEntriesCompanion(
      id: Value(id),
      weightKg: Value(weightKg),
      recordedAt: Value(recordedAt),
    );
  }

  factory BodyWeightEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BodyWeightEntry(
      id: serializer.fromJson<int>(json['id']),
      weightKg: serializer.fromJson<double>(json['weightKg']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'weightKg': serializer.toJson<double>(weightKg),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
    };
  }

  BodyWeightEntry copyWith({int? id, double? weightKg, DateTime? recordedAt}) =>
      BodyWeightEntry(
        id: id ?? this.id,
        weightKg: weightKg ?? this.weightKg,
        recordedAt: recordedAt ?? this.recordedAt,
      );
  BodyWeightEntry copyWithCompanion(BodyWeightEntriesCompanion data) {
    return BodyWeightEntry(
      id: data.id.present ? data.id.value : this.id,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BodyWeightEntry(')
          ..write('id: $id, ')
          ..write('weightKg: $weightKg, ')
          ..write('recordedAt: $recordedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, weightKg, recordedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BodyWeightEntry &&
          other.id == this.id &&
          other.weightKg == this.weightKg &&
          other.recordedAt == this.recordedAt);
}

class BodyWeightEntriesCompanion extends UpdateCompanion<BodyWeightEntry> {
  final Value<int> id;
  final Value<double> weightKg;
  final Value<DateTime> recordedAt;
  const BodyWeightEntriesCompanion({
    this.id = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.recordedAt = const Value.absent(),
  });
  BodyWeightEntriesCompanion.insert({
    this.id = const Value.absent(),
    required double weightKg,
    required DateTime recordedAt,
  }) : weightKg = Value(weightKg),
       recordedAt = Value(recordedAt);
  static Insertable<BodyWeightEntry> custom({
    Expression<int>? id,
    Expression<double>? weightKg,
    Expression<DateTime>? recordedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (weightKg != null) 'weight_kg': weightKg,
      if (recordedAt != null) 'recorded_at': recordedAt,
    });
  }

  BodyWeightEntriesCompanion copyWith({
    Value<int>? id,
    Value<double>? weightKg,
    Value<DateTime>? recordedAt,
  }) {
    return BodyWeightEntriesCompanion(
      id: id ?? this.id,
      weightKg: weightKg ?? this.weightKg,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BodyWeightEntriesCompanion(')
          ..write('id: $id, ')
          ..write('weightKg: $weightKg, ')
          ..write('recordedAt: $recordedAt')
          ..write(')'))
        .toString();
  }
}

class $ProgressionConfigsTable extends ProgressionConfigs
    with TableInfo<$ProgressionConfigsTable, ProgressionConfigEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProgressionConfigsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<int> exerciseId = GeneratedColumn<int>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<StrategyId, String> strategy =
      GeneratedColumn<String>(
        'strategy',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<StrategyId>($ProgressionConfigsTable.$converterstrategy);
  static const VerificationMeta _paramsJsonMeta = const VerificationMeta(
    'paramsJson',
  );
  @override
  late final GeneratedColumn<String> paramsJson = GeneratedColumn<String>(
    'params_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _incrementKgMeta = const VerificationMeta(
    'incrementKg',
  );
  @override
  late final GeneratedColumn<double> incrementKg = GeneratedColumn<double>(
    'increment_kg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _supersededAtMeta = const VerificationMeta(
    'supersededAt',
  );
  @override
  late final GeneratedColumn<DateTime> supersededAt = GeneratedColumn<DateTime>(
    'superseded_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _baselineFromMeta = const VerificationMeta(
    'baselineFrom',
  );
  @override
  late final GeneratedColumn<DateTime> baselineFrom = GeneratedColumn<DateTime>(
    'baseline_from',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    exerciseId,
    strategy,
    paramsJson,
    incrementKg,
    createdAt,
    supersededAt,
    baselineFrom,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'progression_configs';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProgressionConfigEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('params_json')) {
      context.handle(
        _paramsJsonMeta,
        paramsJson.isAcceptableOrUnknown(data['params_json']!, _paramsJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_paramsJsonMeta);
    }
    if (data.containsKey('increment_kg')) {
      context.handle(
        _incrementKgMeta,
        incrementKg.isAcceptableOrUnknown(
          data['increment_kg']!,
          _incrementKgMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_incrementKgMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('superseded_at')) {
      context.handle(
        _supersededAtMeta,
        supersededAt.isAcceptableOrUnknown(
          data['superseded_at']!,
          _supersededAtMeta,
        ),
      );
    }
    if (data.containsKey('baseline_from')) {
      context.handle(
        _baselineFromMeta,
        baselineFrom.isAcceptableOrUnknown(
          data['baseline_from']!,
          _baselineFromMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProgressionConfigEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProgressionConfigEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}exercise_id'],
      )!,
      strategy: $ProgressionConfigsTable.$converterstrategy.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}strategy'],
        )!,
      ),
      paramsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}params_json'],
      )!,
      incrementKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}increment_kg'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      supersededAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}superseded_at'],
      ),
      baselineFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}baseline_from'],
      ),
    );
  }

  @override
  $ProgressionConfigsTable createAlias(String alias) {
    return $ProgressionConfigsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<StrategyId, String, String> $converterstrategy =
      const EnumNameConverter<StrategyId>(StrategyId.values);
}

class ProgressionConfigEntry extends DataClass
    implements Insertable<ProgressionConfigEntry> {
  final int id;
  final int exerciseId;
  final StrategyId strategy;
  final String paramsJson;
  final double incrementKg;
  final DateTime createdAt;
  final DateTime? supersededAt;
  final DateTime? baselineFrom;
  const ProgressionConfigEntry({
    required this.id,
    required this.exerciseId,
    required this.strategy,
    required this.paramsJson,
    required this.incrementKg,
    required this.createdAt,
    this.supersededAt,
    this.baselineFrom,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['exercise_id'] = Variable<int>(exerciseId);
    {
      map['strategy'] = Variable<String>(
        $ProgressionConfigsTable.$converterstrategy.toSql(strategy),
      );
    }
    map['params_json'] = Variable<String>(paramsJson);
    map['increment_kg'] = Variable<double>(incrementKg);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || supersededAt != null) {
      map['superseded_at'] = Variable<DateTime>(supersededAt);
    }
    if (!nullToAbsent || baselineFrom != null) {
      map['baseline_from'] = Variable<DateTime>(baselineFrom);
    }
    return map;
  }

  ProgressionConfigsCompanion toCompanion(bool nullToAbsent) {
    return ProgressionConfigsCompanion(
      id: Value(id),
      exerciseId: Value(exerciseId),
      strategy: Value(strategy),
      paramsJson: Value(paramsJson),
      incrementKg: Value(incrementKg),
      createdAt: Value(createdAt),
      supersededAt: supersededAt == null && nullToAbsent
          ? const Value.absent()
          : Value(supersededAt),
      baselineFrom: baselineFrom == null && nullToAbsent
          ? const Value.absent()
          : Value(baselineFrom),
    );
  }

  factory ProgressionConfigEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProgressionConfigEntry(
      id: serializer.fromJson<int>(json['id']),
      exerciseId: serializer.fromJson<int>(json['exerciseId']),
      strategy: $ProgressionConfigsTable.$converterstrategy.fromJson(
        serializer.fromJson<String>(json['strategy']),
      ),
      paramsJson: serializer.fromJson<String>(json['paramsJson']),
      incrementKg: serializer.fromJson<double>(json['incrementKg']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      supersededAt: serializer.fromJson<DateTime?>(json['supersededAt']),
      baselineFrom: serializer.fromJson<DateTime?>(json['baselineFrom']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'exerciseId': serializer.toJson<int>(exerciseId),
      'strategy': serializer.toJson<String>(
        $ProgressionConfigsTable.$converterstrategy.toJson(strategy),
      ),
      'paramsJson': serializer.toJson<String>(paramsJson),
      'incrementKg': serializer.toJson<double>(incrementKg),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'supersededAt': serializer.toJson<DateTime?>(supersededAt),
      'baselineFrom': serializer.toJson<DateTime?>(baselineFrom),
    };
  }

  ProgressionConfigEntry copyWith({
    int? id,
    int? exerciseId,
    StrategyId? strategy,
    String? paramsJson,
    double? incrementKg,
    DateTime? createdAt,
    Value<DateTime?> supersededAt = const Value.absent(),
    Value<DateTime?> baselineFrom = const Value.absent(),
  }) => ProgressionConfigEntry(
    id: id ?? this.id,
    exerciseId: exerciseId ?? this.exerciseId,
    strategy: strategy ?? this.strategy,
    paramsJson: paramsJson ?? this.paramsJson,
    incrementKg: incrementKg ?? this.incrementKg,
    createdAt: createdAt ?? this.createdAt,
    supersededAt: supersededAt.present ? supersededAt.value : this.supersededAt,
    baselineFrom: baselineFrom.present ? baselineFrom.value : this.baselineFrom,
  );
  ProgressionConfigEntry copyWithCompanion(ProgressionConfigsCompanion data) {
    return ProgressionConfigEntry(
      id: data.id.present ? data.id.value : this.id,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      strategy: data.strategy.present ? data.strategy.value : this.strategy,
      paramsJson: data.paramsJson.present
          ? data.paramsJson.value
          : this.paramsJson,
      incrementKg: data.incrementKg.present
          ? data.incrementKg.value
          : this.incrementKg,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      supersededAt: data.supersededAt.present
          ? data.supersededAt.value
          : this.supersededAt,
      baselineFrom: data.baselineFrom.present
          ? data.baselineFrom.value
          : this.baselineFrom,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProgressionConfigEntry(')
          ..write('id: $id, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('strategy: $strategy, ')
          ..write('paramsJson: $paramsJson, ')
          ..write('incrementKg: $incrementKg, ')
          ..write('createdAt: $createdAt, ')
          ..write('supersededAt: $supersededAt, ')
          ..write('baselineFrom: $baselineFrom')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    exerciseId,
    strategy,
    paramsJson,
    incrementKg,
    createdAt,
    supersededAt,
    baselineFrom,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProgressionConfigEntry &&
          other.id == this.id &&
          other.exerciseId == this.exerciseId &&
          other.strategy == this.strategy &&
          other.paramsJson == this.paramsJson &&
          other.incrementKg == this.incrementKg &&
          other.createdAt == this.createdAt &&
          other.supersededAt == this.supersededAt &&
          other.baselineFrom == this.baselineFrom);
}

class ProgressionConfigsCompanion
    extends UpdateCompanion<ProgressionConfigEntry> {
  final Value<int> id;
  final Value<int> exerciseId;
  final Value<StrategyId> strategy;
  final Value<String> paramsJson;
  final Value<double> incrementKg;
  final Value<DateTime> createdAt;
  final Value<DateTime?> supersededAt;
  final Value<DateTime?> baselineFrom;
  const ProgressionConfigsCompanion({
    this.id = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.strategy = const Value.absent(),
    this.paramsJson = const Value.absent(),
    this.incrementKg = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.supersededAt = const Value.absent(),
    this.baselineFrom = const Value.absent(),
  });
  ProgressionConfigsCompanion.insert({
    this.id = const Value.absent(),
    required int exerciseId,
    required StrategyId strategy,
    required String paramsJson,
    required double incrementKg,
    required DateTime createdAt,
    this.supersededAt = const Value.absent(),
    this.baselineFrom = const Value.absent(),
  }) : exerciseId = Value(exerciseId),
       strategy = Value(strategy),
       paramsJson = Value(paramsJson),
       incrementKg = Value(incrementKg),
       createdAt = Value(createdAt);
  static Insertable<ProgressionConfigEntry> custom({
    Expression<int>? id,
    Expression<int>? exerciseId,
    Expression<String>? strategy,
    Expression<String>? paramsJson,
    Expression<double>? incrementKg,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? supersededAt,
    Expression<DateTime>? baselineFrom,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (strategy != null) 'strategy': strategy,
      if (paramsJson != null) 'params_json': paramsJson,
      if (incrementKg != null) 'increment_kg': incrementKg,
      if (createdAt != null) 'created_at': createdAt,
      if (supersededAt != null) 'superseded_at': supersededAt,
      if (baselineFrom != null) 'baseline_from': baselineFrom,
    });
  }

  ProgressionConfigsCompanion copyWith({
    Value<int>? id,
    Value<int>? exerciseId,
    Value<StrategyId>? strategy,
    Value<String>? paramsJson,
    Value<double>? incrementKg,
    Value<DateTime>? createdAt,
    Value<DateTime?>? supersededAt,
    Value<DateTime?>? baselineFrom,
  }) {
    return ProgressionConfigsCompanion(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      strategy: strategy ?? this.strategy,
      paramsJson: paramsJson ?? this.paramsJson,
      incrementKg: incrementKg ?? this.incrementKg,
      createdAt: createdAt ?? this.createdAt,
      supersededAt: supersededAt ?? this.supersededAt,
      baselineFrom: baselineFrom ?? this.baselineFrom,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<int>(exerciseId.value);
    }
    if (strategy.present) {
      map['strategy'] = Variable<String>(
        $ProgressionConfigsTable.$converterstrategy.toSql(strategy.value),
      );
    }
    if (paramsJson.present) {
      map['params_json'] = Variable<String>(paramsJson.value);
    }
    if (incrementKg.present) {
      map['increment_kg'] = Variable<double>(incrementKg.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (supersededAt.present) {
      map['superseded_at'] = Variable<DateTime>(supersededAt.value);
    }
    if (baselineFrom.present) {
      map['baseline_from'] = Variable<DateTime>(baselineFrom.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProgressionConfigsCompanion(')
          ..write('id: $id, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('strategy: $strategy, ')
          ..write('paramsJson: $paramsJson, ')
          ..write('incrementKg: $incrementKg, ')
          ..write('createdAt: $createdAt, ')
          ..write('supersededAt: $supersededAt, ')
          ..write('baselineFrom: $baselineFrom')
          ..write(')'))
        .toString();
  }
}

class $ProgressionRecommendationsTable extends ProgressionRecommendations
    with
        TableInfo<
          $ProgressionRecommendationsTable,
          ProgressionRecommendationEntry
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProgressionRecommendationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<int> exerciseId = GeneratedColumn<int>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _configIdMeta = const VerificationMeta(
    'configId',
  );
  @override
  late final GeneratedColumn<int> configId = GeneratedColumn<int>(
    'config_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<StrategyId, String> strategy =
      GeneratedColumn<String>(
        'strategy',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<StrategyId>(
        $ProgressionRecommendationsTable.$converterstrategy,
      );
  static const VerificationMeta _generatedAtMeta = const VerificationMeta(
    'generatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> generatedAt = GeneratedColumn<DateTime>(
    'generated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceSessionIdMeta = const VerificationMeta(
    'sourceSessionId',
  );
  @override
  late final GeneratedColumn<int> sourceSessionId = GeneratedColumn<int>(
    'source_session_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _analyzedSessionIdsJsonMeta =
      const VerificationMeta('analyzedSessionIdsJson');
  @override
  late final GeneratedColumn<String> analyzedSessionIdsJson =
      GeneratedColumn<String>(
        'analyzed_session_ids_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  @override
  late final GeneratedColumnWithTypeConverter<RecommendationStatus, String>
  status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<RecommendationStatus>(
        $ProgressionRecommendationsTable.$converterstatus,
      );
  static const VerificationMeta _reasonCodeMeta = const VerificationMeta(
    'reasonCode',
  );
  @override
  late final GeneratedColumn<String> reasonCode = GeneratedColumn<String>(
    'reason_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _explanationMeta = const VerificationMeta(
    'explanation',
  );
  @override
  late final GeneratedColumn<String> explanation = GeneratedColumn<String>(
    'explanation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _criteriaMetJsonMeta = const VerificationMeta(
    'criteriaMetJson',
  );
  @override
  late final GeneratedColumn<String> criteriaMetJson = GeneratedColumn<String>(
    'criteria_met_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _criteriaUnmetJsonMeta = const VerificationMeta(
    'criteriaUnmetJson',
  );
  @override
  late final GeneratedColumn<String> criteriaUnmetJson =
      GeneratedColumn<String>(
        'criteria_unmet_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _currentWeightKgMeta = const VerificationMeta(
    'currentWeightKg',
  );
  @override
  late final GeneratedColumn<double> currentWeightKg = GeneratedColumn<double>(
    'current_weight_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recommendedTargetsJsonMeta =
      const VerificationMeta('recommendedTargetsJson');
  @override
  late final GeneratedColumn<String> recommendedTargetsJson =
      GeneratedColumn<String>(
        'recommended_targets_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _strategyStateJsonMeta = const VerificationMeta(
    'strategyStateJson',
  );
  @override
  late final GeneratedColumn<String> strategyStateJson =
      GeneratedColumn<String>(
        'strategy_state_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  @override
  late final GeneratedColumnWithTypeConverter<RecommendationDecision, String>
  decision =
      GeneratedColumn<String>(
        'decision',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(RecommendationDecision.pending.name),
      ).withConverter<RecommendationDecision>(
        $ProgressionRecommendationsTable.$converterdecision,
      );
  static const VerificationMeta _decidedAtMeta = const VerificationMeta(
    'decidedAt',
  );
  @override
  late final GeneratedColumn<DateTime> decidedAt = GeneratedColumn<DateTime>(
    'decided_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _finalTargetsJsonMeta = const VerificationMeta(
    'finalTargetsJson',
  );
  @override
  late final GeneratedColumn<String> finalTargetsJson = GeneratedColumn<String>(
    'final_targets_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    exerciseId,
    configId,
    strategy,
    generatedAt,
    sourceSessionId,
    analyzedSessionIdsJson,
    status,
    reasonCode,
    explanation,
    criteriaMetJson,
    criteriaUnmetJson,
    currentWeightKg,
    recommendedTargetsJson,
    strategyStateJson,
    decision,
    decidedAt,
    finalTargetsJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'progression_recommendations';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProgressionRecommendationEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('config_id')) {
      context.handle(
        _configIdMeta,
        configId.isAcceptableOrUnknown(data['config_id']!, _configIdMeta),
      );
    } else if (isInserting) {
      context.missing(_configIdMeta);
    }
    if (data.containsKey('generated_at')) {
      context.handle(
        _generatedAtMeta,
        generatedAt.isAcceptableOrUnknown(
          data['generated_at']!,
          _generatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_generatedAtMeta);
    }
    if (data.containsKey('source_session_id')) {
      context.handle(
        _sourceSessionIdMeta,
        sourceSessionId.isAcceptableOrUnknown(
          data['source_session_id']!,
          _sourceSessionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceSessionIdMeta);
    }
    if (data.containsKey('analyzed_session_ids_json')) {
      context.handle(
        _analyzedSessionIdsJsonMeta,
        analyzedSessionIdsJson.isAcceptableOrUnknown(
          data['analyzed_session_ids_json']!,
          _analyzedSessionIdsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_analyzedSessionIdsJsonMeta);
    }
    if (data.containsKey('reason_code')) {
      context.handle(
        _reasonCodeMeta,
        reasonCode.isAcceptableOrUnknown(data['reason_code']!, _reasonCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonCodeMeta);
    }
    if (data.containsKey('explanation')) {
      context.handle(
        _explanationMeta,
        explanation.isAcceptableOrUnknown(
          data['explanation']!,
          _explanationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_explanationMeta);
    }
    if (data.containsKey('criteria_met_json')) {
      context.handle(
        _criteriaMetJsonMeta,
        criteriaMetJson.isAcceptableOrUnknown(
          data['criteria_met_json']!,
          _criteriaMetJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_criteriaMetJsonMeta);
    }
    if (data.containsKey('criteria_unmet_json')) {
      context.handle(
        _criteriaUnmetJsonMeta,
        criteriaUnmetJson.isAcceptableOrUnknown(
          data['criteria_unmet_json']!,
          _criteriaUnmetJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_criteriaUnmetJsonMeta);
    }
    if (data.containsKey('current_weight_kg')) {
      context.handle(
        _currentWeightKgMeta,
        currentWeightKg.isAcceptableOrUnknown(
          data['current_weight_kg']!,
          _currentWeightKgMeta,
        ),
      );
    }
    if (data.containsKey('recommended_targets_json')) {
      context.handle(
        _recommendedTargetsJsonMeta,
        recommendedTargetsJson.isAcceptableOrUnknown(
          data['recommended_targets_json']!,
          _recommendedTargetsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recommendedTargetsJsonMeta);
    }
    if (data.containsKey('strategy_state_json')) {
      context.handle(
        _strategyStateJsonMeta,
        strategyStateJson.isAcceptableOrUnknown(
          data['strategy_state_json']!,
          _strategyStateJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_strategyStateJsonMeta);
    }
    if (data.containsKey('decided_at')) {
      context.handle(
        _decidedAtMeta,
        decidedAt.isAcceptableOrUnknown(data['decided_at']!, _decidedAtMeta),
      );
    }
    if (data.containsKey('final_targets_json')) {
      context.handle(
        _finalTargetsJsonMeta,
        finalTargetsJson.isAcceptableOrUnknown(
          data['final_targets_json']!,
          _finalTargetsJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProgressionRecommendationEntry map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProgressionRecommendationEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}exercise_id'],
      )!,
      configId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}config_id'],
      )!,
      strategy: $ProgressionRecommendationsTable.$converterstrategy.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}strategy'],
        )!,
      ),
      generatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}generated_at'],
      )!,
      sourceSessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_session_id'],
      )!,
      analyzedSessionIdsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}analyzed_session_ids_json'],
      )!,
      status: $ProgressionRecommendationsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      reasonCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason_code'],
      )!,
      explanation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}explanation'],
      )!,
      criteriaMetJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}criteria_met_json'],
      )!,
      criteriaUnmetJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}criteria_unmet_json'],
      )!,
      currentWeightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}current_weight_kg'],
      ),
      recommendedTargetsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recommended_targets_json'],
      )!,
      strategyStateJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}strategy_state_json'],
      )!,
      decision: $ProgressionRecommendationsTable.$converterdecision.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}decision'],
        )!,
      ),
      decidedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}decided_at'],
      ),
      finalTargetsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}final_targets_json'],
      ),
    );
  }

  @override
  $ProgressionRecommendationsTable createAlias(String alias) {
    return $ProgressionRecommendationsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<StrategyId, String, String> $converterstrategy =
      const EnumNameConverter<StrategyId>(StrategyId.values);
  static JsonTypeConverter2<RecommendationStatus, String, String>
  $converterstatus = const EnumNameConverter<RecommendationStatus>(
    RecommendationStatus.values,
  );
  static JsonTypeConverter2<RecommendationDecision, String, String>
  $converterdecision = const EnumNameConverter<RecommendationDecision>(
    RecommendationDecision.values,
  );
}

class ProgressionRecommendationEntry extends DataClass
    implements Insertable<ProgressionRecommendationEntry> {
  final int id;
  final int exerciseId;
  final int configId;
  final StrategyId strategy;
  final DateTime generatedAt;
  final int sourceSessionId;
  final String analyzedSessionIdsJson;
  final RecommendationStatus status;
  final String reasonCode;
  final String explanation;
  final String criteriaMetJson;
  final String criteriaUnmetJson;
  final double? currentWeightKg;
  final String recommendedTargetsJson;
  final String strategyStateJson;
  final RecommendationDecision decision;
  final DateTime? decidedAt;
  final String? finalTargetsJson;
  const ProgressionRecommendationEntry({
    required this.id,
    required this.exerciseId,
    required this.configId,
    required this.strategy,
    required this.generatedAt,
    required this.sourceSessionId,
    required this.analyzedSessionIdsJson,
    required this.status,
    required this.reasonCode,
    required this.explanation,
    required this.criteriaMetJson,
    required this.criteriaUnmetJson,
    this.currentWeightKg,
    required this.recommendedTargetsJson,
    required this.strategyStateJson,
    required this.decision,
    this.decidedAt,
    this.finalTargetsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['exercise_id'] = Variable<int>(exerciseId);
    map['config_id'] = Variable<int>(configId);
    {
      map['strategy'] = Variable<String>(
        $ProgressionRecommendationsTable.$converterstrategy.toSql(strategy),
      );
    }
    map['generated_at'] = Variable<DateTime>(generatedAt);
    map['source_session_id'] = Variable<int>(sourceSessionId);
    map['analyzed_session_ids_json'] = Variable<String>(analyzedSessionIdsJson);
    {
      map['status'] = Variable<String>(
        $ProgressionRecommendationsTable.$converterstatus.toSql(status),
      );
    }
    map['reason_code'] = Variable<String>(reasonCode);
    map['explanation'] = Variable<String>(explanation);
    map['criteria_met_json'] = Variable<String>(criteriaMetJson);
    map['criteria_unmet_json'] = Variable<String>(criteriaUnmetJson);
    if (!nullToAbsent || currentWeightKg != null) {
      map['current_weight_kg'] = Variable<double>(currentWeightKg);
    }
    map['recommended_targets_json'] = Variable<String>(recommendedTargetsJson);
    map['strategy_state_json'] = Variable<String>(strategyStateJson);
    {
      map['decision'] = Variable<String>(
        $ProgressionRecommendationsTable.$converterdecision.toSql(decision),
      );
    }
    if (!nullToAbsent || decidedAt != null) {
      map['decided_at'] = Variable<DateTime>(decidedAt);
    }
    if (!nullToAbsent || finalTargetsJson != null) {
      map['final_targets_json'] = Variable<String>(finalTargetsJson);
    }
    return map;
  }

  ProgressionRecommendationsCompanion toCompanion(bool nullToAbsent) {
    return ProgressionRecommendationsCompanion(
      id: Value(id),
      exerciseId: Value(exerciseId),
      configId: Value(configId),
      strategy: Value(strategy),
      generatedAt: Value(generatedAt),
      sourceSessionId: Value(sourceSessionId),
      analyzedSessionIdsJson: Value(analyzedSessionIdsJson),
      status: Value(status),
      reasonCode: Value(reasonCode),
      explanation: Value(explanation),
      criteriaMetJson: Value(criteriaMetJson),
      criteriaUnmetJson: Value(criteriaUnmetJson),
      currentWeightKg: currentWeightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(currentWeightKg),
      recommendedTargetsJson: Value(recommendedTargetsJson),
      strategyStateJson: Value(strategyStateJson),
      decision: Value(decision),
      decidedAt: decidedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(decidedAt),
      finalTargetsJson: finalTargetsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(finalTargetsJson),
    );
  }

  factory ProgressionRecommendationEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProgressionRecommendationEntry(
      id: serializer.fromJson<int>(json['id']),
      exerciseId: serializer.fromJson<int>(json['exerciseId']),
      configId: serializer.fromJson<int>(json['configId']),
      strategy: $ProgressionRecommendationsTable.$converterstrategy.fromJson(
        serializer.fromJson<String>(json['strategy']),
      ),
      generatedAt: serializer.fromJson<DateTime>(json['generatedAt']),
      sourceSessionId: serializer.fromJson<int>(json['sourceSessionId']),
      analyzedSessionIdsJson: serializer.fromJson<String>(
        json['analyzedSessionIdsJson'],
      ),
      status: $ProgressionRecommendationsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      reasonCode: serializer.fromJson<String>(json['reasonCode']),
      explanation: serializer.fromJson<String>(json['explanation']),
      criteriaMetJson: serializer.fromJson<String>(json['criteriaMetJson']),
      criteriaUnmetJson: serializer.fromJson<String>(json['criteriaUnmetJson']),
      currentWeightKg: serializer.fromJson<double?>(json['currentWeightKg']),
      recommendedTargetsJson: serializer.fromJson<String>(
        json['recommendedTargetsJson'],
      ),
      strategyStateJson: serializer.fromJson<String>(json['strategyStateJson']),
      decision: $ProgressionRecommendationsTable.$converterdecision.fromJson(
        serializer.fromJson<String>(json['decision']),
      ),
      decidedAt: serializer.fromJson<DateTime?>(json['decidedAt']),
      finalTargetsJson: serializer.fromJson<String?>(json['finalTargetsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'exerciseId': serializer.toJson<int>(exerciseId),
      'configId': serializer.toJson<int>(configId),
      'strategy': serializer.toJson<String>(
        $ProgressionRecommendationsTable.$converterstrategy.toJson(strategy),
      ),
      'generatedAt': serializer.toJson<DateTime>(generatedAt),
      'sourceSessionId': serializer.toJson<int>(sourceSessionId),
      'analyzedSessionIdsJson': serializer.toJson<String>(
        analyzedSessionIdsJson,
      ),
      'status': serializer.toJson<String>(
        $ProgressionRecommendationsTable.$converterstatus.toJson(status),
      ),
      'reasonCode': serializer.toJson<String>(reasonCode),
      'explanation': serializer.toJson<String>(explanation),
      'criteriaMetJson': serializer.toJson<String>(criteriaMetJson),
      'criteriaUnmetJson': serializer.toJson<String>(criteriaUnmetJson),
      'currentWeightKg': serializer.toJson<double?>(currentWeightKg),
      'recommendedTargetsJson': serializer.toJson<String>(
        recommendedTargetsJson,
      ),
      'strategyStateJson': serializer.toJson<String>(strategyStateJson),
      'decision': serializer.toJson<String>(
        $ProgressionRecommendationsTable.$converterdecision.toJson(decision),
      ),
      'decidedAt': serializer.toJson<DateTime?>(decidedAt),
      'finalTargetsJson': serializer.toJson<String?>(finalTargetsJson),
    };
  }

  ProgressionRecommendationEntry copyWith({
    int? id,
    int? exerciseId,
    int? configId,
    StrategyId? strategy,
    DateTime? generatedAt,
    int? sourceSessionId,
    String? analyzedSessionIdsJson,
    RecommendationStatus? status,
    String? reasonCode,
    String? explanation,
    String? criteriaMetJson,
    String? criteriaUnmetJson,
    Value<double?> currentWeightKg = const Value.absent(),
    String? recommendedTargetsJson,
    String? strategyStateJson,
    RecommendationDecision? decision,
    Value<DateTime?> decidedAt = const Value.absent(),
    Value<String?> finalTargetsJson = const Value.absent(),
  }) => ProgressionRecommendationEntry(
    id: id ?? this.id,
    exerciseId: exerciseId ?? this.exerciseId,
    configId: configId ?? this.configId,
    strategy: strategy ?? this.strategy,
    generatedAt: generatedAt ?? this.generatedAt,
    sourceSessionId: sourceSessionId ?? this.sourceSessionId,
    analyzedSessionIdsJson:
        analyzedSessionIdsJson ?? this.analyzedSessionIdsJson,
    status: status ?? this.status,
    reasonCode: reasonCode ?? this.reasonCode,
    explanation: explanation ?? this.explanation,
    criteriaMetJson: criteriaMetJson ?? this.criteriaMetJson,
    criteriaUnmetJson: criteriaUnmetJson ?? this.criteriaUnmetJson,
    currentWeightKg: currentWeightKg.present
        ? currentWeightKg.value
        : this.currentWeightKg,
    recommendedTargetsJson:
        recommendedTargetsJson ?? this.recommendedTargetsJson,
    strategyStateJson: strategyStateJson ?? this.strategyStateJson,
    decision: decision ?? this.decision,
    decidedAt: decidedAt.present ? decidedAt.value : this.decidedAt,
    finalTargetsJson: finalTargetsJson.present
        ? finalTargetsJson.value
        : this.finalTargetsJson,
  );
  ProgressionRecommendationEntry copyWithCompanion(
    ProgressionRecommendationsCompanion data,
  ) {
    return ProgressionRecommendationEntry(
      id: data.id.present ? data.id.value : this.id,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      configId: data.configId.present ? data.configId.value : this.configId,
      strategy: data.strategy.present ? data.strategy.value : this.strategy,
      generatedAt: data.generatedAt.present
          ? data.generatedAt.value
          : this.generatedAt,
      sourceSessionId: data.sourceSessionId.present
          ? data.sourceSessionId.value
          : this.sourceSessionId,
      analyzedSessionIdsJson: data.analyzedSessionIdsJson.present
          ? data.analyzedSessionIdsJson.value
          : this.analyzedSessionIdsJson,
      status: data.status.present ? data.status.value : this.status,
      reasonCode: data.reasonCode.present
          ? data.reasonCode.value
          : this.reasonCode,
      explanation: data.explanation.present
          ? data.explanation.value
          : this.explanation,
      criteriaMetJson: data.criteriaMetJson.present
          ? data.criteriaMetJson.value
          : this.criteriaMetJson,
      criteriaUnmetJson: data.criteriaUnmetJson.present
          ? data.criteriaUnmetJson.value
          : this.criteriaUnmetJson,
      currentWeightKg: data.currentWeightKg.present
          ? data.currentWeightKg.value
          : this.currentWeightKg,
      recommendedTargetsJson: data.recommendedTargetsJson.present
          ? data.recommendedTargetsJson.value
          : this.recommendedTargetsJson,
      strategyStateJson: data.strategyStateJson.present
          ? data.strategyStateJson.value
          : this.strategyStateJson,
      decision: data.decision.present ? data.decision.value : this.decision,
      decidedAt: data.decidedAt.present ? data.decidedAt.value : this.decidedAt,
      finalTargetsJson: data.finalTargetsJson.present
          ? data.finalTargetsJson.value
          : this.finalTargetsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProgressionRecommendationEntry(')
          ..write('id: $id, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('configId: $configId, ')
          ..write('strategy: $strategy, ')
          ..write('generatedAt: $generatedAt, ')
          ..write('sourceSessionId: $sourceSessionId, ')
          ..write('analyzedSessionIdsJson: $analyzedSessionIdsJson, ')
          ..write('status: $status, ')
          ..write('reasonCode: $reasonCode, ')
          ..write('explanation: $explanation, ')
          ..write('criteriaMetJson: $criteriaMetJson, ')
          ..write('criteriaUnmetJson: $criteriaUnmetJson, ')
          ..write('currentWeightKg: $currentWeightKg, ')
          ..write('recommendedTargetsJson: $recommendedTargetsJson, ')
          ..write('strategyStateJson: $strategyStateJson, ')
          ..write('decision: $decision, ')
          ..write('decidedAt: $decidedAt, ')
          ..write('finalTargetsJson: $finalTargetsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    exerciseId,
    configId,
    strategy,
    generatedAt,
    sourceSessionId,
    analyzedSessionIdsJson,
    status,
    reasonCode,
    explanation,
    criteriaMetJson,
    criteriaUnmetJson,
    currentWeightKg,
    recommendedTargetsJson,
    strategyStateJson,
    decision,
    decidedAt,
    finalTargetsJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProgressionRecommendationEntry &&
          other.id == this.id &&
          other.exerciseId == this.exerciseId &&
          other.configId == this.configId &&
          other.strategy == this.strategy &&
          other.generatedAt == this.generatedAt &&
          other.sourceSessionId == this.sourceSessionId &&
          other.analyzedSessionIdsJson == this.analyzedSessionIdsJson &&
          other.status == this.status &&
          other.reasonCode == this.reasonCode &&
          other.explanation == this.explanation &&
          other.criteriaMetJson == this.criteriaMetJson &&
          other.criteriaUnmetJson == this.criteriaUnmetJson &&
          other.currentWeightKg == this.currentWeightKg &&
          other.recommendedTargetsJson == this.recommendedTargetsJson &&
          other.strategyStateJson == this.strategyStateJson &&
          other.decision == this.decision &&
          other.decidedAt == this.decidedAt &&
          other.finalTargetsJson == this.finalTargetsJson);
}

class ProgressionRecommendationsCompanion
    extends UpdateCompanion<ProgressionRecommendationEntry> {
  final Value<int> id;
  final Value<int> exerciseId;
  final Value<int> configId;
  final Value<StrategyId> strategy;
  final Value<DateTime> generatedAt;
  final Value<int> sourceSessionId;
  final Value<String> analyzedSessionIdsJson;
  final Value<RecommendationStatus> status;
  final Value<String> reasonCode;
  final Value<String> explanation;
  final Value<String> criteriaMetJson;
  final Value<String> criteriaUnmetJson;
  final Value<double?> currentWeightKg;
  final Value<String> recommendedTargetsJson;
  final Value<String> strategyStateJson;
  final Value<RecommendationDecision> decision;
  final Value<DateTime?> decidedAt;
  final Value<String?> finalTargetsJson;
  const ProgressionRecommendationsCompanion({
    this.id = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.configId = const Value.absent(),
    this.strategy = const Value.absent(),
    this.generatedAt = const Value.absent(),
    this.sourceSessionId = const Value.absent(),
    this.analyzedSessionIdsJson = const Value.absent(),
    this.status = const Value.absent(),
    this.reasonCode = const Value.absent(),
    this.explanation = const Value.absent(),
    this.criteriaMetJson = const Value.absent(),
    this.criteriaUnmetJson = const Value.absent(),
    this.currentWeightKg = const Value.absent(),
    this.recommendedTargetsJson = const Value.absent(),
    this.strategyStateJson = const Value.absent(),
    this.decision = const Value.absent(),
    this.decidedAt = const Value.absent(),
    this.finalTargetsJson = const Value.absent(),
  });
  ProgressionRecommendationsCompanion.insert({
    this.id = const Value.absent(),
    required int exerciseId,
    required int configId,
    required StrategyId strategy,
    required DateTime generatedAt,
    required int sourceSessionId,
    required String analyzedSessionIdsJson,
    required RecommendationStatus status,
    required String reasonCode,
    required String explanation,
    required String criteriaMetJson,
    required String criteriaUnmetJson,
    this.currentWeightKg = const Value.absent(),
    required String recommendedTargetsJson,
    required String strategyStateJson,
    this.decision = const Value.absent(),
    this.decidedAt = const Value.absent(),
    this.finalTargetsJson = const Value.absent(),
  }) : exerciseId = Value(exerciseId),
       configId = Value(configId),
       strategy = Value(strategy),
       generatedAt = Value(generatedAt),
       sourceSessionId = Value(sourceSessionId),
       analyzedSessionIdsJson = Value(analyzedSessionIdsJson),
       status = Value(status),
       reasonCode = Value(reasonCode),
       explanation = Value(explanation),
       criteriaMetJson = Value(criteriaMetJson),
       criteriaUnmetJson = Value(criteriaUnmetJson),
       recommendedTargetsJson = Value(recommendedTargetsJson),
       strategyStateJson = Value(strategyStateJson);
  static Insertable<ProgressionRecommendationEntry> custom({
    Expression<int>? id,
    Expression<int>? exerciseId,
    Expression<int>? configId,
    Expression<String>? strategy,
    Expression<DateTime>? generatedAt,
    Expression<int>? sourceSessionId,
    Expression<String>? analyzedSessionIdsJson,
    Expression<String>? status,
    Expression<String>? reasonCode,
    Expression<String>? explanation,
    Expression<String>? criteriaMetJson,
    Expression<String>? criteriaUnmetJson,
    Expression<double>? currentWeightKg,
    Expression<String>? recommendedTargetsJson,
    Expression<String>? strategyStateJson,
    Expression<String>? decision,
    Expression<DateTime>? decidedAt,
    Expression<String>? finalTargetsJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (configId != null) 'config_id': configId,
      if (strategy != null) 'strategy': strategy,
      if (generatedAt != null) 'generated_at': generatedAt,
      if (sourceSessionId != null) 'source_session_id': sourceSessionId,
      if (analyzedSessionIdsJson != null)
        'analyzed_session_ids_json': analyzedSessionIdsJson,
      if (status != null) 'status': status,
      if (reasonCode != null) 'reason_code': reasonCode,
      if (explanation != null) 'explanation': explanation,
      if (criteriaMetJson != null) 'criteria_met_json': criteriaMetJson,
      if (criteriaUnmetJson != null) 'criteria_unmet_json': criteriaUnmetJson,
      if (currentWeightKg != null) 'current_weight_kg': currentWeightKg,
      if (recommendedTargetsJson != null)
        'recommended_targets_json': recommendedTargetsJson,
      if (strategyStateJson != null) 'strategy_state_json': strategyStateJson,
      if (decision != null) 'decision': decision,
      if (decidedAt != null) 'decided_at': decidedAt,
      if (finalTargetsJson != null) 'final_targets_json': finalTargetsJson,
    });
  }

  ProgressionRecommendationsCompanion copyWith({
    Value<int>? id,
    Value<int>? exerciseId,
    Value<int>? configId,
    Value<StrategyId>? strategy,
    Value<DateTime>? generatedAt,
    Value<int>? sourceSessionId,
    Value<String>? analyzedSessionIdsJson,
    Value<RecommendationStatus>? status,
    Value<String>? reasonCode,
    Value<String>? explanation,
    Value<String>? criteriaMetJson,
    Value<String>? criteriaUnmetJson,
    Value<double?>? currentWeightKg,
    Value<String>? recommendedTargetsJson,
    Value<String>? strategyStateJson,
    Value<RecommendationDecision>? decision,
    Value<DateTime?>? decidedAt,
    Value<String?>? finalTargetsJson,
  }) {
    return ProgressionRecommendationsCompanion(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      configId: configId ?? this.configId,
      strategy: strategy ?? this.strategy,
      generatedAt: generatedAt ?? this.generatedAt,
      sourceSessionId: sourceSessionId ?? this.sourceSessionId,
      analyzedSessionIdsJson:
          analyzedSessionIdsJson ?? this.analyzedSessionIdsJson,
      status: status ?? this.status,
      reasonCode: reasonCode ?? this.reasonCode,
      explanation: explanation ?? this.explanation,
      criteriaMetJson: criteriaMetJson ?? this.criteriaMetJson,
      criteriaUnmetJson: criteriaUnmetJson ?? this.criteriaUnmetJson,
      currentWeightKg: currentWeightKg ?? this.currentWeightKg,
      recommendedTargetsJson:
          recommendedTargetsJson ?? this.recommendedTargetsJson,
      strategyStateJson: strategyStateJson ?? this.strategyStateJson,
      decision: decision ?? this.decision,
      decidedAt: decidedAt ?? this.decidedAt,
      finalTargetsJson: finalTargetsJson ?? this.finalTargetsJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<int>(exerciseId.value);
    }
    if (configId.present) {
      map['config_id'] = Variable<int>(configId.value);
    }
    if (strategy.present) {
      map['strategy'] = Variable<String>(
        $ProgressionRecommendationsTable.$converterstrategy.toSql(
          strategy.value,
        ),
      );
    }
    if (generatedAt.present) {
      map['generated_at'] = Variable<DateTime>(generatedAt.value);
    }
    if (sourceSessionId.present) {
      map['source_session_id'] = Variable<int>(sourceSessionId.value);
    }
    if (analyzedSessionIdsJson.present) {
      map['analyzed_session_ids_json'] = Variable<String>(
        analyzedSessionIdsJson.value,
      );
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $ProgressionRecommendationsTable.$converterstatus.toSql(status.value),
      );
    }
    if (reasonCode.present) {
      map['reason_code'] = Variable<String>(reasonCode.value);
    }
    if (explanation.present) {
      map['explanation'] = Variable<String>(explanation.value);
    }
    if (criteriaMetJson.present) {
      map['criteria_met_json'] = Variable<String>(criteriaMetJson.value);
    }
    if (criteriaUnmetJson.present) {
      map['criteria_unmet_json'] = Variable<String>(criteriaUnmetJson.value);
    }
    if (currentWeightKg.present) {
      map['current_weight_kg'] = Variable<double>(currentWeightKg.value);
    }
    if (recommendedTargetsJson.present) {
      map['recommended_targets_json'] = Variable<String>(
        recommendedTargetsJson.value,
      );
    }
    if (strategyStateJson.present) {
      map['strategy_state_json'] = Variable<String>(strategyStateJson.value);
    }
    if (decision.present) {
      map['decision'] = Variable<String>(
        $ProgressionRecommendationsTable.$converterdecision.toSql(
          decision.value,
        ),
      );
    }
    if (decidedAt.present) {
      map['decided_at'] = Variable<DateTime>(decidedAt.value);
    }
    if (finalTargetsJson.present) {
      map['final_targets_json'] = Variable<String>(finalTargetsJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProgressionRecommendationsCompanion(')
          ..write('id: $id, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('configId: $configId, ')
          ..write('strategy: $strategy, ')
          ..write('generatedAt: $generatedAt, ')
          ..write('sourceSessionId: $sourceSessionId, ')
          ..write('analyzedSessionIdsJson: $analyzedSessionIdsJson, ')
          ..write('status: $status, ')
          ..write('reasonCode: $reasonCode, ')
          ..write('explanation: $explanation, ')
          ..write('criteriaMetJson: $criteriaMetJson, ')
          ..write('criteriaUnmetJson: $criteriaUnmetJson, ')
          ..write('currentWeightKg: $currentWeightKg, ')
          ..write('recommendedTargetsJson: $recommendedTargetsJson, ')
          ..write('strategyStateJson: $strategyStateJson, ')
          ..write('decision: $decision, ')
          ..write('decidedAt: $decidedAt, ')
          ..write('finalTargetsJson: $finalTargetsJson')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ExercisesTable exercises = $ExercisesTable(this);
  late final $WorkoutTemplatesTable workoutTemplates = $WorkoutTemplatesTable(
    this,
  );
  late final $TemplateExercisesTable templateExercises =
      $TemplateExercisesTable(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $SessionExercisesTable sessionExercises = $SessionExercisesTable(
    this,
  );
  late final $SessionSetsTable sessionSets = $SessionSetsTable(this);
  late final $BodyWeightEntriesTable bodyWeightEntries =
      $BodyWeightEntriesTable(this);
  late final $ProgressionConfigsTable progressionConfigs =
      $ProgressionConfigsTable(this);
  late final $ProgressionRecommendationsTable progressionRecommendations =
      $ProgressionRecommendationsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    exercises,
    workoutTemplates,
    templateExercises,
    sessions,
    sessionExercises,
    sessionSets,
    bodyWeightEntries,
    progressionConfigs,
    progressionRecommendations,
  ];
}

typedef $$ExercisesTableCreateCompanionBuilder =
    ExercisesCompanion Function({
      Value<int> id,
      required String name,
      required String muscleGroup,
      required SetType setType,
      Value<int> restSeconds,
      Value<bool> isArchived,
      Value<DateTime> createdAt,
    });
typedef $$ExercisesTableUpdateCompanionBuilder =
    ExercisesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> muscleGroup,
      Value<SetType> setType,
      Value<int> restSeconds,
      Value<bool> isArchived,
      Value<DateTime> createdAt,
    });

class $$ExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get muscleGroup => $composableBuilder(
    column: $table.muscleGroup,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SetType, SetType, String> get setType =>
      $composableBuilder(
        column: $table.setType,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get restSeconds => $composableBuilder(
    column: $table.restSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get muscleGroup => $composableBuilder(
    column: $table.muscleGroup,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get setType => $composableBuilder(
    column: $table.setType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get restSeconds => $composableBuilder(
    column: $table.restSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get muscleGroup => $composableBuilder(
    column: $table.muscleGroup,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<SetType, String> get setType =>
      $composableBuilder(column: $table.setType, builder: (column) => column);

  GeneratedColumn<int> get restSeconds => $composableBuilder(
    column: $table.restSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ExercisesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExercisesTable,
          Exercise,
          $$ExercisesTableFilterComposer,
          $$ExercisesTableOrderingComposer,
          $$ExercisesTableAnnotationComposer,
          $$ExercisesTableCreateCompanionBuilder,
          $$ExercisesTableUpdateCompanionBuilder,
          (Exercise, BaseReferences<_$AppDatabase, $ExercisesTable, Exercise>),
          Exercise,
          PrefetchHooks Function()
        > {
  $$ExercisesTableTableManager(_$AppDatabase db, $ExercisesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExercisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> muscleGroup = const Value.absent(),
                Value<SetType> setType = const Value.absent(),
                Value<int> restSeconds = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ExercisesCompanion(
                id: id,
                name: name,
                muscleGroup: muscleGroup,
                setType: setType,
                restSeconds: restSeconds,
                isArchived: isArchived,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String muscleGroup,
                required SetType setType,
                Value<int> restSeconds = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ExercisesCompanion.insert(
                id: id,
                name: name,
                muscleGroup: muscleGroup,
                setType: setType,
                restSeconds: restSeconds,
                isArchived: isArchived,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExercisesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExercisesTable,
      Exercise,
      $$ExercisesTableFilterComposer,
      $$ExercisesTableOrderingComposer,
      $$ExercisesTableAnnotationComposer,
      $$ExercisesTableCreateCompanionBuilder,
      $$ExercisesTableUpdateCompanionBuilder,
      (Exercise, BaseReferences<_$AppDatabase, $ExercisesTable, Exercise>),
      Exercise,
      PrefetchHooks Function()
    >;
typedef $$WorkoutTemplatesTableCreateCompanionBuilder =
    WorkoutTemplatesCompanion Function({
      Value<int> id,
      required String name,
      Value<bool> isArchived,
      Value<DateTime> createdAt,
      Value<int> position,
      Value<String?> groupName,
    });
typedef $$WorkoutTemplatesTableUpdateCompanionBuilder =
    WorkoutTemplatesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<bool> isArchived,
      Value<DateTime> createdAt,
      Value<int> position,
      Value<String?> groupName,
    });

class $$WorkoutTemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutTemplatesTable> {
  $$WorkoutTemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupName => $composableBuilder(
    column: $table.groupName,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WorkoutTemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutTemplatesTable> {
  $$WorkoutTemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupName => $composableBuilder(
    column: $table.groupName,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkoutTemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutTemplatesTable> {
  $$WorkoutTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get groupName =>
      $composableBuilder(column: $table.groupName, builder: (column) => column);
}

class $$WorkoutTemplatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkoutTemplatesTable,
          WorkoutTemplate,
          $$WorkoutTemplatesTableFilterComposer,
          $$WorkoutTemplatesTableOrderingComposer,
          $$WorkoutTemplatesTableAnnotationComposer,
          $$WorkoutTemplatesTableCreateCompanionBuilder,
          $$WorkoutTemplatesTableUpdateCompanionBuilder,
          (
            WorkoutTemplate,
            BaseReferences<
              _$AppDatabase,
              $WorkoutTemplatesTable,
              WorkoutTemplate
            >,
          ),
          WorkoutTemplate,
          PrefetchHooks Function()
        > {
  $$WorkoutTemplatesTableTableManager(
    _$AppDatabase db,
    $WorkoutTemplatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutTemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutTemplatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String?> groupName = const Value.absent(),
              }) => WorkoutTemplatesCompanion(
                id: id,
                name: name,
                isArchived: isArchived,
                createdAt: createdAt,
                position: position,
                groupName: groupName,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<bool> isArchived = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String?> groupName = const Value.absent(),
              }) => WorkoutTemplatesCompanion.insert(
                id: id,
                name: name,
                isArchived: isArchived,
                createdAt: createdAt,
                position: position,
                groupName: groupName,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WorkoutTemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkoutTemplatesTable,
      WorkoutTemplate,
      $$WorkoutTemplatesTableFilterComposer,
      $$WorkoutTemplatesTableOrderingComposer,
      $$WorkoutTemplatesTableAnnotationComposer,
      $$WorkoutTemplatesTableCreateCompanionBuilder,
      $$WorkoutTemplatesTableUpdateCompanionBuilder,
      (
        WorkoutTemplate,
        BaseReferences<_$AppDatabase, $WorkoutTemplatesTable, WorkoutTemplate>,
      ),
      WorkoutTemplate,
      PrefetchHooks Function()
    >;
typedef $$TemplateExercisesTableCreateCompanionBuilder =
    TemplateExercisesCompanion Function({
      Value<int> id,
      required int templateId,
      required int exerciseId,
      required int position,
      Value<int?> restSecondsOverride,
    });
typedef $$TemplateExercisesTableUpdateCompanionBuilder =
    TemplateExercisesCompanion Function({
      Value<int> id,
      Value<int> templateId,
      Value<int> exerciseId,
      Value<int> position,
      Value<int?> restSecondsOverride,
    });

class $$TemplateExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $TemplateExercisesTable> {
  $$TemplateExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get restSecondsOverride => $composableBuilder(
    column: $table.restSecondsOverride,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TemplateExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $TemplateExercisesTable> {
  $$TemplateExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get restSecondsOverride => $composableBuilder(
    column: $table.restSecondsOverride,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TemplateExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TemplateExercisesTable> {
  $$TemplateExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<int> get restSecondsOverride => $composableBuilder(
    column: $table.restSecondsOverride,
    builder: (column) => column,
  );
}

class $$TemplateExercisesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TemplateExercisesTable,
          TemplateExercise,
          $$TemplateExercisesTableFilterComposer,
          $$TemplateExercisesTableOrderingComposer,
          $$TemplateExercisesTableAnnotationComposer,
          $$TemplateExercisesTableCreateCompanionBuilder,
          $$TemplateExercisesTableUpdateCompanionBuilder,
          (
            TemplateExercise,
            BaseReferences<
              _$AppDatabase,
              $TemplateExercisesTable,
              TemplateExercise
            >,
          ),
          TemplateExercise,
          PrefetchHooks Function()
        > {
  $$TemplateExercisesTableTableManager(
    _$AppDatabase db,
    $TemplateExercisesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TemplateExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TemplateExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TemplateExercisesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> templateId = const Value.absent(),
                Value<int> exerciseId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int?> restSecondsOverride = const Value.absent(),
              }) => TemplateExercisesCompanion(
                id: id,
                templateId: templateId,
                exerciseId: exerciseId,
                position: position,
                restSecondsOverride: restSecondsOverride,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int templateId,
                required int exerciseId,
                required int position,
                Value<int?> restSecondsOverride = const Value.absent(),
              }) => TemplateExercisesCompanion.insert(
                id: id,
                templateId: templateId,
                exerciseId: exerciseId,
                position: position,
                restSecondsOverride: restSecondsOverride,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TemplateExercisesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TemplateExercisesTable,
      TemplateExercise,
      $$TemplateExercisesTableFilterComposer,
      $$TemplateExercisesTableOrderingComposer,
      $$TemplateExercisesTableAnnotationComposer,
      $$TemplateExercisesTableCreateCompanionBuilder,
      $$TemplateExercisesTableUpdateCompanionBuilder,
      (
        TemplateExercise,
        BaseReferences<
          _$AppDatabase,
          $TemplateExercisesTable,
          TemplateExercise
        >,
      ),
      TemplateExercise,
      PrefetchHooks Function()
    >;
typedef $$SessionsTableCreateCompanionBuilder =
    SessionsCompanion Function({
      Value<int> id,
      required int templateId,
      required DateTime startedAt,
      Value<DateTime?> finishedAt,
      Value<String?> notes,
    });
typedef $$SessionsTableUpdateCompanionBuilder =
    SessionsCompanion Function({
      Value<int> id,
      Value<int> templateId,
      Value<DateTime> startedAt,
      Value<DateTime?> finishedAt,
      Value<String?> notes,
    });

class $$SessionsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$SessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionsTable,
          Session,
          $$SessionsTableFilterComposer,
          $$SessionsTableOrderingComposer,
          $$SessionsTableAnnotationComposer,
          $$SessionsTableCreateCompanionBuilder,
          $$SessionsTableUpdateCompanionBuilder,
          (Session, BaseReferences<_$AppDatabase, $SessionsTable, Session>),
          Session,
          PrefetchHooks Function()
        > {
  $$SessionsTableTableManager(_$AppDatabase db, $SessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> templateId = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => SessionsCompanion(
                id: id,
                templateId: templateId,
                startedAt: startedAt,
                finishedAt: finishedAt,
                notes: notes,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int templateId,
                required DateTime startedAt,
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => SessionsCompanion.insert(
                id: id,
                templateId: templateId,
                startedAt: startedAt,
                finishedAt: finishedAt,
                notes: notes,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionsTable,
      Session,
      $$SessionsTableFilterComposer,
      $$SessionsTableOrderingComposer,
      $$SessionsTableAnnotationComposer,
      $$SessionsTableCreateCompanionBuilder,
      $$SessionsTableUpdateCompanionBuilder,
      (Session, BaseReferences<_$AppDatabase, $SessionsTable, Session>),
      Session,
      PrefetchHooks Function()
    >;
typedef $$SessionExercisesTableCreateCompanionBuilder =
    SessionExercisesCompanion Function({
      Value<int> id,
      required int sessionId,
      required int exerciseId,
      required int position,
      Value<int?> restSeconds,
      Value<bool> isExtra,
      Value<int?> progressionConfigId,
      Value<int?> recommendationId,
      Value<bool> excludeFromProgression,
    });
typedef $$SessionExercisesTableUpdateCompanionBuilder =
    SessionExercisesCompanion Function({
      Value<int> id,
      Value<int> sessionId,
      Value<int> exerciseId,
      Value<int> position,
      Value<int?> restSeconds,
      Value<bool> isExtra,
      Value<int?> progressionConfigId,
      Value<int?> recommendationId,
      Value<bool> excludeFromProgression,
    });

class $$SessionExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $SessionExercisesTable> {
  $$SessionExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get restSeconds => $composableBuilder(
    column: $table.restSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isExtra => $composableBuilder(
    column: $table.isExtra,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get progressionConfigId => $composableBuilder(
    column: $table.progressionConfigId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recommendationId => $composableBuilder(
    column: $table.recommendationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get excludeFromProgression => $composableBuilder(
    column: $table.excludeFromProgression,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SessionExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionExercisesTable> {
  $$SessionExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get restSeconds => $composableBuilder(
    column: $table.restSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isExtra => $composableBuilder(
    column: $table.isExtra,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get progressionConfigId => $composableBuilder(
    column: $table.progressionConfigId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recommendationId => $composableBuilder(
    column: $table.recommendationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get excludeFromProgression => $composableBuilder(
    column: $table.excludeFromProgression,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionExercisesTable> {
  $$SessionExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<int> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<int> get restSeconds => $composableBuilder(
    column: $table.restSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isExtra =>
      $composableBuilder(column: $table.isExtra, builder: (column) => column);

  GeneratedColumn<int> get progressionConfigId => $composableBuilder(
    column: $table.progressionConfigId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get recommendationId => $composableBuilder(
    column: $table.recommendationId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get excludeFromProgression => $composableBuilder(
    column: $table.excludeFromProgression,
    builder: (column) => column,
  );
}

class $$SessionExercisesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionExercisesTable,
          SessionExercise,
          $$SessionExercisesTableFilterComposer,
          $$SessionExercisesTableOrderingComposer,
          $$SessionExercisesTableAnnotationComposer,
          $$SessionExercisesTableCreateCompanionBuilder,
          $$SessionExercisesTableUpdateCompanionBuilder,
          (
            SessionExercise,
            BaseReferences<
              _$AppDatabase,
              $SessionExercisesTable,
              SessionExercise
            >,
          ),
          SessionExercise,
          PrefetchHooks Function()
        > {
  $$SessionExercisesTableTableManager(
    _$AppDatabase db,
    $SessionExercisesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionExercisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> sessionId = const Value.absent(),
                Value<int> exerciseId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int?> restSeconds = const Value.absent(),
                Value<bool> isExtra = const Value.absent(),
                Value<int?> progressionConfigId = const Value.absent(),
                Value<int?> recommendationId = const Value.absent(),
                Value<bool> excludeFromProgression = const Value.absent(),
              }) => SessionExercisesCompanion(
                id: id,
                sessionId: sessionId,
                exerciseId: exerciseId,
                position: position,
                restSeconds: restSeconds,
                isExtra: isExtra,
                progressionConfigId: progressionConfigId,
                recommendationId: recommendationId,
                excludeFromProgression: excludeFromProgression,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int sessionId,
                required int exerciseId,
                required int position,
                Value<int?> restSeconds = const Value.absent(),
                Value<bool> isExtra = const Value.absent(),
                Value<int?> progressionConfigId = const Value.absent(),
                Value<int?> recommendationId = const Value.absent(),
                Value<bool> excludeFromProgression = const Value.absent(),
              }) => SessionExercisesCompanion.insert(
                id: id,
                sessionId: sessionId,
                exerciseId: exerciseId,
                position: position,
                restSeconds: restSeconds,
                isExtra: isExtra,
                progressionConfigId: progressionConfigId,
                recommendationId: recommendationId,
                excludeFromProgression: excludeFromProgression,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SessionExercisesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionExercisesTable,
      SessionExercise,
      $$SessionExercisesTableFilterComposer,
      $$SessionExercisesTableOrderingComposer,
      $$SessionExercisesTableAnnotationComposer,
      $$SessionExercisesTableCreateCompanionBuilder,
      $$SessionExercisesTableUpdateCompanionBuilder,
      (
        SessionExercise,
        BaseReferences<_$AppDatabase, $SessionExercisesTable, SessionExercise>,
      ),
      SessionExercise,
      PrefetchHooks Function()
    >;
typedef $$SessionSetsTableCreateCompanionBuilder =
    SessionSetsCompanion Function({
      Value<int> id,
      required int sessionExerciseId,
      required SetType setType,
      Value<double?> weightKg,
      Value<int?> reps,
      Value<int?> durationSeconds,
      Value<bool> isWarmup,
      Value<bool> toFailure,
      required int position,
      Value<int?> rir,
      Value<double?> rpe,
      Value<ExecutionQuality?> executionQuality,
      Value<SetRole?> setRole,
      Value<double?> targetWeightKg,
      Value<int?> targetRepsMin,
      Value<int?> targetRepsMax,
    });
typedef $$SessionSetsTableUpdateCompanionBuilder =
    SessionSetsCompanion Function({
      Value<int> id,
      Value<int> sessionExerciseId,
      Value<SetType> setType,
      Value<double?> weightKg,
      Value<int?> reps,
      Value<int?> durationSeconds,
      Value<bool> isWarmup,
      Value<bool> toFailure,
      Value<int> position,
      Value<int?> rir,
      Value<double?> rpe,
      Value<ExecutionQuality?> executionQuality,
      Value<SetRole?> setRole,
      Value<double?> targetWeightKg,
      Value<int?> targetRepsMin,
      Value<int?> targetRepsMax,
    });

class $$SessionSetsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionSetsTable> {
  $$SessionSetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sessionExerciseId => $composableBuilder(
    column: $table.sessionExerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SetType, SetType, String> get setType =>
      $composableBuilder(
        column: $table.setType,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isWarmup => $composableBuilder(
    column: $table.isWarmup,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get toFailure => $composableBuilder(
    column: $table.toFailure,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rir => $composableBuilder(
    column: $table.rir,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rpe => $composableBuilder(
    column: $table.rpe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ExecutionQuality?, ExecutionQuality, String>
  get executionQuality => $composableBuilder(
    column: $table.executionQuality,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<SetRole?, SetRole, String> get setRole =>
      $composableBuilder(
        column: $table.setRole,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<double> get targetWeightKg => $composableBuilder(
    column: $table.targetWeightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetRepsMin => $composableBuilder(
    column: $table.targetRepsMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetRepsMax => $composableBuilder(
    column: $table.targetRepsMax,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SessionSetsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionSetsTable> {
  $$SessionSetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sessionExerciseId => $composableBuilder(
    column: $table.sessionExerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get setType => $composableBuilder(
    column: $table.setType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isWarmup => $composableBuilder(
    column: $table.isWarmup,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get toFailure => $composableBuilder(
    column: $table.toFailure,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rir => $composableBuilder(
    column: $table.rir,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rpe => $composableBuilder(
    column: $table.rpe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get executionQuality => $composableBuilder(
    column: $table.executionQuality,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get setRole => $composableBuilder(
    column: $table.setRole,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetWeightKg => $composableBuilder(
    column: $table.targetWeightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetRepsMin => $composableBuilder(
    column: $table.targetRepsMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetRepsMax => $composableBuilder(
    column: $table.targetRepsMax,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionSetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionSetsTable> {
  $$SessionSetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get sessionExerciseId => $composableBuilder(
    column: $table.sessionExerciseId,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<SetType, String> get setType =>
      $composableBuilder(column: $table.setType, builder: (column) => column);

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isWarmup =>
      $composableBuilder(column: $table.isWarmup, builder: (column) => column);

  GeneratedColumn<bool> get toFailure =>
      $composableBuilder(column: $table.toFailure, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<int> get rir =>
      $composableBuilder(column: $table.rir, builder: (column) => column);

  GeneratedColumn<double> get rpe =>
      $composableBuilder(column: $table.rpe, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ExecutionQuality?, String>
  get executionQuality => $composableBuilder(
    column: $table.executionQuality,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<SetRole?, String> get setRole =>
      $composableBuilder(column: $table.setRole, builder: (column) => column);

  GeneratedColumn<double> get targetWeightKg => $composableBuilder(
    column: $table.targetWeightKg,
    builder: (column) => column,
  );

  GeneratedColumn<int> get targetRepsMin => $composableBuilder(
    column: $table.targetRepsMin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get targetRepsMax => $composableBuilder(
    column: $table.targetRepsMax,
    builder: (column) => column,
  );
}

class $$SessionSetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionSetsTable,
          SessionSet,
          $$SessionSetsTableFilterComposer,
          $$SessionSetsTableOrderingComposer,
          $$SessionSetsTableAnnotationComposer,
          $$SessionSetsTableCreateCompanionBuilder,
          $$SessionSetsTableUpdateCompanionBuilder,
          (
            SessionSet,
            BaseReferences<_$AppDatabase, $SessionSetsTable, SessionSet>,
          ),
          SessionSet,
          PrefetchHooks Function()
        > {
  $$SessionSetsTableTableManager(_$AppDatabase db, $SessionSetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionSetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionSetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionSetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> sessionExerciseId = const Value.absent(),
                Value<SetType> setType = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<int?> reps = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<bool> isWarmup = const Value.absent(),
                Value<bool> toFailure = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int?> rir = const Value.absent(),
                Value<double?> rpe = const Value.absent(),
                Value<ExecutionQuality?> executionQuality =
                    const Value.absent(),
                Value<SetRole?> setRole = const Value.absent(),
                Value<double?> targetWeightKg = const Value.absent(),
                Value<int?> targetRepsMin = const Value.absent(),
                Value<int?> targetRepsMax = const Value.absent(),
              }) => SessionSetsCompanion(
                id: id,
                sessionExerciseId: sessionExerciseId,
                setType: setType,
                weightKg: weightKg,
                reps: reps,
                durationSeconds: durationSeconds,
                isWarmup: isWarmup,
                toFailure: toFailure,
                position: position,
                rir: rir,
                rpe: rpe,
                executionQuality: executionQuality,
                setRole: setRole,
                targetWeightKg: targetWeightKg,
                targetRepsMin: targetRepsMin,
                targetRepsMax: targetRepsMax,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int sessionExerciseId,
                required SetType setType,
                Value<double?> weightKg = const Value.absent(),
                Value<int?> reps = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<bool> isWarmup = const Value.absent(),
                Value<bool> toFailure = const Value.absent(),
                required int position,
                Value<int?> rir = const Value.absent(),
                Value<double?> rpe = const Value.absent(),
                Value<ExecutionQuality?> executionQuality =
                    const Value.absent(),
                Value<SetRole?> setRole = const Value.absent(),
                Value<double?> targetWeightKg = const Value.absent(),
                Value<int?> targetRepsMin = const Value.absent(),
                Value<int?> targetRepsMax = const Value.absent(),
              }) => SessionSetsCompanion.insert(
                id: id,
                sessionExerciseId: sessionExerciseId,
                setType: setType,
                weightKg: weightKg,
                reps: reps,
                durationSeconds: durationSeconds,
                isWarmup: isWarmup,
                toFailure: toFailure,
                position: position,
                rir: rir,
                rpe: rpe,
                executionQuality: executionQuality,
                setRole: setRole,
                targetWeightKg: targetWeightKg,
                targetRepsMin: targetRepsMin,
                targetRepsMax: targetRepsMax,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SessionSetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionSetsTable,
      SessionSet,
      $$SessionSetsTableFilterComposer,
      $$SessionSetsTableOrderingComposer,
      $$SessionSetsTableAnnotationComposer,
      $$SessionSetsTableCreateCompanionBuilder,
      $$SessionSetsTableUpdateCompanionBuilder,
      (
        SessionSet,
        BaseReferences<_$AppDatabase, $SessionSetsTable, SessionSet>,
      ),
      SessionSet,
      PrefetchHooks Function()
    >;
typedef $$BodyWeightEntriesTableCreateCompanionBuilder =
    BodyWeightEntriesCompanion Function({
      Value<int> id,
      required double weightKg,
      required DateTime recordedAt,
    });
typedef $$BodyWeightEntriesTableUpdateCompanionBuilder =
    BodyWeightEntriesCompanion Function({
      Value<int> id,
      Value<double> weightKg,
      Value<DateTime> recordedAt,
    });

class $$BodyWeightEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $BodyWeightEntriesTable> {
  $$BodyWeightEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BodyWeightEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $BodyWeightEntriesTable> {
  $$BodyWeightEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BodyWeightEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BodyWeightEntriesTable> {
  $$BodyWeightEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );
}

class $$BodyWeightEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BodyWeightEntriesTable,
          BodyWeightEntry,
          $$BodyWeightEntriesTableFilterComposer,
          $$BodyWeightEntriesTableOrderingComposer,
          $$BodyWeightEntriesTableAnnotationComposer,
          $$BodyWeightEntriesTableCreateCompanionBuilder,
          $$BodyWeightEntriesTableUpdateCompanionBuilder,
          (
            BodyWeightEntry,
            BaseReferences<
              _$AppDatabase,
              $BodyWeightEntriesTable,
              BodyWeightEntry
            >,
          ),
          BodyWeightEntry,
          PrefetchHooks Function()
        > {
  $$BodyWeightEntriesTableTableManager(
    _$AppDatabase db,
    $BodyWeightEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BodyWeightEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BodyWeightEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BodyWeightEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<double> weightKg = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
              }) => BodyWeightEntriesCompanion(
                id: id,
                weightKg: weightKg,
                recordedAt: recordedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required double weightKg,
                required DateTime recordedAt,
              }) => BodyWeightEntriesCompanion.insert(
                id: id,
                weightKg: weightKg,
                recordedAt: recordedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BodyWeightEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BodyWeightEntriesTable,
      BodyWeightEntry,
      $$BodyWeightEntriesTableFilterComposer,
      $$BodyWeightEntriesTableOrderingComposer,
      $$BodyWeightEntriesTableAnnotationComposer,
      $$BodyWeightEntriesTableCreateCompanionBuilder,
      $$BodyWeightEntriesTableUpdateCompanionBuilder,
      (
        BodyWeightEntry,
        BaseReferences<_$AppDatabase, $BodyWeightEntriesTable, BodyWeightEntry>,
      ),
      BodyWeightEntry,
      PrefetchHooks Function()
    >;
typedef $$ProgressionConfigsTableCreateCompanionBuilder =
    ProgressionConfigsCompanion Function({
      Value<int> id,
      required int exerciseId,
      required StrategyId strategy,
      required String paramsJson,
      required double incrementKg,
      required DateTime createdAt,
      Value<DateTime?> supersededAt,
      Value<DateTime?> baselineFrom,
    });
typedef $$ProgressionConfigsTableUpdateCompanionBuilder =
    ProgressionConfigsCompanion Function({
      Value<int> id,
      Value<int> exerciseId,
      Value<StrategyId> strategy,
      Value<String> paramsJson,
      Value<double> incrementKg,
      Value<DateTime> createdAt,
      Value<DateTime?> supersededAt,
      Value<DateTime?> baselineFrom,
    });

class $$ProgressionConfigsTableFilterComposer
    extends Composer<_$AppDatabase, $ProgressionConfigsTable> {
  $$ProgressionConfigsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<StrategyId, StrategyId, String> get strategy =>
      $composableBuilder(
        column: $table.strategy,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get paramsJson => $composableBuilder(
    column: $table.paramsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get incrementKg => $composableBuilder(
    column: $table.incrementKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get supersededAt => $composableBuilder(
    column: $table.supersededAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get baselineFrom => $composableBuilder(
    column: $table.baselineFrom,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProgressionConfigsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProgressionConfigsTable> {
  $$ProgressionConfigsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get strategy => $composableBuilder(
    column: $table.strategy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paramsJson => $composableBuilder(
    column: $table.paramsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get incrementKg => $composableBuilder(
    column: $table.incrementKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get supersededAt => $composableBuilder(
    column: $table.supersededAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get baselineFrom => $composableBuilder(
    column: $table.baselineFrom,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProgressionConfigsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProgressionConfigsTable> {
  $$ProgressionConfigsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<StrategyId, String> get strategy =>
      $composableBuilder(column: $table.strategy, builder: (column) => column);

  GeneratedColumn<String> get paramsJson => $composableBuilder(
    column: $table.paramsJson,
    builder: (column) => column,
  );

  GeneratedColumn<double> get incrementKg => $composableBuilder(
    column: $table.incrementKg,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get supersededAt => $composableBuilder(
    column: $table.supersededAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get baselineFrom => $composableBuilder(
    column: $table.baselineFrom,
    builder: (column) => column,
  );
}

class $$ProgressionConfigsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProgressionConfigsTable,
          ProgressionConfigEntry,
          $$ProgressionConfigsTableFilterComposer,
          $$ProgressionConfigsTableOrderingComposer,
          $$ProgressionConfigsTableAnnotationComposer,
          $$ProgressionConfigsTableCreateCompanionBuilder,
          $$ProgressionConfigsTableUpdateCompanionBuilder,
          (
            ProgressionConfigEntry,
            BaseReferences<
              _$AppDatabase,
              $ProgressionConfigsTable,
              ProgressionConfigEntry
            >,
          ),
          ProgressionConfigEntry,
          PrefetchHooks Function()
        > {
  $$ProgressionConfigsTableTableManager(
    _$AppDatabase db,
    $ProgressionConfigsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProgressionConfigsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProgressionConfigsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProgressionConfigsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> exerciseId = const Value.absent(),
                Value<StrategyId> strategy = const Value.absent(),
                Value<String> paramsJson = const Value.absent(),
                Value<double> incrementKg = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> supersededAt = const Value.absent(),
                Value<DateTime?> baselineFrom = const Value.absent(),
              }) => ProgressionConfigsCompanion(
                id: id,
                exerciseId: exerciseId,
                strategy: strategy,
                paramsJson: paramsJson,
                incrementKg: incrementKg,
                createdAt: createdAt,
                supersededAt: supersededAt,
                baselineFrom: baselineFrom,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int exerciseId,
                required StrategyId strategy,
                required String paramsJson,
                required double incrementKg,
                required DateTime createdAt,
                Value<DateTime?> supersededAt = const Value.absent(),
                Value<DateTime?> baselineFrom = const Value.absent(),
              }) => ProgressionConfigsCompanion.insert(
                id: id,
                exerciseId: exerciseId,
                strategy: strategy,
                paramsJson: paramsJson,
                incrementKg: incrementKg,
                createdAt: createdAt,
                supersededAt: supersededAt,
                baselineFrom: baselineFrom,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProgressionConfigsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProgressionConfigsTable,
      ProgressionConfigEntry,
      $$ProgressionConfigsTableFilterComposer,
      $$ProgressionConfigsTableOrderingComposer,
      $$ProgressionConfigsTableAnnotationComposer,
      $$ProgressionConfigsTableCreateCompanionBuilder,
      $$ProgressionConfigsTableUpdateCompanionBuilder,
      (
        ProgressionConfigEntry,
        BaseReferences<
          _$AppDatabase,
          $ProgressionConfigsTable,
          ProgressionConfigEntry
        >,
      ),
      ProgressionConfigEntry,
      PrefetchHooks Function()
    >;
typedef $$ProgressionRecommendationsTableCreateCompanionBuilder =
    ProgressionRecommendationsCompanion Function({
      Value<int> id,
      required int exerciseId,
      required int configId,
      required StrategyId strategy,
      required DateTime generatedAt,
      required int sourceSessionId,
      required String analyzedSessionIdsJson,
      required RecommendationStatus status,
      required String reasonCode,
      required String explanation,
      required String criteriaMetJson,
      required String criteriaUnmetJson,
      Value<double?> currentWeightKg,
      required String recommendedTargetsJson,
      required String strategyStateJson,
      Value<RecommendationDecision> decision,
      Value<DateTime?> decidedAt,
      Value<String?> finalTargetsJson,
    });
typedef $$ProgressionRecommendationsTableUpdateCompanionBuilder =
    ProgressionRecommendationsCompanion Function({
      Value<int> id,
      Value<int> exerciseId,
      Value<int> configId,
      Value<StrategyId> strategy,
      Value<DateTime> generatedAt,
      Value<int> sourceSessionId,
      Value<String> analyzedSessionIdsJson,
      Value<RecommendationStatus> status,
      Value<String> reasonCode,
      Value<String> explanation,
      Value<String> criteriaMetJson,
      Value<String> criteriaUnmetJson,
      Value<double?> currentWeightKg,
      Value<String> recommendedTargetsJson,
      Value<String> strategyStateJson,
      Value<RecommendationDecision> decision,
      Value<DateTime?> decidedAt,
      Value<String?> finalTargetsJson,
    });

class $$ProgressionRecommendationsTableFilterComposer
    extends Composer<_$AppDatabase, $ProgressionRecommendationsTable> {
  $$ProgressionRecommendationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get configId => $composableBuilder(
    column: $table.configId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<StrategyId, StrategyId, String> get strategy =>
      $composableBuilder(
        column: $table.strategy,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get generatedAt => $composableBuilder(
    column: $table.generatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sourceSessionId => $composableBuilder(
    column: $table.sourceSessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get analyzedSessionIdsJson => $composableBuilder(
    column: $table.analyzedSessionIdsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    RecommendationStatus,
    RecommendationStatus,
    String
  >
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get reasonCode => $composableBuilder(
    column: $table.reasonCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get criteriaMetJson => $composableBuilder(
    column: $table.criteriaMetJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get criteriaUnmetJson => $composableBuilder(
    column: $table.criteriaUnmetJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get currentWeightKg => $composableBuilder(
    column: $table.currentWeightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recommendedTargetsJson => $composableBuilder(
    column: $table.recommendedTargetsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get strategyStateJson => $composableBuilder(
    column: $table.strategyStateJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    RecommendationDecision,
    RecommendationDecision,
    String
  >
  get decision => $composableBuilder(
    column: $table.decision,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get decidedAt => $composableBuilder(
    column: $table.decidedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get finalTargetsJson => $composableBuilder(
    column: $table.finalTargetsJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProgressionRecommendationsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProgressionRecommendationsTable> {
  $$ProgressionRecommendationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get configId => $composableBuilder(
    column: $table.configId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get strategy => $composableBuilder(
    column: $table.strategy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get generatedAt => $composableBuilder(
    column: $table.generatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sourceSessionId => $composableBuilder(
    column: $table.sourceSessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get analyzedSessionIdsJson => $composableBuilder(
    column: $table.analyzedSessionIdsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reasonCode => $composableBuilder(
    column: $table.reasonCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get criteriaMetJson => $composableBuilder(
    column: $table.criteriaMetJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get criteriaUnmetJson => $composableBuilder(
    column: $table.criteriaUnmetJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get currentWeightKg => $composableBuilder(
    column: $table.currentWeightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recommendedTargetsJson => $composableBuilder(
    column: $table.recommendedTargetsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get strategyStateJson => $composableBuilder(
    column: $table.strategyStateJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get decision => $composableBuilder(
    column: $table.decision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get decidedAt => $composableBuilder(
    column: $table.decidedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get finalTargetsJson => $composableBuilder(
    column: $table.finalTargetsJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProgressionRecommendationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProgressionRecommendationsTable> {
  $$ProgressionRecommendationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get configId =>
      $composableBuilder(column: $table.configId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<StrategyId, String> get strategy =>
      $composableBuilder(column: $table.strategy, builder: (column) => column);

  GeneratedColumn<DateTime> get generatedAt => $composableBuilder(
    column: $table.generatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sourceSessionId => $composableBuilder(
    column: $table.sourceSessionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get analyzedSessionIdsJson => $composableBuilder(
    column: $table.analyzedSessionIdsJson,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<RecommendationStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get reasonCode => $composableBuilder(
    column: $table.reasonCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get criteriaMetJson => $composableBuilder(
    column: $table.criteriaMetJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get criteriaUnmetJson => $composableBuilder(
    column: $table.criteriaUnmetJson,
    builder: (column) => column,
  );

  GeneratedColumn<double> get currentWeightKg => $composableBuilder(
    column: $table.currentWeightKg,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recommendedTargetsJson => $composableBuilder(
    column: $table.recommendedTargetsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get strategyStateJson => $composableBuilder(
    column: $table.strategyStateJson,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<RecommendationDecision, String>
  get decision =>
      $composableBuilder(column: $table.decision, builder: (column) => column);

  GeneratedColumn<DateTime> get decidedAt =>
      $composableBuilder(column: $table.decidedAt, builder: (column) => column);

  GeneratedColumn<String> get finalTargetsJson => $composableBuilder(
    column: $table.finalTargetsJson,
    builder: (column) => column,
  );
}

class $$ProgressionRecommendationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProgressionRecommendationsTable,
          ProgressionRecommendationEntry,
          $$ProgressionRecommendationsTableFilterComposer,
          $$ProgressionRecommendationsTableOrderingComposer,
          $$ProgressionRecommendationsTableAnnotationComposer,
          $$ProgressionRecommendationsTableCreateCompanionBuilder,
          $$ProgressionRecommendationsTableUpdateCompanionBuilder,
          (
            ProgressionRecommendationEntry,
            BaseReferences<
              _$AppDatabase,
              $ProgressionRecommendationsTable,
              ProgressionRecommendationEntry
            >,
          ),
          ProgressionRecommendationEntry,
          PrefetchHooks Function()
        > {
  $$ProgressionRecommendationsTableTableManager(
    _$AppDatabase db,
    $ProgressionRecommendationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProgressionRecommendationsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ProgressionRecommendationsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ProgressionRecommendationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> exerciseId = const Value.absent(),
                Value<int> configId = const Value.absent(),
                Value<StrategyId> strategy = const Value.absent(),
                Value<DateTime> generatedAt = const Value.absent(),
                Value<int> sourceSessionId = const Value.absent(),
                Value<String> analyzedSessionIdsJson = const Value.absent(),
                Value<RecommendationStatus> status = const Value.absent(),
                Value<String> reasonCode = const Value.absent(),
                Value<String> explanation = const Value.absent(),
                Value<String> criteriaMetJson = const Value.absent(),
                Value<String> criteriaUnmetJson = const Value.absent(),
                Value<double?> currentWeightKg = const Value.absent(),
                Value<String> recommendedTargetsJson = const Value.absent(),
                Value<String> strategyStateJson = const Value.absent(),
                Value<RecommendationDecision> decision = const Value.absent(),
                Value<DateTime?> decidedAt = const Value.absent(),
                Value<String?> finalTargetsJson = const Value.absent(),
              }) => ProgressionRecommendationsCompanion(
                id: id,
                exerciseId: exerciseId,
                configId: configId,
                strategy: strategy,
                generatedAt: generatedAt,
                sourceSessionId: sourceSessionId,
                analyzedSessionIdsJson: analyzedSessionIdsJson,
                status: status,
                reasonCode: reasonCode,
                explanation: explanation,
                criteriaMetJson: criteriaMetJson,
                criteriaUnmetJson: criteriaUnmetJson,
                currentWeightKg: currentWeightKg,
                recommendedTargetsJson: recommendedTargetsJson,
                strategyStateJson: strategyStateJson,
                decision: decision,
                decidedAt: decidedAt,
                finalTargetsJson: finalTargetsJson,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int exerciseId,
                required int configId,
                required StrategyId strategy,
                required DateTime generatedAt,
                required int sourceSessionId,
                required String analyzedSessionIdsJson,
                required RecommendationStatus status,
                required String reasonCode,
                required String explanation,
                required String criteriaMetJson,
                required String criteriaUnmetJson,
                Value<double?> currentWeightKg = const Value.absent(),
                required String recommendedTargetsJson,
                required String strategyStateJson,
                Value<RecommendationDecision> decision = const Value.absent(),
                Value<DateTime?> decidedAt = const Value.absent(),
                Value<String?> finalTargetsJson = const Value.absent(),
              }) => ProgressionRecommendationsCompanion.insert(
                id: id,
                exerciseId: exerciseId,
                configId: configId,
                strategy: strategy,
                generatedAt: generatedAt,
                sourceSessionId: sourceSessionId,
                analyzedSessionIdsJson: analyzedSessionIdsJson,
                status: status,
                reasonCode: reasonCode,
                explanation: explanation,
                criteriaMetJson: criteriaMetJson,
                criteriaUnmetJson: criteriaUnmetJson,
                currentWeightKg: currentWeightKg,
                recommendedTargetsJson: recommendedTargetsJson,
                strategyStateJson: strategyStateJson,
                decision: decision,
                decidedAt: decidedAt,
                finalTargetsJson: finalTargetsJson,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProgressionRecommendationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProgressionRecommendationsTable,
      ProgressionRecommendationEntry,
      $$ProgressionRecommendationsTableFilterComposer,
      $$ProgressionRecommendationsTableOrderingComposer,
      $$ProgressionRecommendationsTableAnnotationComposer,
      $$ProgressionRecommendationsTableCreateCompanionBuilder,
      $$ProgressionRecommendationsTableUpdateCompanionBuilder,
      (
        ProgressionRecommendationEntry,
        BaseReferences<
          _$AppDatabase,
          $ProgressionRecommendationsTable,
          ProgressionRecommendationEntry
        >,
      ),
      ProgressionRecommendationEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ExercisesTableTableManager get exercises =>
      $$ExercisesTableTableManager(_db, _db.exercises);
  $$WorkoutTemplatesTableTableManager get workoutTemplates =>
      $$WorkoutTemplatesTableTableManager(_db, _db.workoutTemplates);
  $$TemplateExercisesTableTableManager get templateExercises =>
      $$TemplateExercisesTableTableManager(_db, _db.templateExercises);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$SessionExercisesTableTableManager get sessionExercises =>
      $$SessionExercisesTableTableManager(_db, _db.sessionExercises);
  $$SessionSetsTableTableManager get sessionSets =>
      $$SessionSetsTableTableManager(_db, _db.sessionSets);
  $$BodyWeightEntriesTableTableManager get bodyWeightEntries =>
      $$BodyWeightEntriesTableTableManager(_db, _db.bodyWeightEntries);
  $$ProgressionConfigsTableTableManager get progressionConfigs =>
      $$ProgressionConfigsTableTableManager(_db, _db.progressionConfigs);
  $$ProgressionRecommendationsTableTableManager
  get progressionRecommendations =>
      $$ProgressionRecommendationsTableTableManager(
        _db,
        _db.progressionRecommendations,
      );
}
