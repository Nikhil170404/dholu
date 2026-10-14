// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $NotificationEventsTable extends NotificationEvents
    with TableInfo<$NotificationEventsTable, NotificationEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotificationEventsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pkgMeta = const VerificationMeta('pkg');
  @override
  late final GeneratedColumn<String> pkg = GeneratedColumn<String>(
    'pkg',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _appNameMeta = const VerificationMeta(
    'appName',
  );
  @override
  late final GeneratedColumn<String> appName = GeneratedColumn<String>(
    'app_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _senderMeta = const VerificationMeta('sender');
  @override
  late final GeneratedColumn<String> sender = GeneratedColumn<String>(
    'sender',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _textRedactedMeta = const VerificationMeta(
    'textRedacted',
  );
  @override
  late final GeneratedColumn<String> textRedacted = GeneratedColumn<String>(
    'text_redacted',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tsMeta = const VerificationMeta('ts');
  @override
  late final GeneratedColumn<DateTime> ts = GeneratedColumn<DateTime>(
    'ts',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
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
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<String> priority = GeneratedColumn<String>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _handledMeta = const VerificationMeta(
    'handled',
  );
  @override
  late final GeneratedColumn<bool> handled = GeneratedColumn<bool>(
    'handled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("handled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    key,
    pkg,
    appName,
    sender,
    textRedacted,
    ts,
    category,
    priority,
    action,
    summary,
    handled,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notification_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<NotificationEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('pkg')) {
      context.handle(
        _pkgMeta,
        pkg.isAcceptableOrUnknown(data['pkg']!, _pkgMeta),
      );
    } else if (isInserting) {
      context.missing(_pkgMeta);
    }
    if (data.containsKey('app_name')) {
      context.handle(
        _appNameMeta,
        appName.isAcceptableOrUnknown(data['app_name']!, _appNameMeta),
      );
    } else if (isInserting) {
      context.missing(_appNameMeta);
    }
    if (data.containsKey('sender')) {
      context.handle(
        _senderMeta,
        sender.isAcceptableOrUnknown(data['sender']!, _senderMeta),
      );
    } else if (isInserting) {
      context.missing(_senderMeta);
    }
    if (data.containsKey('text_redacted')) {
      context.handle(
        _textRedactedMeta,
        textRedacted.isAcceptableOrUnknown(
          data['text_redacted']!,
          _textRedactedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_textRedactedMeta);
    }
    if (data.containsKey('ts')) {
      context.handle(_tsMeta, ts.isAcceptableOrUnknown(data['ts']!, _tsMeta));
    } else if (isInserting) {
      context.missing(_tsMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    } else if (isInserting) {
      context.missing(_priorityMeta);
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
    } else if (isInserting) {
      context.missing(_summaryMeta);
    }
    if (data.containsKey('handled')) {
      context.handle(
        _handledMeta,
        handled.isAcceptableOrUnknown(data['handled']!, _handledMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {key, ts},
  ];
  @override
  NotificationEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotificationEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      pkg: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pkg'],
      )!,
      appName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}app_name'],
      )!,
      sender: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender'],
      )!,
      textRedacted: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_redacted'],
      )!,
      ts: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ts'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}priority'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      )!,
      handled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}handled'],
      )!,
    );
  }

  @override
  $NotificationEventsTable createAlias(String alias) {
    return $NotificationEventsTable(attachedDatabase, alias);
  }
}

class NotificationEvent extends DataClass
    implements Insertable<NotificationEvent> {
  final int id;
  final String key;
  final String pkg;
  final String appName;
  final String sender;
  final String textRedacted;
  final DateTime ts;
  final String category;
  final String priority;
  final String action;
  final String summary;
  final bool handled;
  const NotificationEvent({
    required this.id,
    required this.key,
    required this.pkg,
    required this.appName,
    required this.sender,
    required this.textRedacted,
    required this.ts,
    required this.category,
    required this.priority,
    required this.action,
    required this.summary,
    required this.handled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['key'] = Variable<String>(key);
    map['pkg'] = Variable<String>(pkg);
    map['app_name'] = Variable<String>(appName);
    map['sender'] = Variable<String>(sender);
    map['text_redacted'] = Variable<String>(textRedacted);
    map['ts'] = Variable<DateTime>(ts);
    map['category'] = Variable<String>(category);
    map['priority'] = Variable<String>(priority);
    map['action'] = Variable<String>(action);
    map['summary'] = Variable<String>(summary);
    map['handled'] = Variable<bool>(handled);
    return map;
  }

  NotificationEventsCompanion toCompanion(bool nullToAbsent) {
    return NotificationEventsCompanion(
      id: Value(id),
      key: Value(key),
      pkg: Value(pkg),
      appName: Value(appName),
      sender: Value(sender),
      textRedacted: Value(textRedacted),
      ts: Value(ts),
      category: Value(category),
      priority: Value(priority),
      action: Value(action),
      summary: Value(summary),
      handled: Value(handled),
    );
  }

  factory NotificationEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotificationEvent(
      id: serializer.fromJson<int>(json['id']),
      key: serializer.fromJson<String>(json['key']),
      pkg: serializer.fromJson<String>(json['pkg']),
      appName: serializer.fromJson<String>(json['appName']),
      sender: serializer.fromJson<String>(json['sender']),
      textRedacted: serializer.fromJson<String>(json['textRedacted']),
      ts: serializer.fromJson<DateTime>(json['ts']),
      category: serializer.fromJson<String>(json['category']),
      priority: serializer.fromJson<String>(json['priority']),
      action: serializer.fromJson<String>(json['action']),
      summary: serializer.fromJson<String>(json['summary']),
      handled: serializer.fromJson<bool>(json['handled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'key': serializer.toJson<String>(key),
      'pkg': serializer.toJson<String>(pkg),
      'appName': serializer.toJson<String>(appName),
      'sender': serializer.toJson<String>(sender),
      'textRedacted': serializer.toJson<String>(textRedacted),
      'ts': serializer.toJson<DateTime>(ts),
      'category': serializer.toJson<String>(category),
      'priority': serializer.toJson<String>(priority),
      'action': serializer.toJson<String>(action),
      'summary': serializer.toJson<String>(summary),
      'handled': serializer.toJson<bool>(handled),
    };
  }

  NotificationEvent copyWith({
    int? id,
    String? key,
    String? pkg,
    String? appName,
    String? sender,
    String? textRedacted,
    DateTime? ts,
    String? category,
    String? priority,
    String? action,
    String? summary,
    bool? handled,
  }) => NotificationEvent(
    id: id ?? this.id,
    key: key ?? this.key,
    pkg: pkg ?? this.pkg,
    appName: appName ?? this.appName,
    sender: sender ?? this.sender,
    textRedacted: textRedacted ?? this.textRedacted,
    ts: ts ?? this.ts,
    category: category ?? this.category,
    priority: priority ?? this.priority,
    action: action ?? this.action,
    summary: summary ?? this.summary,
    handled: handled ?? this.handled,
  );
  NotificationEvent copyWithCompanion(NotificationEventsCompanion data) {
    return NotificationEvent(
      id: data.id.present ? data.id.value : this.id,
      key: data.key.present ? data.key.value : this.key,
      pkg: data.pkg.present ? data.pkg.value : this.pkg,
      appName: data.appName.present ? data.appName.value : this.appName,
      sender: data.sender.present ? data.sender.value : this.sender,
      textRedacted: data.textRedacted.present
          ? data.textRedacted.value
          : this.textRedacted,
      ts: data.ts.present ? data.ts.value : this.ts,
      category: data.category.present ? data.category.value : this.category,
      priority: data.priority.present ? data.priority.value : this.priority,
      action: data.action.present ? data.action.value : this.action,
      summary: data.summary.present ? data.summary.value : this.summary,
      handled: data.handled.present ? data.handled.value : this.handled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotificationEvent(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('pkg: $pkg, ')
          ..write('appName: $appName, ')
          ..write('sender: $sender, ')
          ..write('textRedacted: $textRedacted, ')
          ..write('ts: $ts, ')
          ..write('category: $category, ')
          ..write('priority: $priority, ')
          ..write('action: $action, ')
          ..write('summary: $summary, ')
          ..write('handled: $handled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    key,
    pkg,
    appName,
    sender,
    textRedacted,
    ts,
    category,
    priority,
    action,
    summary,
    handled,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotificationEvent &&
          other.id == this.id &&
          other.key == this.key &&
          other.pkg == this.pkg &&
          other.appName == this.appName &&
          other.sender == this.sender &&
          other.textRedacted == this.textRedacted &&
          other.ts == this.ts &&
          other.category == this.category &&
          other.priority == this.priority &&
          other.action == this.action &&
          other.summary == this.summary &&
          other.handled == this.handled);
}

class NotificationEventsCompanion extends UpdateCompanion<NotificationEvent> {
  final Value<int> id;
  final Value<String> key;
  final Value<String> pkg;
  final Value<String> appName;
  final Value<String> sender;
  final Value<String> textRedacted;
  final Value<DateTime> ts;
  final Value<String> category;
  final Value<String> priority;
  final Value<String> action;
  final Value<String> summary;
  final Value<bool> handled;
  const NotificationEventsCompanion({
    this.id = const Value.absent(),
    this.key = const Value.absent(),
    this.pkg = const Value.absent(),
    this.appName = const Value.absent(),
    this.sender = const Value.absent(),
    this.textRedacted = const Value.absent(),
    this.ts = const Value.absent(),
    this.category = const Value.absent(),
    this.priority = const Value.absent(),
    this.action = const Value.absent(),
    this.summary = const Value.absent(),
    this.handled = const Value.absent(),
  });
  NotificationEventsCompanion.insert({
    this.id = const Value.absent(),
    required String key,
    required String pkg,
    required String appName,
    required String sender,
    required String textRedacted,
    required DateTime ts,
    required String category,
    required String priority,
    required String action,
    required String summary,
    this.handled = const Value.absent(),
  }) : key = Value(key),
       pkg = Value(pkg),
       appName = Value(appName),
       sender = Value(sender),
       textRedacted = Value(textRedacted),
       ts = Value(ts),
       category = Value(category),
       priority = Value(priority),
       action = Value(action),
       summary = Value(summary);
  static Insertable<NotificationEvent> custom({
    Expression<int>? id,
    Expression<String>? key,
    Expression<String>? pkg,
    Expression<String>? appName,
    Expression<String>? sender,
    Expression<String>? textRedacted,
    Expression<DateTime>? ts,
    Expression<String>? category,
    Expression<String>? priority,
    Expression<String>? action,
    Expression<String>? summary,
    Expression<bool>? handled,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (key != null) 'key': key,
      if (pkg != null) 'pkg': pkg,
      if (appName != null) 'app_name': appName,
      if (sender != null) 'sender': sender,
      if (textRedacted != null) 'text_redacted': textRedacted,
      if (ts != null) 'ts': ts,
      if (category != null) 'category': category,
      if (priority != null) 'priority': priority,
      if (action != null) 'action': action,
      if (summary != null) 'summary': summary,
      if (handled != null) 'handled': handled,
    });
  }

  NotificationEventsCompanion copyWith({
    Value<int>? id,
    Value<String>? key,
    Value<String>? pkg,
    Value<String>? appName,
    Value<String>? sender,
    Value<String>? textRedacted,
    Value<DateTime>? ts,
    Value<String>? category,
    Value<String>? priority,
    Value<String>? action,
    Value<String>? summary,
    Value<bool>? handled,
  }) {
    return NotificationEventsCompanion(
      id: id ?? this.id,
      key: key ?? this.key,
      pkg: pkg ?? this.pkg,
      appName: appName ?? this.appName,
      sender: sender ?? this.sender,
      textRedacted: textRedacted ?? this.textRedacted,
      ts: ts ?? this.ts,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      action: action ?? this.action,
      summary: summary ?? this.summary,
      handled: handled ?? this.handled,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (pkg.present) {
      map['pkg'] = Variable<String>(pkg.value);
    }
    if (appName.present) {
      map['app_name'] = Variable<String>(appName.value);
    }
    if (sender.present) {
      map['sender'] = Variable<String>(sender.value);
    }
    if (textRedacted.present) {
      map['text_redacted'] = Variable<String>(textRedacted.value);
    }
    if (ts.present) {
      map['ts'] = Variable<DateTime>(ts.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(priority.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (handled.present) {
      map['handled'] = Variable<bool>(handled.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotificationEventsCompanion(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('pkg: $pkg, ')
          ..write('appName: $appName, ')
          ..write('sender: $sender, ')
          ..write('textRedacted: $textRedacted, ')
          ..write('ts: $ts, ')
          ..write('category: $category, ')
          ..write('priority: $priority, ')
          ..write('action: $action, ')
          ..write('summary: $summary, ')
          ..write('handled: $handled')
          ..write(')'))
        .toString();
  }
}

class $AppPrefsTable extends AppPrefs with TableInfo<$AppPrefsTable, AppPref> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppPrefsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _pkgMeta = const VerificationMeta('pkg');
  @override
  late final GeneratedColumn<String> pkg = GeneratedColumn<String>(
    'pkg',
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
  static const VerificationMeta _importantMeta = const VerificationMeta(
    'important',
  );
  @override
  late final GeneratedColumn<bool> important = GeneratedColumn<bool>(
    'important',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("important" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [pkg, name, important];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_prefs';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppPref> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('pkg')) {
      context.handle(
        _pkgMeta,
        pkg.isAcceptableOrUnknown(data['pkg']!, _pkgMeta),
      );
    } else if (isInserting) {
      context.missing(_pkgMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('important')) {
      context.handle(
        _importantMeta,
        important.isAcceptableOrUnknown(data['important']!, _importantMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {pkg};
  @override
  AppPref map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppPref(
      pkg: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pkg'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      important: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}important'],
      )!,
    );
  }

  @override
  $AppPrefsTable createAlias(String alias) {
    return $AppPrefsTable(attachedDatabase, alias);
  }
}

class AppPref extends DataClass implements Insertable<AppPref> {
  final String pkg;
  final String name;
  final bool important;
  const AppPref({
    required this.pkg,
    required this.name,
    required this.important,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['pkg'] = Variable<String>(pkg);
    map['name'] = Variable<String>(name);
    map['important'] = Variable<bool>(important);
    return map;
  }

  AppPrefsCompanion toCompanion(bool nullToAbsent) {
    return AppPrefsCompanion(
      pkg: Value(pkg),
      name: Value(name),
      important: Value(important),
    );
  }

  factory AppPref.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppPref(
      pkg: serializer.fromJson<String>(json['pkg']),
      name: serializer.fromJson<String>(json['name']),
      important: serializer.fromJson<bool>(json['important']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'pkg': serializer.toJson<String>(pkg),
      'name': serializer.toJson<String>(name),
      'important': serializer.toJson<bool>(important),
    };
  }

  AppPref copyWith({String? pkg, String? name, bool? important}) => AppPref(
    pkg: pkg ?? this.pkg,
    name: name ?? this.name,
    important: important ?? this.important,
  );
  AppPref copyWithCompanion(AppPrefsCompanion data) {
    return AppPref(
      pkg: data.pkg.present ? data.pkg.value : this.pkg,
      name: data.name.present ? data.name.value : this.name,
      important: data.important.present ? data.important.value : this.important,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppPref(')
          ..write('pkg: $pkg, ')
          ..write('name: $name, ')
          ..write('important: $important')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(pkg, name, important);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppPref &&
          other.pkg == this.pkg &&
          other.name == this.name &&
          other.important == this.important);
}

class AppPrefsCompanion extends UpdateCompanion<AppPref> {
  final Value<String> pkg;
  final Value<String> name;
  final Value<bool> important;
  final Value<int> rowid;
  const AppPrefsCompanion({
    this.pkg = const Value.absent(),
    this.name = const Value.absent(),
    this.important = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppPrefsCompanion.insert({
    required String pkg,
    required String name,
    this.important = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : pkg = Value(pkg),
       name = Value(name);
  static Insertable<AppPref> custom({
    Expression<String>? pkg,
    Expression<String>? name,
    Expression<bool>? important,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (pkg != null) 'pkg': pkg,
      if (name != null) 'name': name,
      if (important != null) 'important': important,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppPrefsCompanion copyWith({
    Value<String>? pkg,
    Value<String>? name,
    Value<bool>? important,
    Value<int>? rowid,
  }) {
    return AppPrefsCompanion(
      pkg: pkg ?? this.pkg,
      name: name ?? this.name,
      important: important ?? this.important,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (pkg.present) {
      map['pkg'] = Variable<String>(pkg.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (important.present) {
      map['important'] = Variable<bool>(important.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppPrefsCompanion(')
          ..write('pkg: $pkg, ')
          ..write('name: $name, ')
          ..write('important: $important, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContactsTable extends Contacts with TableInfo<$ContactsTable, Contact> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContactsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _importanceMeta = const VerificationMeta(
    'importance',
  );
  @override
  late final GeneratedColumn<int> importance = GeneratedColumn<int>(
    'importance',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [name, importance];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contacts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Contact> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('importance')) {
      context.handle(
        _importanceMeta,
        importance.isAcceptableOrUnknown(data['importance']!, _importanceMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {name};
  @override
  Contact map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Contact(
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      importance: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}importance'],
      )!,
    );
  }

  @override
  $ContactsTable createAlias(String alias) {
    return $ContactsTable(attachedDatabase, alias);
  }
}

class Contact extends DataClass implements Insertable<Contact> {
  final String name;

  /// 0 normal, 1 important (starred / family / boss).
  final int importance;
  const Contact({required this.name, required this.importance});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['name'] = Variable<String>(name);
    map['importance'] = Variable<int>(importance);
    return map;
  }

  ContactsCompanion toCompanion(bool nullToAbsent) {
    return ContactsCompanion(name: Value(name), importance: Value(importance));
  }

  factory Contact.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Contact(
      name: serializer.fromJson<String>(json['name']),
      importance: serializer.fromJson<int>(json['importance']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'name': serializer.toJson<String>(name),
      'importance': serializer.toJson<int>(importance),
    };
  }

  Contact copyWith({String? name, int? importance}) => Contact(
    name: name ?? this.name,
    importance: importance ?? this.importance,
  );
  Contact copyWithCompanion(ContactsCompanion data) {
    return Contact(
      name: data.name.present ? data.name.value : this.name,
      importance: data.importance.present
          ? data.importance.value
          : this.importance,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Contact(')
          ..write('name: $name, ')
          ..write('importance: $importance')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(name, importance);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Contact &&
          other.name == this.name &&
          other.importance == this.importance);
}

class ContactsCompanion extends UpdateCompanion<Contact> {
  final Value<String> name;
  final Value<int> importance;
  final Value<int> rowid;
  const ContactsCompanion({
    this.name = const Value.absent(),
    this.importance = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContactsCompanion.insert({
    required String name,
    this.importance = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Contact> custom({
    Expression<String>? name,
    Expression<int>? importance,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (name != null) 'name': name,
      if (importance != null) 'importance': importance,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContactsCompanion copyWith({
    Value<String>? name,
    Value<int>? importance,
    Value<int>? rowid,
  }) {
    return ContactsCompanion(
      name: name ?? this.name,
      importance: importance ?? this.importance,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (importance.present) {
      map['importance'] = Variable<int>(importance.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContactsCompanion(')
          ..write('name: $name, ')
          ..write('importance: $importance, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FeedbacksTable extends Feedbacks
    with TableInfo<$FeedbacksTable, Feedback> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FeedbacksTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<int> eventId = GeneratedColumn<int>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _senderMeta = const VerificationMeta('sender');
  @override
  late final GeneratedColumn<String> sender = GeneratedColumn<String>(
    'sender',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userActionMeta = const VerificationMeta(
    'userAction',
  );
  @override
  late final GeneratedColumn<String> userAction = GeneratedColumn<String>(
    'user_action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tsMeta = const VerificationMeta('ts');
  @override
  late final GeneratedColumn<DateTime> ts = GeneratedColumn<DateTime>(
    'ts',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, eventId, sender, userAction, ts];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'feedbacks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Feedback> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('sender')) {
      context.handle(
        _senderMeta,
        sender.isAcceptableOrUnknown(data['sender']!, _senderMeta),
      );
    } else if (isInserting) {
      context.missing(_senderMeta);
    }
    if (data.containsKey('user_action')) {
      context.handle(
        _userActionMeta,
        userAction.isAcceptableOrUnknown(data['user_action']!, _userActionMeta),
      );
    } else if (isInserting) {
      context.missing(_userActionMeta);
    }
    if (data.containsKey('ts')) {
      context.handle(_tsMeta, ts.isAcceptableOrUnknown(data['ts']!, _tsMeta));
    } else if (isInserting) {
      context.missing(_tsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Feedback map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Feedback(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}event_id'],
      )!,
      sender: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender'],
      )!,
      userAction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_action'],
      )!,
      ts: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ts'],
      )!,
    );
  }

  @override
  $FeedbacksTable createAlias(String alias) {
    return $FeedbacksTable(attachedDatabase, alias);
  }
}

class Feedback extends DataClass implements Insertable<Feedback> {
  final int id;
  final int eventId;
  final String sender;
  final String userAction;
  final DateTime ts;
  const Feedback({
    required this.id,
    required this.eventId,
    required this.sender,
    required this.userAction,
    required this.ts,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['event_id'] = Variable<int>(eventId);
    map['sender'] = Variable<String>(sender);
    map['user_action'] = Variable<String>(userAction);
    map['ts'] = Variable<DateTime>(ts);
    return map;
  }

  FeedbacksCompanion toCompanion(bool nullToAbsent) {
    return FeedbacksCompanion(
      id: Value(id),
      eventId: Value(eventId),
      sender: Value(sender),
      userAction: Value(userAction),
      ts: Value(ts),
    );
  }

  factory Feedback.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Feedback(
      id: serializer.fromJson<int>(json['id']),
      eventId: serializer.fromJson<int>(json['eventId']),
      sender: serializer.fromJson<String>(json['sender']),
      userAction: serializer.fromJson<String>(json['userAction']),
      ts: serializer.fromJson<DateTime>(json['ts']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'eventId': serializer.toJson<int>(eventId),
      'sender': serializer.toJson<String>(sender),
      'userAction': serializer.toJson<String>(userAction),
      'ts': serializer.toJson<DateTime>(ts),
    };
  }

  Feedback copyWith({
    int? id,
    int? eventId,
    String? sender,
    String? userAction,
    DateTime? ts,
  }) => Feedback(
    id: id ?? this.id,
    eventId: eventId ?? this.eventId,
    sender: sender ?? this.sender,
    userAction: userAction ?? this.userAction,
    ts: ts ?? this.ts,
  );
  Feedback copyWithCompanion(FeedbacksCompanion data) {
    return Feedback(
      id: data.id.present ? data.id.value : this.id,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      sender: data.sender.present ? data.sender.value : this.sender,
      userAction: data.userAction.present
          ? data.userAction.value
          : this.userAction,
      ts: data.ts.present ? data.ts.value : this.ts,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Feedback(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('sender: $sender, ')
          ..write('userAction: $userAction, ')
          ..write('ts: $ts')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, eventId, sender, userAction, ts);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Feedback &&
          other.id == this.id &&
          other.eventId == this.eventId &&
          other.sender == this.sender &&
          other.userAction == this.userAction &&
          other.ts == this.ts);
}

class FeedbacksCompanion extends UpdateCompanion<Feedback> {
  final Value<int> id;
  final Value<int> eventId;
  final Value<String> sender;
  final Value<String> userAction;
  final Value<DateTime> ts;
  const FeedbacksCompanion({
    this.id = const Value.absent(),
    this.eventId = const Value.absent(),
    this.sender = const Value.absent(),
    this.userAction = const Value.absent(),
    this.ts = const Value.absent(),
  });
  FeedbacksCompanion.insert({
    this.id = const Value.absent(),
    required int eventId,
    required String sender,
    required String userAction,
    required DateTime ts,
  }) : eventId = Value(eventId),
       sender = Value(sender),
       userAction = Value(userAction),
       ts = Value(ts);
  static Insertable<Feedback> custom({
    Expression<int>? id,
    Expression<int>? eventId,
    Expression<String>? sender,
    Expression<String>? userAction,
    Expression<DateTime>? ts,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (eventId != null) 'event_id': eventId,
      if (sender != null) 'sender': sender,
      if (userAction != null) 'user_action': userAction,
      if (ts != null) 'ts': ts,
    });
  }

  FeedbacksCompanion copyWith({
    Value<int>? id,
    Value<int>? eventId,
    Value<String>? sender,
    Value<String>? userAction,
    Value<DateTime>? ts,
  }) {
    return FeedbacksCompanion(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      sender: sender ?? this.sender,
      userAction: userAction ?? this.userAction,
      ts: ts ?? this.ts,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<int>(eventId.value);
    }
    if (sender.present) {
      map['sender'] = Variable<String>(sender.value);
    }
    if (userAction.present) {
      map['user_action'] = Variable<String>(userAction.value);
    }
    if (ts.present) {
      map['ts'] = Variable<DateTime>(ts.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FeedbacksCompanion(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('sender: $sender, ')
          ..write('userAction: $userAction, ')
          ..write('ts: $ts')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $NotificationEventsTable notificationEvents =
      $NotificationEventsTable(this);
  late final $AppPrefsTable appPrefs = $AppPrefsTable(this);
  late final $ContactsTable contacts = $ContactsTable(this);
  late final $FeedbacksTable feedbacks = $FeedbacksTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    notificationEvents,
    appPrefs,
    contacts,
    feedbacks,
  ];
}

typedef $$NotificationEventsTableCreateCompanionBuilder =
    NotificationEventsCompanion Function({
      Value<int> id,
      required String key,
      required String pkg,
      required String appName,
      required String sender,
      required String textRedacted,
      required DateTime ts,
      required String category,
      required String priority,
      required String action,
      required String summary,
      Value<bool> handled,
    });
typedef $$NotificationEventsTableUpdateCompanionBuilder =
    NotificationEventsCompanion Function({
      Value<int> id,
      Value<String> key,
      Value<String> pkg,
      Value<String> appName,
      Value<String> sender,
      Value<String> textRedacted,
      Value<DateTime> ts,
      Value<String> category,
      Value<String> priority,
      Value<String> action,
      Value<String> summary,
      Value<bool> handled,
    });

class $$NotificationEventsTableFilterComposer
    extends Composer<_$AppDatabase, $NotificationEventsTable> {
  $$NotificationEventsTableFilterComposer({
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

  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pkg => $composableBuilder(
    column: $table.pkg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appName => $composableBuilder(
    column: $table.appName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sender => $composableBuilder(
    column: $table.sender,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textRedacted => $composableBuilder(
    column: $table.textRedacted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get handled => $composableBuilder(
    column: $table.handled,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotificationEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $NotificationEventsTable> {
  $$NotificationEventsTableOrderingComposer({
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

  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pkg => $composableBuilder(
    column: $table.pkg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appName => $composableBuilder(
    column: $table.appName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sender => $composableBuilder(
    column: $table.sender,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textRedacted => $composableBuilder(
    column: $table.textRedacted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get handled => $composableBuilder(
    column: $table.handled,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotificationEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotificationEventsTable> {
  $$NotificationEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get pkg =>
      $composableBuilder(column: $table.pkg, builder: (column) => column);

  GeneratedColumn<String> get appName =>
      $composableBuilder(column: $table.appName, builder: (column) => column);

  GeneratedColumn<String> get sender =>
      $composableBuilder(column: $table.sender, builder: (column) => column);

  GeneratedColumn<String> get textRedacted => $composableBuilder(
    column: $table.textRedacted,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get ts =>
      $composableBuilder(column: $table.ts, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<bool> get handled =>
      $composableBuilder(column: $table.handled, builder: (column) => column);
}

class $$NotificationEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotificationEventsTable,
          NotificationEvent,
          $$NotificationEventsTableFilterComposer,
          $$NotificationEventsTableOrderingComposer,
          $$NotificationEventsTableAnnotationComposer,
          $$NotificationEventsTableCreateCompanionBuilder,
          $$NotificationEventsTableUpdateCompanionBuilder,
          (
            NotificationEvent,
            BaseReferences<
              _$AppDatabase,
              $NotificationEventsTable,
              NotificationEvent
            >,
          ),
          NotificationEvent,
          PrefetchHooks Function()
        > {
  $$NotificationEventsTableTableManager(
    _$AppDatabase db,
    $NotificationEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotificationEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotificationEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotificationEventsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> key = const Value.absent(),
                Value<String> pkg = const Value.absent(),
                Value<String> appName = const Value.absent(),
                Value<String> sender = const Value.absent(),
                Value<String> textRedacted = const Value.absent(),
                Value<DateTime> ts = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> priority = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String> summary = const Value.absent(),
                Value<bool> handled = const Value.absent(),
              }) => NotificationEventsCompanion(
                id: id,
                key: key,
                pkg: pkg,
                appName: appName,
                sender: sender,
                textRedacted: textRedacted,
                ts: ts,
                category: category,
                priority: priority,
                action: action,
                summary: summary,
                handled: handled,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String key,
                required String pkg,
                required String appName,
                required String sender,
                required String textRedacted,
                required DateTime ts,
                required String category,
                required String priority,
                required String action,
                required String summary,
                Value<bool> handled = const Value.absent(),
              }) => NotificationEventsCompanion.insert(
                id: id,
                key: key,
                pkg: pkg,
                appName: appName,
                sender: sender,
                textRedacted: textRedacted,
                ts: ts,
                category: category,
                priority: priority,
                action: action,
                summary: summary,
                handled: handled,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NotificationEventsTable, NotificationEvent>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $NotificationEventsTable,
                    NotificationEvent
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotificationEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotificationEventsTable,
      NotificationEvent,
      $$NotificationEventsTableFilterComposer,
      $$NotificationEventsTableOrderingComposer,
      $$NotificationEventsTableAnnotationComposer,
      $$NotificationEventsTableCreateCompanionBuilder,
      $$NotificationEventsTableUpdateCompanionBuilder,
      (
        NotificationEvent,
        BaseReferences<
          _$AppDatabase,
          $NotificationEventsTable,
          NotificationEvent
        >,
      ),
      NotificationEvent,
      PrefetchHooks Function()
    >;
typedef $$AppPrefsTableCreateCompanionBuilder = AppPrefsCompanion Function({
  required String pkg,
  required String name,
  Value<bool> important,
  Value<int> rowid,
});
typedef $$AppPrefsTableUpdateCompanionBuilder = AppPrefsCompanion Function({
  Value<String> pkg,
  Value<String> name,
  Value<bool> important,
  Value<int> rowid,
});

class $$AppPrefsTableFilterComposer
    extends Composer<_$AppDatabase, $AppPrefsTable> {
  $$AppPrefsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get pkg => $composableBuilder(
    column: $table.pkg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get important => $composableBuilder(
    column: $table.important,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppPrefsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppPrefsTable> {
  $$AppPrefsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get pkg => $composableBuilder(
    column: $table.pkg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get important => $composableBuilder(
    column: $table.important,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppPrefsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppPrefsTable> {
  $$AppPrefsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get pkg =>
      $composableBuilder(column: $table.pkg, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get important =>
      $composableBuilder(column: $table.important, builder: (column) => column);
}

class $$AppPrefsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppPrefsTable,
          AppPref,
          $$AppPrefsTableFilterComposer,
          $$AppPrefsTableOrderingComposer,
          $$AppPrefsTableAnnotationComposer,
          $$AppPrefsTableCreateCompanionBuilder,
          $$AppPrefsTableUpdateCompanionBuilder,
          (AppPref, BaseReferences<_$AppDatabase, $AppPrefsTable, AppPref>),
          AppPref,
          PrefetchHooks Function()
        > {
  $$AppPrefsTableTableManager(_$AppDatabase db, $AppPrefsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppPrefsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppPrefsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppPrefsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> pkg = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> important = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppPrefsCompanion(
                pkg: pkg,
                name: name,
                important: important,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String pkg,
                required String name,
                Value<bool> important = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppPrefsCompanion.insert(
                pkg: pkg,
                name: name,
                important: important,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppPrefsTable, AppPref>(table),
                  BaseReferences<_$AppDatabase, $AppPrefsTable, AppPref>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppPrefsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppPrefsTable,
      AppPref,
      $$AppPrefsTableFilterComposer,
      $$AppPrefsTableOrderingComposer,
      $$AppPrefsTableAnnotationComposer,
      $$AppPrefsTableCreateCompanionBuilder,
      $$AppPrefsTableUpdateCompanionBuilder,
      (AppPref, BaseReferences<_$AppDatabase, $AppPrefsTable, AppPref>),
      AppPref,
      PrefetchHooks Function()
    >;
typedef $$ContactsTableCreateCompanionBuilder = ContactsCompanion Function({
  required String name,
  Value<int> importance,
  Value<int> rowid,
});
typedef $$ContactsTableUpdateCompanionBuilder = ContactsCompanion Function({
  Value<String> name,
  Value<int> importance,
  Value<int> rowid,
});

class $$ContactsTableFilterComposer
    extends Composer<_$AppDatabase, $ContactsTable> {
  $$ContactsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get importance => $composableBuilder(
    column: $table.importance,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ContactsTableOrderingComposer
    extends Composer<_$AppDatabase, $ContactsTable> {
  $$ContactsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get importance => $composableBuilder(
    column: $table.importance,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ContactsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ContactsTable> {
  $$ContactsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get importance => $composableBuilder(
    column: $table.importance,
    builder: (column) => column,
  );
}

class $$ContactsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ContactsTable,
          Contact,
          $$ContactsTableFilterComposer,
          $$ContactsTableOrderingComposer,
          $$ContactsTableAnnotationComposer,
          $$ContactsTableCreateCompanionBuilder,
          $$ContactsTableUpdateCompanionBuilder,
          (Contact, BaseReferences<_$AppDatabase, $ContactsTable, Contact>),
          Contact,
          PrefetchHooks Function()
        > {
  $$ContactsTableTableManager(_$AppDatabase db, $ContactsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContactsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContactsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContactsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> name = const Value.absent(),
                Value<int> importance = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContactsCompanion(
                name: name,
                importance: importance,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String name,
                Value<int> importance = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContactsCompanion.insert(
                name: name,
                importance: importance,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ContactsTable, Contact>(table),
                  BaseReferences<_$AppDatabase, $ContactsTable, Contact>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ContactsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ContactsTable,
      Contact,
      $$ContactsTableFilterComposer,
      $$ContactsTableOrderingComposer,
      $$ContactsTableAnnotationComposer,
      $$ContactsTableCreateCompanionBuilder,
      $$ContactsTableUpdateCompanionBuilder,
      (Contact, BaseReferences<_$AppDatabase, $ContactsTable, Contact>),
      Contact,
      PrefetchHooks Function()
    >;
typedef $$FeedbacksTableCreateCompanionBuilder = FeedbacksCompanion Function({
  Value<int> id,
  required int eventId,
  required String sender,
  required String userAction,
  required DateTime ts,
});
typedef $$FeedbacksTableUpdateCompanionBuilder = FeedbacksCompanion Function({
  Value<int> id,
  Value<int> eventId,
  Value<String> sender,
  Value<String> userAction,
  Value<DateTime> ts,
});

class $$FeedbacksTableFilterComposer
    extends Composer<_$AppDatabase, $FeedbacksTable> {
  $$FeedbacksTableFilterComposer({
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

  ColumnFilters<int> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sender => $composableBuilder(
    column: $table.sender,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userAction => $composableBuilder(
    column: $table.userAction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FeedbacksTableOrderingComposer
    extends Composer<_$AppDatabase, $FeedbacksTable> {
  $$FeedbacksTableOrderingComposer({
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

  ColumnOrderings<int> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sender => $composableBuilder(
    column: $table.sender,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userAction => $composableBuilder(
    column: $table.userAction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FeedbacksTableAnnotationComposer
    extends Composer<_$AppDatabase, $FeedbacksTable> {
  $$FeedbacksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<String> get sender =>
      $composableBuilder(column: $table.sender, builder: (column) => column);

  GeneratedColumn<String> get userAction => $composableBuilder(
    column: $table.userAction,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get ts =>
      $composableBuilder(column: $table.ts, builder: (column) => column);
}

class $$FeedbacksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FeedbacksTable,
          Feedback,
          $$FeedbacksTableFilterComposer,
          $$FeedbacksTableOrderingComposer,
          $$FeedbacksTableAnnotationComposer,
          $$FeedbacksTableCreateCompanionBuilder,
          $$FeedbacksTableUpdateCompanionBuilder,
          (Feedback, BaseReferences<_$AppDatabase, $FeedbacksTable, Feedback>),
          Feedback,
          PrefetchHooks Function()
        > {
  $$FeedbacksTableTableManager(_$AppDatabase db, $FeedbacksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FeedbacksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FeedbacksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FeedbacksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> eventId = const Value.absent(),
                Value<String> sender = const Value.absent(),
                Value<String> userAction = const Value.absent(),
                Value<DateTime> ts = const Value.absent(),
              }) => FeedbacksCompanion(
                id: id,
                eventId: eventId,
                sender: sender,
                userAction: userAction,
                ts: ts,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int eventId,
                required String sender,
                required String userAction,
                required DateTime ts,
              }) => FeedbacksCompanion.insert(
                id: id,
                eventId: eventId,
                sender: sender,
                userAction: userAction,
                ts: ts,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FeedbacksTable, Feedback>(table),
                  BaseReferences<_$AppDatabase, $FeedbacksTable, Feedback>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FeedbacksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FeedbacksTable,
      Feedback,
      $$FeedbacksTableFilterComposer,
      $$FeedbacksTableOrderingComposer,
      $$FeedbacksTableAnnotationComposer,
      $$FeedbacksTableCreateCompanionBuilder,
      $$FeedbacksTableUpdateCompanionBuilder,
      (Feedback, BaseReferences<_$AppDatabase, $FeedbacksTable, Feedback>),
      Feedback,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$NotificationEventsTableTableManager get notificationEvents =>
      $$NotificationEventsTableTableManager(_db, _db.notificationEvents);
  $$AppPrefsTableTableManager get appPrefs =>
      $$AppPrefsTableTableManager(_db, _db.appPrefs);
  $$ContactsTableTableManager get contacts =>
      $$ContactsTableTableManager(_db, _db.contacts);
  $$FeedbacksTableTableManager get feedbacks =>
      $$FeedbacksTableTableManager(_db, _db.feedbacks);
}
