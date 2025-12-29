class TaskLogModel {
  final String taskId;
  final DateTime logDate;
  final int completedCount;

  TaskLogModel({
    required this.taskId,
    required this.logDate,
    required this.completedCount,
  });

  factory TaskLogModel.fromJson(Map<String, dynamic> json) {
    return TaskLogModel(
      taskId: json['task_id'] as String,
      logDate: DateTime.parse(json['log_date'] as String),
      completedCount: json['completed_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'task_id': taskId,
      'log_date': logDate.toIso8601String(),
      'completed_count': completedCount,
    };
  }
}
