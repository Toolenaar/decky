import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'package:decky_core/model/mtg/mtg_set.dart';

class SetController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final int _pageSize = 20;
  
  // Stream controllers
  final BehaviorSubject<List<MtgSet>> _setsSubject = BehaviorSubject.seeded([]);
  final BehaviorSubject<bool> _loadingSubject = BehaviorSubject.seeded(false);
  final BehaviorSubject<bool> _hasMoreSubject = BehaviorSubject.seeded(true);
  final BehaviorSubject<String?> _errorSubject = BehaviorSubject.seeded(null);
  
  // Streams
  Stream<List<MtgSet>> get setsStream => _setsSubject.stream;
  Stream<bool> get loadingStream => _loadingSubject.stream;
  Stream<bool> get hasMoreStream => _hasMoreSubject.stream;
  Stream<String?> get errorStream => _errorSubject.stream;
  
  // Current values
  List<MtgSet> get sets => _setsSubject.value;
  bool get isLoading => _loadingSubject.value;
  bool get hasMore => _hasMoreSubject.value;
  
  // Pagination
  DocumentSnapshot? _lastDocument;
  StreamSubscription? _setsSubscription;
  
  Future<void> init() async {
    await loadInitialSets();
  }
  
  Future<void> loadInitialSets() async {
    try {
      _loadingSubject.add(true);
      _errorSubject.add(null);
      _lastDocument = null;
      
      final query = _firestore
          .collection('sets')
          .orderBy('releaseDate', descending: true)
          .limit(_pageSize);
      
      _setsSubscription?.cancel();
      _setsSubscription = query.snapshots().listen((snapshot) {
        final sets = snapshot.docs.map((doc) {
          final data = doc.data();
          data['code'] = doc.id;
          return MtgSet.fromJson(data);
        }).toList();
        
        _setsSubject.add(sets);
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
  
  Future<void> loadMoreSets() async {
    if (_loadingSubject.value || !_hasMoreSubject.value || _lastDocument == null) {
      return;
    }
    
    try {
      _loadingSubject.add(true);
      
      final query = _firestore
          .collection('sets')
          .orderBy('releaseDate', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(_pageSize);
      
      final snapshot = await query.get();
      final newSets = snapshot.docs.map((doc) {
        final data = doc.data();
        data['code'] = doc.id;
        return MtgSet.fromJson(data);
      }).toList();
      
      final currentSets = List<MtgSet>.from(_setsSubject.value);
      currentSets.addAll(newSets);
      _setsSubject.add(currentSets);
      
      _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      _hasMoreSubject.add(snapshot.docs.length == _pageSize);
      _loadingSubject.add(false);
    } catch (e) {
      _errorSubject.add(e.toString());
      _loadingSubject.add(false);
    }
  }
  
  Future<void> searchSets(String query) async {
    try {
      _loadingSubject.add(true);
      _errorSubject.add(null);
      
      final searchQuery = _firestore
          .collection('sets')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(50);
      
      final snapshot = await searchQuery.get();
      final sets = snapshot.docs.map((doc) {
        final data = doc.data();
        data['code'] = doc.id;
        return MtgSet.fromJson(data);
      }).toList();
      
      _setsSubject.add(sets);
      _hasMoreSubject.add(false);
      _loadingSubject.add(false);
    } catch (e) {
      _errorSubject.add(e.toString());
      _loadingSubject.add(false);
    }
  }
  
  Future<MtgSet?> getSet(String id) async {
    try {
      final doc = await _firestore.collection('sets').doc(id).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['code'] = doc.id;
        return MtgSet.fromJson(data);
      }
      return null;
    } catch (e) {
      _errorSubject.add(e.toString());
      return null;
    }
  }
  
  Future<bool> createSet(MtgSet set) async {
    try {
      await _firestore.collection('sets').doc(set.id).set(set.toJson());
      return true;
    } catch (e) {
      _errorSubject.add(e.toString());
      return false;
    }
  }
  
  Future<bool> updateSet(MtgSet set) async {
    try {
      await _firestore.collection('sets').doc(set.id).update(set.toJson());
      
      // Update local cache
      final currentSets = List<MtgSet>.from(_setsSubject.value);
      final index = currentSets.indexWhere((s) => s.id == set.id);
      if (index != -1) {
        currentSets[index] = set;
        _setsSubject.add(currentSets);
      }
      
      return true;
    } catch (e) {
      _errorSubject.add(e.toString());
      return false;
    }
  }
  
  Future<bool> deleteSet(String id) async {
    try {
      await _firestore.collection('sets').doc(id).delete();
      
      // Update local cache
      final currentSets = List<MtgSet>.from(_setsSubject.value);
      currentSets.removeWhere((set) => set.id == id);
      _setsSubject.add(currentSets);
      
      return true;
    } catch (e) {
      _errorSubject.add(e.toString());
      return false;
    }
  }
  
  void clearSearch() {
    loadInitialSets();
  }
  
  void dispose() {
    _setsSubscription?.cancel();
    _setsSubject.close();
    _loadingSubject.close();
    _hasMoreSubject.close();
    _errorSubject.close();
  }
}