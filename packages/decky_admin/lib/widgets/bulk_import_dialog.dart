import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:decky_core/model/mtg/mtg_card.dart';
import '../services/image_sync_service.dart';

enum ImportDialogState { loading, ready, importing, completed }

class CardImportStatus {
  final MtgCard card;
  final ImportStatus status;
  final String? error;

  CardImportStatus({required this.card, required this.status, this.error});
}

enum ImportStatus { pending, importing, success, failed, skipped }

class BulkImportDialog extends StatefulWidget {
  const BulkImportDialog({super.key});

  @override
  State<BulkImportDialog> createState() => _BulkImportDialogState();
}

class _BulkImportDialogState extends State<BulkImportDialog> {
  final ImageSyncService _imageSyncService = ImageSyncService();

  ImportDialogState _dialogState = ImportDialogState.loading;
  List<CardImportStatus> _cardsToImport = [];
  int _totalCardsCount = 0;
  int _currentCardIndex = 0;
  bool _isPaused = false;
  bool _isCancelled = false;

  // Database counters
  int _totalCardsInDb = 0;
  int _totalCompletedCards = 0;
  int _totalErrorCards = 0;

  // Pagination state
  DocumentSnapshot? _lastDocument;
  bool _hasMoreCards = true;
  static const int _batchSize = 50;

  @override
  void initState() {
    super.initState();
    _loadCardsToImport();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadCardsToImport() async {
    print('🔄 BulkImportDialog: Starting to load first batch of cards');
    setState(() {
      _dialogState = ImportDialogState.loading;
    });

    try {
      // Load database counters in parallel with first batch
      print('📊 BulkImportDialog: Loading database counters');
      final futures = await Future.wait([
        _getTotalCardsCount(),
        _getCompletedCardsCount(),
        _getErrorCardsCount(),
        _getNextBatchOfUnprocessedCards(),
      ]);

      final totalCardsInDb = futures[0] as int;
      final completedCards = futures[1] as int;
      final errorCards = futures[2] as int;
      final firstBatch = futures[3] as List<MtgCard>;

      print(
        '✅ BulkImportDialog: Total cards in DB: $totalCardsInDb, Completed: $completedCards, Errors: $errorCards, First batch: ${firstBatch.length}',
      );

      setState(() {
        _totalCardsInDb = totalCardsInDb;
        _totalCompletedCards = completedCards;
        _totalErrorCards = errorCards;
        _cardsToImport = firstBatch.map((card) => CardImportStatus(card: card, status: ImportStatus.pending)).toList();
        _totalCardsCount = firstBatch.length; // We'll update this as we discover more cards
        _dialogState = ImportDialogState.ready;
      });
      print('🎯 BulkImportDialog: Successfully loaded cards, dialog now ready');
    } catch (e, stackTrace) {
      print('❌ BulkImportDialog: Error loading cards: $e');
      print('🔍 BulkImportDialog: Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load cards: $e'), backgroundColor: Colors.red));
        Navigator.of(context).pop();
      }
    }
  }

  Future<int> _getTotalCardsCount() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('cards').count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('❌ Error getting total cards count: $e');
      return 0;
    }
  }

  Future<int> _getCompletedCardsCount() async {
    try {
      // Firestore count queries don't support isNull: false, so we need to do this differently
      // We'll get cards that have imageDataStatus = 'synced' and then check for scryfallData
      final snapshot = await FirebaseFirestore.instance
          .collection('cards')
          .where('imageDataStatus', isEqualTo: 'synced')
          .get();

      // Count only those that also have scryfallData
      int completedCount = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['scryfallData'] != null) {
          completedCount++;
        }
      }

      return completedCount;
    } catch (e) {
      print('❌ Error getting completed cards count: $e');
      return 0;
    }
  }

  Future<int> _getErrorCardsCount() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('cards')
          .where('imageDataStatus', isEqualTo: 'error')
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('❌ Error getting error cards count: $e');
      return 0;
    }
  }

  Future<List<MtgCard>> _getNextBatchOfUnprocessedCards() async {
    try {
      print('📋 Getting next batch of cards from Firestore (batch size: $_batchSize)');

      Query query = FirebaseFirestore.instance.collection('cards').orderBy('name').limit(_batchSize);

      // Add pagination if we have a last document
      if (_lastDocument != null) {
        print('📄 Starting after document: ${_lastDocument!.id}');
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();
      print('📄 Got ${snapshot.docs.length} documents from Firestore');

      if (snapshot.docs.isEmpty) {
        print('🏁 No more cards found');
        _hasMoreCards = false;
        return [];
      }

      // Update pagination state
      _lastDocument = snapshot.docs.last;

      final unprocessedCards = <MtgCard>[];

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final imageDataStatus = data['imageDataStatus'];
        final firebaseImageUris = data['firebaseImageUris'];
        final scryfallData = data['scryfallData'];
        final importError = data['importError'];

        // Include if missing images OR missing complete Scryfall data
        if (imageDataStatus != 'synced' || firebaseImageUris == null || scryfallData == null || importError == null) {
          try {
            data['uuid'] = doc.id;
            final card = MtgCard.fromJson(data);
            unprocessedCards.add(card);
            print(
              '📝 Added unprocessed card: ${card.name} - status: $imageDataStatus, scryfallData: ${scryfallData != null ? 'present' : 'missing'}',
            );
          } catch (e, stackTrace) {
            print('❌ Error parsing card ${doc.id}: $e');
            print('🔍 Card data: ${doc.data()}');
            print('🔍 Stack trace: $stackTrace');
          }
        } else {
          print('⏭️ Skipping already processed card: ${data['name']} (images synced & Scryfall data present)');
        }
      }

      print('✅ Found ${unprocessedCards.length} unprocessed cards in this batch');
      return unprocessedCards;
    } catch (e, stackTrace) {
      print('❌ Error getting next batch of cards: $e');
      print('🔍 Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> _startImport() async {
    print('🚀 Starting bulk import process');
    setState(() {
      _dialogState = ImportDialogState.importing;
      _currentCardIndex = 0;
      _isPaused = false;
      _isCancelled = false;
    });

    int totalProcessed = 0;

    // Process the current batch and continue loading more as needed
    while (!_isCancelled) {
      print('📊 Processing current batch of ${_cardsToImport.length} cards');

      // Process all cards in current batch
      for (int i = 0; i < _cardsToImport.length && !_isCancelled; i++) {
        // Check for pause
        while (_isPaused && !_isCancelled) {
          print('⏸️ Import paused, waiting...');
          await Future.delayed(const Duration(milliseconds: 100));
        }

        if (_isCancelled) break;

        // Skip already processed cards
        if (_cardsToImport[i].status != ImportStatus.pending) {
          continue;
        }

        totalProcessed++;
        print('🔄 Processing card $totalProcessed: ${_cardsToImport[i].card.name}');
        setState(() {
          _currentCardIndex = i;
          _cardsToImport[i] = CardImportStatus(card: _cardsToImport[i].card, status: ImportStatus.importing);
        });

        try {
          final card = _cardsToImport[i].card;
          print('📋 Card details: ${card.name} (ID: ${card.id})');
          print('🔍 Scryfall ID: ${card.identifiers.scryfallId}');

          // Skip cards without Scryfall ID
          if (card.identifiers.scryfallId == null || card.identifiers.scryfallId!.isEmpty) {
            print('⚠️ Skipping card - no Scryfall ID');
            setState(() {
              _cardsToImport[i] = CardImportStatus(card: card, status: ImportStatus.skipped, error: 'No Scryfall ID');
            });
            continue;
          }
          // skip cards with import error
          if (card.importError != null) {
            print('⚠️ Skipping card - import error');
            setState(() {
              _cardsToImport[i] = CardImportStatus(card: card, status: ImportStatus.skipped, error: 'Import error');
            });
            continue;
          }
          // Skip cards that already have both images and complete Scryfall data
          if (card.imageDataStatus == 'synced' &&
              card.firebaseImageUris?.hasAnyImage == true &&
              card.scryfallData != null) {
            print('⚠️ Skipping card - already has images and Scryfall data');
            setState(() {
              _cardsToImport[i] = CardImportStatus(
                card: card,
                status: ImportStatus.skipped,
                error: 'Already processed',
              );
            });
            continue;
          }

          // Import images for this card
          print('🖼️ Starting image sync for card: ${card.name}');
          await _imageSyncService.syncCardImages(card.id, (progress) {
            print('📈 Sync progress: ${progress.currentImage} (${progress.status})');
          });

          print('✅ Successfully synced images for: ${card.name}');
          setState(() {
            _cardsToImport[i] = CardImportStatus(card: card, status: ImportStatus.success);
            // Update completed counter
            _totalCompletedCards++;
          });
        } catch (e, stackTrace) {
          print('❌ Error importing images for card ${_cardsToImport[i].card.name}: $e');
          print('🔍 Stack trace: $stackTrace');
          setState(() {
            _cardsToImport[i] = CardImportStatus(
              card: _cardsToImport[i].card,
              status: ImportStatus.failed,
              error: e.toString(),
            );
            // Update error counter
            _totalErrorCards++;
          });
        }

        // Rate limiting - wait 1 second between cards
        if (!_isCancelled) {
          print('⏱️ Rate limiting: waiting 1 second before next card');
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      // Check if we need to load more cards
      if (!_isCancelled && _hasMoreCards) {
        print('🔄 Loading next batch of cards...');
        try {
          final nextBatch = await _getNextBatchOfUnprocessedCards();
          if (nextBatch.isNotEmpty) {
            setState(() {
              _cardsToImport.addAll(
                nextBatch.map((card) => CardImportStatus(card: card, status: ImportStatus.pending)),
              );
              _totalCardsCount = _cardsToImport.length;
            });
            print('➕ Added ${nextBatch.length} more cards to process');
          } else {
            print('🏁 No more cards to process');
            break;
          }
        } catch (e) {
          print('❌ Error loading next batch: $e');
          break;
        }
      } else {
        print('🏁 Finished processing all available cards');
        break;
      }
    }

    if (!_isCancelled) {
      print('🎉 Bulk import completed successfully. Total processed: $totalProcessed');
      setState(() {
        _dialogState = ImportDialogState.completed;
      });
    } else {
      print('🛑 Bulk import was cancelled. Total processed: $totalProcessed');
    }
  }

  void _pauseResume() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  void _stopImport() {
    setState(() {
      _isCancelled = true;
      _dialogState = ImportDialogState.completed;
    });
  }

  void _close() {
    Navigator.of(context).pop();
  }

  Widget _buildCardsList() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListView.builder(
          itemCount: _cardsToImport.length,
          itemBuilder: (context, index) {
            final cardStatus = _cardsToImport[index];
            return _buildCardTile(cardStatus, index);
          },
        ),
      ),
    );
  }

  Widget _buildCardTile(CardImportStatus cardStatus, int index) {
    Color statusColor;
    IconData statusIcon;

    switch (cardStatus.status) {
      case ImportStatus.pending:
        statusColor = Colors.grey;
        statusIcon = Icons.pending;
        break;
      case ImportStatus.importing:
        statusColor = Colors.blue;
        statusIcon = Icons.sync;
        break;
      case ImportStatus.success:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case ImportStatus.failed:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      case ImportStatus.skipped:
        statusColor = Colors.orange;
        statusIcon = Icons.skip_next;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: index == _currentCardIndex && _dialogState == ImportDialogState.importing ? Colors.blue[50] : null,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: ListTile(
        leading: Icon(statusIcon, color: statusColor),
        title: Text(cardStatus.card.name, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${cardStatus.card.setCode.toUpperCase()} • ${cardStatus.card.rarity}'),
            if (cardStatus.error != null)
              Text(cardStatus.error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ],
        ),
        trailing: cardStatus.status == ImportStatus.importing
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : null,
      ),
    );
  }

  Widget _buildProgressInfo() {
    final completedCount = _cardsToImport
        .where(
          (c) =>
              c.status == ImportStatus.success || c.status == ImportStatus.failed || c.status == ImportStatus.skipped,
        )
        .length;

    final successCount = _cardsToImport.where((c) => c.status == ImportStatus.success).length;
    final failedCount = _cardsToImport.where((c) => c.status == ImportStatus.failed).length;
    final skippedCount = _cardsToImport.where((c) => c.status == ImportStatus.skipped).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Progress', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // Database Overview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.storage, color: Colors.blue[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Database Overview',
                          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 4),
                        Text('Total cards: $_totalCardsInDb'),
                        Row(
                          children: [
                            Icon(Icons.check_circle, size: 16, color: Colors.green),
                            const SizedBox(width: 4),
                            Text('Completed: $_totalCompletedCards', style: TextStyle(color: Colors.green[700])),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(Icons.error, size: 16, color: Colors.red),
                            const SizedBox(width: 4),
                            Text('Errors: $_totalErrorCards', style: TextStyle(color: Colors.red[700])),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(Icons.pending, size: 16, color: Colors.orange),
                            const SizedBox(width: 4),
                            Text(
                              'Need Processing: ${_totalCardsInDb - _totalCompletedCards}',
                              style: TextStyle(color: Colors.orange[700]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Completion percentage
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _totalCardsInDb > 0 ? Colors.green[100] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _totalCardsInDb > 0
                          ? '${((_totalCompletedCards / _totalCardsInDb) * 100).toStringAsFixed(1)}%'
                          : '0%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _totalCardsInDb > 0 ? Colors.green[700] : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Current Batch Progress
            Text(
              'Current Batch Progress',
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: _cardsToImport.isNotEmpty ? completedCount / _cardsToImport.length : 0),
            const SizedBox(height: 8),
            Text('$completedCount / ${_cardsToImport.length} cards processed in current batch'),
            if (successCount > 0 || failedCount > 0 || skippedCount > 0) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  if (successCount > 0) ...[
                    Icon(Icons.check_circle, size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Text('$successCount success', style: TextStyle(color: Colors.green, fontSize: 12)),
                    const SizedBox(width: 12),
                  ],
                  if (failedCount > 0) ...[
                    Icon(Icons.error, size: 16, color: Colors.red),
                    const SizedBox(width: 4),
                    Text('$failedCount failed', style: TextStyle(color: Colors.red, fontSize: 12)),
                    const SizedBox(width: 12),
                  ],
                  if (skippedCount > 0) ...[
                    Icon(Icons.skip_next, size: 16, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text('$skippedCount skipped', style: TextStyle(color: Colors.orange, fontSize: 12)),
                  ],
                ],
              ),
            ],
            Text('Total cards in current batch: $_totalCardsCount'),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (_dialogState == ImportDialogState.ready)
          ElevatedButton.icon(
            onPressed: _startImport,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Import'),
          )
        else if (_dialogState == ImportDialogState.importing) ...[
          ElevatedButton.icon(
            onPressed: _pauseResume,
            icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
            label: Text(_isPaused ? 'Resume' : 'Pause'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: _stopImport,
            icon: const Icon(Icons.stop),
            label: const Text('Stop'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          ),
        ] else if (_dialogState == ImportDialogState.completed)
          ElevatedButton.icon(onPressed: _close, icon: const Icon(Icons.close), label: const Text('Close')),
        if (_dialogState != ImportDialogState.completed) ...[
          const SizedBox(width: 8),
          OutlinedButton(onPressed: _close, child: const Text('Cancel')),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 900,
        height: 900,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_sync, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Bulk Image Import',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_dialogState == ImportDialogState.loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else ...[
              _buildProgressInfo(),
              const SizedBox(height: 16),
              _buildCardsList(),
              const SizedBox(height: 16),
              _buildControls(),
            ],
          ],
        ),
      ),
    );
  }
}
