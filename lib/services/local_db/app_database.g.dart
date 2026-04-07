// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ConversationsTable extends Conversations
    with TableInfo<$ConversationsTable, Conversation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConversationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, title, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'conversations';
  @override
  VerificationContext validateIntegrity(
    Insertable<Conversation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Conversation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Conversation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ConversationsTable createAlias(String alias) {
    return $ConversationsTable(attachedDatabase, alias);
  }
}

class Conversation extends DataClass implements Insertable<Conversation> {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Conversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ConversationsCompanion toCompanion(bool nullToAbsent) {
    return ConversationsCompanion(
      id: Value(id),
      title: Value(title),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Conversation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Conversation(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Conversation copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Conversation(
    id: id ?? this.id,
    title: title ?? this.title,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Conversation copyWithCompanion(ConversationsCompanion data) {
    return Conversation(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Conversation(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Conversation &&
          other.id == this.id &&
          other.title == this.title &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ConversationsCompanion extends UpdateCompanion<Conversation> {
  final Value<String> id;
  final Value<String> title;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ConversationsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConversationsCompanion.insert({
    required String id,
    this.title = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Conversation> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConversationsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ConversationsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConversationsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MessagesTable extends Messages with TableInfo<$MessagesTable, Message> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _conversationIdMeta = const VerificationMeta(
    'conversationId',
  );
  @override
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
    'conversation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    conversationId,
    content,
    role,
    timestamp,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<Message> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
        _conversationIdMeta,
        conversationId.isAcceptableOrUnknown(
          data['conversation_id']!,
          _conversationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Message map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Message(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      conversationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conversation_id'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
    );
  }

  @override
  $MessagesTable createAlias(String alias) {
    return $MessagesTable(attachedDatabase, alias);
  }
}

class Message extends DataClass implements Insertable<Message> {
  final String id;
  final String conversationId;
  final String content;
  final String role;
  final DateTime timestamp;
  const Message({
    required this.id,
    required this.conversationId,
    required this.content,
    required this.role,
    required this.timestamp,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['conversation_id'] = Variable<String>(conversationId);
    map['content'] = Variable<String>(content);
    map['role'] = Variable<String>(role);
    map['timestamp'] = Variable<DateTime>(timestamp);
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(
      id: Value(id),
      conversationId: Value(conversationId),
      content: Value(content),
      role: Value(role),
      timestamp: Value(timestamp),
    );
  }

  factory Message.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Message(
      id: serializer.fromJson<String>(json['id']),
      conversationId: serializer.fromJson<String>(json['conversationId']),
      content: serializer.fromJson<String>(json['content']),
      role: serializer.fromJson<String>(json['role']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'conversationId': serializer.toJson<String>(conversationId),
      'content': serializer.toJson<String>(content),
      'role': serializer.toJson<String>(role),
      'timestamp': serializer.toJson<DateTime>(timestamp),
    };
  }

  Message copyWith({
    String? id,
    String? conversationId,
    String? content,
    String? role,
    DateTime? timestamp,
  }) => Message(
    id: id ?? this.id,
    conversationId: conversationId ?? this.conversationId,
    content: content ?? this.content,
    role: role ?? this.role,
    timestamp: timestamp ?? this.timestamp,
  );
  Message copyWithCompanion(MessagesCompanion data) {
    return Message(
      id: data.id.present ? data.id.value : this.id,
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      content: data.content.present ? data.content.value : this.content,
      role: data.role.present ? data.role.value : this.role,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Message(')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('content: $content, ')
          ..write('role: $role, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, conversationId, content, role, timestamp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Message &&
          other.id == this.id &&
          other.conversationId == this.conversationId &&
          other.content == this.content &&
          other.role == this.role &&
          other.timestamp == this.timestamp);
}

class MessagesCompanion extends UpdateCompanion<Message> {
  final Value<String> id;
  final Value<String> conversationId;
  final Value<String> content;
  final Value<String> role;
  final Value<DateTime> timestamp;
  final Value<int> rowid;
  const MessagesCompanion({
    this.id = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.content = const Value.absent(),
    this.role = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MessagesCompanion.insert({
    required String id,
    required String conversationId,
    required String content,
    required String role,
    required DateTime timestamp,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       conversationId = Value(conversationId),
       content = Value(content),
       role = Value(role),
       timestamp = Value(timestamp);
  static Insertable<Message> custom({
    Expression<String>? id,
    Expression<String>? conversationId,
    Expression<String>? content,
    Expression<String>? role,
    Expression<DateTime>? timestamp,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (conversationId != null) 'conversation_id': conversationId,
      if (content != null) 'content': content,
      if (role != null) 'role': role,
      if (timestamp != null) 'timestamp': timestamp,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MessagesCompanion copyWith({
    Value<String>? id,
    Value<String>? conversationId,
    Value<String>? content,
    Value<String>? role,
    Value<DateTime>? timestamp,
    Value<int>? rowid,
  }) {
    return MessagesCompanion(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      content: content ?? this.content,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesCompanion(')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('content: $content, ')
          ..write('role: $role, ')
          ..write('timestamp: $timestamp, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LevelHistoryTable extends LevelHistory
    with TableInfo<$LevelHistoryTable, LevelHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LevelHistoryTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasoningMeta = const VerificationMeta(
    'reasoning',
  );
  @override
  late final GeneratedColumn<String> reasoning = GeneratedColumn<String>(
    'reasoning',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _assessedAtMeta = const VerificationMeta(
    'assessedAt',
  );
  @override
  late final GeneratedColumn<DateTime> assessedAt = GeneratedColumn<DateTime>(
    'assessed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, level, reasoning, assessedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'level_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<LevelHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    } else if (isInserting) {
      context.missing(_levelMeta);
    }
    if (data.containsKey('reasoning')) {
      context.handle(
        _reasoningMeta,
        reasoning.isAcceptableOrUnknown(data['reasoning']!, _reasoningMeta),
      );
    }
    if (data.containsKey('assessed_at')) {
      context.handle(
        _assessedAtMeta,
        assessedAt.isAcceptableOrUnknown(data['assessed_at']!, _assessedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_assessedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LevelHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LevelHistoryData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level'],
      )!,
      reasoning: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reasoning'],
      )!,
      assessedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}assessed_at'],
      )!,
    );
  }

  @override
  $LevelHistoryTable createAlias(String alias) {
    return $LevelHistoryTable(attachedDatabase, alias);
  }
}

class LevelHistoryData extends DataClass
    implements Insertable<LevelHistoryData> {
  final int id;
  final int level;
  final String reasoning;
  final DateTime assessedAt;
  const LevelHistoryData({
    required this.id,
    required this.level,
    required this.reasoning,
    required this.assessedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['level'] = Variable<int>(level);
    map['reasoning'] = Variable<String>(reasoning);
    map['assessed_at'] = Variable<DateTime>(assessedAt);
    return map;
  }

  LevelHistoryCompanion toCompanion(bool nullToAbsent) {
    return LevelHistoryCompanion(
      id: Value(id),
      level: Value(level),
      reasoning: Value(reasoning),
      assessedAt: Value(assessedAt),
    );
  }

  factory LevelHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LevelHistoryData(
      id: serializer.fromJson<int>(json['id']),
      level: serializer.fromJson<int>(json['level']),
      reasoning: serializer.fromJson<String>(json['reasoning']),
      assessedAt: serializer.fromJson<DateTime>(json['assessedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'level': serializer.toJson<int>(level),
      'reasoning': serializer.toJson<String>(reasoning),
      'assessedAt': serializer.toJson<DateTime>(assessedAt),
    };
  }

  LevelHistoryData copyWith({
    int? id,
    int? level,
    String? reasoning,
    DateTime? assessedAt,
  }) => LevelHistoryData(
    id: id ?? this.id,
    level: level ?? this.level,
    reasoning: reasoning ?? this.reasoning,
    assessedAt: assessedAt ?? this.assessedAt,
  );
  LevelHistoryData copyWithCompanion(LevelHistoryCompanion data) {
    return LevelHistoryData(
      id: data.id.present ? data.id.value : this.id,
      level: data.level.present ? data.level.value : this.level,
      reasoning: data.reasoning.present ? data.reasoning.value : this.reasoning,
      assessedAt: data.assessedAt.present
          ? data.assessedAt.value
          : this.assessedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LevelHistoryData(')
          ..write('id: $id, ')
          ..write('level: $level, ')
          ..write('reasoning: $reasoning, ')
          ..write('assessedAt: $assessedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, level, reasoning, assessedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LevelHistoryData &&
          other.id == this.id &&
          other.level == this.level &&
          other.reasoning == this.reasoning &&
          other.assessedAt == this.assessedAt);
}

class LevelHistoryCompanion extends UpdateCompanion<LevelHistoryData> {
  final Value<int> id;
  final Value<int> level;
  final Value<String> reasoning;
  final Value<DateTime> assessedAt;
  const LevelHistoryCompanion({
    this.id = const Value.absent(),
    this.level = const Value.absent(),
    this.reasoning = const Value.absent(),
    this.assessedAt = const Value.absent(),
  });
  LevelHistoryCompanion.insert({
    this.id = const Value.absent(),
    required int level,
    this.reasoning = const Value.absent(),
    required DateTime assessedAt,
  }) : level = Value(level),
       assessedAt = Value(assessedAt);
  static Insertable<LevelHistoryData> custom({
    Expression<int>? id,
    Expression<int>? level,
    Expression<String>? reasoning,
    Expression<DateTime>? assessedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (level != null) 'level': level,
      if (reasoning != null) 'reasoning': reasoning,
      if (assessedAt != null) 'assessed_at': assessedAt,
    });
  }

  LevelHistoryCompanion copyWith({
    Value<int>? id,
    Value<int>? level,
    Value<String>? reasoning,
    Value<DateTime>? assessedAt,
  }) {
    return LevelHistoryCompanion(
      id: id ?? this.id,
      level: level ?? this.level,
      reasoning: reasoning ?? this.reasoning,
      assessedAt: assessedAt ?? this.assessedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (reasoning.present) {
      map['reasoning'] = Variable<String>(reasoning.value);
    }
    if (assessedAt.present) {
      map['assessed_at'] = Variable<DateTime>(assessedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LevelHistoryCompanion(')
          ..write('id: $id, ')
          ..write('level: $level, ')
          ..write('reasoning: $reasoning, ')
          ..write('assessedAt: $assessedAt')
          ..write(')'))
        .toString();
  }
}

class $DailyActivityTable extends DailyActivity
    with TableInfo<$DailyActivityTable, DailyActivityData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyActivityTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageCountMeta = const VerificationMeta(
    'messageCount',
  );
  @override
  late final GeneratedColumn<int> messageCount = GeneratedColumn<int>(
    'message_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _streakCountMeta = const VerificationMeta(
    'streakCount',
  );
  @override
  late final GeneratedColumn<int> streakCount = GeneratedColumn<int>(
    'streak_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _goalReachedMeta = const VerificationMeta(
    'goalReached',
  );
  @override
  late final GeneratedColumn<bool> goalReached = GeneratedColumn<bool>(
    'goal_reached',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("goal_reached" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    date,
    messageCount,
    streakCount,
    goalReached,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_activity';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyActivityData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('message_count')) {
      context.handle(
        _messageCountMeta,
        messageCount.isAcceptableOrUnknown(
          data['message_count']!,
          _messageCountMeta,
        ),
      );
    }
    if (data.containsKey('streak_count')) {
      context.handle(
        _streakCountMeta,
        streakCount.isAcceptableOrUnknown(
          data['streak_count']!,
          _streakCountMeta,
        ),
      );
    }
    if (data.containsKey('goal_reached')) {
      context.handle(
        _goalReachedMeta,
        goalReached.isAcceptableOrUnknown(
          data['goal_reached']!,
          _goalReachedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date};
  @override
  DailyActivityData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyActivityData(
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      messageCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}message_count'],
      )!,
      streakCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}streak_count'],
      )!,
      goalReached: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}goal_reached'],
      )!,
    );
  }

  @override
  $DailyActivityTable createAlias(String alias) {
    return $DailyActivityTable(attachedDatabase, alias);
  }
}

class DailyActivityData extends DataClass
    implements Insertable<DailyActivityData> {
  final String date;
  final int messageCount;
  final int streakCount;
  final bool goalReached;
  const DailyActivityData({
    required this.date,
    required this.messageCount,
    required this.streakCount,
    required this.goalReached,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<String>(date);
    map['message_count'] = Variable<int>(messageCount);
    map['streak_count'] = Variable<int>(streakCount);
    map['goal_reached'] = Variable<bool>(goalReached);
    return map;
  }

  DailyActivityCompanion toCompanion(bool nullToAbsent) {
    return DailyActivityCompanion(
      date: Value(date),
      messageCount: Value(messageCount),
      streakCount: Value(streakCount),
      goalReached: Value(goalReached),
    );
  }

  factory DailyActivityData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyActivityData(
      date: serializer.fromJson<String>(json['date']),
      messageCount: serializer.fromJson<int>(json['messageCount']),
      streakCount: serializer.fromJson<int>(json['streakCount']),
      goalReached: serializer.fromJson<bool>(json['goalReached']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<String>(date),
      'messageCount': serializer.toJson<int>(messageCount),
      'streakCount': serializer.toJson<int>(streakCount),
      'goalReached': serializer.toJson<bool>(goalReached),
    };
  }

  DailyActivityData copyWith({
    String? date,
    int? messageCount,
    int? streakCount,
    bool? goalReached,
  }) => DailyActivityData(
    date: date ?? this.date,
    messageCount: messageCount ?? this.messageCount,
    streakCount: streakCount ?? this.streakCount,
    goalReached: goalReached ?? this.goalReached,
  );
  DailyActivityData copyWithCompanion(DailyActivityCompanion data) {
    return DailyActivityData(
      date: data.date.present ? data.date.value : this.date,
      messageCount: data.messageCount.present
          ? data.messageCount.value
          : this.messageCount,
      streakCount: data.streakCount.present
          ? data.streakCount.value
          : this.streakCount,
      goalReached: data.goalReached.present
          ? data.goalReached.value
          : this.goalReached,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyActivityData(')
          ..write('date: $date, ')
          ..write('messageCount: $messageCount, ')
          ..write('streakCount: $streakCount, ')
          ..write('goalReached: $goalReached')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(date, messageCount, streakCount, goalReached);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyActivityData &&
          other.date == this.date &&
          other.messageCount == this.messageCount &&
          other.streakCount == this.streakCount &&
          other.goalReached == this.goalReached);
}

class DailyActivityCompanion extends UpdateCompanion<DailyActivityData> {
  final Value<String> date;
  final Value<int> messageCount;
  final Value<int> streakCount;
  final Value<bool> goalReached;
  final Value<int> rowid;
  const DailyActivityCompanion({
    this.date = const Value.absent(),
    this.messageCount = const Value.absent(),
    this.streakCount = const Value.absent(),
    this.goalReached = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyActivityCompanion.insert({
    required String date,
    this.messageCount = const Value.absent(),
    this.streakCount = const Value.absent(),
    this.goalReached = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : date = Value(date);
  static Insertable<DailyActivityData> custom({
    Expression<String>? date,
    Expression<int>? messageCount,
    Expression<int>? streakCount,
    Expression<bool>? goalReached,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (messageCount != null) 'message_count': messageCount,
      if (streakCount != null) 'streak_count': streakCount,
      if (goalReached != null) 'goal_reached': goalReached,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyActivityCompanion copyWith({
    Value<String>? date,
    Value<int>? messageCount,
    Value<int>? streakCount,
    Value<bool>? goalReached,
    Value<int>? rowid,
  }) {
    return DailyActivityCompanion(
      date: date ?? this.date,
      messageCount: messageCount ?? this.messageCount,
      streakCount: streakCount ?? this.streakCount,
      goalReached: goalReached ?? this.goalReached,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (messageCount.present) {
      map['message_count'] = Variable<int>(messageCount.value);
    }
    if (streakCount.present) {
      map['streak_count'] = Variable<int>(streakCount.value);
    }
    if (goalReached.present) {
      map['goal_reached'] = Variable<bool>(goalReached.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyActivityCompanion(')
          ..write('date: $date, ')
          ..write('messageCount: $messageCount, ')
          ..write('streakCount: $streakCount, ')
          ..write('goalReached: $goalReached, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TopicSessionsTable extends TopicSessions
    with TableInfo<$TopicSessionsTable, TopicSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TopicSessionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _topicIdMeta = const VerificationMeta(
    'topicId',
  );
  @override
  late final GeneratedColumn<String> topicId = GeneratedColumn<String>(
    'topic_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _topicTitleMeta = const VerificationMeta(
    'topicTitle',
  );
  @override
  late final GeneratedColumn<String> topicTitle = GeneratedColumn<String>(
    'topic_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _turnCountMeta = const VerificationMeta(
    'turnCount',
  );
  @override
  late final GeneratedColumn<int> turnCount = GeneratedColumn<int>(
    'turn_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    topicId,
    topicTitle,
    category,
    turnCount,
    startedAt,
    endedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'topic_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<TopicSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('topic_id')) {
      context.handle(
        _topicIdMeta,
        topicId.isAcceptableOrUnknown(data['topic_id']!, _topicIdMeta),
      );
    } else if (isInserting) {
      context.missing(_topicIdMeta);
    }
    if (data.containsKey('topic_title')) {
      context.handle(
        _topicTitleMeta,
        topicTitle.isAcceptableOrUnknown(data['topic_title']!, _topicTitleMeta),
      );
    } else if (isInserting) {
      context.missing(_topicTitleMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('turn_count')) {
      context.handle(
        _turnCountMeta,
        turnCount.isAcceptableOrUnknown(data['turn_count']!, _turnCountMeta),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TopicSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TopicSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      topicId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic_id'],
      )!,
      topicTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic_title'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      turnCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}turn_count'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
    );
  }

  @override
  $TopicSessionsTable createAlias(String alias) {
    return $TopicSessionsTable(attachedDatabase, alias);
  }
}

class TopicSession extends DataClass implements Insertable<TopicSession> {
  final int id;
  final String topicId;
  final String topicTitle;
  final String category;
  final int turnCount;
  final DateTime startedAt;
  final DateTime? endedAt;
  const TopicSession({
    required this.id,
    required this.topicId,
    required this.topicTitle,
    required this.category,
    required this.turnCount,
    required this.startedAt,
    this.endedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['topic_id'] = Variable<String>(topicId);
    map['topic_title'] = Variable<String>(topicTitle);
    map['category'] = Variable<String>(category);
    map['turn_count'] = Variable<int>(turnCount);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    return map;
  }

  TopicSessionsCompanion toCompanion(bool nullToAbsent) {
    return TopicSessionsCompanion(
      id: Value(id),
      topicId: Value(topicId),
      topicTitle: Value(topicTitle),
      category: Value(category),
      turnCount: Value(turnCount),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
    );
  }

  factory TopicSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TopicSession(
      id: serializer.fromJson<int>(json['id']),
      topicId: serializer.fromJson<String>(json['topicId']),
      topicTitle: serializer.fromJson<String>(json['topicTitle']),
      category: serializer.fromJson<String>(json['category']),
      turnCount: serializer.fromJson<int>(json['turnCount']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'topicId': serializer.toJson<String>(topicId),
      'topicTitle': serializer.toJson<String>(topicTitle),
      'category': serializer.toJson<String>(category),
      'turnCount': serializer.toJson<int>(turnCount),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
    };
  }

  TopicSession copyWith({
    int? id,
    String? topicId,
    String? topicTitle,
    String? category,
    int? turnCount,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
  }) => TopicSession(
    id: id ?? this.id,
    topicId: topicId ?? this.topicId,
    topicTitle: topicTitle ?? this.topicTitle,
    category: category ?? this.category,
    turnCount: turnCount ?? this.turnCount,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
  );
  TopicSession copyWithCompanion(TopicSessionsCompanion data) {
    return TopicSession(
      id: data.id.present ? data.id.value : this.id,
      topicId: data.topicId.present ? data.topicId.value : this.topicId,
      topicTitle: data.topicTitle.present
          ? data.topicTitle.value
          : this.topicTitle,
      category: data.category.present ? data.category.value : this.category,
      turnCount: data.turnCount.present ? data.turnCount.value : this.turnCount,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TopicSession(')
          ..write('id: $id, ')
          ..write('topicId: $topicId, ')
          ..write('topicTitle: $topicTitle, ')
          ..write('category: $category, ')
          ..write('turnCount: $turnCount, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    topicId,
    topicTitle,
    category,
    turnCount,
    startedAt,
    endedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TopicSession &&
          other.id == this.id &&
          other.topicId == this.topicId &&
          other.topicTitle == this.topicTitle &&
          other.category == this.category &&
          other.turnCount == this.turnCount &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt);
}

class TopicSessionsCompanion extends UpdateCompanion<TopicSession> {
  final Value<int> id;
  final Value<String> topicId;
  final Value<String> topicTitle;
  final Value<String> category;
  final Value<int> turnCount;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  const TopicSessionsCompanion({
    this.id = const Value.absent(),
    this.topicId = const Value.absent(),
    this.topicTitle = const Value.absent(),
    this.category = const Value.absent(),
    this.turnCount = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
  });
  TopicSessionsCompanion.insert({
    this.id = const Value.absent(),
    required String topicId,
    required String topicTitle,
    required String category,
    this.turnCount = const Value.absent(),
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
  }) : topicId = Value(topicId),
       topicTitle = Value(topicTitle),
       category = Value(category),
       startedAt = Value(startedAt);
  static Insertable<TopicSession> custom({
    Expression<int>? id,
    Expression<String>? topicId,
    Expression<String>? topicTitle,
    Expression<String>? category,
    Expression<int>? turnCount,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (topicId != null) 'topic_id': topicId,
      if (topicTitle != null) 'topic_title': topicTitle,
      if (category != null) 'category': category,
      if (turnCount != null) 'turn_count': turnCount,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
    });
  }

  TopicSessionsCompanion copyWith({
    Value<int>? id,
    Value<String>? topicId,
    Value<String>? topicTitle,
    Value<String>? category,
    Value<int>? turnCount,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
  }) {
    return TopicSessionsCompanion(
      id: id ?? this.id,
      topicId: topicId ?? this.topicId,
      topicTitle: topicTitle ?? this.topicTitle,
      category: category ?? this.category,
      turnCount: turnCount ?? this.turnCount,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (topicId.present) {
      map['topic_id'] = Variable<String>(topicId.value);
    }
    if (topicTitle.present) {
      map['topic_title'] = Variable<String>(topicTitle.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (turnCount.present) {
      map['turn_count'] = Variable<int>(turnCount.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TopicSessionsCompanion(')
          ..write('id: $id, ')
          ..write('topicId: $topicId, ')
          ..write('topicTitle: $topicTitle, ')
          ..write('category: $category, ')
          ..write('turnCount: $turnCount, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt')
          ..write(')'))
        .toString();
  }
}

class $MissionCompletionsTable extends MissionCompletions
    with TableInfo<$MissionCompletionsTable, MissionCompletion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MissionCompletionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _missionIdMeta = const VerificationMeta(
    'missionId',
  );
  @override
  late final GeneratedColumn<String> missionId = GeneratedColumn<String>(
    'mission_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _turnCountMeta = const VerificationMeta(
    'turnCount',
  );
  @override
  late final GeneratedColumn<int> turnCount = GeneratedColumn<int>(
    'turn_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _starsEarnedMeta = const VerificationMeta(
    'starsEarned',
  );
  @override
  late final GeneratedColumn<int> starsEarned = GeneratedColumn<int>(
    'stars_earned',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    missionId,
    turnCount,
    starsEarned,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mission_completions';
  @override
  VerificationContext validateIntegrity(
    Insertable<MissionCompletion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('mission_id')) {
      context.handle(
        _missionIdMeta,
        missionId.isAcceptableOrUnknown(data['mission_id']!, _missionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_missionIdMeta);
    }
    if (data.containsKey('turn_count')) {
      context.handle(
        _turnCountMeta,
        turnCount.isAcceptableOrUnknown(data['turn_count']!, _turnCountMeta),
      );
    } else if (isInserting) {
      context.missing(_turnCountMeta);
    }
    if (data.containsKey('stars_earned')) {
      context.handle(
        _starsEarnedMeta,
        starsEarned.isAcceptableOrUnknown(
          data['stars_earned']!,
          _starsEarnedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_starsEarnedMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MissionCompletion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MissionCompletion(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      missionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mission_id'],
      )!,
      turnCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}turn_count'],
      )!,
      starsEarned: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stars_earned'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      )!,
    );
  }

  @override
  $MissionCompletionsTable createAlias(String alias) {
    return $MissionCompletionsTable(attachedDatabase, alias);
  }
}

class MissionCompletion extends DataClass
    implements Insertable<MissionCompletion> {
  final int id;
  final String missionId;
  final int turnCount;
  final int starsEarned;
  final DateTime completedAt;
  const MissionCompletion({
    required this.id,
    required this.missionId,
    required this.turnCount,
    required this.starsEarned,
    required this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['mission_id'] = Variable<String>(missionId);
    map['turn_count'] = Variable<int>(turnCount);
    map['stars_earned'] = Variable<int>(starsEarned);
    map['completed_at'] = Variable<DateTime>(completedAt);
    return map;
  }

  MissionCompletionsCompanion toCompanion(bool nullToAbsent) {
    return MissionCompletionsCompanion(
      id: Value(id),
      missionId: Value(missionId),
      turnCount: Value(turnCount),
      starsEarned: Value(starsEarned),
      completedAt: Value(completedAt),
    );
  }

  factory MissionCompletion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MissionCompletion(
      id: serializer.fromJson<int>(json['id']),
      missionId: serializer.fromJson<String>(json['missionId']),
      turnCount: serializer.fromJson<int>(json['turnCount']),
      starsEarned: serializer.fromJson<int>(json['starsEarned']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'missionId': serializer.toJson<String>(missionId),
      'turnCount': serializer.toJson<int>(turnCount),
      'starsEarned': serializer.toJson<int>(starsEarned),
      'completedAt': serializer.toJson<DateTime>(completedAt),
    };
  }

  MissionCompletion copyWith({
    int? id,
    String? missionId,
    int? turnCount,
    int? starsEarned,
    DateTime? completedAt,
  }) => MissionCompletion(
    id: id ?? this.id,
    missionId: missionId ?? this.missionId,
    turnCount: turnCount ?? this.turnCount,
    starsEarned: starsEarned ?? this.starsEarned,
    completedAt: completedAt ?? this.completedAt,
  );
  MissionCompletion copyWithCompanion(MissionCompletionsCompanion data) {
    return MissionCompletion(
      id: data.id.present ? data.id.value : this.id,
      missionId: data.missionId.present ? data.missionId.value : this.missionId,
      turnCount: data.turnCount.present ? data.turnCount.value : this.turnCount,
      starsEarned: data.starsEarned.present
          ? data.starsEarned.value
          : this.starsEarned,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MissionCompletion(')
          ..write('id: $id, ')
          ..write('missionId: $missionId, ')
          ..write('turnCount: $turnCount, ')
          ..write('starsEarned: $starsEarned, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, missionId, turnCount, starsEarned, completedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MissionCompletion &&
          other.id == this.id &&
          other.missionId == this.missionId &&
          other.turnCount == this.turnCount &&
          other.starsEarned == this.starsEarned &&
          other.completedAt == this.completedAt);
}

class MissionCompletionsCompanion extends UpdateCompanion<MissionCompletion> {
  final Value<int> id;
  final Value<String> missionId;
  final Value<int> turnCount;
  final Value<int> starsEarned;
  final Value<DateTime> completedAt;
  const MissionCompletionsCompanion({
    this.id = const Value.absent(),
    this.missionId = const Value.absent(),
    this.turnCount = const Value.absent(),
    this.starsEarned = const Value.absent(),
    this.completedAt = const Value.absent(),
  });
  MissionCompletionsCompanion.insert({
    this.id = const Value.absent(),
    required String missionId,
    required int turnCount,
    required int starsEarned,
    required DateTime completedAt,
  }) : missionId = Value(missionId),
       turnCount = Value(turnCount),
       starsEarned = Value(starsEarned),
       completedAt = Value(completedAt);
  static Insertable<MissionCompletion> custom({
    Expression<int>? id,
    Expression<String>? missionId,
    Expression<int>? turnCount,
    Expression<int>? starsEarned,
    Expression<DateTime>? completedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (missionId != null) 'mission_id': missionId,
      if (turnCount != null) 'turn_count': turnCount,
      if (starsEarned != null) 'stars_earned': starsEarned,
      if (completedAt != null) 'completed_at': completedAt,
    });
  }

  MissionCompletionsCompanion copyWith({
    Value<int>? id,
    Value<String>? missionId,
    Value<int>? turnCount,
    Value<int>? starsEarned,
    Value<DateTime>? completedAt,
  }) {
    return MissionCompletionsCompanion(
      id: id ?? this.id,
      missionId: missionId ?? this.missionId,
      turnCount: turnCount ?? this.turnCount,
      starsEarned: starsEarned ?? this.starsEarned,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (missionId.present) {
      map['mission_id'] = Variable<String>(missionId.value);
    }
    if (turnCount.present) {
      map['turn_count'] = Variable<int>(turnCount.value);
    }
    if (starsEarned.present) {
      map['stars_earned'] = Variable<int>(starsEarned.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MissionCompletionsCompanion(')
          ..write('id: $id, ')
          ..write('missionId: $missionId, ')
          ..write('turnCount: $turnCount, ')
          ..write('starsEarned: $starsEarned, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }
}

class $VocabularyItemsTable extends VocabularyItems
    with TableInfo<$VocabularyItemsTable, VocabularyItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VocabularyItemsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _expressionMeta = const VerificationMeta(
    'expression',
  );
  @override
  late final GeneratedColumn<String> expression = GeneratedColumn<String>(
    'expression',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _meaningMeta = const VerificationMeta(
    'meaning',
  );
  @override
  late final GeneratedColumn<String> meaning = GeneratedColumn<String>(
    'meaning',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _exampleMeta = const VerificationMeta(
    'example',
  );
  @override
  late final GeneratedColumn<String> example = GeneratedColumn<String>(
    'example',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _nextReviewAtMeta = const VerificationMeta(
    'nextReviewAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextReviewAt = GeneratedColumn<DateTime>(
    'next_review_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _intervalDaysMeta = const VerificationMeta(
    'intervalDays',
  );
  @override
  late final GeneratedColumn<int> intervalDays = GeneratedColumn<int>(
    'interval_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _correctCountMeta = const VerificationMeta(
    'correctCount',
  );
  @override
  late final GeneratedColumn<int> correctCount = GeneratedColumn<int>(
    'correct_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    expression,
    meaning,
    example,
    nextReviewAt,
    intervalDays,
    correctCount,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vocabulary_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<VocabularyItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('expression')) {
      context.handle(
        _expressionMeta,
        expression.isAcceptableOrUnknown(data['expression']!, _expressionMeta),
      );
    } else if (isInserting) {
      context.missing(_expressionMeta);
    }
    if (data.containsKey('meaning')) {
      context.handle(
        _meaningMeta,
        meaning.isAcceptableOrUnknown(data['meaning']!, _meaningMeta),
      );
    }
    if (data.containsKey('example')) {
      context.handle(
        _exampleMeta,
        example.isAcceptableOrUnknown(data['example']!, _exampleMeta),
      );
    }
    if (data.containsKey('next_review_at')) {
      context.handle(
        _nextReviewAtMeta,
        nextReviewAt.isAcceptableOrUnknown(
          data['next_review_at']!,
          _nextReviewAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nextReviewAtMeta);
    }
    if (data.containsKey('interval_days')) {
      context.handle(
        _intervalDaysMeta,
        intervalDays.isAcceptableOrUnknown(
          data['interval_days']!,
          _intervalDaysMeta,
        ),
      );
    }
    if (data.containsKey('correct_count')) {
      context.handle(
        _correctCountMeta,
        correctCount.isAcceptableOrUnknown(
          data['correct_count']!,
          _correctCountMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VocabularyItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VocabularyItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      expression: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}expression'],
      )!,
      meaning: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meaning'],
      )!,
      example: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}example'],
      )!,
      nextReviewAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_review_at'],
      )!,
      intervalDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_days'],
      )!,
      correctCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}correct_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $VocabularyItemsTable createAlias(String alias) {
    return $VocabularyItemsTable(attachedDatabase, alias);
  }
}

class VocabularyItem extends DataClass implements Insertable<VocabularyItem> {
  final int id;

  /// 단어 또는 표현 (대상 언어)
  final String expression;

  /// 뜻 (모국어)
  final String meaning;

  /// 예문
  final String example;

  /// 다음 복습 시점 (Spaced Repetition)
  final DateTime nextReviewAt;

  /// 복습 간격 (일 단위)
  final int intervalDays;

  /// 연속 정답 횟수
  final int correctCount;
  final DateTime createdAt;
  const VocabularyItem({
    required this.id,
    required this.expression,
    required this.meaning,
    required this.example,
    required this.nextReviewAt,
    required this.intervalDays,
    required this.correctCount,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['expression'] = Variable<String>(expression);
    map['meaning'] = Variable<String>(meaning);
    map['example'] = Variable<String>(example);
    map['next_review_at'] = Variable<DateTime>(nextReviewAt);
    map['interval_days'] = Variable<int>(intervalDays);
    map['correct_count'] = Variable<int>(correctCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  VocabularyItemsCompanion toCompanion(bool nullToAbsent) {
    return VocabularyItemsCompanion(
      id: Value(id),
      expression: Value(expression),
      meaning: Value(meaning),
      example: Value(example),
      nextReviewAt: Value(nextReviewAt),
      intervalDays: Value(intervalDays),
      correctCount: Value(correctCount),
      createdAt: Value(createdAt),
    );
  }

  factory VocabularyItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VocabularyItem(
      id: serializer.fromJson<int>(json['id']),
      expression: serializer.fromJson<String>(json['expression']),
      meaning: serializer.fromJson<String>(json['meaning']),
      example: serializer.fromJson<String>(json['example']),
      nextReviewAt: serializer.fromJson<DateTime>(json['nextReviewAt']),
      intervalDays: serializer.fromJson<int>(json['intervalDays']),
      correctCount: serializer.fromJson<int>(json['correctCount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'expression': serializer.toJson<String>(expression),
      'meaning': serializer.toJson<String>(meaning),
      'example': serializer.toJson<String>(example),
      'nextReviewAt': serializer.toJson<DateTime>(nextReviewAt),
      'intervalDays': serializer.toJson<int>(intervalDays),
      'correctCount': serializer.toJson<int>(correctCount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  VocabularyItem copyWith({
    int? id,
    String? expression,
    String? meaning,
    String? example,
    DateTime? nextReviewAt,
    int? intervalDays,
    int? correctCount,
    DateTime? createdAt,
  }) => VocabularyItem(
    id: id ?? this.id,
    expression: expression ?? this.expression,
    meaning: meaning ?? this.meaning,
    example: example ?? this.example,
    nextReviewAt: nextReviewAt ?? this.nextReviewAt,
    intervalDays: intervalDays ?? this.intervalDays,
    correctCount: correctCount ?? this.correctCount,
    createdAt: createdAt ?? this.createdAt,
  );
  VocabularyItem copyWithCompanion(VocabularyItemsCompanion data) {
    return VocabularyItem(
      id: data.id.present ? data.id.value : this.id,
      expression: data.expression.present
          ? data.expression.value
          : this.expression,
      meaning: data.meaning.present ? data.meaning.value : this.meaning,
      example: data.example.present ? data.example.value : this.example,
      nextReviewAt: data.nextReviewAt.present
          ? data.nextReviewAt.value
          : this.nextReviewAt,
      intervalDays: data.intervalDays.present
          ? data.intervalDays.value
          : this.intervalDays,
      correctCount: data.correctCount.present
          ? data.correctCount.value
          : this.correctCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VocabularyItem(')
          ..write('id: $id, ')
          ..write('expression: $expression, ')
          ..write('meaning: $meaning, ')
          ..write('example: $example, ')
          ..write('nextReviewAt: $nextReviewAt, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('correctCount: $correctCount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    expression,
    meaning,
    example,
    nextReviewAt,
    intervalDays,
    correctCount,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VocabularyItem &&
          other.id == this.id &&
          other.expression == this.expression &&
          other.meaning == this.meaning &&
          other.example == this.example &&
          other.nextReviewAt == this.nextReviewAt &&
          other.intervalDays == this.intervalDays &&
          other.correctCount == this.correctCount &&
          other.createdAt == this.createdAt);
}

class VocabularyItemsCompanion extends UpdateCompanion<VocabularyItem> {
  final Value<int> id;
  final Value<String> expression;
  final Value<String> meaning;
  final Value<String> example;
  final Value<DateTime> nextReviewAt;
  final Value<int> intervalDays;
  final Value<int> correctCount;
  final Value<DateTime> createdAt;
  const VocabularyItemsCompanion({
    this.id = const Value.absent(),
    this.expression = const Value.absent(),
    this.meaning = const Value.absent(),
    this.example = const Value.absent(),
    this.nextReviewAt = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.correctCount = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  VocabularyItemsCompanion.insert({
    this.id = const Value.absent(),
    required String expression,
    this.meaning = const Value.absent(),
    this.example = const Value.absent(),
    required DateTime nextReviewAt,
    this.intervalDays = const Value.absent(),
    this.correctCount = const Value.absent(),
    required DateTime createdAt,
  }) : expression = Value(expression),
       nextReviewAt = Value(nextReviewAt),
       createdAt = Value(createdAt);
  static Insertable<VocabularyItem> custom({
    Expression<int>? id,
    Expression<String>? expression,
    Expression<String>? meaning,
    Expression<String>? example,
    Expression<DateTime>? nextReviewAt,
    Expression<int>? intervalDays,
    Expression<int>? correctCount,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (expression != null) 'expression': expression,
      if (meaning != null) 'meaning': meaning,
      if (example != null) 'example': example,
      if (nextReviewAt != null) 'next_review_at': nextReviewAt,
      if (intervalDays != null) 'interval_days': intervalDays,
      if (correctCount != null) 'correct_count': correctCount,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  VocabularyItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? expression,
    Value<String>? meaning,
    Value<String>? example,
    Value<DateTime>? nextReviewAt,
    Value<int>? intervalDays,
    Value<int>? correctCount,
    Value<DateTime>? createdAt,
  }) {
    return VocabularyItemsCompanion(
      id: id ?? this.id,
      expression: expression ?? this.expression,
      meaning: meaning ?? this.meaning,
      example: example ?? this.example,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      intervalDays: intervalDays ?? this.intervalDays,
      correctCount: correctCount ?? this.correctCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (expression.present) {
      map['expression'] = Variable<String>(expression.value);
    }
    if (meaning.present) {
      map['meaning'] = Variable<String>(meaning.value);
    }
    if (example.present) {
      map['example'] = Variable<String>(example.value);
    }
    if (nextReviewAt.present) {
      map['next_review_at'] = Variable<DateTime>(nextReviewAt.value);
    }
    if (intervalDays.present) {
      map['interval_days'] = Variable<int>(intervalDays.value);
    }
    if (correctCount.present) {
      map['correct_count'] = Variable<int>(correctCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VocabularyItemsCompanion(')
          ..write('id: $id, ')
          ..write('expression: $expression, ')
          ..write('meaning: $meaning, ')
          ..write('example: $example, ')
          ..write('nextReviewAt: $nextReviewAt, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('correctCount: $correctCount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ConversationsTable conversations = $ConversationsTable(this);
  late final $MessagesTable messages = $MessagesTable(this);
  late final $LevelHistoryTable levelHistory = $LevelHistoryTable(this);
  late final $DailyActivityTable dailyActivity = $DailyActivityTable(this);
  late final $TopicSessionsTable topicSessions = $TopicSessionsTable(this);
  late final $MissionCompletionsTable missionCompletions =
      $MissionCompletionsTable(this);
  late final $VocabularyItemsTable vocabularyItems = $VocabularyItemsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    conversations,
    messages,
    levelHistory,
    dailyActivity,
    topicSessions,
    missionCompletions,
    vocabularyItems,
  ];
}

typedef $$ConversationsTableCreateCompanionBuilder =
    ConversationsCompanion Function({
      required String id,
      Value<String> title,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ConversationsTableUpdateCompanionBuilder =
    ConversationsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ConversationsTableFilterComposer
    extends Composer<_$AppDatabase, $ConversationsTable> {
  $$ConversationsTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ConversationsTableOrderingComposer
    extends Composer<_$AppDatabase, $ConversationsTable> {
  $$ConversationsTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConversationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConversationsTable> {
  $$ConversationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ConversationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConversationsTable,
          Conversation,
          $$ConversationsTableFilterComposer,
          $$ConversationsTableOrderingComposer,
          $$ConversationsTableAnnotationComposer,
          $$ConversationsTableCreateCompanionBuilder,
          $$ConversationsTableUpdateCompanionBuilder,
          (
            Conversation,
            BaseReferences<_$AppDatabase, $ConversationsTable, Conversation>,
          ),
          Conversation,
          PrefetchHooks Function()
        > {
  $$ConversationsTableTableManager(_$AppDatabase db, $ConversationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConversationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConversationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConversationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConversationsCompanion(
                id: id,
                title: title,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> title = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ConversationsCompanion.insert(
                id: id,
                title: title,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ConversationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConversationsTable,
      Conversation,
      $$ConversationsTableFilterComposer,
      $$ConversationsTableOrderingComposer,
      $$ConversationsTableAnnotationComposer,
      $$ConversationsTableCreateCompanionBuilder,
      $$ConversationsTableUpdateCompanionBuilder,
      (
        Conversation,
        BaseReferences<_$AppDatabase, $ConversationsTable, Conversation>,
      ),
      Conversation,
      PrefetchHooks Function()
    >;
typedef $$MessagesTableCreateCompanionBuilder =
    MessagesCompanion Function({
      required String id,
      required String conversationId,
      required String content,
      required String role,
      required DateTime timestamp,
      Value<int> rowid,
    });
typedef $$MessagesTableUpdateCompanionBuilder =
    MessagesCompanion Function({
      Value<String> id,
      Value<String> conversationId,
      Value<String> content,
      Value<String> role,
      Value<DateTime> timestamp,
      Value<int> rowid,
    });

class $$MessagesTableFilterComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableFilterComposer({
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

  ColumnFilters<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableOrderingComposer({
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

  ColumnOrderings<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);
}

class $$MessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MessagesTable,
          Message,
          $$MessagesTableFilterComposer,
          $$MessagesTableOrderingComposer,
          $$MessagesTableAnnotationComposer,
          $$MessagesTableCreateCompanionBuilder,
          $$MessagesTableUpdateCompanionBuilder,
          (Message, BaseReferences<_$AppDatabase, $MessagesTable, Message>),
          Message,
          PrefetchHooks Function()
        > {
  $$MessagesTableTableManager(_$AppDatabase db, $MessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> conversationId = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessagesCompanion(
                id: id,
                conversationId: conversationId,
                content: content,
                role: role,
                timestamp: timestamp,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String conversationId,
                required String content,
                required String role,
                required DateTime timestamp,
                Value<int> rowid = const Value.absent(),
              }) => MessagesCompanion.insert(
                id: id,
                conversationId: conversationId,
                content: content,
                role: role,
                timestamp: timestamp,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MessagesTable,
      Message,
      $$MessagesTableFilterComposer,
      $$MessagesTableOrderingComposer,
      $$MessagesTableAnnotationComposer,
      $$MessagesTableCreateCompanionBuilder,
      $$MessagesTableUpdateCompanionBuilder,
      (Message, BaseReferences<_$AppDatabase, $MessagesTable, Message>),
      Message,
      PrefetchHooks Function()
    >;
typedef $$LevelHistoryTableCreateCompanionBuilder =
    LevelHistoryCompanion Function({
      Value<int> id,
      required int level,
      Value<String> reasoning,
      required DateTime assessedAt,
    });
typedef $$LevelHistoryTableUpdateCompanionBuilder =
    LevelHistoryCompanion Function({
      Value<int> id,
      Value<int> level,
      Value<String> reasoning,
      Value<DateTime> assessedAt,
    });

class $$LevelHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $LevelHistoryTable> {
  $$LevelHistoryTableFilterComposer({
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

  ColumnFilters<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reasoning => $composableBuilder(
    column: $table.reasoning,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get assessedAt => $composableBuilder(
    column: $table.assessedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LevelHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $LevelHistoryTable> {
  $$LevelHistoryTableOrderingComposer({
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

  ColumnOrderings<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reasoning => $composableBuilder(
    column: $table.reasoning,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get assessedAt => $composableBuilder(
    column: $table.assessedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LevelHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $LevelHistoryTable> {
  $$LevelHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<String> get reasoning =>
      $composableBuilder(column: $table.reasoning, builder: (column) => column);

  GeneratedColumn<DateTime> get assessedAt => $composableBuilder(
    column: $table.assessedAt,
    builder: (column) => column,
  );
}

class $$LevelHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LevelHistoryTable,
          LevelHistoryData,
          $$LevelHistoryTableFilterComposer,
          $$LevelHistoryTableOrderingComposer,
          $$LevelHistoryTableAnnotationComposer,
          $$LevelHistoryTableCreateCompanionBuilder,
          $$LevelHistoryTableUpdateCompanionBuilder,
          (
            LevelHistoryData,
            BaseReferences<_$AppDatabase, $LevelHistoryTable, LevelHistoryData>,
          ),
          LevelHistoryData,
          PrefetchHooks Function()
        > {
  $$LevelHistoryTableTableManager(_$AppDatabase db, $LevelHistoryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LevelHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LevelHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LevelHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> level = const Value.absent(),
                Value<String> reasoning = const Value.absent(),
                Value<DateTime> assessedAt = const Value.absent(),
              }) => LevelHistoryCompanion(
                id: id,
                level: level,
                reasoning: reasoning,
                assessedAt: assessedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int level,
                Value<String> reasoning = const Value.absent(),
                required DateTime assessedAt,
              }) => LevelHistoryCompanion.insert(
                id: id,
                level: level,
                reasoning: reasoning,
                assessedAt: assessedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LevelHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LevelHistoryTable,
      LevelHistoryData,
      $$LevelHistoryTableFilterComposer,
      $$LevelHistoryTableOrderingComposer,
      $$LevelHistoryTableAnnotationComposer,
      $$LevelHistoryTableCreateCompanionBuilder,
      $$LevelHistoryTableUpdateCompanionBuilder,
      (
        LevelHistoryData,
        BaseReferences<_$AppDatabase, $LevelHistoryTable, LevelHistoryData>,
      ),
      LevelHistoryData,
      PrefetchHooks Function()
    >;
typedef $$DailyActivityTableCreateCompanionBuilder =
    DailyActivityCompanion Function({
      required String date,
      Value<int> messageCount,
      Value<int> streakCount,
      Value<bool> goalReached,
      Value<int> rowid,
    });
typedef $$DailyActivityTableUpdateCompanionBuilder =
    DailyActivityCompanion Function({
      Value<String> date,
      Value<int> messageCount,
      Value<int> streakCount,
      Value<bool> goalReached,
      Value<int> rowid,
    });

class $$DailyActivityTableFilterComposer
    extends Composer<_$AppDatabase, $DailyActivityTable> {
  $$DailyActivityTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get messageCount => $composableBuilder(
    column: $table.messageCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get streakCount => $composableBuilder(
    column: $table.streakCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get goalReached => $composableBuilder(
    column: $table.goalReached,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyActivityTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyActivityTable> {
  $$DailyActivityTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get messageCount => $composableBuilder(
    column: $table.messageCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get streakCount => $composableBuilder(
    column: $table.streakCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get goalReached => $composableBuilder(
    column: $table.goalReached,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyActivityTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyActivityTable> {
  $$DailyActivityTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get messageCount => $composableBuilder(
    column: $table.messageCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get streakCount => $composableBuilder(
    column: $table.streakCount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get goalReached => $composableBuilder(
    column: $table.goalReached,
    builder: (column) => column,
  );
}

class $$DailyActivityTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyActivityTable,
          DailyActivityData,
          $$DailyActivityTableFilterComposer,
          $$DailyActivityTableOrderingComposer,
          $$DailyActivityTableAnnotationComposer,
          $$DailyActivityTableCreateCompanionBuilder,
          $$DailyActivityTableUpdateCompanionBuilder,
          (
            DailyActivityData,
            BaseReferences<
              _$AppDatabase,
              $DailyActivityTable,
              DailyActivityData
            >,
          ),
          DailyActivityData,
          PrefetchHooks Function()
        > {
  $$DailyActivityTableTableManager(_$AppDatabase db, $DailyActivityTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyActivityTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyActivityTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyActivityTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> date = const Value.absent(),
                Value<int> messageCount = const Value.absent(),
                Value<int> streakCount = const Value.absent(),
                Value<bool> goalReached = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyActivityCompanion(
                date: date,
                messageCount: messageCount,
                streakCount: streakCount,
                goalReached: goalReached,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String date,
                Value<int> messageCount = const Value.absent(),
                Value<int> streakCount = const Value.absent(),
                Value<bool> goalReached = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyActivityCompanion.insert(
                date: date,
                messageCount: messageCount,
                streakCount: streakCount,
                goalReached: goalReached,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyActivityTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyActivityTable,
      DailyActivityData,
      $$DailyActivityTableFilterComposer,
      $$DailyActivityTableOrderingComposer,
      $$DailyActivityTableAnnotationComposer,
      $$DailyActivityTableCreateCompanionBuilder,
      $$DailyActivityTableUpdateCompanionBuilder,
      (
        DailyActivityData,
        BaseReferences<_$AppDatabase, $DailyActivityTable, DailyActivityData>,
      ),
      DailyActivityData,
      PrefetchHooks Function()
    >;
typedef $$TopicSessionsTableCreateCompanionBuilder =
    TopicSessionsCompanion Function({
      Value<int> id,
      required String topicId,
      required String topicTitle,
      required String category,
      Value<int> turnCount,
      required DateTime startedAt,
      Value<DateTime?> endedAt,
    });
typedef $$TopicSessionsTableUpdateCompanionBuilder =
    TopicSessionsCompanion Function({
      Value<int> id,
      Value<String> topicId,
      Value<String> topicTitle,
      Value<String> category,
      Value<int> turnCount,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
    });

class $$TopicSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $TopicSessionsTable> {
  $$TopicSessionsTableFilterComposer({
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

  ColumnFilters<String> get topicId => $composableBuilder(
    column: $table.topicId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topicTitle => $composableBuilder(
    column: $table.topicTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get turnCount => $composableBuilder(
    column: $table.turnCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TopicSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TopicSessionsTable> {
  $$TopicSessionsTableOrderingComposer({
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

  ColumnOrderings<String> get topicId => $composableBuilder(
    column: $table.topicId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topicTitle => $composableBuilder(
    column: $table.topicTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get turnCount => $composableBuilder(
    column: $table.turnCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TopicSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TopicSessionsTable> {
  $$TopicSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get topicId =>
      $composableBuilder(column: $table.topicId, builder: (column) => column);

  GeneratedColumn<String> get topicTitle => $composableBuilder(
    column: $table.topicTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get turnCount =>
      $composableBuilder(column: $table.turnCount, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);
}

class $$TopicSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TopicSessionsTable,
          TopicSession,
          $$TopicSessionsTableFilterComposer,
          $$TopicSessionsTableOrderingComposer,
          $$TopicSessionsTableAnnotationComposer,
          $$TopicSessionsTableCreateCompanionBuilder,
          $$TopicSessionsTableUpdateCompanionBuilder,
          (
            TopicSession,
            BaseReferences<_$AppDatabase, $TopicSessionsTable, TopicSession>,
          ),
          TopicSession,
          PrefetchHooks Function()
        > {
  $$TopicSessionsTableTableManager(_$AppDatabase db, $TopicSessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TopicSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TopicSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TopicSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> topicId = const Value.absent(),
                Value<String> topicTitle = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<int> turnCount = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
              }) => TopicSessionsCompanion(
                id: id,
                topicId: topicId,
                topicTitle: topicTitle,
                category: category,
                turnCount: turnCount,
                startedAt: startedAt,
                endedAt: endedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String topicId,
                required String topicTitle,
                required String category,
                Value<int> turnCount = const Value.absent(),
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
              }) => TopicSessionsCompanion.insert(
                id: id,
                topicId: topicId,
                topicTitle: topicTitle,
                category: category,
                turnCount: turnCount,
                startedAt: startedAt,
                endedAt: endedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TopicSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TopicSessionsTable,
      TopicSession,
      $$TopicSessionsTableFilterComposer,
      $$TopicSessionsTableOrderingComposer,
      $$TopicSessionsTableAnnotationComposer,
      $$TopicSessionsTableCreateCompanionBuilder,
      $$TopicSessionsTableUpdateCompanionBuilder,
      (
        TopicSession,
        BaseReferences<_$AppDatabase, $TopicSessionsTable, TopicSession>,
      ),
      TopicSession,
      PrefetchHooks Function()
    >;
typedef $$MissionCompletionsTableCreateCompanionBuilder =
    MissionCompletionsCompanion Function({
      Value<int> id,
      required String missionId,
      required int turnCount,
      required int starsEarned,
      required DateTime completedAt,
    });
typedef $$MissionCompletionsTableUpdateCompanionBuilder =
    MissionCompletionsCompanion Function({
      Value<int> id,
      Value<String> missionId,
      Value<int> turnCount,
      Value<int> starsEarned,
      Value<DateTime> completedAt,
    });

class $$MissionCompletionsTableFilterComposer
    extends Composer<_$AppDatabase, $MissionCompletionsTable> {
  $$MissionCompletionsTableFilterComposer({
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

  ColumnFilters<String> get missionId => $composableBuilder(
    column: $table.missionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get turnCount => $composableBuilder(
    column: $table.turnCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get starsEarned => $composableBuilder(
    column: $table.starsEarned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MissionCompletionsTableOrderingComposer
    extends Composer<_$AppDatabase, $MissionCompletionsTable> {
  $$MissionCompletionsTableOrderingComposer({
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

  ColumnOrderings<String> get missionId => $composableBuilder(
    column: $table.missionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get turnCount => $composableBuilder(
    column: $table.turnCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get starsEarned => $composableBuilder(
    column: $table.starsEarned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MissionCompletionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MissionCompletionsTable> {
  $$MissionCompletionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get missionId =>
      $composableBuilder(column: $table.missionId, builder: (column) => column);

  GeneratedColumn<int> get turnCount =>
      $composableBuilder(column: $table.turnCount, builder: (column) => column);

  GeneratedColumn<int> get starsEarned => $composableBuilder(
    column: $table.starsEarned,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );
}

class $$MissionCompletionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MissionCompletionsTable,
          MissionCompletion,
          $$MissionCompletionsTableFilterComposer,
          $$MissionCompletionsTableOrderingComposer,
          $$MissionCompletionsTableAnnotationComposer,
          $$MissionCompletionsTableCreateCompanionBuilder,
          $$MissionCompletionsTableUpdateCompanionBuilder,
          (
            MissionCompletion,
            BaseReferences<
              _$AppDatabase,
              $MissionCompletionsTable,
              MissionCompletion
            >,
          ),
          MissionCompletion,
          PrefetchHooks Function()
        > {
  $$MissionCompletionsTableTableManager(
    _$AppDatabase db,
    $MissionCompletionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MissionCompletionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MissionCompletionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MissionCompletionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> missionId = const Value.absent(),
                Value<int> turnCount = const Value.absent(),
                Value<int> starsEarned = const Value.absent(),
                Value<DateTime> completedAt = const Value.absent(),
              }) => MissionCompletionsCompanion(
                id: id,
                missionId: missionId,
                turnCount: turnCount,
                starsEarned: starsEarned,
                completedAt: completedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String missionId,
                required int turnCount,
                required int starsEarned,
                required DateTime completedAt,
              }) => MissionCompletionsCompanion.insert(
                id: id,
                missionId: missionId,
                turnCount: turnCount,
                starsEarned: starsEarned,
                completedAt: completedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MissionCompletionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MissionCompletionsTable,
      MissionCompletion,
      $$MissionCompletionsTableFilterComposer,
      $$MissionCompletionsTableOrderingComposer,
      $$MissionCompletionsTableAnnotationComposer,
      $$MissionCompletionsTableCreateCompanionBuilder,
      $$MissionCompletionsTableUpdateCompanionBuilder,
      (
        MissionCompletion,
        BaseReferences<
          _$AppDatabase,
          $MissionCompletionsTable,
          MissionCompletion
        >,
      ),
      MissionCompletion,
      PrefetchHooks Function()
    >;
typedef $$VocabularyItemsTableCreateCompanionBuilder =
    VocabularyItemsCompanion Function({
      Value<int> id,
      required String expression,
      Value<String> meaning,
      Value<String> example,
      required DateTime nextReviewAt,
      Value<int> intervalDays,
      Value<int> correctCount,
      required DateTime createdAt,
    });
typedef $$VocabularyItemsTableUpdateCompanionBuilder =
    VocabularyItemsCompanion Function({
      Value<int> id,
      Value<String> expression,
      Value<String> meaning,
      Value<String> example,
      Value<DateTime> nextReviewAt,
      Value<int> intervalDays,
      Value<int> correctCount,
      Value<DateTime> createdAt,
    });

class $$VocabularyItemsTableFilterComposer
    extends Composer<_$AppDatabase, $VocabularyItemsTable> {
  $$VocabularyItemsTableFilterComposer({
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

  ColumnFilters<String> get expression => $composableBuilder(
    column: $table.expression,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get meaning => $composableBuilder(
    column: $table.meaning,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get example => $composableBuilder(
    column: $table.example,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextReviewAt => $composableBuilder(
    column: $table.nextReviewAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get correctCount => $composableBuilder(
    column: $table.correctCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VocabularyItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $VocabularyItemsTable> {
  $$VocabularyItemsTableOrderingComposer({
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

  ColumnOrderings<String> get expression => $composableBuilder(
    column: $table.expression,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meaning => $composableBuilder(
    column: $table.meaning,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get example => $composableBuilder(
    column: $table.example,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextReviewAt => $composableBuilder(
    column: $table.nextReviewAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get correctCount => $composableBuilder(
    column: $table.correctCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VocabularyItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $VocabularyItemsTable> {
  $$VocabularyItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get expression => $composableBuilder(
    column: $table.expression,
    builder: (column) => column,
  );

  GeneratedColumn<String> get meaning =>
      $composableBuilder(column: $table.meaning, builder: (column) => column);

  GeneratedColumn<String> get example =>
      $composableBuilder(column: $table.example, builder: (column) => column);

  GeneratedColumn<DateTime> get nextReviewAt => $composableBuilder(
    column: $table.nextReviewAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get correctCount => $composableBuilder(
    column: $table.correctCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$VocabularyItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VocabularyItemsTable,
          VocabularyItem,
          $$VocabularyItemsTableFilterComposer,
          $$VocabularyItemsTableOrderingComposer,
          $$VocabularyItemsTableAnnotationComposer,
          $$VocabularyItemsTableCreateCompanionBuilder,
          $$VocabularyItemsTableUpdateCompanionBuilder,
          (
            VocabularyItem,
            BaseReferences<
              _$AppDatabase,
              $VocabularyItemsTable,
              VocabularyItem
            >,
          ),
          VocabularyItem,
          PrefetchHooks Function()
        > {
  $$VocabularyItemsTableTableManager(
    _$AppDatabase db,
    $VocabularyItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VocabularyItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VocabularyItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VocabularyItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> expression = const Value.absent(),
                Value<String> meaning = const Value.absent(),
                Value<String> example = const Value.absent(),
                Value<DateTime> nextReviewAt = const Value.absent(),
                Value<int> intervalDays = const Value.absent(),
                Value<int> correctCount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => VocabularyItemsCompanion(
                id: id,
                expression: expression,
                meaning: meaning,
                example: example,
                nextReviewAt: nextReviewAt,
                intervalDays: intervalDays,
                correctCount: correctCount,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String expression,
                Value<String> meaning = const Value.absent(),
                Value<String> example = const Value.absent(),
                required DateTime nextReviewAt,
                Value<int> intervalDays = const Value.absent(),
                Value<int> correctCount = const Value.absent(),
                required DateTime createdAt,
              }) => VocabularyItemsCompanion.insert(
                id: id,
                expression: expression,
                meaning: meaning,
                example: example,
                nextReviewAt: nextReviewAt,
                intervalDays: intervalDays,
                correctCount: correctCount,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VocabularyItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VocabularyItemsTable,
      VocabularyItem,
      $$VocabularyItemsTableFilterComposer,
      $$VocabularyItemsTableOrderingComposer,
      $$VocabularyItemsTableAnnotationComposer,
      $$VocabularyItemsTableCreateCompanionBuilder,
      $$VocabularyItemsTableUpdateCompanionBuilder,
      (
        VocabularyItem,
        BaseReferences<_$AppDatabase, $VocabularyItemsTable, VocabularyItem>,
      ),
      VocabularyItem,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ConversationsTableTableManager get conversations =>
      $$ConversationsTableTableManager(_db, _db.conversations);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db, _db.messages);
  $$LevelHistoryTableTableManager get levelHistory =>
      $$LevelHistoryTableTableManager(_db, _db.levelHistory);
  $$DailyActivityTableTableManager get dailyActivity =>
      $$DailyActivityTableTableManager(_db, _db.dailyActivity);
  $$TopicSessionsTableTableManager get topicSessions =>
      $$TopicSessionsTableTableManager(_db, _db.topicSessions);
  $$MissionCompletionsTableTableManager get missionCompletions =>
      $$MissionCompletionsTableTableManager(_db, _db.missionCompletions);
  $$VocabularyItemsTableTableManager get vocabularyItems =>
      $$VocabularyItemsTableTableManager(_db, _db.vocabularyItems);
}
