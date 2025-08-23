import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:decky_core/model/deck_metadata.dart';
import 'package:decky_core/model/user_deck.dart';
import 'package:decky_core/model/deck_card.dart';
import 'package:decky_core/model/base_model.dart';
import 'package:decky_core/model/mtg/mtg_card.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/subjects.dart';

class UserDecksController extends ChangeNotifier {
  final BehaviorSubject<List<UserDeck>> _decksSubject = BehaviorSubject.seeded([]);
  final BehaviorSubject<bool> _loadingSubject = BehaviorSubject.seeded(false);
  final BehaviorSubject<String?> _errorSubject = BehaviorSubject.seeded(null);
  
  // Deck cards management
  final Map<String, BehaviorSubject<List<DeckCard>>> _deckCardsSubjects = {};
  final Map<String, StreamSubscription<QuerySnapshot>?> _deckCardsSubscriptions = {};

  StreamSubscription<QuerySnapshot>? _decksSubscription;
  String? _accountId;

  Stream<List<UserDeck>> get decksStream => _decksSubject.stream;
  Stream<bool> get loadingStream => _loadingSubject.stream;
  Stream<String?> get errorStream => _errorSubject.stream;

  List<UserDeck> get decks => _decksSubject.value;
  bool get isLoading => _loadingSubject.value;
  String? get error => _errorSubject.value;

  UserDecksController();

  void initialize(String accountId) {
    _accountId = accountId;
    _listenToDecks();
  }

  void _listenToDecks() {
    _decksSubscription?.cancel();
    _loadingSubject.add(true);
    _errorSubject.add(null);

    _decksSubscription = FirebaseFirestore.instance
        .collection('accounts')
        .doc(_accountId)
        .collection('decks')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            final decks = snapshot.docs.map((doc) {
              return UserDeck.fromJson(doc.id, doc.data());
            }).toList();

            _decksSubject.add(decks);
            _loadingSubject.add(false);
            notifyListeners();
          },
          onError: (error) {
            _errorSubject.add(error.toString());
            _loadingSubject.add(false);
            notifyListeners();
          },
        );
  }

  Future<UserDeck> createDeck({
    required String name,
    required MtgFormat format,
    String? description,
    String? coverImageUrl,
  }) async {
    if (_accountId == null) {
      throw Exception('No account ID available');
    }

    try {
      _loadingSubject.add(true);
      _errorSubject.add(null);

      final deckId = BaseModel.newId(
        FirebaseFirestore.instance.collection('accounts').doc(_accountId).collection('decks'),
      );

      final deck = UserDeck(
        id: deckId,
        accountId: _accountId!,
        name: name,
        format: format,
        metadata: DeckMetadata(description: description ?? ''),
        coverImageUrl: coverImageUrl,
      );

      await deck.create();

      _loadingSubject.add(false);
      notifyListeners();

      return deck;
    } catch (e) {
      _errorSubject.add(e.toString());
      _loadingSubject.add(false);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateDeck(UserDeck deck, Map<String, dynamic> updates) async {
    try {
      _loadingSubject.add(true);
      _errorSubject.add(null);

      await deck.update(updates);

      _loadingSubject.add(false);
      notifyListeners();
    } catch (e) {
      _errorSubject.add(e.toString());
      _loadingSubject.add(false);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteDeck(UserDeck deck) async {
    try {
      _loadingSubject.add(true);
      _errorSubject.add(null);

      await deck.delete();

      _loadingSubject.add(false);
      notifyListeners();
    } catch (e) {
      _errorSubject.add(e.toString());
      _loadingSubject.add(false);
      notifyListeners();
      rethrow;
    }
  }

  UserDeck? getDeckById(String id) {
    try {
      return _decksSubject.value.firstWhere((deck) => deck.id == id);
    } catch (e) {
      return null;
    }
  }

  // Deck Cards Management
  Stream<List<DeckCard>> getDeckCardsStream(String deckId) {
    if (!_deckCardsSubjects.containsKey(deckId)) {
      _deckCardsSubjects[deckId] = BehaviorSubject.seeded([]);
      _listenToDeckCards(deckId);
    }
    return _deckCardsSubjects[deckId]!.stream;
  }

  List<DeckCard> getDeckCards(String deckId) {
    if (!_deckCardsSubjects.containsKey(deckId)) {
      _deckCardsSubjects[deckId] = BehaviorSubject.seeded([]);
      _listenToDeckCards(deckId);
    }
    return _deckCardsSubjects[deckId]!.value;
  }

  int getDeckCardCount(String deckId) {
    final cards = getDeckCards(deckId);
    return cards.fold(0, (total, card) => total + (card.isInSideboard ? 0 : card.count));
  }

  int getCardCountInDeck(String deckId, String cardUuid) {
    final cards = getDeckCards(deckId);
    final card = cards.where((c) => c.cardUuid == cardUuid).firstOrNull;
    return card?.count ?? 0;
  }

  void _listenToDeckCards(String deckId) {
    if (_accountId == null) return;

    _deckCardsSubscriptions[deckId]?.cancel();
    
    _deckCardsSubscriptions[deckId] = FirebaseFirestore.instance
        .collection('accounts')
        .doc(_accountId)
        .collection('decks')
        .doc(deckId)
        .collection('cards')
        .snapshots()
        .listen(
      (snapshot) {
        final cards = snapshot.docs.map((doc) {
          return DeckCard.fromJson(doc.data(), doc.id);
        }).toList();
        
        _deckCardsSubjects[deckId]?.add(cards);
        notifyListeners();
      },
      onError: (error) {
        _errorSubject.add(error.toString());
        notifyListeners();
      },
    );
  }

  Future<DeckCard> addCardToDeck({
    required String deckId,
    required MtgCard mtgCard,
    int count = 1,
    bool isCommander = false,
    bool isInSideboard = false,
    String? notes,
  }) async {
    if (_accountId == null) {
      throw Exception('No account ID available');
    }

    try {
      _loadingSubject.add(true);
      _errorSubject.add(null);

      // Check if card already exists in deck
      final existingCards = getDeckCards(deckId);
      final existingCard = existingCards.where((c) => 
        c.cardUuid == mtgCard.id && 
        c.isCommander == isCommander && 
        c.isInSideboard == isInSideboard
      ).firstOrNull;

      if (existingCard != null) {
        // Update existing card count
        final updatedCard = existingCard.copyWith(count: existingCard.count + count);
        await updatedCard.update({'count': updatedCard.count});
        _loadingSubject.add(false);
        return updatedCard;
      } else {
        // Create new deck card entry
        final cardId = BaseModel.newId(
          FirebaseFirestore.instance
              .collection('accounts')
              .doc(_accountId)
              .collection('decks')
              .doc(deckId)
              .collection('cards'),
        );

        final deckCard = DeckCard(
          id: cardId,
          cardUuid: mtgCard.id,
          count: count,
          isCommander: isCommander,
          isInSideboard: isInSideboard,
          accountId: _accountId!,
          deckId: deckId,
          mtgCardReference: mtgCard,
          notes: notes,
        );

        await deckCard.create();
        _loadingSubject.add(false);
        return deckCard;
      }
    } catch (e) {
      _errorSubject.add(e.toString());
      _loadingSubject.add(false);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> removeCardFromDeck({
    required String deckId,
    required String cardUuid,
    int count = 1,
    bool isCommander = false,
    bool isInSideboard = false,
  }) async {
    try {
      _loadingSubject.add(true);
      _errorSubject.add(null);

      final existingCards = getDeckCards(deckId);
      final existingCard = existingCards.where((c) => 
        c.cardUuid == cardUuid && 
        c.isCommander == isCommander && 
        c.isInSideboard == isInSideboard
      ).firstOrNull;

      if (existingCard != null) {
        final newCount = existingCard.count - count;
        if (newCount <= 0) {
          // Remove card entirely
          await existingCard.delete();
        } else {
          // Update count
          await existingCard.update({'count': newCount});
        }
      }

      _loadingSubject.add(false);
      notifyListeners();
    } catch (e) {
      _errorSubject.add(e.toString());
      _loadingSubject.add(false);
      notifyListeners();
      rethrow;
    }
  }

  bool isDeckValid(UserDeck deck) {
    final cardCount = getDeckCardCount(deck.id);

    switch (deck.format) {
      case MtgFormat.commander:
      case MtgFormat.commanderOnehundred:
      case MtgFormat.pauperCommander:
      case MtgFormat.brawl:
      case MtgFormat.standardBrawl:
        return cardCount == 100;
      case MtgFormat.standard:
      case MtgFormat.pioneer:
      case MtgFormat.modern:
      case MtgFormat.legacy:
      case MtgFormat.vintage:
      case MtgFormat.historic:
      case MtgFormat.alchemy:
      case MtgFormat.explorer:
      case MtgFormat.pauper:
        return cardCount >= 60;
      case MtgFormat.limited:
        return cardCount >= 40;
      case MtgFormat.cube:
      case MtgFormat.custom:
        return true;
    }
  }

  @override
  void dispose() {
    _decksSubscription?.cancel();
    
    // Clean up deck cards subscriptions
    for (final subscription in _deckCardsSubscriptions.values) {
      subscription?.cancel();
    }
    _deckCardsSubscriptions.clear();
    
    // Close deck cards subjects
    for (final subject in _deckCardsSubjects.values) {
      subject.close();
    }
    _deckCardsSubjects.clear();
    
    _decksSubject.close();
    _loadingSubject.close();
    _errorSubject.close();
    super.dispose();
  }
}
