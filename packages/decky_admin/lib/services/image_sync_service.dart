import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:decky_core/model/mtg/firebase_image_uris.dart';
import 'package:decky_core/model/mtg/mtg_card.dart';
import 'scryfall_service.dart';

class ImageSyncProgress {
  final int totalImages;
  final int completedImages;
  final String currentImage;
  final String status;

  ImageSyncProgress({
    required this.totalImages,
    required this.completedImages,
    required this.currentImage,
    required this.status,
  });

  double get progress => totalImages > 0 ? completedImages / totalImages : 0.0;
}

class ImageSyncService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScryfallService _scryfallService = ScryfallService();

  Future<void> syncCardImages(
    String cardId, 
    Function(ImageSyncProgress) onProgress
  ) async {
    try {
      onProgress(ImageSyncProgress(
        totalImages: 0,
        completedImages: 0,
        currentImage: 'Fetching Scryfall data...',
        status: 'fetching',
      ));

      final cardDoc = await _firestore.collection('cards').doc(cardId).get();
      if (!cardDoc.exists) {
        throw Exception('Card not found');
      }

      final card = MtgCard.fromJson({...cardDoc.data()!, 'uuid': cardDoc.id});
      final scryfallId = card.identifiers.scryfallId;
      
      if (scryfallId == null || scryfallId.isEmpty) {
        throw Exception('No Scryfall ID found for this card');
      }

      final scryfallCard = await _scryfallService.getCardById(scryfallId);
      
      if (scryfallCard?.imageUris == null) {
        throw Exception('No images found on Scryfall for this card');
      }

      final imageUris = scryfallCard!.imageUris!;
      final imageFormats = <String, String?>{
        'small': imageUris.small,
        'normal': imageUris.normal,
        'large': imageUris.large,
        'png': imageUris.png,
        'art_crop': imageUris.artCrop,
        'border_crop': imageUris.borderCrop,
      };

      final availableImages = imageFormats.entries
          .where((entry) => entry.value != null && entry.value!.isNotEmpty)
          .toList();

      onProgress(ImageSyncProgress(
        totalImages: availableImages.length,
        completedImages: 0,
        currentImage: 'Starting image sync...',
        status: 'syncing',
      ));

      final firebaseImageUris = <String, String>{};
      
      for (int i = 0; i < availableImages.length; i++) {
        final format = availableImages[i].key;
        final url = availableImages[i].value!;
        
        onProgress(ImageSyncProgress(
          totalImages: availableImages.length,
          completedImages: i,
          currentImage: 'Downloading $format image...',
          status: 'syncing',
        ));

        try {
          final downloadedImage = await _downloadImage(url);
          final firebaseUrl = await _uploadToFirebase(
            cardId, 
            format, 
            downloadedImage,
            _getContentType(url),
          );
          firebaseImageUris[format] = firebaseUrl;
          
          onProgress(ImageSyncProgress(
            totalImages: availableImages.length,
            completedImages: i + 1,
            currentImage: 'Uploaded $format image',
            status: 'syncing',
          ));
        } catch (e) {
          // Continue with other images if one fails
          continue;
        }
      }

      if (firebaseImageUris.isEmpty) {
        throw Exception('Failed to upload any images');
      }

      onProgress(ImageSyncProgress(
        totalImages: availableImages.length,
        completedImages: availableImages.length,
        currentImage: 'Updating card data...',
        status: 'updating',
      ));

      final firebaseImageUrisObject = FirebaseImageUris(
        small: firebaseImageUris['small'],
        normal: firebaseImageUris['normal'],
        large: firebaseImageUris['large'],
        png: firebaseImageUris['png'],
        artCrop: firebaseImageUris['art_crop'],
        borderCrop: firebaseImageUris['border_crop'],
      );

      await _firestore.collection('cards').doc(cardId).update({
        'firebaseImageUris': firebaseImageUrisObject.toJson(),
        'imageDataStatus': 'synced',
        'scryfallData': scryfallCard.toJson(),
        'importError': null, // Clear any previous errors
      });

      onProgress(ImageSyncProgress(
        totalImages: availableImages.length,
        completedImages: availableImages.length,
        currentImage: 'Sync completed successfully!',
        status: 'completed',
      ));
    } catch (e) {
      final errorMessage = e.toString();
      await _firestore.collection('cards').doc(cardId).update({
        'imageDataStatus': 'error',
        'importError': errorMessage,
      });
      
      onProgress(ImageSyncProgress(
        totalImages: 0,
        completedImages: 0,
        currentImage: 'Sync failed: $e',
        status: 'error',
      ));
      
      rethrow;
    }
  }

  Future<Uint8List> _downloadImage(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Failed to download image: ${response.statusCode}');
    }
    return response.bodyBytes;
  }

  Future<String> _uploadToFirebase(
    String cardId, 
    String format, 
    Uint8List imageData,
    String contentType,
  ) async {
    final fileName = '$format.${_getFileExtension(contentType)}';
    final path = 'cards/$cardId/images/$fileName';
    final ref = _storage.ref().child(path);
    
    final uploadTask = ref.putData(
      imageData,
      SettableMetadata(contentType: contentType),
    );
    
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  String _getContentType(String url) {
    if (url.toLowerCase().contains('.png')) return 'image/png';
    if (url.toLowerCase().contains('.jpg') || url.toLowerCase().contains('.jpeg')) return 'image/jpeg';
    if (url.toLowerCase().contains('.webp')) return 'image/webp';
    return 'image/jpeg'; // Default fallback
  }

  String _getFileExtension(String contentType) {
    switch (contentType) {
      case 'image/png':
        return 'png';
      case 'image/jpeg':
        return 'jpg';
      case 'image/webp':
        return 'webp';
      default:
        return 'jpg';
    }
  }
}

extension ScryfallCardJsonExtension on ScryfallCard {
  Map<String, dynamic> toJson() {
    return rawData;
  }
}

extension ScryfallImageUrisJsonExtension on ScryfallImageUris {
  Map<String, dynamic> toJson() {
    return {
      if (small != null) 'small': small,
      if (normal != null) 'normal': normal,
      if (large != null) 'large': large,
      if (png != null) 'png': png,
      if (artCrop != null) 'art_crop': artCrop,
      if (borderCrop != null) 'border_crop': borderCrop,
    };
  }
}