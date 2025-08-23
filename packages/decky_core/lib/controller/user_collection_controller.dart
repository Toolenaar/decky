import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:decky_core/model/user_collection.dart';
import 'package:decky_core/model/collection_card.dart';
import 'package:decky_core/model/base_model.dart';
import 'package:decky_core/model/mtg/mtg_card.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class UserCollectionController extends ChangeNotifier {
  final BehaviorSubject<UserCollection?> _defaultCollectionSubject = BehaviorSubject.seeded(null);
  final BehaviorSubject<List<CollectionCard>> _collectionCardsSubject = BehaviorSubject.seeded([]);
  final BehaviorSubject<bool> _loadingSubject = BehaviorSubject.seeded(false);
  final BehaviorSubject<String?> _errorSubject = BehaviorSubject.seeded(null);
  final BehaviorSubject<Map<String, CollectionCard>> _cardsByUuidSubject = BehaviorSubject.seeded({});
  
  StreamSubscription<QuerySnapshot>? _collectionCardsSubscription;
  String? _accountId;
  final String _defaultCollectionId = 'default';
  
  // Batch loading configuration
  static const int _batchSize = 100;
  DocumentSnapshot? _lastDocument;
  bool _hasMoreCards = true;
  bool _isLoadingMore = false;
  
  Stream<UserCollection?> get defaultCollectionStream => _defaultCollectionSubject.stream;
  Stream<List<CollectionCard>> get collectionCardsStream => _collectionCardsSubject.stream;
  Stream<bool> get loadingStream => _loadingSubject.stream;
  Stream<String?> get errorStream => _errorSubject.stream;
  Stream<Map<String, CollectionCard>> get cardsByUuidStream => _cardsByUuidSubject.stream;
  
  UserCollection? get defaultCollection => _defaultCollectionSubject.value;
  List<CollectionCard> get collectionCards => _collectionCardsSubject.value;
  bool get isLoading => _loadingSubject.value;
  String? get error => _errorSubject.value;
  Map<String, CollectionCard> get cardsByUuid => _cardsByUuidSubject.value;
  bool get hasMoreCards => _hasMoreCards;
  bool get isLoadingMore => _isLoadingMore;
  
  UserCollectionController();
  
  void initialize(String accountId) {
    _accountId = accountId;
    _loadDefaultCollection();
    _listenToCollectionCards();
  }
  
  Future<void> _loadDefaultCollection() async {
    if (_accountId == null) return;
    
    try {
      _loadingSubject.add(true);
      _errorSubject.add(null);
      
      final collectionRef = FirebaseFirestore.instance
          .collection('accounts')
          .doc(_accountId)
          .collection('collections')
          .doc(_defaultCollectionId);
      
      final collectionDoc = await collectionRef.get();
      
      if (!collectionDoc.exists) {
        // Create default collection if it doesn't exist
        final defaultCollection = UserCollection(
          id: _defaultCollectionId,
          accountId: _accountId!,
          name: 'My Collection',
          totalCards: 0,
        );
        
        await defaultCollection.create();
        _defaultCollectionSubject.add(defaultCollection);
      } else {
        final collection = UserCollection(
          id: collectionDoc.id,
          accountId: _accountId!,
          name: collectionDoc.data()?['name'] ?? 'My Collection',
          totalCards: collectionDoc.data()?['totalCards'] ?? 0,
        );
        _defaultCollectionSubject.add(collection);
      }
      
      _loadingSubject.add(false);
      notifyListeners();
    } catch (e) {
      _errorSubject.add(e.toString());
      _loadingSubject.add(false);
      notifyListeners();
    }
  }
  
  void _listenToCollectionCards() {
    if (_accountId == null) return;
    
    _collectionCardsSubscription?.cancel();
    
    // Start with initial batch
    _loadInitialBatch();
  }
  
  Future<void> _loadInitialBatch() async {
    if (_accountId == null) return;
    
    try {
      _loadingSubject.add(true);
      _errorSubject.add(null);
      _lastDocument = null;
      _hasMoreCards = true;
      
      final query = FirebaseFirestore.instance
          .collection('accounts')
          .doc(_accountId)
          .collection('collections')
          .doc(_defaultCollectionId)
          .collection('cards')
          .orderBy('mtgCardReference.name')
          .limit(_batchSize);
      
      final snapshot = await query.get();
      
      final cards = snapshot.docs.map((doc) {
        return CollectionCard.fromJson(doc.data(), doc.id);
      }).toList();
      
      _collectionCardsSubject.add(cards);
      _updateCardsByUuid(cards);
      
      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
      }
      
      _hasMoreCards = snapshot.docs.length == _batchSize;
      _loadingSubject.add(false);
      notifyListeners();
      
      // Set up real-time listener for the loaded cards
      _setupRealtimeListener();
    } catch (e) {
      _errorSubject.add(e.toString());
      _loadingSubject.add(false);
      notifyListeners();
    }
  }
  
  void _setupRealtimeListener() {
    if (_accountId == null) return;
    
    _collectionCardsSubscription?.cancel();
    
    // Listen to changes in the collection
    _collectionCardsSubscription = FirebaseFirestore.instance
        .collection('accounts')
        .doc(_accountId)
        .collection('collections')
        .doc(_defaultCollectionId)
        .collection('cards')
        .snapshots()
        .listen(
      (snapshot) {
        for (final change in snapshot.docChanges) {
          final card = CollectionCard.fromJson(change.doc.data()!, change.doc.id);
          final currentCards = List<CollectionCard>.from(_collectionCardsSubject.value);
          
          switch (change.type) {
            case DocumentChangeType.added:
              // Only add if not already in list (to avoid duplicates from batch loading)
              if (!currentCards.any((c) => c.id == card.id)) {
                currentCards.add(card);
              }
              break;
            case DocumentChangeType.modified:
              final index = currentCards.indexWhere((c) => c.id == card.id);
              if (index != -1) {
                currentCards[index] = card;
              }
              break;
            case DocumentChangeType.removed:
              currentCards.removeWhere((c) => c.id == card.id);
              break;
          }
          
          _collectionCardsSubject.add(currentCards);
          _updateCardsByUuid(currentCards);
        }
        
        notifyListeners();
      },
      onError: (error) {
        _errorSubject.add(error.toString());
        notifyListeners();
      },
    );
  }
  
  Future<void> loadMoreCards() async {
    if (_accountId == null || !_hasMoreCards || _isLoadingMore || _lastDocument == null) return;
    
    try {
      _isLoadingMore = true;
      notifyListeners();
      
      final query = FirebaseFirestore.instance
          .collection('accounts')
          .doc(_accountId)
          .collection('collections')
          .doc(_defaultCollectionId)
          .collection('cards')
          .orderBy('mtgCardReference.name')
          .startAfterDocument(_lastDocument!)
          .limit(_batchSize);
      
      final snapshot = await query.get();
      
      final newCards = snapshot.docs.map((doc) {
        return CollectionCard.fromJson(doc.data(), doc.id);
      }).toList();
      
      final currentCards = List<CollectionCard>.from(_collectionCardsSubject.value);
      currentCards.addAll(newCards);
      
      _collectionCardsSubject.add(currentCards);
      _updateCardsByUuid(currentCards);
      
      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
      }
      
      _hasMoreCards = snapshot.docs.length == _batchSize;
      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      _errorSubject.add(e.toString());
      _isLoadingMore = false;
      notifyListeners();
    }
  }
  
  void _updateCardsByUuid(List<CollectionCard> cards) {
    final cardMap = <String, CollectionCard>{};
    for (final card in cards) {
      cardMap[card.cardUuid] = card;
    }
    _cardsByUuidSubject.add(cardMap);
  }
  
  bool isCardInCollection(String cardUuid) {
    return _cardsByUuidSubject.value.containsKey(cardUuid);
  }
  
  CollectionCard? getCardFromCollection(String cardUuid) {
    return _cardsByUuidSubject.value[cardUuid];
  }
  
  Future<MtgCard?> fetchMtgCardFromFirestore(String cardUuid) async {
    try {
      final cardDoc = await FirebaseFirestore.instance
          .collection('cards')
          .doc(cardUuid)
          .get();
      
      if (!cardDoc.exists) return null;
      
      return MtgCard.fromJson({
        ...cardDoc.data()!,
        'uuid': cardDoc.id,
      }, cardDoc.id);
    } catch (e) {
      _errorSubject.add('Failed to fetch card data: $e');
      return null;
    }
  }
  
  Future<CollectionCard?> addCardToCollectionByUuid({
    required String cardUuid,
    int count = 1,
  }) async {
    if (_accountId == null) {
      throw Exception('No account ID available');
    }

    try {
      _errorSubject.add(null);
      
      // Check if card already exists in collection
      final existingCard = getCardFromCollection(cardUuid);
      
      if (existingCard != null) {
        // Update existing card count
        final updatedCard = existingCard.copyWith(count: existingCard.count + count);
        await updatedCard.update({'count': updatedCard.count});
        return updatedCard;
      } else {
        // Fetch the full MTG card data from Firestore
        final mtgCard = await fetchMtgCardFromFirestore(cardUuid);
        if (mtgCard == null) {
          throw Exception('Card not found in database');
        }
        
        // Create new collection card entry
        final cardId = BaseModel.newId(
          FirebaseFirestore.instance
              .collection('accounts')
              .doc(_accountId)
              .collection('collections')
              .doc(_defaultCollectionId)
              .collection('cards'),
        );
        
        final collectionCard = CollectionCard(
          id: cardId,
          cardUuid: mtgCard.id,
          count: count,
          accountId: _accountId!,
          collectionId: _defaultCollectionId,
          mtgCardReference: mtgCard,
        );
        
        await collectionCard.create();
        
        // Update total cards count
        await _updateTotalCardsCount(count);
        
        return collectionCard;
      }
    } catch (e) {
      _errorSubject.add(e.toString());
      notifyListeners();
      rethrow;
    }
  }
  
  Future<CollectionCard> addCardToCollection({
    required MtgCard mtgCard,
    int count = 1,
  }) async {
    if (_accountId == null) {
      throw Exception('No account ID available');
    }
    
    try {
      _errorSubject.add(null);
      
      // Check if card already exists in collection
      final existingCard = getCardFromCollection(mtgCard.id);
      
      if (existingCard != null) {
        // Update existing card count
        final updatedCard = existingCard.copyWith(count: existingCard.count + count);
        await updatedCard.update({'count': updatedCard.count});
        return updatedCard;
      } else {
        // Create new collection card entry
        final cardId = BaseModel.newId(
          FirebaseFirestore.instance
              .collection('accounts')
              .doc(_accountId)
              .collection('collections')
              .doc(_defaultCollectionId)
              .collection('cards'),
        );
        
        final collectionCard = CollectionCard(
          id: cardId,
          cardUuid: mtgCard.id,
          count: count,
          accountId: _accountId!,
          collectionId: _defaultCollectionId,
          mtgCardReference: mtgCard,
        );
        
        await collectionCard.create();
        
        // Update total cards count
        await _updateTotalCardsCount(count);
        
        return collectionCard;
      }
    } catch (e) {
      _errorSubject.add(e.toString());
      notifyListeners();
      rethrow;
    }
  }
  
  Future<void> removeCardFromCollection({
    required String cardUuid,
    int count = 1,
  }) async {
    try {
      _errorSubject.add(null);
      
      final existingCard = getCardFromCollection(cardUuid);
      
      if (existingCard != null) {
        final newCount = existingCard.count - count;
        if (newCount <= 0) {
          // Remove card entirely
          await existingCard.delete();
          await _updateTotalCardsCount(-existingCard.count);
        } else {
          // Update count
          await existingCard.update({'count': newCount});
          await _updateTotalCardsCount(-count);
        }
      }
      
      notifyListeners();
    } catch (e) {
      _errorSubject.add(e.toString());
      notifyListeners();
      rethrow;
    }
  }
  
  Future<void> updateCardCount(CollectionCard card, int newCount) async {
    try {
      _errorSubject.add(null);
      
      if (newCount <= 0) {
        await card.delete();
        await _updateTotalCardsCount(-card.count);
      } else {
        final countDiff = newCount - card.count;
        await card.update({'count': newCount});
        if (countDiff != 0) {
          await _updateTotalCardsCount(countDiff);
        }
      }
      
      notifyListeners();
    } catch (e) {
      _errorSubject.add(e.toString());
      notifyListeners();
      rethrow;
    }
  }
  
  Future<void> _updateTotalCardsCount(int change) async {
    if (_defaultCollectionSubject.value != null) {
      final newTotal = _defaultCollectionSubject.value!.totalCards + change;
      await _defaultCollectionSubject.value!.update({'totalCards': newTotal});
      _defaultCollectionSubject.add(
        UserCollection(
          id: _defaultCollectionSubject.value!.id,
          accountId: _defaultCollectionSubject.value!.accountId,
          name: _defaultCollectionSubject.value!.name,
          totalCards: newTotal,
        ),
      );
    }
  }
  
  @override
  void dispose() {
    _collectionCardsSubscription?.cancel();
    _defaultCollectionSubject.close();
    _collectionCardsSubject.close();
    _loadingSubject.close();
    _errorSubject.close();
    _cardsByUuidSubject.close();
    super.dispose();
  }
}
