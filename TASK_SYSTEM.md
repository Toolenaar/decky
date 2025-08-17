# Smart Task Queue System for Card Updates

## Overview
The Smart Task Queue System automatically manages updating MTG card data and images from Scryfall. It intelligently determines when cards need updates and processes them in the background using Firebase Functions.

## System Components

### 1. Data Models (`decky_core/lib/model/task.dart`)
- **Task**: Main task model with status tracking
- **TaskType**: Enum for different task types (currently: `cardUpdate`)
- **TaskStatus**: Enum for task progression (`pending`, `processing`, `completed`, `failed`)
- **CardUpdateTaskMetadata**: Specific metadata for card update tasks

### 2. Task Controller (`decky_core/lib/controller/task_controller.dart`)
- **shouldUpdateCard()**: Determines if a card needs updating
- **createCardUpdateTask()**: Creates new tasks with duplicate prevention
- **updateTaskStatus()**: Updates task status during processing
- **hasExistingTask()**: Prevents duplicate task creation
- **deleteCompletedTasks()**: Cleanup old completed tasks

### 3. Firebase Functions (`backend/functions/src/tasks.functions.ts`)
- **onTaskCreated**: Trigger that processes new tasks automatically
- **processTaskManually**: Manual task processing endpoint
- **cleanupCompletedTasks**: Scheduled daily cleanup of old tasks
- **processCardUpdateTask**: Core logic for updating card data and images

### 4. Search Integration (`decky_core/lib/providers/search_provider.dart`)
- Automatically checks search results for cards needing updates
- Creates tasks for cards missing images or data
- Limits task creation to prevent system overload

## How It Works

### 1. Card Update Detection
The system identifies cards needing updates based on:
- **Missing data**: No Scryfall data, missing images, or missing Scryfall ID
- **Error status**: Previous update failures
- **Age**: Data older than 1 week (configurable)

### 2. Task Creation
When a card needs updating:
1. Check if task already exists (prevent duplicates)
2. Determine update reason and requirements
3. Create task in `tasks/` Firestore collection
4. Task is automatically picked up by Firebase Function

### 3. Task Processing (Firebase Functions)
1. **onTaskCreated** trigger activates when new task is added
2. Function fetches fresh data from Scryfall API
3. Downloads and uploads images to Firebase Storage
4. Updates card document in Firestore
5. Marks task as completed and triggers cleanup

### 4. Smart Features
- **Duplicate Prevention**: Won't create tasks for cards already queued
- **Selective Image Downloads**: Skips images for scheduled refreshes if images exist
- **Error Handling**: Failed tasks are marked with error messages
- **Automatic Cleanup**: Completed tasks are removed after 7 days
- **Rate Limiting**: Search integration limits tasks created per search

## Usage Examples

### Manual Task Creation
```dart
final taskController = TaskController();
final task = await taskController.createCardUpdateTask(
  'card-uuid-here',
  reason: 'missing_images',
  skipImageDownload: false,
);
```

### Checking if Card Needs Update
```dart
final card = MtgCard.fromJson(cardData);
final needsUpdate = await taskController.shouldUpdateCard(card);
final reason = await taskController.determineUpdateReason(card);
```

### Monitoring Tasks
```dart
final pendingTasks = await taskController.getPendingTasks();
// or use stream
taskController.watchTasks(status: TaskStatus.pending)
  .listen((tasks) => print('Pending: ${tasks.length}'));
```

## Configuration

### Update Intervals
- Default refresh interval: **7 days**
- Configurable in `TaskController._updateInterval`

### Task Limits
- Max cards checked per search: **10**
- Configurable in `SearchProvider._checkAndCreateUpdateTasks()`

### Cleanup Schedule
- Completed tasks deleted after: **7 days**
- Cleanup runs daily at: **2 AM Europe/Amsterdam**

## Firebase Collections

### `tasks/`
```json
{
  "taskType": "cardUpdate",
  "status": "pending",
  "metadata": {
    "cardId": "card-uuid",
    "forceUpdate": false,
    "skipImageDownload": false,
    "reason": "missing_images"
  },
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "startedAt": "timestamp",
  "completedAt": "timestamp",
  "errorMessage": "error details if failed"
}
```

## Integration Points

### Search System
- Automatically creates tasks during card searches
- Prioritizes cards missing images or data
- Prevents overwhelming the system with too many tasks

### Elasticsearch Sync
- Card updates automatically trigger Elasticsearch reindexing
- No additional work needed for search index updates

### Admin Dashboard
- Can display task status and monitoring
- Manual task creation and management

## Benefits

1. **Automatic Maintenance**: Cards stay up-to-date without manual intervention
2. **Smart Detection**: Only updates cards that actually need it
3. **Resource Efficient**: Prevents unnecessary API calls and downloads
4. **Background Processing**: Doesn't impact user experience
5. **Error Recovery**: Failed updates can be retried
6. **Scalable**: Handles large card databases efficiently

## Future Enhancements

- Task prioritization (e.g., recently viewed cards first)
- Batch processing for improved efficiency
- Webhook support for real-time Scryfall updates
- Analytics on update patterns and success rates
- User-requested card updates
- Integration with price tracking systems