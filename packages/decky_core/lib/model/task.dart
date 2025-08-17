import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_model.dart';

enum TaskType {
  cardUpdate,
}

enum TaskStatus {
  pending,
  processing,
  completed,
  failed,
}

class Task extends BaseModel {
  final TaskType taskType;
  final TaskStatus status;
  final Map<String, dynamic> metadata;
  final String? errorMessage;
  final Timestamp? completedAt;
  final Timestamp? startedAt;

  Task({
    required super.id,
    required this.taskType,
    required this.status,
    required this.metadata,
    this.errorMessage,
    this.completedAt,
    this.startedAt,
  });

  @override
  DocumentReference<Map<String, dynamic>> get ref => 
      FirebaseFirestore.instance.collection('tasks').doc(id);

  @override
  Map<String, dynamic> toJson() {
    return {
      'taskType': taskType.name,
      'status': status.name,
      'metadata': metadata,
      if (errorMessage != null) 'errorMessage': errorMessage,
      if (completedAt != null) 'completedAt': completedAt,
      if (startedAt != null) 'startedAt': startedAt,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json, String id) {
    final task = Task(
      id: id,
      taskType: TaskType.values.firstWhere(
        (type) => type.name == json['taskType'],
        orElse: () => TaskType.cardUpdate,
      ),
      status: TaskStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => TaskStatus.pending,
      ),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      errorMessage: json['errorMessage'],
      completedAt: json['completedAt'] as Timestamp?,
      startedAt: json['startedAt'] as Timestamp?,
    );
    task.createdAt = json['createdAt'] as Timestamp?;
    task.updatedAt = json['updatedAt'] as Timestamp?;
    return task;
  }

  Task copyWith({
    TaskType? taskType,
    TaskStatus? status,
    Map<String, dynamic>? metadata,
    String? errorMessage,
    Timestamp? completedAt,
    Timestamp? startedAt,
  }) {
    final task = Task(
      id: id,
      taskType: taskType ?? this.taskType,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
      errorMessage: errorMessage ?? this.errorMessage,
      completedAt: completedAt ?? this.completedAt,
      startedAt: startedAt ?? this.startedAt,
    );
    task.createdAt = createdAt;
    task.updatedAt = updatedAt;
    return task;
  }
}

class CardUpdateTaskMetadata {
  final String cardId;
  final bool forceUpdate;
  final bool skipImageDownload;
  final String? reason;

  CardUpdateTaskMetadata({
    required this.cardId,
    this.forceUpdate = false,
    this.skipImageDownload = false,
    this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      'cardId': cardId,
      'forceUpdate': forceUpdate,
      'skipImageDownload': skipImageDownload,
      if (reason != null) 'reason': reason,
    };
  }

  factory CardUpdateTaskMetadata.fromJson(Map<String, dynamic> json) {
    return CardUpdateTaskMetadata(
      cardId: json['cardId'],
      forceUpdate: json['forceUpdate'] ?? false,
      skipImageDownload: json['skipImageDownload'] ?? false,
      reason: json['reason'],
    );
  }
}