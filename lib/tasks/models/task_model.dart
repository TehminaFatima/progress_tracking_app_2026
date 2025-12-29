class TaskModel {
  final String id;
  final String challengeId;
  final String name;
  final int targetCount;
  final DateTime createdAt;

  TaskModel({
    required this.id,
    required this.challengeId,
    required this.name,
    required this.targetCount,
    required this.createdAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      challengeId: json['challenge_id'] as String,
      name: json['name'] as String,
      targetCount: json['target_count'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'challenge_id': challengeId,
      'name': name,
      'target_count': targetCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  TaskModel copyWith({
    String? id,
    String? challengeId,
    String? name,
    int? targetCount,
    DateTime? createdAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      challengeId: challengeId ?? this.challengeId,
      name: name ?? this.name,
      targetCount: targetCount ?? this.targetCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Calculate progress percentage for a given completed count
  double progressPercentageFor(int completedCount) => targetCount > 0 ? (completedCount / targetCount) * 100 : 0.0;

  /// Check if task is completed for a given completed count
  bool isCompletedFor(int completedCount) => completedCount >= targetCount;
}
