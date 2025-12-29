import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';

class TaskController extends GetxController {
  final TaskService _service = TaskService();

  final RxList<TaskModel> _tasks = <TaskModel>[].obs;
  final RxMap<String, int> _todayCounts = <String, int>{}.obs;
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;
  String? _currentChallengeId;
  DateTime _today = DateTime.now();

  // Cache for fetched tasks per challenge
  final Map<String, List<TaskModel>> _cache = {};

  String? get currentChallengeId => _currentChallengeId;
  List<TaskModel> get tasks => _tasks;
  Map<String, int> get todayCounts => _todayCounts;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  bool get hasTasks => _tasks.isNotEmpty;

  int completedCountFor(String taskId) => _todayCounts[taskId] ?? 0;
  bool isTaskCompleted(TaskModel task) => task.isCompletedFor(completedCountFor(task.id));
  double progressFor(TaskModel task) => task.progressPercentageFor(completedCountFor(task.id));

  /// Fetch tasks for a specific challenge
  Future<void> fetchForChallenge(String challengeId) async {
    try {
      print('🎯 TaskController: Fetching tasks for challenge $challengeId');
      print('🎯 TaskController: Previous challenge was: $_currentChallengeId');

      // Defer all state changes until after the current frame is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _isLoading.value = true;
      });

      // Set current challenge FIRST
      _currentChallengeId = challengeId;

      // Clear the tasks list after frame is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print('🎯 TaskController: Clearing ${_tasks.length} existing tasks from display');
        _tasks.clear();
        _todayCounts.clear();
        _today = DateTime.now();
        _errorMessage.value = '';
      });

      // Check cache first
      if (_cache.containsKey(challengeId)) {
        print('🎯 TaskController: Using cached tasks (${_cache[challengeId]!.length} items)');
        final cachedTasks = _cache[challengeId]!;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _tasks.assignAll(cachedTasks);
          print('🎯 TaskController: Now displaying ${_tasks.length} tasks for challenge $_currentChallengeId');
        });
        await _loadTodayLogsForTasks(cachedTasks);
        WidgetsBinding.instance.addPostFrameCallback((_) => _isLoading.value = false);
      } else {
        print('🎯 TaskController: No cache found, fetching from API...');
        final list = await _service.fetchTasksForChallenge(challengeId);
        print('🎯 TaskController: Fetched ${list.length} tasks from API');
        _cache[challengeId] = list;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _tasks.assignAll(list);
          print('🎯 TaskController: Now displaying ${_tasks.length} tasks for challenge $_currentChallengeId');
        });
        await _loadTodayLogsForTasks(list);
        WidgetsBinding.instance.addPostFrameCallback((_) => _isLoading.value = false);
      }
    } on TaskException catch (e) {
      print('❌ TaskController: Exception - ${e.message}');
      _errorMessage.value = e.message;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Get.context != null) {
          Get.snackbar('Error', e.message, snackPosition: SnackPosition.BOTTOM);
        }
      });
    } catch (e) {
      print('❌ TaskController: Error - $e');
      _errorMessage.value = 'Failed to load tasks: ${e.toString()}';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Get.context != null) {
          Get.snackbar('Error', 'Failed to load tasks: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
        }
      });
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _isLoading.value = false;
      });
    }
  }

  Future<void> _loadTodayLogsForTasks(List<TaskModel> tasks) async {
    try {
      final ids = tasks.map((t) => t.id).toList();
      final logs = await _service.fetchTodayLogs(taskIds: ids, logDate: _today);

      final next = <String, int>{};
      for (final task in tasks) {
        next[task.id] = logs[task.id]?.completedCount ?? 0;
      }
      _todayCounts.assignAll(next);
    } catch (e) {
      print('❌ TaskController: Error loading logs - $e');
      _errorMessage.value = "Failed to load today's progress";
    }
  }

  /// Create a new task
  Future<bool> create({
    required String challengeId,
    required String name,
    required int targetCount,
  }) async {
    try {
      print('🎯 TaskController: Creating task for challenge: $challengeId, current challenge: $_currentChallengeId');
      _isLoading.value = true;
      _errorMessage.value = '';
      
      final created = await _service.createTask(
        challengeId: challengeId,
        name: name,
        targetCount: targetCount,
      );

      // Only add to current list if we're viewing the same challenge
      if (_currentChallengeId == challengeId) {
        _tasks.insert(0, created);
        _todayCounts[created.id] = 0;
      }

      // Always update cache for the correct challenge
      if (_cache.containsKey(challengeId)) {
        _cache[challengeId]!.insert(0, created);
      } else {
        _cache[challengeId] = [created];
      }

      print('🎯 TaskController: Task added to cache for challenge $challengeId');
      Get.snackbar(
        '✓ Task Created',
        '"$name" has been added successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
      );
      return true;
    } on TaskException catch (e) {
      print('❌ TaskController: TaskException - ${e.message}');
      Get.snackbar('Error', e.message, snackPosition: SnackPosition.BOTTOM);
      return false;
    } catch (e) {
      print('❌ TaskController: Error creating task - $e');
      Get.snackbar('Error', 'Failed to create task: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Update an existing task
  Future<bool> updateTask({
    required String taskId,
    required String name,
    required int targetCount,
  }) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';
      
      final updated = await _service.updateTask(
        taskId: taskId,
        name: name,
        targetCount: targetCount,
      );

      // Update in current list
      final idx = _tasks.indexWhere((t) => t.id == taskId);
      if (idx != -1) {
        _tasks[idx] = updated;
      }

      // Update in cache
      if (_currentChallengeId != null && _cache.containsKey(_currentChallengeId)) {
        final cacheIdx = _cache[_currentChallengeId]!.indexWhere((t) => t.id == taskId);
        if (cacheIdx != -1) {
          _cache[_currentChallengeId]![cacheIdx] = updated;
        }
      }

      Get.snackbar(
        '✓ Task Updated',
        '"$name" has been updated',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue.withOpacity(0.9),
        colorText: Colors.white,
      );
      return true;
    } on TaskException catch (e) {
      Get.snackbar('Error', e.message, snackPosition: SnackPosition.BOTTOM);
      return false;
    } catch (e) {
      Get.snackbar('Error', 'Failed to update task: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Delete a task
  Future<void> deleteTask(String taskId) async {
    try {
      _isLoading.value = true;
      await _service.deleteTask(taskId);

      // Remove from current list
      _tasks.removeWhere((t) => t.id == taskId);

      // Remove from cache
      if (_currentChallengeId != null && _cache.containsKey(_currentChallengeId)) {
        _cache[_currentChallengeId]!.removeWhere((t) => t.id == taskId);
      }

      Get.snackbar(
        '✓ Task Deleted',
        'Task has been removed',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withOpacity(0.9),
        colorText: Colors.white,
      );
    } on TaskException catch (e) {
      Get.snackbar('Error', e.message, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete task: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
    } finally {
      _isLoading.value = false;
    }
  }

  /// Toggle task completion status (for single-count tasks; uses task_logs)
  Future<bool> toggleTaskCompletion({
    required String taskId,
  }) async {
    try {
      final current = completedCountFor(taskId);
      final newCount = current == 0 ? 1 : 0;
      
      print('🎯 TaskController: Toggling completion for task $taskId to count $newCount');
      
      await _service.upsertTaskLog(
        taskId: taskId,
        logDate: _today,
        newCount: newCount,
      );

      _todayCounts[taskId] = newCount;
      return true;
    } catch (e) {
      print('❌ TaskController: Error toggling completion - $e');
      Get.snackbar('Error', 'Failed to update task: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
      return false;
    }
  }

  /// Update task progress by incrementing counter (uses task_logs)
  Future<bool> incrementTaskProgress({
    required String taskId,
  }) async {
    try {
      final task = _tasks.firstWhere((t) => t.id == taskId);
      final current = completedCountFor(taskId);
      final newCount = (current + 1).clamp(0, task.targetCount);
      
      print('🎯 TaskController: Incrementing task $taskId to $newCount/${task.targetCount}');
      
      await _service.upsertTaskLog(
        taskId: taskId,
        logDate: _today,
        newCount: newCount,
      );

      _todayCounts[taskId] = newCount;

      return true;
    } catch (e) {
      print('❌ TaskController: Error incrementing progress - $e');
      Get.snackbar('Error', 'Failed to update task: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
      return false;
    }
  }

  /// Update task progress by decrementing counter (uses task_logs)
  Future<bool> decrementTaskProgress({
    required String taskId,
  }) async {
    try {
      final task = _tasks.firstWhere((t) => t.id == taskId);
      final current = completedCountFor(taskId);
      final newCount = (current - 1).clamp(0, task.targetCount);
      
      print('🎯 TaskController: Decrementing task $taskId to $newCount/${task.targetCount}');
      
      await _service.upsertTaskLog(
        taskId: taskId,
        logDate: _today,
        newCount: newCount,
      );

      _todayCounts[taskId] = newCount;

      return true;
    } catch (e) {
      print('❌ TaskController: Error decrementing progress - $e');
      Get.snackbar('Error', 'Failed to update task: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
      return false;
    }
  }

  /// Refresh tasks for current challenge
  Future<void> refresh() async {
    if (_currentChallengeId != null) {
      // Clear cache and refetch
      _cache.remove(_currentChallengeId);
      _todayCounts.clear();
      _today = DateTime.now();
      await fetchForChallenge(_currentChallengeId!);
    }
  }
}
