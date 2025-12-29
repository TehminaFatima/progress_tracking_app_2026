# Step-4: Task Checkboxes & Counters

## Overview

Every task now has measurable progress through intelligent UI that adapts to the task's target count:

| Task Type | UI Component | Behavior |
|-----------|--------------|----------|
| **Single-Count (target = 1)** | ✅ Checkbox | Tap to mark complete/incomplete |
| **Multi-Count (target > 1)** | ➕➖ Counter | Increment/decrement counter up to target |

This makes progress **measurable**, enabling:
- ✅ Percentage tracking
- 🔥 Streak calculations
- 📊 Progress graphs
- ⚖️ Life balance analytics

---

## Feature Architecture

### 1. Data Model (`TaskModel`)

New fields track task completion:

```dart
class TaskModel {
  final String id;
  final String challengeId;
  final String name;
  final int targetCount;
  final int currentCount;      // NEW: Progress count (0 by default)
  final bool isCompleted;       // NEW: Manual completion flag
  final DateTime createdAt;
  final DateTime? completedAt;  // NEW: When completed
}
```

**Helper Methods:**
- `progressPercentage` - Calculate progress as percentage
- `isTaskCompleted` - True if manually completed OR currentCount >= targetCount

### 2. Task Service (`TaskService`)

New endpoints for progress updates:

#### Update Progress (Counter)
```dart
Future<TaskModel> updateTaskProgress({
  required String taskId,
  required int currentCount,
})
```
Updates the `current_count` when user taps ➕ or ➖ buttons.

#### Toggle Completion (Checkbox)
```dart
Future<TaskModel> toggleTaskCompletion({
  required String taskId,
  required bool isCompleted,
})
```
Updates `is_completed` and `completed_at` timestamp when user taps checkbox.

### 3. Controller (`TaskController`)

Methods for UI interactions:

```dart
// For single-count tasks
Future<bool> toggleTaskCompletion({ required String taskId })

// For multi-count tasks
Future<bool> incrementTaskProgress({ required String taskId })
Future<bool> decrementTaskProgress({ required String taskId })
```

### 4. UI Widget (`_TaskCard`)

Smart widget that shows:

#### Single-Count Tasks (target = 1)
```
┌─────────────────────────────┐
│ ✅ Task Name                │
│    Completed ✓              │
│ ▓▓▓▓▓▓▓▓▓▓ 100%            │
│ Done! 🎉                    │
└─────────────────────────────┘
```

Tap checkbox to toggle between completed/pending.

#### Multi-Count Tasks (target > 1)
```
┌─────────────────────────────┐
│ 🔄 Drink Water              │
│    Target: 8                │
│ ▓▓▓░░░░░░ 37.5%            │
│  [−]  3/8  [+]             │
└─────────────────────────────┘
```

Tap ➖ to decrement, ➕ to increment counter.

---

## Database Schema (`supabase_schema.sql`)

Tasks table now includes:

```sql
CREATE TABLE tasks (
    id UUID PRIMARY KEY,
    challenge_id UUID REFERENCES challenges(id),
    name TEXT NOT NULL,
    target_count INT DEFAULT 1,
    
    -- NEW FIELDS
    current_count INT DEFAULT 0,           -- Progress tracker
    is_completed BOOLEAN DEFAULT false,    -- Manual completion
    created_at TIMESTAMP,
    completed_at TIMESTAMP,                -- When marked done
    
    CONSTRAINT tasks_current_count_non_negative CHECK (current_count >= 0),
    CONSTRAINT tasks_current_count_not_exceed_target CHECK (current_count <= target_count)
);
```

---

## User Flow Examples

### Example 1: Single-Count Task (Fajr Prayer)

1. User sees task "Fajr Prayer" with ✅ checkbox
2. Taps checkbox → Icon fills with color, status becomes "Completed ✓"
3. Progress bar fills to 100%
4. Task marked as `is_completed = true`, `completed_at = NOW()`

### Example 2: Multi-Count Task (Drink Water)

1. User sees task "Drink Water" with target = 8
2. Counter shows `0/8` with ➖ and ➕ buttons
3. User drinks water, taps ➕ button
4. Counter updates: `1/8` → `2/8` → ... → `8/8`
5. Progress bar fills as counter increases
6. At `8/8`, counter buttons disabled (task auto-completed)

---

## State Management Flow

```
User Interaction (Tap Checkbox/Counter)
            ↓
    _TaskCardState Handler
            ↓
TaskController Method:
  - toggleTaskCompletion()
  - incrementTaskProgress()
  - decrementTaskProgress()
            ↓
TaskService API Call (Supabase)
            ↓
Update Supabase DB
            ↓
TaskController Updates Reactive List
            ↓
Obx() Rebuilds _TaskCard
            ↓
UI Reflects Changes
```

---

## Integration Checklist

✅ **Completed:**
- TaskModel updated with new fields
- TaskService methods added for progress updates
- TaskController methods for user interactions
- _TaskCard widget shows checkbox/counter UI
- Database schema updated with new fields
- Progress percentage calculation
- Completion status logic

**Next Steps for Full Implementation:**
- [ ] Migration: Run SQL on production Supabase
- [ ] Daily reset logic (if needed)
- [ ] Progress graphs using new data
- [ ] Streak tracking based on daily completion
- [ ] Notifications for completion milestones
- [ ] Habit statistics dashboard

---

## Code Examples

### Creating a Task

```dart
// Single-count task (Morning Prayer)
await controller.create(
  challengeId: 'challenge-123',
  name: 'Fajr Prayer',
  targetCount: 1,  // Shows checkbox
);

// Multi-count task (Drink Water)
await controller.create(
  challengeId: 'challenge-123',
  name: 'Drink Water',
  targetCount: 8,  // Shows counter
);
```

### Checking Task Progress

```dart
final task = controller.tasks.first;
print('Progress: ${task.currentCount}/${task.targetCount}');
print('Percentage: ${task.progressPercentage.toStringAsFixed(1)}%');
print('Completed: ${task.isTaskCompleted ? 'Yes' : 'No'}');
```

### Updating Progress Programmatically

```dart
// Increment counter
await controller.incrementTaskProgress(taskId: task.id);

// Decrement counter
await controller.decrementTaskProgress(taskId: task.id);

// Toggle checkbox
await controller.toggleTaskCompletion(taskId: task.id);
```

---

## Testing

### Test Case 1: Single-Count Task Checkbox
1. Create task with target = 1
2. Tap checkbox → Should toggle between checked/unchecked
3. Progress bar should show 0% or 100%
4. `is_completed` should reflect checkbox state

### Test Case 2: Multi-Count Task Counter
1. Create task with target = 5
2. Tap ➕ button 3 times → Counter should show `3/5`
3. Progress bar should show 60%
4. Tap ➖ button → Counter should show `2/5`
5. Tap ➕ until `5/5` → Counter buttons should disable

### Test Case 3: State Persistence
1. Create and update task progress
2. Refresh task list
3. Progress should persist (read from Supabase)

---

## Metrics Enabled

With checkbox/counter implementation, you can now:

1. **Calculate Completion Rate**
   ```
   % = (completed_tasks / total_tasks) × 100
   ```

2. **Track Habit Streaks**
   ```
   consecutive_days where all_tasks_completed = true
   ```

3. **Measure Daily Progress**
   ```
   avg_progress = SUM(current_count) / SUM(target_count)
   ```

4. **Generate Insights**
   - Most completed tasks
   - Most challenging tasks (lowest completion)
   - Time to completion patterns
   - Progress trends over weeks/months

---

## Files Modified

| File | Changes |
|------|---------|
| `lib/tasks/models/task_model.dart` | Added currentCount, isCompleted, completedAt, helper methods |
| `lib/tasks/services/task_service.dart` | Added updateTaskProgress(), toggleTaskCompletion() methods |
| `lib/tasks/controllers/task_controller.dart` | Added increment/decrement/toggle methods |
| `lib/tasks/screens/task_list_screen.dart` | Rewrote _TaskCard widget for checkbox/counter UI |
| `supabase_schema.sql` | Added new columns and constraints to tasks table |

---

## Next: Step-5 Features

Once checkpoint/counter is working:
1. **Daily Streaks** - Track consecutive days of completion
2. **Progress Analytics** - Charts showing completion trends
3. **Notifications** - Reminders for incomplete tasks
4. **Leaderboards** - Compare progress with goals
5. **Auto-Reset** - Reset daily counts at midnight
