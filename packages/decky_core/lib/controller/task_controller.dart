import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/task.dart';
import '../model/mtg/mtg_card.dart';

class TaskController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static const Duration _updateInterval = Duration(days: 7);

  Future<bool> shouldUpdateCard(MtgCard card) async {
    return _cardNeedsUpdate(card) || _cardDataTooOld(card);
  }

  bool _cardNeedsUpdate(MtgCard card) {
    // Check if card is missing essential data or images
    return card.firebaseImageUris == null ||
           card.scryfallData == null ||
           card.imageDataStatus == 'error' ||
           card.identifiers.scryfallId == null ||
           card.identifiers.scryfallId!.isEmpty;
  }

  bool _cardDataTooOld(MtgCard card) {
    if (card.updatedAt == null) return true;
    
    final now = DateTime.now();
    final lastUpdate = card.updatedAt!.toDate();
    return now.difference(lastUpdate) > _updateInterval;
  }

  Future<String> determineUpdateReason(MtgCard card) async {
    if (card.firebaseImageUris == null) return 'missing_images';
    if (card.scryfallData == null) return 'missing_scryfall_data';
    if (card.imageDataStatus == 'error') return 'previous_error';
    if (card.identifiers.scryfallId == null || card.identifiers.scryfallId!.isEmpty) {
      return 'missing_scryfall_id';
    }
    if (_cardDataTooOld(card)) return 'scheduled_refresh';
    return 'unknown';
  }

  Future<bool> hasExistingTask(String cardId) async {
    final existingTasks = await _firestore
        .collection('tasks')
        .where('metadata.cardId', isEqualTo: cardId)
        .where('status', whereIn: ['pending', 'processing'])
        .limit(1)
        .get();
    
    return existingTasks.docs.isNotEmpty;
  }

  Future<Task?> createCardUpdateTask(
    String cardId, {
    bool forceUpdate = false,
    bool skipImageDownload = false,
    String? reason,
  }) async {
    // Check if task already exists
    if (!forceUpdate && await hasExistingTask(cardId)) {
      return null; // Task already exists
    }

    final taskId = _firestore.collection('tasks').doc().id;
    final metadata = CardUpdateTaskMetadata(
      cardId: cardId,
      forceUpdate: forceUpdate,
      skipImageDownload: skipImageDownload,
      reason: reason,
    );

    final task = Task(
      id: taskId,
      taskType: TaskType.cardUpdate,
      status: TaskStatus.pending,
      metadata: metadata.toJson(),
    );

    await task.create();
    return task;
  }

  Future<List<Task>> getPendingTasks({int limit = 50}) async {
    final snapshot = await _firestore
        .collection('tasks')
        .where('status', isEqualTo: TaskStatus.pending.name)
        .orderBy('createdAt')
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => Task.fromJson(doc.data(), doc.id))
        .toList();
  }

  Future<void> updateTaskStatus(
    String taskId,
    TaskStatus status, {
    String? errorMessage,
  }) async {
    final updates = <String, dynamic>{
      'status': status.name,
      'updatedAt': Timestamp.now(),
    };

    if (status == TaskStatus.processing) {
      updates['startedAt'] = Timestamp.now();
    }

    if (status == TaskStatus.completed || status == TaskStatus.failed) {
      updates['completedAt'] = Timestamp.now();
    }

    if (errorMessage != null) {
      updates['errorMessage'] = errorMessage;
    }

    await _firestore.collection('tasks').doc(taskId).update(updates);
  }

  Future<void> deleteCompletedTasks({DateTime? olderThan}) async {
    olderThan ??= DateTime.now().subtract(const Duration(days: 1));
    
    final query = _firestore
        .collection('tasks')
        .where('status', whereIn: [TaskStatus.completed.name, TaskStatus.failed.name])
        .where('completedAt', isLessThan: Timestamp.fromDate(olderThan));

    final snapshot = await query.get();
    
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    
    if (snapshot.docs.isNotEmpty) {
      await batch.commit();
    }
  }

  Future<Task?> getTaskById(String taskId) async {
    final doc = await _firestore.collection('tasks').doc(taskId).get();
    if (!doc.exists) return null;
    
    return Task.fromJson(doc.data()!, doc.id);
  }

  Stream<List<Task>> watchTasks({
    TaskStatus? status,
    TaskType? taskType,
    int limit = 50,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection('tasks');

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    if (taskType != null) {
      query = query.where('taskType', isEqualTo: taskType.name);
    }

    return query
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Task.fromJson(doc.data(), doc.id))
            .toList());
  }

  Future<void> processCardUpdateTasks() async {
    // This will be called by the Firebase Function
    // For now, just get pending tasks - the actual processing will be in the cloud function
    final pendingTasks = await getPendingTasks(limit: 10);
    
    for (final task in pendingTasks) {
      if (task.taskType == TaskType.cardUpdate) {
        await updateTaskStatus(task.id, TaskStatus.processing);
        // The actual processing will happen in the Firebase Function
      }
    }
  }
}