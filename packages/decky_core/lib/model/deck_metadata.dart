import 'package:cloud_firestore/cloud_firestore.dart';

enum DeckPrivacy { private, friends, public }

enum DeckStatus { draft, published, archived }

class DeckMetadata {
  final String description;
  final List<String> tags;
  final DeckPrivacy privacy;
  final DeckStatus status;
  final int likes;
  final int views;
  final int shares;
  final int forks;
  final double? averageRating;
  final int ratingCount;
  final String? featuredImageUrl;
  final Map<String, dynamic>? deckStats;
  final List<String>? collaborators;
  final bool allowComments;
  final bool allowForks;
  final String? lastPlayedFormat;
  final Timestamp? lastPlayedAt;
  final Map<String, int>? formatStats;

  DeckMetadata({
    this.description = '',
    this.tags = const [],
    this.privacy = DeckPrivacy.private,
    this.status = DeckStatus.draft,
    this.likes = 0,
    this.views = 0,
    this.shares = 0,
    this.forks = 0,
    this.averageRating,
    this.ratingCount = 0,
    this.featuredImageUrl,
    this.deckStats,
    this.collaborators,
    this.allowComments = true,
    this.allowForks = true,
    this.lastPlayedFormat,
    this.lastPlayedAt,
    this.formatStats,
  });

  factory DeckMetadata.fromJson(Map<String, dynamic> json) {
    return DeckMetadata(
      description: json['description'] ?? '',
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      privacy: DeckPrivacy.values.firstWhere(
        (e) => e.toString().split('.').last == (json['privacy'] ?? 'private'),
        orElse: () => DeckPrivacy.private,
      ),
      status: DeckStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (json['status'] ?? 'draft'),
        orElse: () => DeckStatus.draft,
      ),
      likes: json['likes'] ?? 0,
      views: json['views'] ?? 0,
      shares: json['shares'] ?? 0,
      forks: json['forks'] ?? 0,
      averageRating: json['averageRating']?.toDouble(),
      ratingCount: json['ratingCount'] ?? 0,
      featuredImageUrl: json['featuredImageUrl'],
      deckStats: json['deckStats'] != null 
          ? Map<String, dynamic>.from(json['deckStats'])
          : null,
      collaborators: json['collaborators'] != null 
          ? List<String>.from(json['collaborators'])
          : null,
      allowComments: json['allowComments'] ?? true,
      allowForks: json['allowForks'] ?? true,
      lastPlayedFormat: json['lastPlayedFormat'],
      lastPlayedAt: json['lastPlayedAt'],
      formatStats: json['formatStats'] != null 
          ? Map<String, int>.from(json['formatStats'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'tags': tags,
      'privacy': privacy.toString().split('.').last,
      'status': status.toString().split('.').last,
      'likes': likes,
      'views': views,
      'shares': shares,
      'forks': forks,
      if (averageRating != null) 'averageRating': averageRating,
      'ratingCount': ratingCount,
      if (featuredImageUrl != null) 'featuredImageUrl': featuredImageUrl,
      if (deckStats != null) 'deckStats': deckStats,
      if (collaborators != null) 'collaborators': collaborators,
      'allowComments': allowComments,
      'allowForks': allowForks,
      if (lastPlayedFormat != null) 'lastPlayedFormat': lastPlayedFormat,
      if (lastPlayedAt != null) 'lastPlayedAt': lastPlayedAt,
      if (formatStats != null) 'formatStats': formatStats,
    };
  }

  DeckMetadata copyWith({
    String? description,
    List<String>? tags,
    DeckPrivacy? privacy,
    DeckStatus? status,
    int? likes,
    int? views,
    int? shares,
    int? forks,
    double? averageRating,
    int? ratingCount,
    String? featuredImageUrl,
    Map<String, dynamic>? deckStats,
    List<String>? collaborators,
    bool? allowComments,
    bool? allowForks,
    String? lastPlayedFormat,
    Timestamp? lastPlayedAt,
    Map<String, int>? formatStats,
  }) {
    return DeckMetadata(
      description: description ?? this.description,
      tags: tags ?? this.tags,
      privacy: privacy ?? this.privacy,
      status: status ?? this.status,
      likes: likes ?? this.likes,
      views: views ?? this.views,
      shares: shares ?? this.shares,
      forks: forks ?? this.forks,
      averageRating: averageRating ?? this.averageRating,
      ratingCount: ratingCount ?? this.ratingCount,
      featuredImageUrl: featuredImageUrl ?? this.featuredImageUrl,
      deckStats: deckStats ?? this.deckStats,
      collaborators: collaborators ?? this.collaborators,
      allowComments: allowComments ?? this.allowComments,
      allowForks: allowForks ?? this.allowForks,
      lastPlayedFormat: lastPlayedFormat ?? this.lastPlayedFormat,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      formatStats: formatStats ?? this.formatStats,
    );
  }
}