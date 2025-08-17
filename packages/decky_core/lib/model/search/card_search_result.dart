import '../mtg/firebase_image_uris.dart';
import 'elasticsearch_response.dart';

class CardSearchResult {
  final String id;
  final String name;
  final String? manaCost;
  final String type;
  final String setCode;
  final String rarity;
  final List<String> colors;
  final FirebaseImageUris? firebaseImageUris;
  final double? score;
  final Map<String, List<String>>? highlights;

  CardSearchResult({
    required this.id,
    required this.name,
    this.manaCost,
    required this.type,
    required this.setCode,
    required this.rarity,
    required this.colors,
    this.firebaseImageUris,
    this.score,
    this.highlights,
  });

  String toString() {
    return 'CardSearchResult(id: $id, name: $name, manaCost: $manaCost, type: $type, setCode: $setCode, rarity: $rarity, colors: $colors, firebaseImageUris: $firebaseImageUris, score: $score, highlights: $highlights)';
  }

  factory CardSearchResult.fromElasticsearchHit(ElasticsearchHit hit) {
    final source = hit.source;
    return CardSearchResult(
      id: source['uuid'] ?? hit.id,
      name: source['name'] ?? '',
      manaCost: source['mana_cost'],
      type: source['type'] ?? '',
      setCode: source['set_code'] ?? '',
      rarity: source['rarity'] ?? '',
      colors: List<String>.from(source['colors'] ?? []),
      firebaseImageUris: source['image_uris'] != null
          ? FirebaseImageUris.fromJson(Map<String, dynamic>.from(source['image_uris'] as Map))
          : null,
      score: hit.score,
      highlights: hit.highlight,
    );
  }

  String get displayName {
    if (highlights?['name']?.isNotEmpty == true) {
      return highlights!['name']!.first;
    }
    return name;
  }

  String get displayType {
    if (highlights?['type']?.isNotEmpty == true) {
      return highlights!['type']!.first;
    }
    return type;
  }

  String? get imageUrl {
    if (firebaseImageUris?.hasAnyImage == true) {
      return firebaseImageUris!.small ?? firebaseImageUris!.normal ?? firebaseImageUris!.large;
    }
    return null;
  }

  String? get mediumImageUrl {
    if (firebaseImageUris?.hasAnyImage == true) {
      return firebaseImageUris!.normal ?? firebaseImageUris!.large;
    }
    return null;
  }

  String? get largeImageUrl {
    if (firebaseImageUris?.hasAnyImage == true) {
      return firebaseImageUris!.large ?? firebaseImageUris!.png ?? firebaseImageUris!.normal;
    }
    return null;
  }
}
