import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/challenge_controller.dart';
import '../models/challenge_model.dart';
import 'add_edit_challenge_screen.dart';

class ChallengeListScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const ChallengeListScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<ChallengeListScreen> createState() => _ChallengeListScreenState();
}

class _ChallengeListScreenState extends State<ChallengeListScreen> {
  late ChallengeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(ChallengeController());
    _controller.fetchForCategory(widget.categoryId);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text('Challenges – ${widget.categoryName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.refresh(),
          )
        ],
      ),
      body: Obx(() {
        if (_controller.isLoading && !_controller.hasChallenges) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!_controller.hasChallenges) {
          return _emptyState(context);
        }
        return RefreshIndicator(
          onRefresh: () => _controller.refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _controller.challenges.length,
            itemBuilder: (context, index) {
              final challenge = _controller.challenges[index];
              return _ChallengeCard(
                challenge: challenge,
                primaryColor: primary,
                onEdit: () {
                  Get.to(() => AddEditChallengeScreen(
                        categoryId: widget.categoryId,
                        challenge: challenge,
                      ));
                },
                onDelete: () {
                  _confirmDelete(context, _controller, challenge);
                },
              );
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Get.to(() => AddEditChallengeScreen(categoryId: widget.categoryId));
        },
        icon: const Icon(Icons.add_task),
        label: const Text('Create Challenge'),
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
            Icon(Icons.flag_outlined, size: 120, color: Colors.grey[300]),
            const SizedBox(height: 24),
            Text(
              'No Challenges Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create your first challenge to drive disciplined progress in ${widget.categoryName}.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Get.to(() => AddEditChallengeScreen(categoryId: widget.categoryId)),
              icon: const Icon(Icons.add_task),
              label: const Text('Create Challenge'),
            )
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ChallengeController controller, ChallengeModel challenge) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Challenge'),
        content: const Text('Delete this challenge? All related tasks/logs will be removed.'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              controller.delete(challenge.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          )
        ],
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final ChallengeModel challenge;
  final Color primaryColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ChallengeCard({
    required this.challenge,
    required this.primaryColor,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    String durationText() {
      if (challenge.startDate == null || challenge.endDate == null) return 'No dates';
      final s = challenge.startDate!;
      final e = challenge.endDate!;
      String fmt(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      return '${fmt(s)} → ${fmt(e)}';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Checkbox(
              value: challenge.completed,
              onChanged: (value) {
                final controller = Get.find<ChallengeController>();
                controller.toggleCompletion(challenge.id, challenge.completed);
              },
              activeColor: primaryColor,
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.flag, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  challenge.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    decoration: challenge.completed ? TextDecoration.lineThrough : null,
                    color: challenge.completed ? Colors.grey[600] : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(durationText(), style: TextStyle(color: Colors.grey[600])),
              ]),
            ),
            PopupMenuButton<String>(
              onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 12), Text('Edit')])),
                PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 20, color: Colors.red), SizedBox(width: 12), Text('Delete', style: TextStyle(color: Colors.red))])),
              ],
            )
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: challenge.completed ? Colors.green.withOpacity(0.1) : primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(children: [
                Icon(challenge.completed ? Icons.check_circle : Icons.play_circle, size: 18, color: challenge.completed ? Colors.green : primaryColor),
                const SizedBox(width: 6),
                Text(challenge.completed ? 'Completed' : 'Active', style: TextStyle(color: challenge.completed ? Colors.green[800] : primaryColor)),
              ]),
            ),
            const SizedBox(width: 12),
            Text(challenge.type.toUpperCase(), style: TextStyle(color: Colors.grey[600])),
          ])
        ]),
      ),
    );
  }
}