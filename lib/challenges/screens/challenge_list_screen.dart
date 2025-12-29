import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/challenge_controller.dart';
import '../models/challenge_model.dart';
import 'add_edit_challenge_screen.dart';
import '../../categories/screens/category_drawer.dart';
import '../../tasks/screens/task_list_screen.dart';

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
  ChallengeController? _controller;

  @override
  void initState() {
    super.initState();
    print('🎬 ChallengeListScreen: initState for category ${widget.categoryId} (${widget.categoryName})');
    _controller = Get.find<ChallengeController>();
    _controller!.fetchForCategory(widget.categoryId);
  }
  
  @override
  void dispose() {
    super.dispose();
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
        title: Text('Challenges – ${widget.categoryName}'),
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
        if (_controller!.isLoading && !_controller!.hasChallenges) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!_controller!.hasChallenges) {
          return _emptyState(context);
        }
        return RefreshIndicator(
          onRefresh: () async => await _controller!.refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _controller!.challenges.length,
            itemBuilder: (context, index) {
              final challenge = _controller!.challenges[index];
              return _ChallengeCard(
                challenge: challenge,
                primaryColor: primary,
                onTap: () {
                  // Navigate to task list when card is tapped
                  Get.to(() => TaskListScreen(
                        challengeId: challenge.id,
                        challengeName: challenge.title,
                      ));
                },
                onEdit: () {
                  Get.to(() => AddEditChallengeScreen(
                        categoryId: widget.categoryId,
                        challenge: challenge,
                      ));
                },
                onDelete: () {
                  _confirmDelete(context, _controller!, challenge);
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
              controller.deleteChallenge(challenge.id);
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
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ChallengeCard({
    required this.challenge,
    required this.primaryColor,
    required this.onTap,
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

    // Determine status based on dates
    bool isCompleted = false;
    if (challenge.endDate != null) {
      final now = DateTime.now();
      isCompleted = now.isAfter(challenge.endDate!);
    }

    // Progress % - TODO: Calculate from tasks when STEP 4 is implemented
    final progress = 0; // Placeholder - will be: (completedTasks / totalTasks) * 100

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
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
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
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
            // Progress indicator
            Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Progress', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    Text('$progress%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor)),
                  ]),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: progress / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ]),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green.withOpacity(0.1) : primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(children: [
                  Icon(isCompleted ? Icons.check_circle : Icons.play_circle, size: 18, color: isCompleted ? Colors.green : primaryColor),
                  const SizedBox(width: 6),
                  Text(isCompleted ? 'Completed' : 'Active', style: TextStyle(color: isCompleted ? Colors.green[800] : primaryColor)),
                ]),
              ),
              const SizedBox(width: 12),
              Text(challenge.type.toUpperCase(), style: TextStyle(color: Colors.grey[600])),
            ]),
            const SizedBox(height: 12),
            // View Tasks Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.checklist, size: 20),
                label: const Text('View Tasks'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: BorderSide(color: primaryColor),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}