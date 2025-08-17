import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'package:decky_core/model/mtg/mtg_token.dart';

class TokenController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final int _pageSize = 20;
  
  // Stream controllers
  final BehaviorSubject<List<MtgToken>> _tokensSubject = BehaviorSubject.seeded([]);
  final BehaviorSubject<bool> _loadingSubject = BehaviorSubject.seeded(false);
  final BehaviorSubject<bool> _hasMoreSubject = BehaviorSubject.seeded(true);
  final BehaviorSubject<String?> _errorSubject = BehaviorSubject.seeded(null);
  
  // Streams
  Stream<List<MtgToken>> get tokensStream => _tokensSubject.stream;
  Stream<bool> get loadingStream => _loadingSubject.stream;
  Stream<bool> get hasMoreStream => _hasMoreSubject.stream;
  Stream<String?> get errorStream => _errorSubject.stream;
  
  // Current values
  List<MtgToken> get tokens => _tokensSubject.value;
  bool get isLoading => _loadingSubject.value;
  bool get hasMore => _hasMoreSubject.value;
  
  // Pagination
  DocumentSnapshot? _lastDocument;
  StreamSubscription? _tokensSubscription;
  
  Future<void> init() async {
    await loadInitialTokens();
  }
  
  Future<void> loadInitialTokens() async {
    try {
      _loadingSubject.add(true);
      _errorSubject.add(null);
      _lastDocument = null;
      
      final query = _firestore
          .collection('tokens')
          .orderBy('name')
          .limit(_pageSize);
      
      _tokensSubscription?.cancel();
      _tokensSubscription = query.snapshots().listen((snapshot) {
        final tokens = snapshot.docs.map((doc) {
          final data = doc.data();
          data['uuid'] = doc.id;
          return MtgToken.fromJson(data);
        }).toList();
        
        _tokensSubject.add(tokens);
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
  
  Future<void> loadMoreTokens() async {
    if (_loadingSubject.value || !_hasMoreSubject.value || _lastDocument == null) {
      return;
    }
    
    try {
      _loadingSubject.add(true);
      
      final query = _firestore
          .collection('tokens')
          .orderBy('name')
          .startAfterDocument(_lastDocument!)
          .limit(_pageSize);
      
      final snapshot = await query.get();
      final newTokens = snapshot.docs.map((doc) {
        final data = doc.data();
        data['uuid'] = doc.id;
        return MtgToken.fromJson(data);
      }).toList();
      
      final currentTokens = List<MtgToken>.from(_tokensSubject.value);
      currentTokens.addAll(newTokens);
      _tokensSubject.add(currentTokens);
      
      _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      _hasMoreSubject.add(snapshot.docs.length == _pageSize);
      _loadingSubject.add(false);
    } catch (e) {
      _errorSubject.add(e.toString());
      _loadingSubject.add(false);
    }
  }
  
  Future<void> searchTokens(String query) async {
    try {
      _loadingSubject.add(true);
      _errorSubject.add(null);
      
      final searchQuery = _firestore
          .collection('tokens')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(50);
      
      final snapshot = await searchQuery.get();
      final tokens = snapshot.docs.map((doc) {
        final data = doc.data();
        data['uuid'] = doc.id;
        return MtgToken.fromJson(data);
      }).toList();
      
      _tokensSubject.add(tokens);
      _hasMoreSubject.add(false);
      _loadingSubject.add(false);
    } catch (e) {
      _errorSubject.add(e.toString());
      _loadingSubject.add(false);
    }
  }
  
  Future<MtgToken?> getToken(String id) async {
    try {
      final doc = await _firestore.collection('tokens').doc(id).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['uuid'] = doc.id;
        return MtgToken.fromJson(data);
      }
      return null;
    } catch (e) {
      _errorSubject.add(e.toString());
      return null;
    }
  }
  
  Future<bool> createToken(MtgToken token) async {
    try {
      await _firestore.collection('tokens').doc(token.id).set(token.toJson());
      return true;
    } catch (e) {
      _errorSubject.add(e.toString());
      return false;
    }
  }
  
  Future<bool> updateToken(MtgToken token) async {
    try {
      await _firestore.collection('tokens').doc(token.id).update(token.toJson());
      
      // Update local cache
      final currentTokens = List<MtgToken>.from(_tokensSubject.value);
      final index = currentTokens.indexWhere((t) => t.id == token.id);
      if (index != -1) {
        currentTokens[index] = token;
        _tokensSubject.add(currentTokens);
      }
      
      return true;
    } catch (e) {
      _errorSubject.add(e.toString());
      return false;
    }
  }
  
  Future<bool> deleteToken(String id) async {
    try {
      await _firestore.collection('tokens').doc(id).delete();
      
      // Update local cache
      final currentTokens = List<MtgToken>.from(_tokensSubject.value);
      currentTokens.removeWhere((token) => token.id == id);
      _tokensSubject.add(currentTokens);
      
      return true;
    } catch (e) {
      _errorSubject.add(e.toString());
      return false;
    }
  }
  
  void clearSearch() {
    loadInitialTokens();
  }
  
  void dispose() {
    _tokensSubscription?.cancel();
    _tokensSubject.close();
    _loadingSubject.close();
    _hasMoreSubject.close();
    _errorSubject.close();
  }
}