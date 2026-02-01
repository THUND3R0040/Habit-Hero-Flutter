import 'package:json_annotation/json_annotation.dart';

part 'routine.g.dart';

// ADD this enum
enum RoutineType {
  @JsonValue('morning')
  morning,
  @JsonValue('evening')
  evening,
  @JsonValue('custom')
  custom;

  String get displayName {
    switch (this) {
      case RoutineType.morning:
        return 'Morning';
      case RoutineType.evening:
        return 'Evening';
      case RoutineType.custom:
        return 'Custom';
    }
  }
}

@JsonSerializable()
class Routine {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  final String name;
  final String? description;
  final bool active;
  @JsonKey(name: 'preferred_time')
  final String? preferredTime;  // KEEP this for backward compatibility
  @JsonKey(name: 'custom_time_text')
  final String? customTimeText;  // ADD this
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  Routine({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.active,
    this.preferredTime,
    this.customTimeText,  // ADD this
    required this.createdAt,
  });

  // ADD this getter to convert preferredTime string to enum
  RoutineType get type {
    switch (preferredTime) {
      case 'morning':
        return RoutineType.morning;
      case 'evening':
        return RoutineType.evening;
      case 'custom':
        return RoutineType.custom;
      default:
        return RoutineType.morning;
    }
  }

  factory Routine.fromJson(Map<String, dynamic> json) => _$RoutineFromJson(json);

  Map<String, dynamic> toJson() => _$RoutineToJson(this);

  Routine copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    bool? active,
    String? preferredTime,
    String? customTimeText,  // ADD this
    DateTime? createdAt,
  }) {
    return Routine(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      active: active ?? this.active,
      preferredTime: preferredTime ?? this.preferredTime,
      customTimeText: customTimeText ?? this.customTimeText,  // ADD this
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// ADD this new class for form data
class RoutineFormData {
  final String name;
  final String? description;
  final RoutineType type;
  final String? customTimeText;

  const RoutineFormData({
    required this.name,
    this.description,
    required this.type,
    this.customTimeText,
  });
}