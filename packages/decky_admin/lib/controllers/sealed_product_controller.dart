import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'package:decky_core/model/mtg/mtg_sealed_product.dart';

class SealedProductController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final int _pageSize = 20;
  
  // Stream controllers
  final BehaviorSubject<List<MtgSealedProduct>> _productsSubject = BehaviorSubject.seeded([]);
  final BehaviorSubject<bool> _loadingSubject = BehaviorSubject.seeded(false);
  final BehaviorSubject<bool> _hasMoreSubject = BehaviorSubject.seeded(true);
  final BehaviorSubject<String?> _errorSubject = BehaviorSubject.seeded(null);
  
  // Streams
  Stream<List<MtgSealedProduct>> get productsStream => _productsSubject.stream;
  Stream<bool> get loadingStream => _loadingSubject.stream;
  Stream<bool> get hasMoreStream => _hasMoreSubject.stream;
  Stream<String?> get errorStream => _errorSubject.stream;
  
  // Current values
  List<MtgSealedProduct> get products => _productsSubject.value;
  bool get isLoading => _loadingSubject.value;
  bool get hasMore => _hasMoreSubject.value;
  
  // Pagination
  DocumentSnapshot? _lastDocument;
  StreamSubscription? _productsSubscription;
  
  Future<void> init() async {
    await loadInitialProducts();
  }
  
  Future<void> loadInitialProducts() async {
    try {
      _loadingSubject.add(true);
      _errorSubject.add(null);
      _lastDocument = null;
      
      final query = _firestore
          .collection('sealed-products')
          .orderBy('name')
          .limit(_pageSize);
      
      _productsSubscription?.cancel();
      _productsSubscription = query.snapshots().listen((snapshot) {
        final products = snapshot.docs.map((doc) {
          final data = doc.data();
          data['uuid'] = doc.id;
          return MtgSealedProduct.fromJson(data);
        }).toList();
        
        _productsSubject.add(products);
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
  
  Future<void> loadMoreProducts() async {
    if (_loadingSubject.value || !_hasMoreSubject.value || _lastDocument == null) {
      return;
    }
    
    try {
      _loadingSubject.add(true);
      
      final query = _firestore
          .collection('sealed-products')
          .orderBy('name')
          .startAfterDocument(_lastDocument!)
          .limit(_pageSize);
      
      final snapshot = await query.get();
      final newProducts = snapshot.docs.map((doc) {
        final data = doc.data();
        data['uuid'] = doc.id;
        return MtgSealedProduct.fromJson(data);
      }).toList();
      
      final currentProducts = List<MtgSealedProduct>.from(_productsSubject.value);
      currentProducts.addAll(newProducts);
      _productsSubject.add(currentProducts);
      
      _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      _hasMoreSubject.add(snapshot.docs.length == _pageSize);
      _loadingSubject.add(false);
    } catch (e) {
      _errorSubject.add(e.toString());
      _loadingSubject.add(false);
    }
  }
  
  Future<void> searchProducts(String query) async {
    try {
      _loadingSubject.add(true);
      _errorSubject.add(null);
      
      final searchQuery = _firestore
          .collection('sealed-products')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(50);
      
      final snapshot = await searchQuery.get();
      final products = snapshot.docs.map((doc) {
        final data = doc.data();
        data['uuid'] = doc.id;
        return MtgSealedProduct.fromJson(data);
      }).toList();
      
      _productsSubject.add(products);
      _hasMoreSubject.add(false);
      _loadingSubject.add(false);
    } catch (e) {
      _errorSubject.add(e.toString());
      _loadingSubject.add(false);
    }
  }
  
  Future<MtgSealedProduct?> getProduct(String id) async {
    try {
      final doc = await _firestore.collection('sealed-products').doc(id).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['uuid'] = doc.id;
        return MtgSealedProduct.fromJson(data);
      }
      return null;
    } catch (e) {
      _errorSubject.add(e.toString());
      return null;
    }
  }
  
  Future<bool> createProduct(MtgSealedProduct product) async {
    try {
      await _firestore.collection('sealed-products').doc(product.id).set(product.toJson());
      return true;
    } catch (e) {
      _errorSubject.add(e.toString());
      return false;
    }
  }
  
  Future<bool> updateProduct(MtgSealedProduct product) async {
    try {
      await _firestore.collection('sealed-products').doc(product.id).update(product.toJson());
      
      // Update local cache
      final currentProducts = List<MtgSealedProduct>.from(_productsSubject.value);
      final index = currentProducts.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        currentProducts[index] = product;
        _productsSubject.add(currentProducts);
      }
      
      return true;
    } catch (e) {
      _errorSubject.add(e.toString());
      return false;
    }
  }
  
  Future<bool> deleteProduct(String id) async {
    try {
      await _firestore.collection('sealed-products').doc(id).delete();
      
      // Update local cache
      final currentProducts = List<MtgSealedProduct>.from(_productsSubject.value);
      currentProducts.removeWhere((product) => product.id == id);
      _productsSubject.add(currentProducts);
      
      return true;
    } catch (e) {
      _errorSubject.add(e.toString());
      return false;
    }
  }
  
  void clearSearch() {
    loadInitialProducts();
  }
  
  void dispose() {
    _productsSubscription?.cancel();
    _productsSubject.close();
    _loadingSubject.close();
    _hasMoreSubject.close();
    _errorSubject.close();
  }
}