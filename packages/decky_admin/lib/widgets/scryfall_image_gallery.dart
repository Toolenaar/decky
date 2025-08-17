import 'package:flutter/material.dart';
import 'package:decky_core/model/mtg/mtg_card.dart';
import 'package:decky_core/model/mtg/firebase_image_uris.dart';
import '../services/scryfall_service.dart';

class ScryfallImageGallery extends StatefulWidget {
  final String? scryfallId;
  final String cardName;
  final MtgCard? card;

  const ScryfallImageGallery({
    super.key,
    this.scryfallId,
    required this.cardName,
    this.card,
  });

  @override
  State<ScryfallImageGallery> createState() => _ScryfallImageGalleryState();
}

class _ScryfallImageGalleryState extends State<ScryfallImageGallery> {
  final ScryfallService _scryfallService = ScryfallService();
  ScryfallCard? _scryfallCard;
  bool _loading = false;
  String? _error;
  String _selectedFormat = 'normal';

  final Map<String, String> _imageFormats = {
    'small': 'Small (146×204)',
    'normal': 'Normal (488×680)',
    'large': 'Large (672×936)',
    'png': 'PNG (745×1040)',
    'art_crop': 'Art Crop',
    'border_crop': 'Border Crop (480×680)',
  };

  @override
  void initState() {
    super.initState();
    if (widget.scryfallId != null && widget.scryfallId!.isNotEmpty) {
      _loadScryfallData();
    }
  }

  @override
  void didUpdateWidget(ScryfallImageGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scryfallId != oldWidget.scryfallId) {
      if (widget.scryfallId != null && widget.scryfallId!.isNotEmpty) {
        _loadScryfallData();
      } else {
        setState(() {
          _scryfallCard = null;
          _error = null;
        });
      }
    }
  }

  Future<void> _loadScryfallData() async {
    if (widget.scryfallId == null || widget.scryfallId!.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final card = await _scryfallService.getCardById(widget.scryfallId!);
      setState(() {
        _scryfallCard = card;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load Scryfall data: $e';
        _loading = false;
      });
    }
  }

  String? _getImageUrl(String format) {
    if (widget.card?.firebaseImageUris != null) {
      final firebaseUris = widget.card!.firebaseImageUris!;
      switch (format) {
        case 'small':
          return firebaseUris.small;
        case 'normal':
          return firebaseUris.normal;
        case 'large':
          return firebaseUris.large;
        case 'png':
          return firebaseUris.png;
        case 'art_crop':
          return firebaseUris.artCrop;
        case 'border_crop':
          return firebaseUris.borderCrop;
        default:
          return firebaseUris.normal;
      }
    }
    
    if (_scryfallCard?.imageUris == null) return null;
    
    switch (format) {
      case 'small':
        return _scryfallCard!.imageUris!.small;
      case 'normal':
        return _scryfallCard!.imageUris!.normal;
      case 'large':
        return _scryfallCard!.imageUris!.large;
      case 'png':
        return _scryfallCard!.imageUris!.png;
      case 'art_crop':
        return _scryfallCard!.imageUris!.artCrop;
      case 'border_crop':
        return _scryfallCard!.imageUris!.borderCrop;
      default:
        return _scryfallCard!.imageUris!.normal;
    }
  }

  bool _isUsingFirebaseImages() {
    return widget.card?.firebaseImageUris?.hasAnyImage == true;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.scryfallId == null || widget.scryfallId!.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
              const SizedBox(height: 8),
              Text(
                'No Scryfall ID provided',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _isUsingFirebaseImages() ? 'Card Images' : 'Scryfall Images',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_isUsingFirebaseImages())
                  Chip(
                    label: const Text('Firebase'),
                    backgroundColor: Colors.green[100],
                    avatar: const Icon(Icons.cloud_done, size: 16),
                  )
                else
                  Chip(
                    label: const Text('Scryfall'),
                    backgroundColor: Colors.blue[100],
                    avatar: const Icon(Icons.link, size: 16),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                    TextButton(
                      onPressed: _loadScryfallData,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (_scryfallCard?.imageUris == null)
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No images available for this card',
                        style: TextStyle(color: Colors.orange[700]),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              DropdownButtonFormField<String>(
                value: _selectedFormat,
                decoration: const InputDecoration(
                  labelText: 'Image Format',
                  border: OutlineInputBorder(),
                ),
                items: _imageFormats.entries.map((entry) {
                  final isAvailable = _getImageUrl(entry.key) != null;
                  return DropdownMenuItem(
                    value: entry.key,
                    enabled: isAvailable,
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        color: isAvailable ? null : Colors.grey,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedFormat = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              Center(
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: 400,
                    maxHeight: 600,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _getImageUrl(_selectedFormat) != null
                        ? Image.network(
                            _getImageUrl(_selectedFormat)!,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 200,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.broken_image, size: 48, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text('Failed to load image'),
                                    ],
                                  ),
                                ),
                              );
                            },
                          )
                        : Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Image not available'),
                                ],
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              if (_scryfallCard?.imageStatus != null) ...[
                const SizedBox(height: 8),
                Center(
                  child: Chip(
                    label: Text('Status: ${_scryfallCard!.imageStatus}'),
                    backgroundColor: _getStatusColor(_scryfallCard!.imageStatus!),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'highres_scan':
        return Colors.green[100]!;
      case 'lowres':
        return Colors.orange[100]!;
      case 'placeholder':
        return Colors.yellow[100]!;
      case 'missing':
        return Colors.red[100]!;
      default:
        return Colors.grey[100]!;
    }
  }
}