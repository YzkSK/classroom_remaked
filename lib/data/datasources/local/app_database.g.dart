// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CoursesTable extends Courses with TableInfo<$CoursesTable, CourseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CoursesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sectionMeta = const VerificationMeta(
    'section',
  );
  @override
  late final GeneratedColumn<String> section = GeneratedColumn<String>(
    'section',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _roomMeta = const VerificationMeta('room');
  @override
  late final GeneratedColumn<String> room = GeneratedColumn<String>(
    'room',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _courseStateMeta = const VerificationMeta(
    'courseState',
  );
  @override
  late final GeneratedColumn<String> courseState = GeneratedColumn<String>(
    'course_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('ACTIVE'),
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('student'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    section,
    room,
    ownerId,
    courseState,
    role,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'courses';
  @override
  VerificationContext validateIntegrity(
    Insertable<CourseRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('section')) {
      context.handle(
        _sectionMeta,
        section.isAcceptableOrUnknown(data['section']!, _sectionMeta),
      );
    }
    if (data.containsKey('room')) {
      context.handle(
        _roomMeta,
        room.isAcceptableOrUnknown(data['room']!, _roomMeta),
      );
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    }
    if (data.containsKey('course_state')) {
      context.handle(
        _courseStateMeta,
        courseState.isAcceptableOrUnknown(
          data['course_state']!,
          _courseStateMeta,
        ),
      );
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CourseRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CourseRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      section: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}section'],
      ),
      room: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}room'],
      ),
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      ),
      courseState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}course_state'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
    );
  }

  @override
  $CoursesTable createAlias(String alias) {
    return $CoursesTable(attachedDatabase, alias);
  }
}

class CourseRow extends DataClass implements Insertable<CourseRow> {
  final String id;
  final String name;
  final String? description;
  final String? section;
  final String? room;
  final String? ownerId;
  final String courseState;
  final String role;
  const CourseRow({
    required this.id,
    required this.name,
    this.description,
    this.section,
    this.room,
    this.ownerId,
    required this.courseState,
    required this.role,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || section != null) {
      map['section'] = Variable<String>(section);
    }
    if (!nullToAbsent || room != null) {
      map['room'] = Variable<String>(room);
    }
    if (!nullToAbsent || ownerId != null) {
      map['owner_id'] = Variable<String>(ownerId);
    }
    map['course_state'] = Variable<String>(courseState);
    map['role'] = Variable<String>(role);
    return map;
  }

  CoursesCompanion toCompanion(bool nullToAbsent) {
    return CoursesCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      section: section == null && nullToAbsent
          ? const Value.absent()
          : Value(section),
      room: room == null && nullToAbsent ? const Value.absent() : Value(room),
      ownerId: ownerId == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerId),
      courseState: Value(courseState),
      role: Value(role),
    );
  }

  factory CourseRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CourseRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      section: serializer.fromJson<String?>(json['section']),
      room: serializer.fromJson<String?>(json['room']),
      ownerId: serializer.fromJson<String?>(json['ownerId']),
      courseState: serializer.fromJson<String>(json['courseState']),
      role: serializer.fromJson<String>(json['role']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'section': serializer.toJson<String?>(section),
      'room': serializer.toJson<String?>(room),
      'ownerId': serializer.toJson<String?>(ownerId),
      'courseState': serializer.toJson<String>(courseState),
      'role': serializer.toJson<String>(role),
    };
  }

  CourseRow copyWith({
    String? id,
    String? name,
    Value<String?> description = const Value.absent(),
    Value<String?> section = const Value.absent(),
    Value<String?> room = const Value.absent(),
    Value<String?> ownerId = const Value.absent(),
    String? courseState,
    String? role,
  }) => CourseRow(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    section: section.present ? section.value : this.section,
    room: room.present ? room.value : this.room,
    ownerId: ownerId.present ? ownerId.value : this.ownerId,
    courseState: courseState ?? this.courseState,
    role: role ?? this.role,
  );
  CourseRow copyWithCompanion(CoursesCompanion data) {
    return CourseRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      section: data.section.present ? data.section.value : this.section,
      room: data.room.present ? data.room.value : this.room,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      courseState: data.courseState.present
          ? data.courseState.value
          : this.courseState,
      role: data.role.present ? data.role.value : this.role,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CourseRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('section: $section, ')
          ..write('room: $room, ')
          ..write('ownerId: $ownerId, ')
          ..write('courseState: $courseState, ')
          ..write('role: $role')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    section,
    room,
    ownerId,
    courseState,
    role,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CourseRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.section == this.section &&
          other.room == this.room &&
          other.ownerId == this.ownerId &&
          other.courseState == this.courseState &&
          other.role == this.role);
}

class CoursesCompanion extends UpdateCompanion<CourseRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<String?> section;
  final Value<String?> room;
  final Value<String?> ownerId;
  final Value<String> courseState;
  final Value<String> role;
  final Value<int> rowid;
  const CoursesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.section = const Value.absent(),
    this.room = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.courseState = const Value.absent(),
    this.role = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CoursesCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    this.section = const Value.absent(),
    this.room = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.courseState = const Value.absent(),
    this.role = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<CourseRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? section,
    Expression<String>? room,
    Expression<String>? ownerId,
    Expression<String>? courseState,
    Expression<String>? role,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (section != null) 'section': section,
      if (room != null) 'room': room,
      if (ownerId != null) 'owner_id': ownerId,
      if (courseState != null) 'course_state': courseState,
      if (role != null) 'role': role,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CoursesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<String?>? section,
    Value<String?>? room,
    Value<String?>? ownerId,
    Value<String>? courseState,
    Value<String>? role,
    Value<int>? rowid,
  }) {
    return CoursesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      section: section ?? this.section,
      room: room ?? this.room,
      ownerId: ownerId ?? this.ownerId,
      courseState: courseState ?? this.courseState,
      role: role ?? this.role,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (section.present) {
      map['section'] = Variable<String>(section.value);
    }
    if (room.present) {
      map['room'] = Variable<String>(room.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (courseState.present) {
      map['course_state'] = Variable<String>(courseState.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CoursesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('section: $section, ')
          ..write('room: $room, ')
          ..write('ownerId: $ownerId, ')
          ..write('courseState: $courseState, ')
          ..write('role: $role, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AssignmentsTable extends Assignments
    with TableInfo<$AssignmentsTable, AssignmentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AssignmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _courseIdMeta = const VerificationMeta(
    'courseId',
  );
  @override
  late final GeneratedColumn<String> courseId = GeneratedColumn<String>(
    'course_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueDateMillisMeta = const VerificationMeta(
    'dueDateMillis',
  );
  @override
  late final GeneratedColumn<int> dueDateMillis = GeneratedColumn<int>(
    'due_date_millis',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('published'),
  );
  static const VerificationMeta _submissionStateMeta = const VerificationMeta(
    'submissionState',
  );
  @override
  late final GeneratedColumn<String> submissionState = GeneratedColumn<String>(
    'submission_state',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _submissionIdMeta = const VerificationMeta(
    'submissionId',
  );
  @override
  late final GeneratedColumn<String> submissionId = GeneratedColumn<String>(
    'submission_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _materialsJsonMeta = const VerificationMeta(
    'materialsJson',
  );
  @override
  late final GeneratedColumn<String> materialsJson = GeneratedColumn<String>(
    'materials_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _submissionAttachmentsJsonMeta =
      const VerificationMeta('submissionAttachmentsJson');
  @override
  late final GeneratedColumn<String> submissionAttachmentsJson =
      GeneratedColumn<String>(
        'submission_attachments_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    courseId,
    title,
    description,
    dueDateMillis,
    state,
    submissionState,
    submissionId,
    materialsJson,
    submissionAttachmentsJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'assignments';
  @override
  VerificationContext validateIntegrity(
    Insertable<AssignmentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('course_id')) {
      context.handle(
        _courseIdMeta,
        courseId.isAcceptableOrUnknown(data['course_id']!, _courseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_courseIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('due_date_millis')) {
      context.handle(
        _dueDateMillisMeta,
        dueDateMillis.isAcceptableOrUnknown(
          data['due_date_millis']!,
          _dueDateMillisMeta,
        ),
      );
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    }
    if (data.containsKey('submission_state')) {
      context.handle(
        _submissionStateMeta,
        submissionState.isAcceptableOrUnknown(
          data['submission_state']!,
          _submissionStateMeta,
        ),
      );
    }
    if (data.containsKey('submission_id')) {
      context.handle(
        _submissionIdMeta,
        submissionId.isAcceptableOrUnknown(
          data['submission_id']!,
          _submissionIdMeta,
        ),
      );
    }
    if (data.containsKey('materials_json')) {
      context.handle(
        _materialsJsonMeta,
        materialsJson.isAcceptableOrUnknown(
          data['materials_json']!,
          _materialsJsonMeta,
        ),
      );
    }
    if (data.containsKey('submission_attachments_json')) {
      context.handle(
        _submissionAttachmentsJsonMeta,
        submissionAttachmentsJson.isAcceptableOrUnknown(
          data['submission_attachments_json']!,
          _submissionAttachmentsJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AssignmentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AssignmentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      courseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}course_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      dueDateMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_date_millis'],
      ),
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      submissionState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}submission_state'],
      ),
      submissionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}submission_id'],
      ),
      materialsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}materials_json'],
      ),
      submissionAttachmentsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}submission_attachments_json'],
      ),
    );
  }

  @override
  $AssignmentsTable createAlias(String alias) {
    return $AssignmentsTable(attachedDatabase, alias);
  }
}

class AssignmentRow extends DataClass implements Insertable<AssignmentRow> {
  final String id;
  final String courseId;
  final String title;
  final String? description;
  final int? dueDateMillis;
  final String state;
  final String? submissionState;
  final String? submissionId;
  final String? materialsJson;
  final String? submissionAttachmentsJson;
  const AssignmentRow({
    required this.id,
    required this.courseId,
    required this.title,
    this.description,
    this.dueDateMillis,
    required this.state,
    this.submissionState,
    this.submissionId,
    this.materialsJson,
    this.submissionAttachmentsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['course_id'] = Variable<String>(courseId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || dueDateMillis != null) {
      map['due_date_millis'] = Variable<int>(dueDateMillis);
    }
    map['state'] = Variable<String>(state);
    if (!nullToAbsent || submissionState != null) {
      map['submission_state'] = Variable<String>(submissionState);
    }
    if (!nullToAbsent || submissionId != null) {
      map['submission_id'] = Variable<String>(submissionId);
    }
    if (!nullToAbsent || materialsJson != null) {
      map['materials_json'] = Variable<String>(materialsJson);
    }
    if (!nullToAbsent || submissionAttachmentsJson != null) {
      map['submission_attachments_json'] = Variable<String>(
        submissionAttachmentsJson,
      );
    }
    return map;
  }

  AssignmentsCompanion toCompanion(bool nullToAbsent) {
    return AssignmentsCompanion(
      id: Value(id),
      courseId: Value(courseId),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      dueDateMillis: dueDateMillis == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDateMillis),
      state: Value(state),
      submissionState: submissionState == null && nullToAbsent
          ? const Value.absent()
          : Value(submissionState),
      submissionId: submissionId == null && nullToAbsent
          ? const Value.absent()
          : Value(submissionId),
      materialsJson: materialsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(materialsJson),
      submissionAttachmentsJson:
          submissionAttachmentsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(submissionAttachmentsJson),
    );
  }

  factory AssignmentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AssignmentRow(
      id: serializer.fromJson<String>(json['id']),
      courseId: serializer.fromJson<String>(json['courseId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      dueDateMillis: serializer.fromJson<int?>(json['dueDateMillis']),
      state: serializer.fromJson<String>(json['state']),
      submissionState: serializer.fromJson<String?>(json['submissionState']),
      submissionId: serializer.fromJson<String?>(json['submissionId']),
      materialsJson: serializer.fromJson<String?>(json['materialsJson']),
      submissionAttachmentsJson: serializer.fromJson<String?>(
        json['submissionAttachmentsJson'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'courseId': serializer.toJson<String>(courseId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'dueDateMillis': serializer.toJson<int?>(dueDateMillis),
      'state': serializer.toJson<String>(state),
      'submissionState': serializer.toJson<String?>(submissionState),
      'submissionId': serializer.toJson<String?>(submissionId),
      'materialsJson': serializer.toJson<String?>(materialsJson),
      'submissionAttachmentsJson': serializer.toJson<String?>(
        submissionAttachmentsJson,
      ),
    };
  }

  AssignmentRow copyWith({
    String? id,
    String? courseId,
    String? title,
    Value<String?> description = const Value.absent(),
    Value<int?> dueDateMillis = const Value.absent(),
    String? state,
    Value<String?> submissionState = const Value.absent(),
    Value<String?> submissionId = const Value.absent(),
    Value<String?> materialsJson = const Value.absent(),
    Value<String?> submissionAttachmentsJson = const Value.absent(),
  }) => AssignmentRow(
    id: id ?? this.id,
    courseId: courseId ?? this.courseId,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    dueDateMillis: dueDateMillis.present
        ? dueDateMillis.value
        : this.dueDateMillis,
    state: state ?? this.state,
    submissionState: submissionState.present
        ? submissionState.value
        : this.submissionState,
    submissionId: submissionId.present ? submissionId.value : this.submissionId,
    materialsJson: materialsJson.present
        ? materialsJson.value
        : this.materialsJson,
    submissionAttachmentsJson: submissionAttachmentsJson.present
        ? submissionAttachmentsJson.value
        : this.submissionAttachmentsJson,
  );
  AssignmentRow copyWithCompanion(AssignmentsCompanion data) {
    return AssignmentRow(
      id: data.id.present ? data.id.value : this.id,
      courseId: data.courseId.present ? data.courseId.value : this.courseId,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      dueDateMillis: data.dueDateMillis.present
          ? data.dueDateMillis.value
          : this.dueDateMillis,
      state: data.state.present ? data.state.value : this.state,
      submissionState: data.submissionState.present
          ? data.submissionState.value
          : this.submissionState,
      submissionId: data.submissionId.present
          ? data.submissionId.value
          : this.submissionId,
      materialsJson: data.materialsJson.present
          ? data.materialsJson.value
          : this.materialsJson,
      submissionAttachmentsJson: data.submissionAttachmentsJson.present
          ? data.submissionAttachmentsJson.value
          : this.submissionAttachmentsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AssignmentRow(')
          ..write('id: $id, ')
          ..write('courseId: $courseId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('dueDateMillis: $dueDateMillis, ')
          ..write('state: $state, ')
          ..write('submissionState: $submissionState, ')
          ..write('submissionId: $submissionId, ')
          ..write('materialsJson: $materialsJson, ')
          ..write('submissionAttachmentsJson: $submissionAttachmentsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    courseId,
    title,
    description,
    dueDateMillis,
    state,
    submissionState,
    submissionId,
    materialsJson,
    submissionAttachmentsJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AssignmentRow &&
          other.id == this.id &&
          other.courseId == this.courseId &&
          other.title == this.title &&
          other.description == this.description &&
          other.dueDateMillis == this.dueDateMillis &&
          other.state == this.state &&
          other.submissionState == this.submissionState &&
          other.submissionId == this.submissionId &&
          other.materialsJson == this.materialsJson &&
          other.submissionAttachmentsJson == this.submissionAttachmentsJson);
}

class AssignmentsCompanion extends UpdateCompanion<AssignmentRow> {
  final Value<String> id;
  final Value<String> courseId;
  final Value<String> title;
  final Value<String?> description;
  final Value<int?> dueDateMillis;
  final Value<String> state;
  final Value<String?> submissionState;
  final Value<String?> submissionId;
  final Value<String?> materialsJson;
  final Value<String?> submissionAttachmentsJson;
  final Value<int> rowid;
  const AssignmentsCompanion({
    this.id = const Value.absent(),
    this.courseId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.dueDateMillis = const Value.absent(),
    this.state = const Value.absent(),
    this.submissionState = const Value.absent(),
    this.submissionId = const Value.absent(),
    this.materialsJson = const Value.absent(),
    this.submissionAttachmentsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AssignmentsCompanion.insert({
    required String id,
    required String courseId,
    required String title,
    this.description = const Value.absent(),
    this.dueDateMillis = const Value.absent(),
    this.state = const Value.absent(),
    this.submissionState = const Value.absent(),
    this.submissionId = const Value.absent(),
    this.materialsJson = const Value.absent(),
    this.submissionAttachmentsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       courseId = Value(courseId),
       title = Value(title);
  static Insertable<AssignmentRow> custom({
    Expression<String>? id,
    Expression<String>? courseId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<int>? dueDateMillis,
    Expression<String>? state,
    Expression<String>? submissionState,
    Expression<String>? submissionId,
    Expression<String>? materialsJson,
    Expression<String>? submissionAttachmentsJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (courseId != null) 'course_id': courseId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (dueDateMillis != null) 'due_date_millis': dueDateMillis,
      if (state != null) 'state': state,
      if (submissionState != null) 'submission_state': submissionState,
      if (submissionId != null) 'submission_id': submissionId,
      if (materialsJson != null) 'materials_json': materialsJson,
      if (submissionAttachmentsJson != null)
        'submission_attachments_json': submissionAttachmentsJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AssignmentsCompanion copyWith({
    Value<String>? id,
    Value<String>? courseId,
    Value<String>? title,
    Value<String?>? description,
    Value<int?>? dueDateMillis,
    Value<String>? state,
    Value<String?>? submissionState,
    Value<String?>? submissionId,
    Value<String?>? materialsJson,
    Value<String?>? submissionAttachmentsJson,
    Value<int>? rowid,
  }) {
    return AssignmentsCompanion(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDateMillis: dueDateMillis ?? this.dueDateMillis,
      state: state ?? this.state,
      submissionState: submissionState ?? this.submissionState,
      submissionId: submissionId ?? this.submissionId,
      materialsJson: materialsJson ?? this.materialsJson,
      submissionAttachmentsJson:
          submissionAttachmentsJson ?? this.submissionAttachmentsJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (courseId.present) {
      map['course_id'] = Variable<String>(courseId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (dueDateMillis.present) {
      map['due_date_millis'] = Variable<int>(dueDateMillis.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (submissionState.present) {
      map['submission_state'] = Variable<String>(submissionState.value);
    }
    if (submissionId.present) {
      map['submission_id'] = Variable<String>(submissionId.value);
    }
    if (materialsJson.present) {
      map['materials_json'] = Variable<String>(materialsJson.value);
    }
    if (submissionAttachmentsJson.present) {
      map['submission_attachments_json'] = Variable<String>(
        submissionAttachmentsJson.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AssignmentsCompanion(')
          ..write('id: $id, ')
          ..write('courseId: $courseId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('dueDateMillis: $dueDateMillis, ')
          ..write('state: $state, ')
          ..write('submissionState: $submissionState, ')
          ..write('submissionId: $submissionId, ')
          ..write('materialsJson: $materialsJson, ')
          ..write('submissionAttachmentsJson: $submissionAttachmentsJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AnnouncementsTable extends Announcements
    with TableInfo<$AnnouncementsTable, AnnouncementRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnnouncementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _courseIdMeta = const VerificationMeta(
    'courseId',
  );
  @override
  late final GeneratedColumn<String> courseId = GeneratedColumn<String>(
    'course_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _creationTimeMillisMeta =
      const VerificationMeta('creationTimeMillis');
  @override
  late final GeneratedColumn<int> creationTimeMillis = GeneratedColumn<int>(
    'creation_time_millis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updateTimeMillisMeta = const VerificationMeta(
    'updateTimeMillis',
  );
  @override
  late final GeneratedColumn<int> updateTimeMillis = GeneratedColumn<int>(
    'update_time_millis',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isMaterialMeta = const VerificationMeta(
    'isMaterial',
  );
  @override
  late final GeneratedColumn<bool> isMaterial = GeneratedColumn<bool>(
    'is_material',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_material" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _materialsJsonMeta = const VerificationMeta(
    'materialsJson',
  );
  @override
  late final GeneratedColumn<String> materialsJson = GeneratedColumn<String>(
    'materials_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    courseId,
    body,
    creationTimeMillis,
    updateTimeMillis,
    title,
    isMaterial,
    materialsJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'announcements';
  @override
  VerificationContext validateIntegrity(
    Insertable<AnnouncementRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('course_id')) {
      context.handle(
        _courseIdMeta,
        courseId.isAcceptableOrUnknown(data['course_id']!, _courseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_courseIdMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('creation_time_millis')) {
      context.handle(
        _creationTimeMillisMeta,
        creationTimeMillis.isAcceptableOrUnknown(
          data['creation_time_millis']!,
          _creationTimeMillisMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_creationTimeMillisMeta);
    }
    if (data.containsKey('update_time_millis')) {
      context.handle(
        _updateTimeMillisMeta,
        updateTimeMillis.isAcceptableOrUnknown(
          data['update_time_millis']!,
          _updateTimeMillisMeta,
        ),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('is_material')) {
      context.handle(
        _isMaterialMeta,
        isMaterial.isAcceptableOrUnknown(data['is_material']!, _isMaterialMeta),
      );
    }
    if (data.containsKey('materials_json')) {
      context.handle(
        _materialsJsonMeta,
        materialsJson.isAcceptableOrUnknown(
          data['materials_json']!,
          _materialsJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AnnouncementRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AnnouncementRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      courseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}course_id'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      creationTimeMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}creation_time_millis'],
      )!,
      updateTimeMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}update_time_millis'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      isMaterial: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_material'],
      )!,
      materialsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}materials_json'],
      ),
    );
  }

  @override
  $AnnouncementsTable createAlias(String alias) {
    return $AnnouncementsTable(attachedDatabase, alias);
  }
}

class AnnouncementRow extends DataClass implements Insertable<AnnouncementRow> {
  final String id;
  final String courseId;
  final String body;
  final int creationTimeMillis;
  final int? updateTimeMillis;
  final String? title;
  final bool isMaterial;
  final String? materialsJson;
  const AnnouncementRow({
    required this.id,
    required this.courseId,
    required this.body,
    required this.creationTimeMillis,
    this.updateTimeMillis,
    this.title,
    required this.isMaterial,
    this.materialsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['course_id'] = Variable<String>(courseId);
    map['body'] = Variable<String>(body);
    map['creation_time_millis'] = Variable<int>(creationTimeMillis);
    if (!nullToAbsent || updateTimeMillis != null) {
      map['update_time_millis'] = Variable<int>(updateTimeMillis);
    }
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    map['is_material'] = Variable<bool>(isMaterial);
    if (!nullToAbsent || materialsJson != null) {
      map['materials_json'] = Variable<String>(materialsJson);
    }
    return map;
  }

  AnnouncementsCompanion toCompanion(bool nullToAbsent) {
    return AnnouncementsCompanion(
      id: Value(id),
      courseId: Value(courseId),
      body: Value(body),
      creationTimeMillis: Value(creationTimeMillis),
      updateTimeMillis: updateTimeMillis == null && nullToAbsent
          ? const Value.absent()
          : Value(updateTimeMillis),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      isMaterial: Value(isMaterial),
      materialsJson: materialsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(materialsJson),
    );
  }

  factory AnnouncementRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AnnouncementRow(
      id: serializer.fromJson<String>(json['id']),
      courseId: serializer.fromJson<String>(json['courseId']),
      body: serializer.fromJson<String>(json['body']),
      creationTimeMillis: serializer.fromJson<int>(json['creationTimeMillis']),
      updateTimeMillis: serializer.fromJson<int?>(json['updateTimeMillis']),
      title: serializer.fromJson<String?>(json['title']),
      isMaterial: serializer.fromJson<bool>(json['isMaterial']),
      materialsJson: serializer.fromJson<String?>(json['materialsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'courseId': serializer.toJson<String>(courseId),
      'body': serializer.toJson<String>(body),
      'creationTimeMillis': serializer.toJson<int>(creationTimeMillis),
      'updateTimeMillis': serializer.toJson<int?>(updateTimeMillis),
      'title': serializer.toJson<String?>(title),
      'isMaterial': serializer.toJson<bool>(isMaterial),
      'materialsJson': serializer.toJson<String?>(materialsJson),
    };
  }

  AnnouncementRow copyWith({
    String? id,
    String? courseId,
    String? body,
    int? creationTimeMillis,
    Value<int?> updateTimeMillis = const Value.absent(),
    Value<String?> title = const Value.absent(),
    bool? isMaterial,
    Value<String?> materialsJson = const Value.absent(),
  }) => AnnouncementRow(
    id: id ?? this.id,
    courseId: courseId ?? this.courseId,
    body: body ?? this.body,
    creationTimeMillis: creationTimeMillis ?? this.creationTimeMillis,
    updateTimeMillis: updateTimeMillis.present
        ? updateTimeMillis.value
        : this.updateTimeMillis,
    title: title.present ? title.value : this.title,
    isMaterial: isMaterial ?? this.isMaterial,
    materialsJson: materialsJson.present
        ? materialsJson.value
        : this.materialsJson,
  );
  AnnouncementRow copyWithCompanion(AnnouncementsCompanion data) {
    return AnnouncementRow(
      id: data.id.present ? data.id.value : this.id,
      courseId: data.courseId.present ? data.courseId.value : this.courseId,
      body: data.body.present ? data.body.value : this.body,
      creationTimeMillis: data.creationTimeMillis.present
          ? data.creationTimeMillis.value
          : this.creationTimeMillis,
      updateTimeMillis: data.updateTimeMillis.present
          ? data.updateTimeMillis.value
          : this.updateTimeMillis,
      title: data.title.present ? data.title.value : this.title,
      isMaterial: data.isMaterial.present
          ? data.isMaterial.value
          : this.isMaterial,
      materialsJson: data.materialsJson.present
          ? data.materialsJson.value
          : this.materialsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AnnouncementRow(')
          ..write('id: $id, ')
          ..write('courseId: $courseId, ')
          ..write('body: $body, ')
          ..write('creationTimeMillis: $creationTimeMillis, ')
          ..write('updateTimeMillis: $updateTimeMillis, ')
          ..write('title: $title, ')
          ..write('isMaterial: $isMaterial, ')
          ..write('materialsJson: $materialsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    courseId,
    body,
    creationTimeMillis,
    updateTimeMillis,
    title,
    isMaterial,
    materialsJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnnouncementRow &&
          other.id == this.id &&
          other.courseId == this.courseId &&
          other.body == this.body &&
          other.creationTimeMillis == this.creationTimeMillis &&
          other.updateTimeMillis == this.updateTimeMillis &&
          other.title == this.title &&
          other.isMaterial == this.isMaterial &&
          other.materialsJson == this.materialsJson);
}

class AnnouncementsCompanion extends UpdateCompanion<AnnouncementRow> {
  final Value<String> id;
  final Value<String> courseId;
  final Value<String> body;
  final Value<int> creationTimeMillis;
  final Value<int?> updateTimeMillis;
  final Value<String?> title;
  final Value<bool> isMaterial;
  final Value<String?> materialsJson;
  final Value<int> rowid;
  const AnnouncementsCompanion({
    this.id = const Value.absent(),
    this.courseId = const Value.absent(),
    this.body = const Value.absent(),
    this.creationTimeMillis = const Value.absent(),
    this.updateTimeMillis = const Value.absent(),
    this.title = const Value.absent(),
    this.isMaterial = const Value.absent(),
    this.materialsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AnnouncementsCompanion.insert({
    required String id,
    required String courseId,
    required String body,
    required int creationTimeMillis,
    this.updateTimeMillis = const Value.absent(),
    this.title = const Value.absent(),
    this.isMaterial = const Value.absent(),
    this.materialsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       courseId = Value(courseId),
       body = Value(body),
       creationTimeMillis = Value(creationTimeMillis);
  static Insertable<AnnouncementRow> custom({
    Expression<String>? id,
    Expression<String>? courseId,
    Expression<String>? body,
    Expression<int>? creationTimeMillis,
    Expression<int>? updateTimeMillis,
    Expression<String>? title,
    Expression<bool>? isMaterial,
    Expression<String>? materialsJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (courseId != null) 'course_id': courseId,
      if (body != null) 'body': body,
      if (creationTimeMillis != null)
        'creation_time_millis': creationTimeMillis,
      if (updateTimeMillis != null) 'update_time_millis': updateTimeMillis,
      if (title != null) 'title': title,
      if (isMaterial != null) 'is_material': isMaterial,
      if (materialsJson != null) 'materials_json': materialsJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AnnouncementsCompanion copyWith({
    Value<String>? id,
    Value<String>? courseId,
    Value<String>? body,
    Value<int>? creationTimeMillis,
    Value<int?>? updateTimeMillis,
    Value<String?>? title,
    Value<bool>? isMaterial,
    Value<String?>? materialsJson,
    Value<int>? rowid,
  }) {
    return AnnouncementsCompanion(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      body: body ?? this.body,
      creationTimeMillis: creationTimeMillis ?? this.creationTimeMillis,
      updateTimeMillis: updateTimeMillis ?? this.updateTimeMillis,
      title: title ?? this.title,
      isMaterial: isMaterial ?? this.isMaterial,
      materialsJson: materialsJson ?? this.materialsJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (courseId.present) {
      map['course_id'] = Variable<String>(courseId.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (creationTimeMillis.present) {
      map['creation_time_millis'] = Variable<int>(creationTimeMillis.value);
    }
    if (updateTimeMillis.present) {
      map['update_time_millis'] = Variable<int>(updateTimeMillis.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (isMaterial.present) {
      map['is_material'] = Variable<bool>(isMaterial.value);
    }
    if (materialsJson.present) {
      map['materials_json'] = Variable<String>(materialsJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnnouncementsCompanion(')
          ..write('id: $id, ')
          ..write('courseId: $courseId, ')
          ..write('body: $body, ')
          ..write('creationTimeMillis: $creationTimeMillis, ')
          ..write('updateTimeMillis: $updateTimeMillis, ')
          ..write('title: $title, ')
          ..write('isMaterial: $isMaterial, ')
          ..write('materialsJson: $materialsJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CourseOrdersTable extends CourseOrders
    with TableInfo<$CourseOrdersTable, CourseOrderRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CourseOrdersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _courseIdMeta = const VerificationMeta(
    'courseId',
  );
  @override
  late final GeneratedColumn<String> courseId = GeneratedColumn<String>(
    'course_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortIndexMeta = const VerificationMeta(
    'sortIndex',
  );
  @override
  late final GeneratedColumn<int> sortIndex = GeneratedColumn<int>(
    'sort_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [courseId, sortIndex];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'course_orders';
  @override
  VerificationContext validateIntegrity(
    Insertable<CourseOrderRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('course_id')) {
      context.handle(
        _courseIdMeta,
        courseId.isAcceptableOrUnknown(data['course_id']!, _courseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_courseIdMeta);
    }
    if (data.containsKey('sort_index')) {
      context.handle(
        _sortIndexMeta,
        sortIndex.isAcceptableOrUnknown(data['sort_index']!, _sortIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_sortIndexMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {courseId};
  @override
  CourseOrderRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CourseOrderRow(
      courseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}course_id'],
      )!,
      sortIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_index'],
      )!,
    );
  }

  @override
  $CourseOrdersTable createAlias(String alias) {
    return $CourseOrdersTable(attachedDatabase, alias);
  }
}

class CourseOrderRow extends DataClass implements Insertable<CourseOrderRow> {
  final String courseId;
  final int sortIndex;
  const CourseOrderRow({required this.courseId, required this.sortIndex});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['course_id'] = Variable<String>(courseId);
    map['sort_index'] = Variable<int>(sortIndex);
    return map;
  }

  CourseOrdersCompanion toCompanion(bool nullToAbsent) {
    return CourseOrdersCompanion(
      courseId: Value(courseId),
      sortIndex: Value(sortIndex),
    );
  }

  factory CourseOrderRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CourseOrderRow(
      courseId: serializer.fromJson<String>(json['courseId']),
      sortIndex: serializer.fromJson<int>(json['sortIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'courseId': serializer.toJson<String>(courseId),
      'sortIndex': serializer.toJson<int>(sortIndex),
    };
  }

  CourseOrderRow copyWith({String? courseId, int? sortIndex}) => CourseOrderRow(
    courseId: courseId ?? this.courseId,
    sortIndex: sortIndex ?? this.sortIndex,
  );
  CourseOrderRow copyWithCompanion(CourseOrdersCompanion data) {
    return CourseOrderRow(
      courseId: data.courseId.present ? data.courseId.value : this.courseId,
      sortIndex: data.sortIndex.present ? data.sortIndex.value : this.sortIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CourseOrderRow(')
          ..write('courseId: $courseId, ')
          ..write('sortIndex: $sortIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(courseId, sortIndex);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CourseOrderRow &&
          other.courseId == this.courseId &&
          other.sortIndex == this.sortIndex);
}

class CourseOrdersCompanion extends UpdateCompanion<CourseOrderRow> {
  final Value<String> courseId;
  final Value<int> sortIndex;
  final Value<int> rowid;
  const CourseOrdersCompanion({
    this.courseId = const Value.absent(),
    this.sortIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CourseOrdersCompanion.insert({
    required String courseId,
    required int sortIndex,
    this.rowid = const Value.absent(),
  }) : courseId = Value(courseId),
       sortIndex = Value(sortIndex);
  static Insertable<CourseOrderRow> custom({
    Expression<String>? courseId,
    Expression<int>? sortIndex,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (courseId != null) 'course_id': courseId,
      if (sortIndex != null) 'sort_index': sortIndex,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CourseOrdersCompanion copyWith({
    Value<String>? courseId,
    Value<int>? sortIndex,
    Value<int>? rowid,
  }) {
    return CourseOrdersCompanion(
      courseId: courseId ?? this.courseId,
      sortIndex: sortIndex ?? this.sortIndex,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (courseId.present) {
      map['course_id'] = Variable<String>(courseId.value);
    }
    if (sortIndex.present) {
      map['sort_index'] = Variable<int>(sortIndex.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CourseOrdersCompanion(')
          ..write('courseId: $courseId, ')
          ..write('sortIndex: $sortIndex, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncStatesTable extends SyncStates
    with TableInfo<$SyncStatesTable, SyncStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SyncStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStateRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SyncStatesTable createAlias(String alias) {
    return $SyncStatesTable(attachedDatabase, alias);
  }
}

class SyncStateRow extends DataClass implements Insertable<SyncStateRow> {
  final String key;
  final String value;
  const SyncStateRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SyncStatesCompanion toCompanion(bool nullToAbsent) {
    return SyncStatesCompanion(key: Value(key), value: Value(value));
  }

  factory SyncStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStateRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SyncStateRow copyWith({String? key, String? value}) =>
      SyncStateRow(key: key ?? this.key, value: value ?? this.value);
  SyncStateRow copyWithCompanion(SyncStatesCompanion data) {
    return SyncStateRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStateRow &&
          other.key == this.key &&
          other.value == this.value);
}

class SyncStatesCompanion extends UpdateCompanion<SyncStateRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SyncStatesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStatesCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SyncStateRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncStatesCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SyncStatesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStatesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HiddenItemsTable extends HiddenItems
    with TableInfo<$HiddenItemsTable, HiddenItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HiddenItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hiddenAtMeta = const VerificationMeta(
    'hiddenAt',
  );
  @override
  late final GeneratedColumn<DateTime> hiddenAt = GeneratedColumn<DateTime>(
    'hidden_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [itemId, type, hiddenAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hidden_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<HiddenItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('hidden_at')) {
      context.handle(
        _hiddenAtMeta,
        hiddenAt.isAcceptableOrUnknown(data['hidden_at']!, _hiddenAtMeta),
      );
    } else if (isInserting) {
      context.missing(_hiddenAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {itemId};
  @override
  HiddenItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HiddenItemRow(
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      hiddenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}hidden_at'],
      )!,
    );
  }

  @override
  $HiddenItemsTable createAlias(String alias) {
    return $HiddenItemsTable(attachedDatabase, alias);
  }
}

class HiddenItemRow extends DataClass implements Insertable<HiddenItemRow> {
  final String itemId;
  final String type;
  final DateTime hiddenAt;
  const HiddenItemRow({
    required this.itemId,
    required this.type,
    required this.hiddenAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['item_id'] = Variable<String>(itemId);
    map['type'] = Variable<String>(type);
    map['hidden_at'] = Variable<DateTime>(hiddenAt);
    return map;
  }

  HiddenItemsCompanion toCompanion(bool nullToAbsent) {
    return HiddenItemsCompanion(
      itemId: Value(itemId),
      type: Value(type),
      hiddenAt: Value(hiddenAt),
    );
  }

  factory HiddenItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HiddenItemRow(
      itemId: serializer.fromJson<String>(json['itemId']),
      type: serializer.fromJson<String>(json['type']),
      hiddenAt: serializer.fromJson<DateTime>(json['hiddenAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'itemId': serializer.toJson<String>(itemId),
      'type': serializer.toJson<String>(type),
      'hiddenAt': serializer.toJson<DateTime>(hiddenAt),
    };
  }

  HiddenItemRow copyWith({String? itemId, String? type, DateTime? hiddenAt}) =>
      HiddenItemRow(
        itemId: itemId ?? this.itemId,
        type: type ?? this.type,
        hiddenAt: hiddenAt ?? this.hiddenAt,
      );
  HiddenItemRow copyWithCompanion(HiddenItemsCompanion data) {
    return HiddenItemRow(
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      type: data.type.present ? data.type.value : this.type,
      hiddenAt: data.hiddenAt.present ? data.hiddenAt.value : this.hiddenAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HiddenItemRow(')
          ..write('itemId: $itemId, ')
          ..write('type: $type, ')
          ..write('hiddenAt: $hiddenAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(itemId, type, hiddenAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HiddenItemRow &&
          other.itemId == this.itemId &&
          other.type == this.type &&
          other.hiddenAt == this.hiddenAt);
}

class HiddenItemsCompanion extends UpdateCompanion<HiddenItemRow> {
  final Value<String> itemId;
  final Value<String> type;
  final Value<DateTime> hiddenAt;
  final Value<int> rowid;
  const HiddenItemsCompanion({
    this.itemId = const Value.absent(),
    this.type = const Value.absent(),
    this.hiddenAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HiddenItemsCompanion.insert({
    required String itemId,
    required String type,
    required DateTime hiddenAt,
    this.rowid = const Value.absent(),
  }) : itemId = Value(itemId),
       type = Value(type),
       hiddenAt = Value(hiddenAt);
  static Insertable<HiddenItemRow> custom({
    Expression<String>? itemId,
    Expression<String>? type,
    Expression<DateTime>? hiddenAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (itemId != null) 'item_id': itemId,
      if (type != null) 'type': type,
      if (hiddenAt != null) 'hidden_at': hiddenAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HiddenItemsCompanion copyWith({
    Value<String>? itemId,
    Value<String>? type,
    Value<DateTime>? hiddenAt,
    Value<int>? rowid,
  }) {
    return HiddenItemsCompanion(
      itemId: itemId ?? this.itemId,
      type: type ?? this.type,
      hiddenAt: hiddenAt ?? this.hiddenAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (hiddenAt.present) {
      map['hidden_at'] = Variable<DateTime>(hiddenAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HiddenItemsCompanion(')
          ..write('itemId: $itemId, ')
          ..write('type: $type, ')
          ..write('hiddenAt: $hiddenAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserPreferencesTable extends UserPreferences
    with TableInfo<$UserPreferencesTable, UserPreferenceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserPreferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserPreferenceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  UserPreferenceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserPreferenceRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $UserPreferencesTable createAlias(String alias) {
    return $UserPreferencesTable(attachedDatabase, alias);
  }
}

class UserPreferenceRow extends DataClass
    implements Insertable<UserPreferenceRow> {
  final String key;
  final String value;
  const UserPreferenceRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  UserPreferencesCompanion toCompanion(bool nullToAbsent) {
    return UserPreferencesCompanion(key: Value(key), value: Value(value));
  }

  factory UserPreferenceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserPreferenceRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  UserPreferenceRow copyWith({String? key, String? value}) =>
      UserPreferenceRow(key: key ?? this.key, value: value ?? this.value);
  UserPreferenceRow copyWithCompanion(UserPreferencesCompanion data) {
    return UserPreferenceRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserPreferenceRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserPreferenceRow &&
          other.key == this.key &&
          other.value == this.value);
}

class UserPreferencesCompanion extends UpdateCompanion<UserPreferenceRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const UserPreferencesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserPreferencesCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<UserPreferenceRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserPreferencesCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return UserPreferencesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserPreferencesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotificationLogsTable extends NotificationLogs
    with TableInfo<$NotificationLogsTable, NotificationLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotificationLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _assignmentIdMeta = const VerificationMeta(
    'assignmentId',
  );
  @override
  late final GeneratedColumn<String> assignmentId = GeneratedColumn<String>(
    'assignment_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notifiedAtMeta = const VerificationMeta(
    'notifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> notifiedAt = GeneratedColumn<DateTime>(
    'notified_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [assignmentId, notifiedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notification_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<NotificationLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('assignment_id')) {
      context.handle(
        _assignmentIdMeta,
        assignmentId.isAcceptableOrUnknown(
          data['assignment_id']!,
          _assignmentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_assignmentIdMeta);
    }
    if (data.containsKey('notified_at')) {
      context.handle(
        _notifiedAtMeta,
        notifiedAt.isAcceptableOrUnknown(data['notified_at']!, _notifiedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_notifiedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {assignmentId};
  @override
  NotificationLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotificationLogRow(
      assignmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}assignment_id'],
      )!,
      notifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}notified_at'],
      )!,
    );
  }

  @override
  $NotificationLogsTable createAlias(String alias) {
    return $NotificationLogsTable(attachedDatabase, alias);
  }
}

class NotificationLogRow extends DataClass
    implements Insertable<NotificationLogRow> {
  final String assignmentId;
  final DateTime notifiedAt;
  const NotificationLogRow({
    required this.assignmentId,
    required this.notifiedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['assignment_id'] = Variable<String>(assignmentId);
    map['notified_at'] = Variable<DateTime>(notifiedAt);
    return map;
  }

  NotificationLogsCompanion toCompanion(bool nullToAbsent) {
    return NotificationLogsCompanion(
      assignmentId: Value(assignmentId),
      notifiedAt: Value(notifiedAt),
    );
  }

  factory NotificationLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotificationLogRow(
      assignmentId: serializer.fromJson<String>(json['assignmentId']),
      notifiedAt: serializer.fromJson<DateTime>(json['notifiedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'assignmentId': serializer.toJson<String>(assignmentId),
      'notifiedAt': serializer.toJson<DateTime>(notifiedAt),
    };
  }

  NotificationLogRow copyWith({String? assignmentId, DateTime? notifiedAt}) =>
      NotificationLogRow(
        assignmentId: assignmentId ?? this.assignmentId,
        notifiedAt: notifiedAt ?? this.notifiedAt,
      );
  NotificationLogRow copyWithCompanion(NotificationLogsCompanion data) {
    return NotificationLogRow(
      assignmentId: data.assignmentId.present
          ? data.assignmentId.value
          : this.assignmentId,
      notifiedAt: data.notifiedAt.present
          ? data.notifiedAt.value
          : this.notifiedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotificationLogRow(')
          ..write('assignmentId: $assignmentId, ')
          ..write('notifiedAt: $notifiedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(assignmentId, notifiedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotificationLogRow &&
          other.assignmentId == this.assignmentId &&
          other.notifiedAt == this.notifiedAt);
}

class NotificationLogsCompanion extends UpdateCompanion<NotificationLogRow> {
  final Value<String> assignmentId;
  final Value<DateTime> notifiedAt;
  final Value<int> rowid;
  const NotificationLogsCompanion({
    this.assignmentId = const Value.absent(),
    this.notifiedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotificationLogsCompanion.insert({
    required String assignmentId,
    required DateTime notifiedAt,
    this.rowid = const Value.absent(),
  }) : assignmentId = Value(assignmentId),
       notifiedAt = Value(notifiedAt);
  static Insertable<NotificationLogRow> custom({
    Expression<String>? assignmentId,
    Expression<DateTime>? notifiedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (assignmentId != null) 'assignment_id': assignmentId,
      if (notifiedAt != null) 'notified_at': notifiedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotificationLogsCompanion copyWith({
    Value<String>? assignmentId,
    Value<DateTime>? notifiedAt,
    Value<int>? rowid,
  }) {
    return NotificationLogsCompanion(
      assignmentId: assignmentId ?? this.assignmentId,
      notifiedAt: notifiedAt ?? this.notifiedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (assignmentId.present) {
      map['assignment_id'] = Variable<String>(assignmentId.value);
    }
    if (notifiedAt.present) {
      map['notified_at'] = Variable<DateTime>(notifiedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotificationLogsCompanion(')
          ..write('assignmentId: $assignmentId, ')
          ..write('notifiedAt: $notifiedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SnoozedItemsTable extends SnoozedItems
    with TableInfo<$SnoozedItemsTable, SnoozedItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SnoozedItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _assignmentIdMeta = const VerificationMeta(
    'assignmentId',
  );
  @override
  late final GeneratedColumn<String> assignmentId = GeneratedColumn<String>(
    'assignment_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _snoozedUntilMeta = const VerificationMeta(
    'snoozedUntil',
  );
  @override
  late final GeneratedColumn<DateTime> snoozedUntil = GeneratedColumn<DateTime>(
    'snoozed_until',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [assignmentId, snoozedUntil];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'snoozed_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<SnoozedItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('assignment_id')) {
      context.handle(
        _assignmentIdMeta,
        assignmentId.isAcceptableOrUnknown(
          data['assignment_id']!,
          _assignmentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_assignmentIdMeta);
    }
    if (data.containsKey('snoozed_until')) {
      context.handle(
        _snoozedUntilMeta,
        snoozedUntil.isAcceptableOrUnknown(
          data['snoozed_until']!,
          _snoozedUntilMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_snoozedUntilMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {assignmentId};
  @override
  SnoozedItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SnoozedItemRow(
      assignmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}assignment_id'],
      )!,
      snoozedUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}snoozed_until'],
      )!,
    );
  }

  @override
  $SnoozedItemsTable createAlias(String alias) {
    return $SnoozedItemsTable(attachedDatabase, alias);
  }
}

class SnoozedItemRow extends DataClass implements Insertable<SnoozedItemRow> {
  final String assignmentId;
  final DateTime snoozedUntil;
  const SnoozedItemRow({
    required this.assignmentId,
    required this.snoozedUntil,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['assignment_id'] = Variable<String>(assignmentId);
    map['snoozed_until'] = Variable<DateTime>(snoozedUntil);
    return map;
  }

  SnoozedItemsCompanion toCompanion(bool nullToAbsent) {
    return SnoozedItemsCompanion(
      assignmentId: Value(assignmentId),
      snoozedUntil: Value(snoozedUntil),
    );
  }

  factory SnoozedItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SnoozedItemRow(
      assignmentId: serializer.fromJson<String>(json['assignmentId']),
      snoozedUntil: serializer.fromJson<DateTime>(json['snoozedUntil']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'assignmentId': serializer.toJson<String>(assignmentId),
      'snoozedUntil': serializer.toJson<DateTime>(snoozedUntil),
    };
  }

  SnoozedItemRow copyWith({String? assignmentId, DateTime? snoozedUntil}) =>
      SnoozedItemRow(
        assignmentId: assignmentId ?? this.assignmentId,
        snoozedUntil: snoozedUntil ?? this.snoozedUntil,
      );
  SnoozedItemRow copyWithCompanion(SnoozedItemsCompanion data) {
    return SnoozedItemRow(
      assignmentId: data.assignmentId.present
          ? data.assignmentId.value
          : this.assignmentId,
      snoozedUntil: data.snoozedUntil.present
          ? data.snoozedUntil.value
          : this.snoozedUntil,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SnoozedItemRow(')
          ..write('assignmentId: $assignmentId, ')
          ..write('snoozedUntil: $snoozedUntil')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(assignmentId, snoozedUntil);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SnoozedItemRow &&
          other.assignmentId == this.assignmentId &&
          other.snoozedUntil == this.snoozedUntil);
}

class SnoozedItemsCompanion extends UpdateCompanion<SnoozedItemRow> {
  final Value<String> assignmentId;
  final Value<DateTime> snoozedUntil;
  final Value<int> rowid;
  const SnoozedItemsCompanion({
    this.assignmentId = const Value.absent(),
    this.snoozedUntil = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SnoozedItemsCompanion.insert({
    required String assignmentId,
    required DateTime snoozedUntil,
    this.rowid = const Value.absent(),
  }) : assignmentId = Value(assignmentId),
       snoozedUntil = Value(snoozedUntil);
  static Insertable<SnoozedItemRow> custom({
    Expression<String>? assignmentId,
    Expression<DateTime>? snoozedUntil,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (assignmentId != null) 'assignment_id': assignmentId,
      if (snoozedUntil != null) 'snoozed_until': snoozedUntil,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SnoozedItemsCompanion copyWith({
    Value<String>? assignmentId,
    Value<DateTime>? snoozedUntil,
    Value<int>? rowid,
  }) {
    return SnoozedItemsCompanion(
      assignmentId: assignmentId ?? this.assignmentId,
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (assignmentId.present) {
      map['assignment_id'] = Variable<String>(assignmentId.value);
    }
    if (snoozedUntil.present) {
      map['snoozed_until'] = Variable<DateTime>(snoozedUntil.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SnoozedItemsCompanion(')
          ..write('assignmentId: $assignmentId, ')
          ..write('snoozedUntil: $snoozedUntil, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CoursesTable courses = $CoursesTable(this);
  late final $AssignmentsTable assignments = $AssignmentsTable(this);
  late final $AnnouncementsTable announcements = $AnnouncementsTable(this);
  late final $CourseOrdersTable courseOrders = $CourseOrdersTable(this);
  late final $SyncStatesTable syncStates = $SyncStatesTable(this);
  late final $HiddenItemsTable hiddenItems = $HiddenItemsTable(this);
  late final $UserPreferencesTable userPreferences = $UserPreferencesTable(
    this,
  );
  late final $NotificationLogsTable notificationLogs = $NotificationLogsTable(
    this,
  );
  late final $SnoozedItemsTable snoozedItems = $SnoozedItemsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    courses,
    assignments,
    announcements,
    courseOrders,
    syncStates,
    hiddenItems,
    userPreferences,
    notificationLogs,
    snoozedItems,
  ];
}

typedef $$CoursesTableCreateCompanionBuilder =
    CoursesCompanion Function({
      required String id,
      required String name,
      Value<String?> description,
      Value<String?> section,
      Value<String?> room,
      Value<String?> ownerId,
      Value<String> courseState,
      Value<String> role,
      Value<int> rowid,
    });
typedef $$CoursesTableUpdateCompanionBuilder =
    CoursesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> description,
      Value<String?> section,
      Value<String?> room,
      Value<String?> ownerId,
      Value<String> courseState,
      Value<String> role,
      Value<int> rowid,
    });

class $$CoursesTableFilterComposer
    extends Composer<_$AppDatabase, $CoursesTable> {
  $$CoursesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get section => $composableBuilder(
    column: $table.section,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get room => $composableBuilder(
    column: $table.room,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get courseState => $composableBuilder(
    column: $table.courseState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CoursesTableOrderingComposer
    extends Composer<_$AppDatabase, $CoursesTable> {
  $$CoursesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get section => $composableBuilder(
    column: $table.section,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get room => $composableBuilder(
    column: $table.room,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get courseState => $composableBuilder(
    column: $table.courseState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CoursesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CoursesTable> {
  $$CoursesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get section =>
      $composableBuilder(column: $table.section, builder: (column) => column);

  GeneratedColumn<String> get room =>
      $composableBuilder(column: $table.room, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get courseState => $composableBuilder(
    column: $table.courseState,
    builder: (column) => column,
  );

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);
}

class $$CoursesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CoursesTable,
          CourseRow,
          $$CoursesTableFilterComposer,
          $$CoursesTableOrderingComposer,
          $$CoursesTableAnnotationComposer,
          $$CoursesTableCreateCompanionBuilder,
          $$CoursesTableUpdateCompanionBuilder,
          (CourseRow, BaseReferences<_$AppDatabase, $CoursesTable, CourseRow>),
          CourseRow,
          PrefetchHooks Function()
        > {
  $$CoursesTableTableManager(_$AppDatabase db, $CoursesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CoursesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CoursesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CoursesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> section = const Value.absent(),
                Value<String?> room = const Value.absent(),
                Value<String?> ownerId = const Value.absent(),
                Value<String> courseState = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CoursesCompanion(
                id: id,
                name: name,
                description: description,
                section: section,
                room: room,
                ownerId: ownerId,
                courseState: courseState,
                role: role,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> description = const Value.absent(),
                Value<String?> section = const Value.absent(),
                Value<String?> room = const Value.absent(),
                Value<String?> ownerId = const Value.absent(),
                Value<String> courseState = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CoursesCompanion.insert(
                id: id,
                name: name,
                description: description,
                section: section,
                room: room,
                ownerId: ownerId,
                courseState: courseState,
                role: role,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CoursesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CoursesTable,
      CourseRow,
      $$CoursesTableFilterComposer,
      $$CoursesTableOrderingComposer,
      $$CoursesTableAnnotationComposer,
      $$CoursesTableCreateCompanionBuilder,
      $$CoursesTableUpdateCompanionBuilder,
      (CourseRow, BaseReferences<_$AppDatabase, $CoursesTable, CourseRow>),
      CourseRow,
      PrefetchHooks Function()
    >;
typedef $$AssignmentsTableCreateCompanionBuilder =
    AssignmentsCompanion Function({
      required String id,
      required String courseId,
      required String title,
      Value<String?> description,
      Value<int?> dueDateMillis,
      Value<String> state,
      Value<String?> submissionState,
      Value<String?> submissionId,
      Value<String?> materialsJson,
      Value<String?> submissionAttachmentsJson,
      Value<int> rowid,
    });
typedef $$AssignmentsTableUpdateCompanionBuilder =
    AssignmentsCompanion Function({
      Value<String> id,
      Value<String> courseId,
      Value<String> title,
      Value<String?> description,
      Value<int?> dueDateMillis,
      Value<String> state,
      Value<String?> submissionState,
      Value<String?> submissionId,
      Value<String?> materialsJson,
      Value<String?> submissionAttachmentsJson,
      Value<int> rowid,
    });

class $$AssignmentsTableFilterComposer
    extends Composer<_$AppDatabase, $AssignmentsTable> {
  $$AssignmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get courseId => $composableBuilder(
    column: $table.courseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dueDateMillis => $composableBuilder(
    column: $table.dueDateMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get submissionState => $composableBuilder(
    column: $table.submissionState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get submissionId => $composableBuilder(
    column: $table.submissionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get materialsJson => $composableBuilder(
    column: $table.materialsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get submissionAttachmentsJson => $composableBuilder(
    column: $table.submissionAttachmentsJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AssignmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $AssignmentsTable> {
  $$AssignmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get courseId => $composableBuilder(
    column: $table.courseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dueDateMillis => $composableBuilder(
    column: $table.dueDateMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get submissionState => $composableBuilder(
    column: $table.submissionState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get submissionId => $composableBuilder(
    column: $table.submissionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get materialsJson => $composableBuilder(
    column: $table.materialsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get submissionAttachmentsJson => $composableBuilder(
    column: $table.submissionAttachmentsJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AssignmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AssignmentsTable> {
  $$AssignmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get courseId =>
      $composableBuilder(column: $table.courseId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dueDateMillis => $composableBuilder(
    column: $table.dueDateMillis,
    builder: (column) => column,
  );

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get submissionState => $composableBuilder(
    column: $table.submissionState,
    builder: (column) => column,
  );

  GeneratedColumn<String> get submissionId => $composableBuilder(
    column: $table.submissionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get materialsJson => $composableBuilder(
    column: $table.materialsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get submissionAttachmentsJson => $composableBuilder(
    column: $table.submissionAttachmentsJson,
    builder: (column) => column,
  );
}

class $$AssignmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AssignmentsTable,
          AssignmentRow,
          $$AssignmentsTableFilterComposer,
          $$AssignmentsTableOrderingComposer,
          $$AssignmentsTableAnnotationComposer,
          $$AssignmentsTableCreateCompanionBuilder,
          $$AssignmentsTableUpdateCompanionBuilder,
          (
            AssignmentRow,
            BaseReferences<_$AppDatabase, $AssignmentsTable, AssignmentRow>,
          ),
          AssignmentRow,
          PrefetchHooks Function()
        > {
  $$AssignmentsTableTableManager(_$AppDatabase db, $AssignmentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AssignmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AssignmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AssignmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> courseId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int?> dueDateMillis = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<String?> submissionState = const Value.absent(),
                Value<String?> submissionId = const Value.absent(),
                Value<String?> materialsJson = const Value.absent(),
                Value<String?> submissionAttachmentsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AssignmentsCompanion(
                id: id,
                courseId: courseId,
                title: title,
                description: description,
                dueDateMillis: dueDateMillis,
                state: state,
                submissionState: submissionState,
                submissionId: submissionId,
                materialsJson: materialsJson,
                submissionAttachmentsJson: submissionAttachmentsJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String courseId,
                required String title,
                Value<String?> description = const Value.absent(),
                Value<int?> dueDateMillis = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<String?> submissionState = const Value.absent(),
                Value<String?> submissionId = const Value.absent(),
                Value<String?> materialsJson = const Value.absent(),
                Value<String?> submissionAttachmentsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AssignmentsCompanion.insert(
                id: id,
                courseId: courseId,
                title: title,
                description: description,
                dueDateMillis: dueDateMillis,
                state: state,
                submissionState: submissionState,
                submissionId: submissionId,
                materialsJson: materialsJson,
                submissionAttachmentsJson: submissionAttachmentsJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AssignmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AssignmentsTable,
      AssignmentRow,
      $$AssignmentsTableFilterComposer,
      $$AssignmentsTableOrderingComposer,
      $$AssignmentsTableAnnotationComposer,
      $$AssignmentsTableCreateCompanionBuilder,
      $$AssignmentsTableUpdateCompanionBuilder,
      (
        AssignmentRow,
        BaseReferences<_$AppDatabase, $AssignmentsTable, AssignmentRow>,
      ),
      AssignmentRow,
      PrefetchHooks Function()
    >;
typedef $$AnnouncementsTableCreateCompanionBuilder =
    AnnouncementsCompanion Function({
      required String id,
      required String courseId,
      required String body,
      required int creationTimeMillis,
      Value<int?> updateTimeMillis,
      Value<String?> title,
      Value<bool> isMaterial,
      Value<String?> materialsJson,
      Value<int> rowid,
    });
typedef $$AnnouncementsTableUpdateCompanionBuilder =
    AnnouncementsCompanion Function({
      Value<String> id,
      Value<String> courseId,
      Value<String> body,
      Value<int> creationTimeMillis,
      Value<int?> updateTimeMillis,
      Value<String?> title,
      Value<bool> isMaterial,
      Value<String?> materialsJson,
      Value<int> rowid,
    });

class $$AnnouncementsTableFilterComposer
    extends Composer<_$AppDatabase, $AnnouncementsTable> {
  $$AnnouncementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get courseId => $composableBuilder(
    column: $table.courseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get creationTimeMillis => $composableBuilder(
    column: $table.creationTimeMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updateTimeMillis => $composableBuilder(
    column: $table.updateTimeMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isMaterial => $composableBuilder(
    column: $table.isMaterial,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get materialsJson => $composableBuilder(
    column: $table.materialsJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AnnouncementsTableOrderingComposer
    extends Composer<_$AppDatabase, $AnnouncementsTable> {
  $$AnnouncementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get courseId => $composableBuilder(
    column: $table.courseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get creationTimeMillis => $composableBuilder(
    column: $table.creationTimeMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updateTimeMillis => $composableBuilder(
    column: $table.updateTimeMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isMaterial => $composableBuilder(
    column: $table.isMaterial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get materialsJson => $composableBuilder(
    column: $table.materialsJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AnnouncementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AnnouncementsTable> {
  $$AnnouncementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get courseId =>
      $composableBuilder(column: $table.courseId, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<int> get creationTimeMillis => $composableBuilder(
    column: $table.creationTimeMillis,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updateTimeMillis => $composableBuilder(
    column: $table.updateTimeMillis,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<bool> get isMaterial => $composableBuilder(
    column: $table.isMaterial,
    builder: (column) => column,
  );

  GeneratedColumn<String> get materialsJson => $composableBuilder(
    column: $table.materialsJson,
    builder: (column) => column,
  );
}

class $$AnnouncementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AnnouncementsTable,
          AnnouncementRow,
          $$AnnouncementsTableFilterComposer,
          $$AnnouncementsTableOrderingComposer,
          $$AnnouncementsTableAnnotationComposer,
          $$AnnouncementsTableCreateCompanionBuilder,
          $$AnnouncementsTableUpdateCompanionBuilder,
          (
            AnnouncementRow,
            BaseReferences<_$AppDatabase, $AnnouncementsTable, AnnouncementRow>,
          ),
          AnnouncementRow,
          PrefetchHooks Function()
        > {
  $$AnnouncementsTableTableManager(_$AppDatabase db, $AnnouncementsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AnnouncementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AnnouncementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AnnouncementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> courseId = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<int> creationTimeMillis = const Value.absent(),
                Value<int?> updateTimeMillis = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<bool> isMaterial = const Value.absent(),
                Value<String?> materialsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AnnouncementsCompanion(
                id: id,
                courseId: courseId,
                body: body,
                creationTimeMillis: creationTimeMillis,
                updateTimeMillis: updateTimeMillis,
                title: title,
                isMaterial: isMaterial,
                materialsJson: materialsJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String courseId,
                required String body,
                required int creationTimeMillis,
                Value<int?> updateTimeMillis = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<bool> isMaterial = const Value.absent(),
                Value<String?> materialsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AnnouncementsCompanion.insert(
                id: id,
                courseId: courseId,
                body: body,
                creationTimeMillis: creationTimeMillis,
                updateTimeMillis: updateTimeMillis,
                title: title,
                isMaterial: isMaterial,
                materialsJson: materialsJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AnnouncementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AnnouncementsTable,
      AnnouncementRow,
      $$AnnouncementsTableFilterComposer,
      $$AnnouncementsTableOrderingComposer,
      $$AnnouncementsTableAnnotationComposer,
      $$AnnouncementsTableCreateCompanionBuilder,
      $$AnnouncementsTableUpdateCompanionBuilder,
      (
        AnnouncementRow,
        BaseReferences<_$AppDatabase, $AnnouncementsTable, AnnouncementRow>,
      ),
      AnnouncementRow,
      PrefetchHooks Function()
    >;
typedef $$CourseOrdersTableCreateCompanionBuilder =
    CourseOrdersCompanion Function({
      required String courseId,
      required int sortIndex,
      Value<int> rowid,
    });
typedef $$CourseOrdersTableUpdateCompanionBuilder =
    CourseOrdersCompanion Function({
      Value<String> courseId,
      Value<int> sortIndex,
      Value<int> rowid,
    });

class $$CourseOrdersTableFilterComposer
    extends Composer<_$AppDatabase, $CourseOrdersTable> {
  $$CourseOrdersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get courseId => $composableBuilder(
    column: $table.courseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortIndex => $composableBuilder(
    column: $table.sortIndex,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CourseOrdersTableOrderingComposer
    extends Composer<_$AppDatabase, $CourseOrdersTable> {
  $$CourseOrdersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get courseId => $composableBuilder(
    column: $table.courseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortIndex => $composableBuilder(
    column: $table.sortIndex,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CourseOrdersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CourseOrdersTable> {
  $$CourseOrdersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get courseId =>
      $composableBuilder(column: $table.courseId, builder: (column) => column);

  GeneratedColumn<int> get sortIndex =>
      $composableBuilder(column: $table.sortIndex, builder: (column) => column);
}

class $$CourseOrdersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CourseOrdersTable,
          CourseOrderRow,
          $$CourseOrdersTableFilterComposer,
          $$CourseOrdersTableOrderingComposer,
          $$CourseOrdersTableAnnotationComposer,
          $$CourseOrdersTableCreateCompanionBuilder,
          $$CourseOrdersTableUpdateCompanionBuilder,
          (
            CourseOrderRow,
            BaseReferences<_$AppDatabase, $CourseOrdersTable, CourseOrderRow>,
          ),
          CourseOrderRow,
          PrefetchHooks Function()
        > {
  $$CourseOrdersTableTableManager(_$AppDatabase db, $CourseOrdersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CourseOrdersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CourseOrdersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CourseOrdersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> courseId = const Value.absent(),
                Value<int> sortIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CourseOrdersCompanion(
                courseId: courseId,
                sortIndex: sortIndex,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String courseId,
                required int sortIndex,
                Value<int> rowid = const Value.absent(),
              }) => CourseOrdersCompanion.insert(
                courseId: courseId,
                sortIndex: sortIndex,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CourseOrdersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CourseOrdersTable,
      CourseOrderRow,
      $$CourseOrdersTableFilterComposer,
      $$CourseOrdersTableOrderingComposer,
      $$CourseOrdersTableAnnotationComposer,
      $$CourseOrdersTableCreateCompanionBuilder,
      $$CourseOrdersTableUpdateCompanionBuilder,
      (
        CourseOrderRow,
        BaseReferences<_$AppDatabase, $CourseOrdersTable, CourseOrderRow>,
      ),
      CourseOrderRow,
      PrefetchHooks Function()
    >;
typedef $$SyncStatesTableCreateCompanionBuilder =
    SyncStatesCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SyncStatesTableUpdateCompanionBuilder =
    SyncStatesCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SyncStatesTableFilterComposer
    extends Composer<_$AppDatabase, $SyncStatesTable> {
  $$SyncStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncStatesTable> {
  $$SyncStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncStatesTable> {
  $$SyncStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SyncStatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncStatesTable,
          SyncStateRow,
          $$SyncStatesTableFilterComposer,
          $$SyncStatesTableOrderingComposer,
          $$SyncStatesTableAnnotationComposer,
          $$SyncStatesTableCreateCompanionBuilder,
          $$SyncStatesTableUpdateCompanionBuilder,
          (
            SyncStateRow,
            BaseReferences<_$AppDatabase, $SyncStatesTable, SyncStateRow>,
          ),
          SyncStateRow,
          PrefetchHooks Function()
        > {
  $$SyncStatesTableTableManager(_$AppDatabase db, $SyncStatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStatesCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SyncStatesCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncStatesTable,
      SyncStateRow,
      $$SyncStatesTableFilterComposer,
      $$SyncStatesTableOrderingComposer,
      $$SyncStatesTableAnnotationComposer,
      $$SyncStatesTableCreateCompanionBuilder,
      $$SyncStatesTableUpdateCompanionBuilder,
      (
        SyncStateRow,
        BaseReferences<_$AppDatabase, $SyncStatesTable, SyncStateRow>,
      ),
      SyncStateRow,
      PrefetchHooks Function()
    >;
typedef $$HiddenItemsTableCreateCompanionBuilder =
    HiddenItemsCompanion Function({
      required String itemId,
      required String type,
      required DateTime hiddenAt,
      Value<int> rowid,
    });
typedef $$HiddenItemsTableUpdateCompanionBuilder =
    HiddenItemsCompanion Function({
      Value<String> itemId,
      Value<String> type,
      Value<DateTime> hiddenAt,
      Value<int> rowid,
    });

class $$HiddenItemsTableFilterComposer
    extends Composer<_$AppDatabase, $HiddenItemsTable> {
  $$HiddenItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get hiddenAt => $composableBuilder(
    column: $table.hiddenAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HiddenItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $HiddenItemsTable> {
  $$HiddenItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get hiddenAt => $composableBuilder(
    column: $table.hiddenAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HiddenItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HiddenItemsTable> {
  $$HiddenItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<DateTime> get hiddenAt =>
      $composableBuilder(column: $table.hiddenAt, builder: (column) => column);
}

class $$HiddenItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HiddenItemsTable,
          HiddenItemRow,
          $$HiddenItemsTableFilterComposer,
          $$HiddenItemsTableOrderingComposer,
          $$HiddenItemsTableAnnotationComposer,
          $$HiddenItemsTableCreateCompanionBuilder,
          $$HiddenItemsTableUpdateCompanionBuilder,
          (
            HiddenItemRow,
            BaseReferences<_$AppDatabase, $HiddenItemsTable, HiddenItemRow>,
          ),
          HiddenItemRow,
          PrefetchHooks Function()
        > {
  $$HiddenItemsTableTableManager(_$AppDatabase db, $HiddenItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HiddenItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HiddenItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HiddenItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> itemId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<DateTime> hiddenAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HiddenItemsCompanion(
                itemId: itemId,
                type: type,
                hiddenAt: hiddenAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String itemId,
                required String type,
                required DateTime hiddenAt,
                Value<int> rowid = const Value.absent(),
              }) => HiddenItemsCompanion.insert(
                itemId: itemId,
                type: type,
                hiddenAt: hiddenAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HiddenItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HiddenItemsTable,
      HiddenItemRow,
      $$HiddenItemsTableFilterComposer,
      $$HiddenItemsTableOrderingComposer,
      $$HiddenItemsTableAnnotationComposer,
      $$HiddenItemsTableCreateCompanionBuilder,
      $$HiddenItemsTableUpdateCompanionBuilder,
      (
        HiddenItemRow,
        BaseReferences<_$AppDatabase, $HiddenItemsTable, HiddenItemRow>,
      ),
      HiddenItemRow,
      PrefetchHooks Function()
    >;
typedef $$UserPreferencesTableCreateCompanionBuilder =
    UserPreferencesCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$UserPreferencesTableUpdateCompanionBuilder =
    UserPreferencesCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$UserPreferencesTableFilterComposer
    extends Composer<_$AppDatabase, $UserPreferencesTable> {
  $$UserPreferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserPreferencesTableOrderingComposer
    extends Composer<_$AppDatabase, $UserPreferencesTable> {
  $$UserPreferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserPreferencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserPreferencesTable> {
  $$UserPreferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$UserPreferencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserPreferencesTable,
          UserPreferenceRow,
          $$UserPreferencesTableFilterComposer,
          $$UserPreferencesTableOrderingComposer,
          $$UserPreferencesTableAnnotationComposer,
          $$UserPreferencesTableCreateCompanionBuilder,
          $$UserPreferencesTableUpdateCompanionBuilder,
          (
            UserPreferenceRow,
            BaseReferences<
              _$AppDatabase,
              $UserPreferencesTable,
              UserPreferenceRow
            >,
          ),
          UserPreferenceRow,
          PrefetchHooks Function()
        > {
  $$UserPreferencesTableTableManager(
    _$AppDatabase db,
    $UserPreferencesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserPreferencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserPreferencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserPreferencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserPreferencesCompanion(
                key: key,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => UserPreferencesCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserPreferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserPreferencesTable,
      UserPreferenceRow,
      $$UserPreferencesTableFilterComposer,
      $$UserPreferencesTableOrderingComposer,
      $$UserPreferencesTableAnnotationComposer,
      $$UserPreferencesTableCreateCompanionBuilder,
      $$UserPreferencesTableUpdateCompanionBuilder,
      (
        UserPreferenceRow,
        BaseReferences<_$AppDatabase, $UserPreferencesTable, UserPreferenceRow>,
      ),
      UserPreferenceRow,
      PrefetchHooks Function()
    >;
typedef $$NotificationLogsTableCreateCompanionBuilder =
    NotificationLogsCompanion Function({
      required String assignmentId,
      required DateTime notifiedAt,
      Value<int> rowid,
    });
typedef $$NotificationLogsTableUpdateCompanionBuilder =
    NotificationLogsCompanion Function({
      Value<String> assignmentId,
      Value<DateTime> notifiedAt,
      Value<int> rowid,
    });

class $$NotificationLogsTableFilterComposer
    extends Composer<_$AppDatabase, $NotificationLogsTable> {
  $$NotificationLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get assignmentId => $composableBuilder(
    column: $table.assignmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get notifiedAt => $composableBuilder(
    column: $table.notifiedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotificationLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $NotificationLogsTable> {
  $$NotificationLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get assignmentId => $composableBuilder(
    column: $table.assignmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get notifiedAt => $composableBuilder(
    column: $table.notifiedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotificationLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotificationLogsTable> {
  $$NotificationLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get assignmentId => $composableBuilder(
    column: $table.assignmentId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get notifiedAt => $composableBuilder(
    column: $table.notifiedAt,
    builder: (column) => column,
  );
}

class $$NotificationLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotificationLogsTable,
          NotificationLogRow,
          $$NotificationLogsTableFilterComposer,
          $$NotificationLogsTableOrderingComposer,
          $$NotificationLogsTableAnnotationComposer,
          $$NotificationLogsTableCreateCompanionBuilder,
          $$NotificationLogsTableUpdateCompanionBuilder,
          (
            NotificationLogRow,
            BaseReferences<
              _$AppDatabase,
              $NotificationLogsTable,
              NotificationLogRow
            >,
          ),
          NotificationLogRow,
          PrefetchHooks Function()
        > {
  $$NotificationLogsTableTableManager(
    _$AppDatabase db,
    $NotificationLogsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotificationLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotificationLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotificationLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> assignmentId = const Value.absent(),
                Value<DateTime> notifiedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotificationLogsCompanion(
                assignmentId: assignmentId,
                notifiedAt: notifiedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String assignmentId,
                required DateTime notifiedAt,
                Value<int> rowid = const Value.absent(),
              }) => NotificationLogsCompanion.insert(
                assignmentId: assignmentId,
                notifiedAt: notifiedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotificationLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotificationLogsTable,
      NotificationLogRow,
      $$NotificationLogsTableFilterComposer,
      $$NotificationLogsTableOrderingComposer,
      $$NotificationLogsTableAnnotationComposer,
      $$NotificationLogsTableCreateCompanionBuilder,
      $$NotificationLogsTableUpdateCompanionBuilder,
      (
        NotificationLogRow,
        BaseReferences<
          _$AppDatabase,
          $NotificationLogsTable,
          NotificationLogRow
        >,
      ),
      NotificationLogRow,
      PrefetchHooks Function()
    >;
typedef $$SnoozedItemsTableCreateCompanionBuilder =
    SnoozedItemsCompanion Function({
      required String assignmentId,
      required DateTime snoozedUntil,
      Value<int> rowid,
    });
typedef $$SnoozedItemsTableUpdateCompanionBuilder =
    SnoozedItemsCompanion Function({
      Value<String> assignmentId,
      Value<DateTime> snoozedUntil,
      Value<int> rowid,
    });

class $$SnoozedItemsTableFilterComposer
    extends Composer<_$AppDatabase, $SnoozedItemsTable> {
  $$SnoozedItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get assignmentId => $composableBuilder(
    column: $table.assignmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get snoozedUntil => $composableBuilder(
    column: $table.snoozedUntil,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SnoozedItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $SnoozedItemsTable> {
  $$SnoozedItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get assignmentId => $composableBuilder(
    column: $table.assignmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get snoozedUntil => $composableBuilder(
    column: $table.snoozedUntil,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SnoozedItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SnoozedItemsTable> {
  $$SnoozedItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get assignmentId => $composableBuilder(
    column: $table.assignmentId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get snoozedUntil => $composableBuilder(
    column: $table.snoozedUntil,
    builder: (column) => column,
  );
}

class $$SnoozedItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SnoozedItemsTable,
          SnoozedItemRow,
          $$SnoozedItemsTableFilterComposer,
          $$SnoozedItemsTableOrderingComposer,
          $$SnoozedItemsTableAnnotationComposer,
          $$SnoozedItemsTableCreateCompanionBuilder,
          $$SnoozedItemsTableUpdateCompanionBuilder,
          (
            SnoozedItemRow,
            BaseReferences<_$AppDatabase, $SnoozedItemsTable, SnoozedItemRow>,
          ),
          SnoozedItemRow,
          PrefetchHooks Function()
        > {
  $$SnoozedItemsTableTableManager(_$AppDatabase db, $SnoozedItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SnoozedItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SnoozedItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SnoozedItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> assignmentId = const Value.absent(),
                Value<DateTime> snoozedUntil = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SnoozedItemsCompanion(
                assignmentId: assignmentId,
                snoozedUntil: snoozedUntil,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String assignmentId,
                required DateTime snoozedUntil,
                Value<int> rowid = const Value.absent(),
              }) => SnoozedItemsCompanion.insert(
                assignmentId: assignmentId,
                snoozedUntil: snoozedUntil,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SnoozedItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SnoozedItemsTable,
      SnoozedItemRow,
      $$SnoozedItemsTableFilterComposer,
      $$SnoozedItemsTableOrderingComposer,
      $$SnoozedItemsTableAnnotationComposer,
      $$SnoozedItemsTableCreateCompanionBuilder,
      $$SnoozedItemsTableUpdateCompanionBuilder,
      (
        SnoozedItemRow,
        BaseReferences<_$AppDatabase, $SnoozedItemsTable, SnoozedItemRow>,
      ),
      SnoozedItemRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CoursesTableTableManager get courses =>
      $$CoursesTableTableManager(_db, _db.courses);
  $$AssignmentsTableTableManager get assignments =>
      $$AssignmentsTableTableManager(_db, _db.assignments);
  $$AnnouncementsTableTableManager get announcements =>
      $$AnnouncementsTableTableManager(_db, _db.announcements);
  $$CourseOrdersTableTableManager get courseOrders =>
      $$CourseOrdersTableTableManager(_db, _db.courseOrders);
  $$SyncStatesTableTableManager get syncStates =>
      $$SyncStatesTableTableManager(_db, _db.syncStates);
  $$HiddenItemsTableTableManager get hiddenItems =>
      $$HiddenItemsTableTableManager(_db, _db.hiddenItems);
  $$UserPreferencesTableTableManager get userPreferences =>
      $$UserPreferencesTableTableManager(_db, _db.userPreferences);
  $$NotificationLogsTableTableManager get notificationLogs =>
      $$NotificationLogsTableTableManager(_db, _db.notificationLogs);
  $$SnoozedItemsTableTableManager get snoozedItems =>
      $$SnoozedItemsTableTableManager(_db, _db.snoozedItems);
}
