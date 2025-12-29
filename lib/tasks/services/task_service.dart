import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_model.dart';
import '../models/task_log_model.dart';

class TaskException implements Exception {
  final String message;
  final String? code;
  TaskException({required this.message, this.code});
  @override
  String toString() => message;
}

class TaskService {
  static final TaskService _instance = TaskService._internal();
  late final SupabaseClient supabase;

  factory TaskService() => _instance;

  TaskService._internal() {
    supabase = Supabase.instance.client;
  }

  String? get currentUserId => supabase.auth.currentUser?.id;

  String _dateKey(DateTime date) => date.toUtc().toIso8601String().split('T').first;

  /// Fetch all tasks for a specific challenge
  Future<List<TaskModel>> fetchTasksForChallenge(String challengeId) async {
    try {
      print('📝 TaskService: Fetching tasks for challengeId: $challengeId');
      
        final response = await supabase
          .from('tasks')
          .select()
          .eq('challenge_id', challengeId)
          .order('created_at', ascending: false);

      print('📝 TaskService: Raw response: $response');
      final tasks = (response as List)
          .map((e) => TaskModel.fromJson(e as Map<String, dynamic>))
          .toList();
      print('📝 TaskService: Returning ${tasks.length} tasks');
      
      return tasks;
    } catch (e) {
      print('❌ TaskService: Error fetching tasks - $e');
      throw TaskException(message: 'Failed to fetch tasks: ${e.toString()}');
    }
  }

  /// Create a new task
  Future<TaskModel> createTask({
    required String challengeId,
    required String name,
    required int targetCount,
  }) async {
    try {
      print('📝 TaskService: Creating task \"$name\" for challenge $challengeId');
      
      if (name.trim().length < 2) {
        throw TaskException(message: 'Task name must be at least 2 characters');
      }
      
      if (targetCount <= 0) {
        throw TaskException(message: 'Target count must be greater than 0');
      }

      final response = await supabase
          .from('tasks')
          .insert({
            'challenge_id': challengeId,
            'name': name.trim(),
            'target_count': targetCount,
          })
          .select()
          .single();

      print('📝 TaskService: Task created successfully');
      return TaskModel.fromJson(response);
    } catch (e) {
      print('❌ TaskService: Error creating task - $e');
      throw TaskException(message: 'Failed to create task: ${e.toString()}');
    }
  }

  /// Update an existing task
  Future<TaskModel> updateTask({
    required String taskId,
    required String name,
    required int targetCount,
  }) async {
    try {
      print('📝 TaskService: Updating task $taskId');
      
      if (name.trim().length < 2) {
        throw TaskException(message: 'Task name must be at least 2 characters');
      }
      
      if (targetCount <= 0) {
        throw TaskException(message: 'Target count must be greater than 0');
      }

      final response = await supabase
          .from('tasks')
          .update({
            'name': name.trim(),
            'target_count': targetCount,
          })
          .eq('id', taskId)
          .select()
          .single();

      print('📝 TaskService: Task updated successfully');
      return TaskModel.fromJson(response);
    } catch (e) {
      print('❌ TaskService: Error updating task - $e');
      throw TaskException(message: 'Failed to update task: ${e.toString()}');
    }
  }

  /// Fetch today's logs for a list of task ids
  Future<Map<String, TaskLogModel>> fetchTodayLogs({
    required List<String> taskIds,
    required DateTime logDate,
  }) async {
    if (taskIds.isEmpty) return {};

    try {
      final dateKey = _dateKey(logDate);
      print('📝 TaskService: Fetching logs for ${taskIds.length} tasks on $dateKey');

        final response = await supabase
          .from('task_logs')
          .select('task_id, log_date, completed_count')
          .inFilter('task_id', taskIds)
          .eq('log_date', dateKey);

      final logs = <String, TaskLogModel>{};
      for (final raw in response as List) {
        final log = TaskLogModel.fromJson(raw as Map<String, dynamic>);
        logs[log.taskId] = log;
      }
      print('📝 TaskService: Loaded ${logs.length} logs for $dateKey');
      return logs;
    } catch (e) {
      print('❌ TaskService: Error fetching task logs - $e');
      throw TaskException(message: 'Failed to fetch task logs: ${e.toString()}');
    }
  }

  /// Upsert today's log for a task
  Future<TaskLogModel> upsertTaskLog({
    required String taskId,
    required DateTime logDate,
    required int newCount,
  }) async {
    if (newCount < 0) {
      throw TaskException(message: 'Completed count cannot be negative');
    }

    try {
      final todayString = logDate.toUtc().toIso8601String().split('T').first;
      print('📝 TaskService: Upserting log for task $taskId on $todayString to $newCount');

      final response = await supabase.from('task_logs').upsert({
        'task_id': taskId,
        'log_date': todayString,
        'completed_count': newCount,
      }, onConflict: 'task_id,log_date').select().single();

      return TaskLogModel.fromJson(response);
    } catch (e) {
      print('❌ TaskService: Error upserting task log - $e');
      throw TaskException(message: 'Failed to update task log: ${e.toString()}');
    }
  }

  /// Delete a task
  Future<void> deleteTask(String taskId) async {
    try {
      print('📝 TaskService: Deleting task $taskId');
      
        await supabase
          .from('tasks')
          .delete()
          .eq('id', taskId);

      print('📝 TaskService: Task deleted successfully');
    } catch (e) {
      print('❌ TaskService: Error deleting task - $e');
      throw TaskException(message: 'Failed to delete task: ${e.toString()}');
    }
  }
}
