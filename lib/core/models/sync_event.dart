enum SyncEventType {
  quizAttemptSubmitted,
  vocabularyActivityRecorded,
  readingPositionSet,
  profilePreferenceChanged,
}

extension SyncEventTypeName on SyncEventType {
  String get wireName => switch (this) {
    SyncEventType.quizAttemptSubmitted => 'quiz_attempt_submitted',
    SyncEventType.vocabularyActivityRecorded =>
      'vocabulary_activity_recorded',
    SyncEventType.readingPositionSet => 'reading_position_set',
    SyncEventType.profilePreferenceChanged => 'profile_preference_changed',
  };
}

class SyncEvent {
  SyncEvent({
    required this.eventId,
    required this.userId,
    required this.deviceId,
    required this.type,
    required this.aggregateId,
    required DateTime occurredAt,
    required this.schemaVersion,
    required Map<String, Object?> payload,
  }) : occurredAt = occurredAt.toUtc(),
       payload = _immutableMap(payload) {
    if (eventId.trim().isEmpty ||
        userId.trim().isEmpty ||
        deviceId.trim().isEmpty ||
        aggregateId.trim().isEmpty) {
      throw ArgumentError('Event and aggregate identifiers must not be empty.');
    }
    if (schemaVersion < 1) {
      throw ArgumentError.value(schemaVersion, 'schemaVersion');
    }
  }

  final String eventId;
  final String userId;
  final String deviceId;
  final SyncEventType type;
  final String aggregateId;
  final DateTime occurredAt;
  final int schemaVersion;
  final Map<String, Object?> payload;

  Map<String, Object?> toMap() => {
    'eventId': eventId,
    'userId': userId,
    'deviceId': deviceId,
    'type': type.wireName,
    'aggregateId': aggregateId,
    'occurredAt': occurredAt.toIso8601String(),
    'schemaVersion': schemaVersion,
    'payload': payload,
  };

  factory SyncEvent.fromMap(Map<String, Object?> map) {
    final typeName = map['type'];
    SyncEventType? eventType;
    for (final type in SyncEventType.values) {
      if (type.wireName == typeName) {
        eventType = type;
        break;
      }
    }
    final timestamp = map['occurredAt'];
    final rawPayload = map['payload'];
    if (eventType == null ||
        timestamp is! String ||
        rawPayload is! Map<String, Object?>) {
      throw const FormatException('Sync event data is invalid.');
    }

    final occurredAt = DateTime.tryParse(timestamp);
    if (occurredAt == null) {
      throw const FormatException('Sync event occurredAt is invalid.');
    }
    return SyncEvent(
      eventId: _requiredString(map, 'eventId'),
      userId: _requiredString(map, 'userId'),
      deviceId: _requiredString(map, 'deviceId'),
      type: eventType,
      aggregateId: _requiredString(map, 'aggregateId'),
      occurredAt: occurredAt,
      schemaVersion: _requiredInt(map, 'schemaVersion'),
      payload: rawPayload,
    );
  }

  static String _requiredString(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Sync event $key is missing or invalid.');
    }
    return value;
  }

  static int _requiredInt(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is! int) {
      throw FormatException('Sync event $key is missing or invalid.');
    }
    return value;
  }

  static Map<String, Object?> _immutableMap(Map<String, Object?> source) =>
      Map.unmodifiable({
        for (final entry in source.entries)
          entry.key: _immutableValue(entry.value),
      });

  static Object? _immutableValue(Object? value) {
    if (value is Map) {
      final immutable = <String, Object?>{};
      for (final entry in value.entries) {
        if (entry.key is! String) {
          throw const FormatException(
            'Sync event payload keys must be strings.',
          );
        }
        immutable[entry.key as String] = _immutableValue(entry.value);
      }
      return Map<String, Object?>.unmodifiable(immutable);
    }
    if (value is List) {
      return List<Object?>.unmodifiable(value.map(_immutableValue));
    }
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }
    throw FormatException(
      'Sync event payload contains unsupported value ${value.runtimeType}.',
    );
  }
}
