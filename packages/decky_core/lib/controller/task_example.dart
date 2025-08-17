import 'package:cloud_firestore/cloud_firestore.dart';
import 'task_controller.dart';
import '../model/task.dart';
import '../model/mtg/mtg_card.dart';

class TaskExample {
  final TaskController _taskController = TaskController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> demonstrateTaskSystem() async {
    print('=== Decky Smart Task Queue System Demo ===\n');

    // 1. Show how to check if a card needs updating
    print('1. Checking if cards need updating...');
    await _demonstrateCardUpdateCheck();

    // 2. Show how to create tasks
    print('\n2. Creating update tasks...');
    await _demonstrateTaskCreation();

    // 3. Show task monitoring
    print('\n3. Monitoring tasks...');
    await _demonstrateTaskMonitoring();

    print('\n=== Demo Complete ===');
  }

  Future<void> _demonstrateCardUpdateCheck() async {
    // Fetch a few cards from the database
    final cardsQuery = await _firestore
        .collection('cards')
        .limit(3)
        .get();

    for (final doc in cardsQuery.docs) {
      try {
        final card = MtgCard.fromJson({...doc.data(), 'uuid': doc.id});
        final needsUpdate = await _taskController.shouldUpdateCard(card);
        final reason = await _taskController.determineUpdateReason(card);
        
        print('  Card: ${card.name}');
        print('    Needs Update: $needsUpdate');
        print('    Reason: $reason');
        print('    Has Images: ${card.firebaseImageUris != null}');
        print('    Has Scryfall Data: ${card.scryfallData != null}');
        print('    Last Updated: ${card.updatedAt?.toDate() ?? 'Never'}');
        print('    ');
      } catch (e) {
        print('  Error checking card ${doc.id}: $e');
      }
    }
  }

  Future<void> _demonstrateTaskCreation() async {
    // Create a sample task for a card that needs updating
    const sampleCardId = 'sample-card-id';
    
    print('  Creating task for card: $sampleCardId');
    
    try {
      final task = await _taskController.createCardUpdateTask(
        sampleCardId,
        reason: 'demo_task',
        skipImageDownload: false,
      );
      
      if (task != null) {
        print('    ✅ Task created successfully: ${task.id}');
        print('    Task Type: ${task.taskType.name}');
        print('    Status: ${task.status.name}');
        print('    Metadata: ${task.metadata}');
      } else {
        print('    ⚠️ Task not created (may already exist)');
      }
    } catch (e) {
      print('    ❌ Error creating task: $e');
    }
  }

  Future<void> _demonstrateTaskMonitoring() async {
    // Show pending tasks
    print('  Fetching pending tasks...');
    
    try {
      final pendingTasks = await _taskController.getPendingTasks(limit: 5);
      
      if (pendingTasks.isEmpty) {
        print('    No pending tasks found');
      } else {
        print('    Found ${pendingTasks.length} pending tasks:');
        for (final task in pendingTasks) {
          final metadata = CardUpdateTaskMetadata.fromJson(task.metadata);
          print('      - Task ${task.id}:');
          print('        Card ID: ${metadata.cardId}');
          print('        Reason: ${metadata.reason}');
          print('        Created: ${task.createdAt?.toDate() ?? 'Unknown'}');
          print('        Status: ${task.status.name}');
        }
      }
    } catch (e) {
      print('    ❌ Error fetching tasks: $e');
    }
  }

  Future<void> simulateTaskProcessing(String taskId) async {
    print('\n=== Simulating Task Processing ===');
    print('Processing task: $taskId');
    
    try {
      // Simulate task progression
      await _taskController.updateTaskStatus(taskId, TaskStatus.processing);
      print('  ✅ Task marked as processing');
      
      // Simulate some work (in real system, this would be done by Firebase Function)
      await Future.delayed(const Duration(seconds: 2));
      
      // Mark as completed
      await _taskController.updateTaskStatus(taskId, TaskStatus.completed);
      print('  ✅ Task marked as completed');
      
    } catch (e) {
      print('  ❌ Error processing task: $e');
    }
  }

  Future<void> cleanupDemo() async {
    print('\n=== Cleaning up demo tasks ===');
    
    try {
      // Clean up any demo tasks
      await _taskController.deleteCompletedTasks(
        olderThan: DateTime.now().subtract(const Duration(minutes: 1))
      );
      print('  ✅ Demo cleanup completed');
    } catch (e) {
      print('  ❌ Error during cleanup: $e');
    }
  }
}