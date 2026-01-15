import 'package:json_annotation/json_annotation.dart';

part 'routine.g.dart';

@JsonSerializable()
class Routine {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  final String name;
  final String? description;
  final bool active;
  @JsonKey(name: 'preferred_time')
  final String? preferredTime;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  Routine({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.active,
    this.preferredTime,
    required this.createdAt,
  });

  factory Routine.fromJson(Map<String, dynamic> json) => _$RoutineFromJson(json);

  Map<String, dynamic> toJson() => _$RoutineToJson(this);

  Routine copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    bool? active,
    String? preferredTime,
    DateTime? createdAt,
  }) {
    return Routine(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      active: active ?? this.active,
      preferredTime: preferredTime ?? this.preferredTime,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

