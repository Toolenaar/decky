import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';

class ScryfallImageUris {
  final String? small;
  final String? normal;
  final String? large;
  final String? png;
  final String? artCrop;
  final String? borderCrop;

  ScryfallImageUris({
    this.small,
    this.normal,
    this.large,
    this.png,
    this.artCrop,
    this.borderCrop,
  });

  factory ScryfallImageUris.fromJson(Map<String, dynamic> json) {
    return ScryfallImageUris(
      small: json['small']?.toString(),
      normal: json['normal']?.toString(),
      large: json['large']?.toString(),
      png: json['png']?.toString(),
      artCrop: json['art_crop']?.toString(),
      borderCrop: json['border_crop']?.toString(),
    );
  }
}

class ScryfallCard {
  final String id;
  final String name;
  final ScryfallImageUris? imageUris;
  final String? imageStatus;
  final Map<String, dynamic> rawData;

  ScryfallCard({
    required this.id,
    required this.name,
    this.imageUris,
    this.imageStatus,
    required this.rawData,
  });

  factory ScryfallCard.fromJson(Map<String, dynamic> json) {
    return ScryfallCard(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      imageUris: json['image_uris'] != null 
          ? ScryfallImageUris.fromJson(Map<String, dynamic>.from(json['image_uris'] as Map))
          : null,
      imageStatus: json['image_status']?.toString(),
      rawData: Map<String, dynamic>.from(json),
    );
  }
}

class ScryfallService {
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'europe-west3');

  Future<ScryfallCard?> getCardById(String cardId) async {
    try {
      final callable = _functions.httpsCallable('getScryfallCard');
      final result = await callable.call({'cardId': cardId});
      
      if (result.data != null) {
        final data = Map<String, dynamic>.from(result.data as Map);
        return ScryfallCard.fromJson(data);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
}