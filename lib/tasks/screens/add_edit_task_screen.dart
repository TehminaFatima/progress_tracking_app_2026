import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/task_controller.dart';
import '../models/task_model.dart';

class AddEditTaskScreen extends StatefulWidget {
  final String challengeId;
  final TaskModel? task;

  const AddEditTaskScreen({super.key, required this.challengeId, this.task});

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _targetCountCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.task?.name ?? '';
    _targetCountCtrl.text = widget.task?.targetCount.toString() ?? '1';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCountCtrl.dispose();
    super.dispose();
  }

  void _resetForm() {
    _nameCtrl.clear();
    _targetCountCtrl.text = '1';
    _formKey.currentState?.reset();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TaskController>();
    final isEdit = widget.task != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Task' : 'Add Task')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Task Name
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Task Name',
                hintText: 'e.g. Morning Prayer, Code Review, Exercise',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().length < 2) {
                  return 'Enter a task name (min 2 chars)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Target Count
            TextFormField(
              controller: _targetCountCtrl,
              decoration: const InputDecoration(
                labelText: 'Target Count',
                hintText: 'How many times per day? (e.g. 5 prayers)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Enter target count';
                }
                final count = int.tryParse(v.trim());
                if (count == null || count <= 0) {
                  return 'Must be a positive number';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Enter how many times you want to complete this task per day.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            // Submit Button
            Obx(() {
              final loading = controller.isLoading;
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: loading
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;

                          final name = _nameCtrl.text.trim();
                          final targetCount = int.parse(_targetCountCtrl.text.trim());

                          bool success;
                          if (isEdit) {
                            success = await controller.updateTask(
                              taskId: widget.task!.id,
                              name: name,
                              targetCount: targetCount,
                            );
                          } else {
                            success = await controller.create(
                              challengeId: widget.challengeId,
                              name: name,
                              targetCount: targetCount,
                            );
                          }

                          if (success) {
                            if (!isEdit) {
                              // Reset form for next task
                              _resetForm();
                            }
                            await Future.delayed(const Duration(milliseconds: 1500));
                            Get.back();
                          }
                        },
                  icon: Icon(isEdit ? Icons.save : Icons.add_task),
                  label: Text(isEdit ? 'Save Changes' : 'Add Task'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              );
            }),
          ]),
        ),
      ),
    );
  }
}
