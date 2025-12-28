/// Challenge Model
/// Represents a structured mission under a life category.
class ChallengeModel {
  final String id;
  final String userId;
  final String categoryId;
  final String title;
  final String type; // daily, weekly, monthly, yearly, custom
  final DateTime? startDate;
  final DateTime? endDate;
  final bool completed;
  final DateTime createdAt;

  ChallengeModel({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.title,
    required this.type,
    required this.createdAt,
    this.startDate,
    this.endDate,
    this.completed = false,
  });

  factory ChallengeModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.parse(value as String);
    }

    return ChallengeModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      categoryId: json['category_id'] as String,
      title: json['title'] as String,
      type: json['type'] as String,
      startDate: parseDate(json['start_date']),
      endDate: parseDate(json['end_date']),
      completed: json['completed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'title': title,
      'type': type,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'completed': completed,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'category_id': categoryId,
      'title': title,
      'type': type,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'completed': completed,
    };
  }

  ChallengeModel copyWith({
    String? id,
    String? userId,
    String? categoryId,
    String? title,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    bool? completed,
    DateTime? createdAt,
  }) {
    return ChallengeModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Compute progress percentage based on dates (0-1 scale)
  double progressFraction({DateTime? reference}) {
    if (startDate == null || endDate == null) return 0.0;
    final now = reference ?? DateTime.now();
    if (endDate!.isBefore(startDate!)) return 0.0;
    final total = endDate!.difference(startDate!).inDays + 1;
    final elapsed = now.difference(startDate!).inDays + 1;
    final frac = elapsed / total;
    if (frac.isNaN) return 0.0;
    return frac.clamp(0.0, 1.0);
  }

  /// Status string: Active or Completed (date-based)
  String status({DateTime? reference}) {
    final now = reference ?? DateTime.now();
    if (endDate != null && now.isAfter(endDate!)) {
      return 'Completed';
    }
    return 'Active';
  }

  @override
  String toString() => 'ChallengeModel(id: $id, title: $title, type: $type)';
}