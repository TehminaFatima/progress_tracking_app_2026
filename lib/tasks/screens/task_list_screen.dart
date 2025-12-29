import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/task_controller.dart';
import '../models/task_model.dart';
import 'add_edit_task_screen.dart';
import '../../categories/screens/category_drawer.dart';

class TaskListScreen extends StatefulWidget {
  final String challengeId;
  final String challengeName;

  const TaskListScreen({
    super.key,
    required this.challengeId,
    required this.challengeName,
  });

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  TaskController? _controller;

  @override
  void initState() {
    super.initState();
    print('🎬 TaskListScreen: initState for challenge ${widget.challengeId} (${widget.challengeName})');
    _controller = Get.find<TaskController>();
    _controller!.fetchForChallenge(widget.challengeId);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    if (_controller == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Tasks – ${widget.challengeName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _controller!.refresh();
            },
          )
        ],
      ),
      drawer: const CategoryDrawer(),
      body: Obx(() {
        if (_controller!.isLoading && !_controller!.hasTasks) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!_controller!.hasTasks) {
          return _emptyState(context);
        }
        return RefreshIndicator(
          onRefresh: () async => await _controller!.refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _controller!.tasks.length,
            itemBuilder: (context, index) {
              final task = _controller!.tasks[index];
              return _TaskCard(
                task: task,
                primaryColor: primary,
                onEdit: () {
                  Get.to(() => AddEditTaskScreen(
                        challengeId: widget.challengeId,
                        task: task,
                      ));
                },
                onDelete: () {
                  _confirmDelete(context, _controller!, task);
                },
              );
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Get.to(() => AddEditTaskScreen(challengeId: widget.challengeId));
        },
        icon: const Icon(Icons.add_task),
        label: const Text('Add Task'),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.checklist_outlined,
              size: 120,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 24),
            Text(
              'No Tasks Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add tasks to track your daily actions in this challenge!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Get.to(() => AddEditTaskScreen(challengeId: widget.challengeId)),
              icon: const Icon(Icons.add),
              label: const Text('Add First Task'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, TaskController controller, TaskModel task) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.name}"?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteTask(task.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          )
        ],
      ),
    );
  }
}

class _TaskCard extends StatefulWidget {
  final TaskModel task;
  final Color primaryColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TaskCard({
    required this.task,
    required this.primaryColor,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<_TaskCard> {
  late TaskController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<TaskController>();
  }

  void _handleCheckboxToggle() async {
    final success = await _controller.toggleTaskCompletion(taskId: widget.task.id);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update task')),
      );
    }
  }

  void _handleIncrement() async {
    final success = await _controller.incrementTaskProgress(taskId: widget.task.id);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update task')),
      );
    }
  }

  void _handleDecrement() async {
    final success = await _controller.decrementTaskProgress(taskId: widget.task.id);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update task')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSingleCount = widget.task.targetCount == 1;
    
    return Obx(() {
      // Get updated task from controller
      final updatedTask = _controller.tasks.firstWhere(
        (t) => t.id == widget.task.id,
        orElse: () => widget.task,
      );

      final completedCount = _controller.completedCountFor(widget.task.id);
      final isCompleted = _controller.isTaskCompleted(updatedTask);
      final progressPercent = _controller.progressFor(updatedTask);
      
      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with title and menu
              Row(
                children: [
                  // Checkbox/Counter indicator
                  if (isSingleCount)
                    GestureDetector(
                      onTap: _handleCheckboxToggle,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? widget.primaryColor
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isCompleted ? Icons.check_box : Icons.check_box_outline_blank,
                          color: isCompleted ? Colors.white : Colors.grey[600],
                          size: 28,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.repeat,
                        color: widget.primaryColor,
                        size: 28,
                      ),
                    ),
                  const SizedBox(width: 16),
                  // Title and target
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          updatedTask.name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                            color: isCompleted ? Colors.grey[500] : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (isSingleCount)
                          Text(
                            isCompleted ? 'Completed ✓' : 'Pending',
                            style: TextStyle(
                              color: isCompleted ? Colors.green : Colors.grey[600],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        else
                          Text(
                            'Target: ${updatedTask.targetCount}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (v) => v == 'edit' ? widget.onEdit() : widget.onDelete(),
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 12),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 12),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 16),
              
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progressPercent / 100,
                  minHeight: 6,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCompleted ? Colors.green : widget.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Counter or checkbox controls
              if (isSingleCount)
                Center(
                  child: Text(
                    isCompleted ? 'Done! 🎉' : 'Tap checkbox to mark complete',
                    style: TextStyle(
                      color: isCompleted ? Colors.green : Colors.grey[600],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Decrement button
                    ElevatedButton.icon(
                      onPressed: completedCount > 0 ? _handleDecrement : null,
                      icon: const Icon(Icons.remove),
                      label: const Text('−'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    // Counter display
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: widget.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$completedCount',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: widget.primaryColor,
                            ),
                          ),
                          Text(
                            '/ ${updatedTask.targetCount}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Increment button
                    ElevatedButton.icon(
                      onPressed: completedCount < updatedTask.targetCount
                          ? _handleIncrement
                          : null,
                      icon: const Icon(Icons.add),
                      label: const Text('+'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      );
    });
  }
}
