import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:decky_core/model/mtg/mtg_card.dart';
import 'image_sync_service.dart';

enum BulkImportState { idle, running, paused, completed, cancelled, error }

class BulkImportProgress {
  final int totalCards;
  final int processedCards;
  final int successfulCards;
  final int failedCards;
  final int skippedCards;
  final String? currentCardName;
  final BulkImportState state;
  final String? error;
  final int currentBatch;
  final int totalBatches;

  BulkImportProgress({
    required this.totalCards,
    required this.processedCards,
    required this.successfulCards,
    required this.failedCards,
    required this.skippedCards,
    this.currentCardName,
    required this.state,
    this.error,
    required this.currentBatch,
    required this.totalBatches,
  });

  double get progress => totalCards > 0 ? processedCards / totalCards : 0.0;
  int get remainingCards => totalCards - processedCards;

  BulkImportProgress copyWith({
    int? totalCards,
    int? processedCards,
    int? successfulCards,
    int? failedCards,
    int? skippedCards,
    String? currentCardName,
    BulkImportState? state,
    String? error,
    int? currentBatch,
    int? totalBatches,
  }) {
    return BulkImportProgress(
      totalCards: totalCards ?? this.totalCards,
      processedCards: processedCards ?? this.processedCards,
      successfulCards: successfulCards ?? this.successfulCards,
      failedCards: failedCards ?? this.failedCards,
      skippedCards: skippedCards ?? this.skippedCards,
      currentCardName: currentCardName ?? this.currentCardName,
      state: state ?? this.state,
      error: error ?? this.error,
      currentBatch: currentBatch ?? this.currentBatch,
      totalBatches: totalBatches ?? this.totalBatches,
    );
  }
}

class BulkImageImportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImageSyncService _imageSyncService = ImageSyncService();

  static const int _batchSize = 20;
  static const Duration _delayBetweenCards = Duration(seconds: 1);

  StreamController<BulkImportProgress>? _progressController;
  bool _isPaused = false;
  bool _isCancelled = false;

  Stream<BulkImportProgress>? get progressStream => _progressController?.stream;

  Future<int> getTotalUnprocessedCardsCount() async {
    try {
      final snapshot = await _firestore
          .collection('cards')
          .where(Filter.or(Filter('imageDataStatus', isNotEqualTo: 'synced'), Filter('imageDataStatus', isNull: true)))
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<List<MtgCard>> _getBatchOfUnprocessedCards({DocumentSnapshot? startAfter}) async {
    Query query = _firestore
        .collection('cards')
        .where(Filter.or(Filter('imageDataStatus', isNotEqualTo: 'synced'), Filter('imageDataStatus', isNull: true)))
        .where('importError', isNull: true)
        .orderBy('name')
        .limit(_batchSize);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['uuid'] = doc.id;
      return MtgCard.fromJson(data);
    }).toList();
  }

  Future<void> startBulkImport() async {
    if (_progressController != null) {
      throw Exception('Import already in progress');
    }

    _progressController = StreamController<BulkImportProgress>.broadcast();
    _isPaused = false;
    _isCancelled = false;

    try {
      final totalCards = await getTotalUnprocessedCardsCount();
      final totalBatches = (totalCards / _batchSize).ceil();

      var progress = BulkImportProgress(
        totalCards: totalCards,
        processedCards: 0,
        successfulCards: 0,
        failedCards: 0,
        skippedCards: 0,
        state: BulkImportState.running,
        currentBatch: 0,
        totalBatches: totalBatches,
      );

      _progressController!.add(progress);

      if (totalCards == 0) {
        progress = progress.copyWith(state: BulkImportState.completed);
        _progressController!.add(progress);
        await _cleanup();
        return;
      }

      DocumentSnapshot? lastDoc;
      int currentBatch = 0;

      while (!_isCancelled && progress.processedCards < totalCards) {
        // Check for pause
        while (_isPaused && !_isCancelled) {
          progress = progress.copyWith(state: BulkImportState.paused);
          _progressController!.add(progress);
          await Future.delayed(const Duration(milliseconds: 100));
        }

        if (_isCancelled) break;

        currentBatch++;
        progress = progress.copyWith(state: BulkImportState.running, currentBatch: currentBatch);
        _progressController!.add(progress);

        final batch = await _getBatchOfUnprocessedCards(startAfter: lastDoc);

        if (batch.isEmpty) break;

        for (final card in batch) {
          if (_isCancelled) break;

          // Check for pause
          while (_isPaused && !_isCancelled) {
            progress = progress.copyWith(state: BulkImportState.paused);
            _progressController!.add(progress);
            await Future.delayed(const Duration(milliseconds: 100));
          }

          if (_isCancelled) break;

          progress = progress.copyWith(currentCardName: card.name, state: BulkImportState.running);
          _progressController!.add(progress);

          // Skip cards that already have both images and complete Scryfall data, or no Scryfall ID
          if ((card.imageDataStatus == 'synced' && card.scryfallData != null) ||
              card.identifiers.scryfallId == null ||
              card.identifiers.scryfallId!.isEmpty) {
            progress = progress.copyWith(
              processedCards: progress.processedCards + 1,
              skippedCards: progress.skippedCards + 1,
            );
            _progressController!.add(progress);
            continue;
          }

          try {
            await _imageSyncService.syncCardImages(card.id, (syncProgress) {
              // We can optionally update progress here for individual card sync
            });

            progress = progress.copyWith(
              processedCards: progress.processedCards + 1,
              successfulCards: progress.successfulCards + 1,
            );
          } catch (e) {
            progress = progress.copyWith(
              processedCards: progress.processedCards + 1,
              failedCards: progress.failedCards + 1,
            );
          }

          _progressController!.add(progress);

          // Rate limiting - wait between cards
          if (!_isCancelled && progress.processedCards < totalCards) {
            await Future.delayed(_delayBetweenCards);
          }
        }

        // Update lastDoc for pagination
        if (batch.isNotEmpty) {
          final lastCard = batch.last;
          final docSnapshot = await _firestore.collection('cards').doc(lastCard.id).get();
          lastDoc = docSnapshot;
        }
      }

      // Final state
      if (_isCancelled) {
        progress = progress.copyWith(state: BulkImportState.cancelled);
      } else {
        progress = progress.copyWith(state: BulkImportState.completed, currentCardName: null);
      }

      _progressController!.add(progress);
    } catch (e) {
      final errorProgress = BulkImportProgress(
        totalCards: 0,
        processedCards: 0,
        successfulCards: 0,
        failedCards: 0,
        skippedCards: 0,
        state: BulkImportState.error,
        error: e.toString(),
        currentBatch: 0,
        totalBatches: 0,
      );
      _progressController!.add(errorProgress);
    } finally {
      await _cleanup();
    }
  }

  void pauseImport() {
    _isPaused = true;
  }

  void resumeImport() {
    _isPaused = false;
  }

  void cancelImport() {
    _isCancelled = true;
  }

  Future<void> _cleanup() async {
    await Future.delayed(const Duration(milliseconds: 100));
    await _progressController?.close();
    _progressController = null;
    _isPaused = false;
    _isCancelled = false;
  }

  void dispose() {
    cancelImport();
    _progressController?.close();
    _progressController = null;
  }
}
