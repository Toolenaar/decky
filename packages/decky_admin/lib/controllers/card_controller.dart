import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'package:decky_core/model/mtg/mtg_card.dart';
import '../services/image_sync_service.dart';
import '../services/bulk_image_import_service.dart';

class CardController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImageSyncService _imageSyncService = ImageSyncService();
  final BulkImageImportService _bulkImportService = BulkImageImportService();
  final int _pageSize = 20;
  
  // Stream controllers
  final BehaviorSubject<List<MtgCard>> _cardsSubject = BehaviorSubject.seeded([]);
  final BehaviorSubject<bool> _loadingSubject = BehaviorSubject.seeded(false);
  final BehaviorSubject<bool> _hasMoreSubject = BehaviorSubject.seeded(true);
  final BehaviorSubject<String?> _errorSubject = BehaviorSubject.seeded(null);
  
  // Streams
  Stream<List<MtgCard>> get cardsStream => _cardsSubject.stream;
  Stream<bool> get loadingStream => _loadingSubject.stream;
  Stream<bool> get hasMoreStream => _hasMoreSubject.stream;
  Stream<String?> get errorStream => _errorSubject.stream;
  
  // Current values
  List<MtgCard> get cards => _cardsSubject.value;
  bool get isLoading => _loadingSubject.value;
  bool get hasMore => _hasMoreSubject.value;
  
  // Pagination
  DocumentSnapshot? _lastDocument;
  StreamSubscription? _cardsSubscription;
  
  Future<void> init() async {
    await loadInitialCards();
  }
  
  Future<void> loadInitialCards() async {
    try {
      _loadingSubject.add(true);
      _errorSubject.add(null);
      _lastDocument = null;
      
      final query = _firestore
          .collection('cards')
          .orderBy('name')
          .limit(_pageSize);
      
      _cardsSubscription?.cancel();
      _cardsSubscription = query.snapshots().listen((snapshot) {
        final cards = snapshot.docs.map((doc) {
          final data = doc.data();
          data['uuid'] = doc.id;
          return MtgCard.fromJson(data);
        }).toList();
        
        _cardsSubject.add(cards);
        _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
        _hasMoreSubject.add(snapshot.docs.length == _pageSize);
        _loadingSubject.add(false);
      }, onError: (error) {
        _errorSubject.add(error.toString());
        _loadingSubject.add(false);
      });
    } catch (e) {
      _errorSubject.add(e.toString());
      _loadingSubject.add(false);
    }
  }
  
  Future<void> loadMoreCards() async {
    if (_loadingSubject.value || !_hasMoreSubject.value || _lastDocument == null) {
      return;
    }
    
    try {
      _loadingSubject.add(true);
      
      final query = _firestore
          .collection('cards')
          .orderBy('name')
          .startAfterDocument(_lastDocument!)
          .limit(_pageSize);
      
      final snapshot = await query.get();
      final newCards = snapshot.docs.map((doc) {
        final data = doc.data();
        data['uuid'] = doc.id;
        return MtgCard.fromJson(data);
      }).toList();
      
      final currentCards = List<MtgCard>.from(_cardsSubject.value);
      currentCards.addAll(newCards);
      _cardsSubject.add(currentCards);
      
      _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      _hasMoreSubject.add(snapshot.docs.length == _pageSize);
      _loadingSubject.add(false);
    } catch (e) {
      _errorSubject.add(e.toString());
      _loadingSubject.add(false);
    }
  }
  
  Future<void> searchCards(String query) async {
    try {
      _loadingSubject.add(true);
      _errorSubject.add(null);
      
      final searchQuery = _firestore
          .collection('cards')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(50);
      
      final snapshot = await searchQuery.get();
      final cards = snapshot.docs.map((doc) {
        final data = doc.data();
        data['uuid'] = doc.id;
        return MtgCard.fromJson(data);
      }).toList();
      
      _cardsSubject.add(cards);
      _hasMoreSubject.add(false);
      _loadingSubject.add(false);
    } catch (e) {
      _errorSubject.add(e.toString());
      _loadingSubject.add(false);
    }
  }
  
  Future<MtgCard?> getCard(String id) async {
    try {
      final doc = await _firestore.collection('cards').doc(id).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['uuid'] = doc.id;
        return MtgCard.fromJson(data);
      }
      return null;
    } catch (e) {
      _errorSubject.add(e.toString());
      return null;
    }
  }
  
  Future<bool> createCard(MtgCard card) async {
    try {
      await _firestore.collection('cards').doc(card.id).set(card.toJson());
      return true;
    } catch (e) {
      _errorSubject.add(e.toString());
      return false;
    }
  }
  
  Future<bool> updateCard(MtgCard card) async {
    try {
      await _firestore.collection('cards').doc(card.id).update(card.toJson());
      
      // Update local cache
      final currentCards = List<MtgCard>.from(_cardsSubject.value);
      final index = currentCards.indexWhere((c) => c.id == card.id);
      if (index != -1) {
        currentCards[index] = card;
        _cardsSubject.add(currentCards);
      }
      
      return true;
    } catch (e) {
      _errorSubject.add(e.toString());
      return false;
    }
  }
  
  Future<bool> deleteCard(String id) async {
    try {
      await _firestore.collection('cards').doc(id).delete();
      
      // Update local cache
      final currentCards = List<MtgCard>.from(_cardsSubject.value);
      currentCards.removeWhere((card) => card.id == id);
      _cardsSubject.add(currentCards);
      
      return true;
    } catch (e) {
      _errorSubject.add(e.toString());
      return false;
    }
  }
  
  void clearSearch() {
    loadInitialCards();
  }

  Future<void> syncCardImages(String cardId, Function(ImageSyncProgress) onProgress) async {
    try {
      await _firestore.collection('cards').doc(cardId).update({
        'imageDataStatus': 'syncing',
      });

      await _imageSyncService.syncCardImages(cardId, onProgress);

      final updatedCard = await getCard(cardId);
      if (updatedCard != null) {
        final currentCards = List<MtgCard>.from(_cardsSubject.value);
        final index = currentCards.indexWhere((c) => c.id == cardId);
        if (index != -1) {
          currentCards[index] = updatedCard;
          _cardsSubject.add(currentCards);
        }
      }
    } catch (e) {
      await _firestore.collection('cards').doc(cardId).update({
        'imageDataStatus': 'error',
      });
      rethrow;
    }
  }

  Future<bool> updateImageSyncStatus(String cardId, String status) async {
    try {
      await _firestore.collection('cards').doc(cardId).update({
        'imageDataStatus': status,
      });

      final currentCards = List<MtgCard>.from(_cardsSubject.value);
      final index = currentCards.indexWhere((c) => c.id == cardId);
      if (index != -1) {
        final updatedCard = await getCard(cardId);
        if (updatedCard != null) {
          currentCards[index] = updatedCard;
          _cardsSubject.add(currentCards);
        }
      }
      
      return true;
    } catch (e) {
      _errorSubject.add(e.toString());
      return false;
    }
  }

  // Bulk import methods
  Future<int> getTotalUnprocessedCardsCount() async {
    return await _bulkImportService.getTotalUnprocessedCardsCount();
  }

  Stream<BulkImportProgress>? get bulkImportProgressStream => 
      _bulkImportService.progressStream;

  Future<void> startBulkImageImport() async {
    await _bulkImportService.startBulkImport();
  }

  void pauseBulkImport() {
    _bulkImportService.pauseImport();
  }

  void resumeBulkImport() {
    _bulkImportService.resumeImport();
  }

  void cancelBulkImport() {
    _bulkImportService.cancelImport();
  }
  
  void dispose() {
    _cardsSubscription?.cancel();
    _bulkImportService.dispose();
    _cardsSubject.close();
    _loadingSubject.close();
    _hasMoreSubject.close();
    _errorSubject.close();
  }
}