import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'package:decky_core/model/mtg/mtg_deck.dart';

class DeckController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final int _pageSize = 20;
  
  // Stream controllers
  final BehaviorSubject<List<MtgDeck>> _decksSubject = BehaviorSubject.seeded([]);
  final BehaviorSubject<bool> _loadingSubject = BehaviorSubject.seeded(false);
  final BehaviorSubject<bool> _hasMoreSubject = BehaviorSubject.seeded(true);
  final BehaviorSubject<String?> _errorSubject = BehaviorSubject.seeded(null);
  
  // Streams
  Stream<List<MtgDeck>> get decksStream => _decksSubject.stream;
  Stream<bool> get loadingStream => _loadingSubject.stream;
  Stream<bool> get hasMoreStream => _hasMoreSubject.stream;
  Stream<String?> get errorStream => _errorSubject.stream;
  
  // Current values
  List<MtgDeck> get decks => _decksSubject.value;
  bool get isLoading => _loadingSubject.value;
  bool get hasMore => _hasMoreSubject.value;
  
  // Pagination
  DocumentSnapshot? _lastDocument;
  StreamSubscription? _decksSubscription;
  
  Future<void> init() async {
    await loadInitialDecks();
  }
  
  Future<void> loadInitialDecks() async {
    try {
      _loadingSubject.add(true);
      _errorSubject.add(null);
      _lastDocument = null;
      
      final query = _firestore
          .collection('decks')
          .orderBy('name')
          .limit(_pageSize);
      
      _decksSubscription?.cancel();
      _decksSubscription = query.snapshots().listen((snapshot) {
        final decks = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return MtgDeck.fromJson(data);
        }).toList();
        
        _decksSubject.add(decks);
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
  
  Future<void> loadMoreDecks() async {
    if (_loadingSubject.value || !_hasMoreSubject.value || _lastDocument == null) {
      return;
    }
    
    try {
      _loadingSubject.add(true);
      
      final query = _firestore
          .collection('decks')
          .orderBy('name')
          .startAfterDocument(_lastDocument!)
          .limit(_pageSize);
      
      final snapshot = await query.get();
      final newDecks = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return MtgDeck.fromJson(data);
      }).toList();
      
      final currentDecks = List<MtgDeck>.from(_decksSubject.value);
      currentDecks.addAll(newDecks);
      _decksSubject.add(currentDecks);
      
      _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      _hasMoreSubject.add(snapshot.docs.length == _pageSize);
      _loadingSubject.add(false);
    } catch (e) {
      _errorSubject.add(e.toString());
      _loadingSubject.add(false);
    }
  }
  
  Future<void> searchDecks(String query) async {
    try {
      _loadingSubject.add(true);
      _errorSubject.add(null);
      
      final searchQuery = _firestore
          .collection('decks')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(50);
      
      final snapshot = await searchQuery.get();
      final decks = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return MtgDeck.fromJson(data);
      }).toList();
      
      _decksSubject.add(decks);
      _hasMoreSubject.add(false);
      _loadingSubject.add(false);
    } catch (e) {
      _errorSubject.add(e.toString());
      _loadingSubject.add(false);
    }
  }
  
  Future<MtgDeck?> getDeck(String id) async {
    try {
      final doc = await _firestore.collection('decks').doc(id).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return MtgDeck.fromJson(data);
      }
      return null;
    } catch (e) {
      _errorSubject.add(e.toString());
      return null;
    }
  }
  
  Future<bool> createDeck(MtgDeck deck) async {
    try {
      await _firestore.collection('decks').doc(deck.id).set(deck.toJson());
      return true;
    } catch (e) {
      _errorSubject.add(e.toString());
      return false;
    }
  }
  
  Future<bool> updateDeck(MtgDeck deck) async {
    try {
      await _firestore.collection('decks').doc(deck.id).update(deck.toJson());
      
      // Update local cache
      final currentDecks = List<MtgDeck>.from(_decksSubject.value);
      final index = currentDecks.indexWhere((d) => d.id == deck.id);
      if (index != -1) {
        currentDecks[index] = deck;
        _decksSubject.add(currentDecks);
      }
      
      return true;
    } catch (e) {
      _errorSubject.add(e.toString());
      return false;
    }
  }
  
  Future<bool> deleteDeck(String id) async {
    try {
      await _firestore.collection('decks').doc(id).delete();
      
      // Update local cache
      final currentDecks = List<MtgDeck>.from(_decksSubject.value);
      currentDecks.removeWhere((deck) => deck.id == id);
      _decksSubject.add(currentDecks);
      
      return true;
    } catch (e) {
      _errorSubject.add(e.toString());
      return false;
    }
  }
  
  void clearSearch() {
    loadInitialDecks();
  }
  
  void dispose() {
    _decksSubscription?.cancel();
    _decksSubject.close();
    _loadingSubject.close();
    _hasMoreSubject.close();
    _errorSubject.close();
  }
}