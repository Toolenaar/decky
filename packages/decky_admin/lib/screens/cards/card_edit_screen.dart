import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:decky_core/model/mtg/mtg_card.dart';
import 'package:decky_core/model/mtg/identifiers.dart';
import 'package:decky_core/model/mtg/legalities.dart';
import 'package:decky_core/model/mtg/purchase_urls.dart';
import '../../controllers/card_controller.dart';
import '../../widgets/scryfall_image_gallery.dart';
import '../../services/image_sync_service.dart';

class CardEditScreen extends StatefulWidget {
  final String? cardId;

  const CardEditScreen({super.key, this.cardId});

  @override
  State<CardEditScreen> createState() => _CardEditScreenState();
}

class _CardEditScreenState extends State<CardEditScreen> {
  final CardController _cardController = GetIt.instance<CardController>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _manaCostController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _powerController = TextEditingController();
  final TextEditingController _toughnessController = TextEditingController();
  final TextEditingController _setCodeController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _rarityController = TextEditingController();
  final TextEditingController _artistController = TextEditingController();
  final TextEditingController _flavorTextController = TextEditingController();
  final TextEditingController _scryfallIdController = TextEditingController();

  MtgCard? _originalCard;
  bool _isLoading = false;
  bool _isNewCard = false;
  final ImageSyncService _imageSyncService = ImageSyncService();
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _isNewCard = widget.cardId == null || widget.cardId == 'new';
    if (!_isNewCard) {
      _loadCard();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _manaCostController.dispose();
    _typeController.dispose();
    _textController.dispose();
    _powerController.dispose();
    _toughnessController.dispose();
    _setCodeController.dispose();
    _numberController.dispose();
    _rarityController.dispose();
    _artistController.dispose();
    _flavorTextController.dispose();
    _scryfallIdController.dispose();
    super.dispose();
  }

  Future<void> _loadCard() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final card = await _cardController.getCard(widget.cardId!);
      if (card != null && mounted) {
        setState(() {
          _originalCard = card;
          _populateForm(card);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading card: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _populateForm(MtgCard card) {
    _nameController.text = card.name;
    _manaCostController.text = card.manaCost ?? '';
    _typeController.text = card.type;
    _textController.text = card.text ?? '';
    _powerController.text = card.power ?? '';
    _toughnessController.text = card.toughness ?? '';
    _setCodeController.text = card.setCode;
    _numberController.text = card.number;
    _rarityController.text = card.rarity;
    _artistController.text = card.artist ?? '';
    _flavorTextController.text = card.flavorText ?? '';
    _scryfallIdController.text = card.identifiers.scryfallId ?? '';
  }

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final card = _createCardFromForm();
      bool success;
      
      if (_isNewCard) {
        success = await _cardController.createCard(card);
      } else {
        success = await _cardController.updateCard(card);
      }

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isNewCard 
                ? 'Card created successfully' 
                : 'Card updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/dashboard/cards');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isNewCard 
                ? 'Failed to create card' 
                : 'Failed to update card'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving card: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  MtgCard _createCardFromForm() {
    return MtgCard(
      id: _isNewCard 
        ? '${_setCodeController.text}_${_numberController.text}' 
        : _originalCard!.id,
      name: _nameController.text,
      manaCost: _manaCostController.text.isEmpty ? null : _manaCostController.text,
      type: _typeController.text,
      text: _textController.text.isEmpty ? null : _textController.text,
      power: _powerController.text.isEmpty ? null : _powerController.text,
      toughness: _toughnessController.text.isEmpty ? null : _toughnessController.text,
      setCode: _setCodeController.text,
      number: _numberController.text,
      rarity: _rarityController.text,
      artist: _artistController.text.isEmpty ? null : _artistController.text,
      flavorText: _flavorTextController.text.isEmpty ? null : _flavorTextController.text,
      // Required fields with defaults or from original
      availability: _originalCard?.availability ?? [],
      borderColor: _originalCard?.borderColor ?? 'black',
      colorIdentity: _originalCard?.colorIdentity ?? [],
      colors: _originalCard?.colors ?? [],
      convertedManaCost: _originalCard?.convertedManaCost ?? 0.0,
      finishes: _originalCard?.finishes ?? ['nonfoil'],
      frameVersion: _originalCard?.frameVersion ?? '2015',
      hasFoil: _originalCard?.hasFoil ?? false,
      hasNonFoil: _originalCard?.hasNonFoil ?? true,
      identifiers: Identifiers(
        scryfallId: _scryfallIdController.text.isEmpty ? null : _scryfallIdController.text,
        abuId: _originalCard?.identifiers.abuId,
        cardKingdomEtchedId: _originalCard?.identifiers.cardKingdomEtchedId,
        cardKingdomFoilId: _originalCard?.identifiers.cardKingdomFoilId,
        cardKingdomId: _originalCard?.identifiers.cardKingdomId,
        cardsphereId: _originalCard?.identifiers.cardsphereId,
        cardsphereFoilId: _originalCard?.identifiers.cardsphereFoilId,
        cardtraderId: _originalCard?.identifiers.cardtraderId,
        csiId: _originalCard?.identifiers.csiId,
        mcmId: _originalCard?.identifiers.mcmId,
        mcmMetaId: _originalCard?.identifiers.mcmMetaId,
        miniaturemarketId: _originalCard?.identifiers.miniaturemarketId,
        mtgArenaId: _originalCard?.identifiers.mtgArenaId,
        mtgjsonFoilVersionId: _originalCard?.identifiers.mtgjsonFoilVersionId,
        mtgjsonNonFoilVersionId: _originalCard?.identifiers.mtgjsonNonFoilVersionId,
        mtgjsonV4Id: _originalCard?.identifiers.mtgjsonV4Id,
        mtgoFoilId: _originalCard?.identifiers.mtgoFoilId,
        mtgoId: _originalCard?.identifiers.mtgoId,
        multiverseId: _originalCard?.identifiers.multiverseId,
        scgId: _originalCard?.identifiers.scgId,
        scryfallCardBackId: _originalCard?.identifiers.scryfallCardBackId,
        scryfallOracleId: _originalCard?.identifiers.scryfallOracleId,
        scryfallIllustrationId: _originalCard?.identifiers.scryfallIllustrationId,
        tcgplayerProductId: _originalCard?.identifiers.tcgplayerProductId,
        tcgplayerEtchedProductId: _originalCard?.identifiers.tcgplayerEtchedProductId,
        tntId: _originalCard?.identifiers.tntId,
      ),
      language: _originalCard?.language ?? 'English',
      layout: _originalCard?.layout ?? 'normal',
      legalities: _originalCard?.legalities ?? Legalities(),
      manaValue: _originalCard?.manaValue ?? 0.0,
      purchaseUrls: _originalCard?.purchaseUrls ?? PurchaseUrls(),
      subtypes: _originalCard?.subtypes ?? [],
      supertypes: _originalCard?.supertypes ?? [],
      types: _originalCard?.types ?? [],
    );
  }

  Future<void> _syncImages() async {
    if (_isNewCard || _originalCard == null || _scryfallIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Save the card first and ensure it has a Scryfall ID'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSyncing = true;
    });

    ImageSyncProgress? progress;
    StateSetter? dialogSetState;
    bool dialogOpen = true;

    try {
      // Show progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) {
            dialogSetState = setDialogState;
            return AlertDialog(
              title: const Text('Syncing Images'),
              content: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (progress != null) ...[
                      LinearProgressIndicator(value: progress!.progress),
                      const SizedBox(height: 16),
                      Text(
                        progress!.currentImage,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text('${progress!.completedImages}/${progress!.totalImages} images'),
                      const SizedBox(height: 8),
                      Text('Status: ${progress!.status}'),
                    ] else ...[
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      const Text('Initializing sync...'),
                    ],
                  ],
                ),
              ),
              actions: progress?.status == 'completed' || progress?.status == 'error'
                  ? [
                      TextButton(
                        onPressed: () {
                          dialogOpen = false;
                          Navigator.of(context).pop();
                        },
                        child: const Text('Close'),
                      ),
                    ]
                  : [],
            );
          },
        ),
      ).then((_) => dialogOpen = false);

      // Run the sync operation
      await _imageSyncService.syncCardImages(_originalCard!.id, (syncProgress) {
        progress = syncProgress;
        if (dialogOpen && mounted && dialogSetState != null) {
          dialogSetState!(() {});
        }
      });

      // Auto-close dialog if still open
      if (dialogOpen && mounted) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Images synced successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadCard();
      }
    } catch (e) {
      // Close dialog if still open
      if (dialogOpen && mounted) {
        Navigator.of(context).pop();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNewCard ? 'New Card' : 'Edit Card'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (!_isNewCard && _originalCard != null && _scryfallIdController.text.isNotEmpty)
            IconButton(
              icon: _isSyncing 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              onPressed: _isSyncing ? null : _syncImages,
              tooltip: 'Sync Images from Scryfall',
            ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _saveCard,
              child: const Text('Save'),
            ),
        ],
      ),
      body: _isLoading && _originalCard == null
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _nameController,
                      label: 'Name',
                      required: true,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _manaCostController,
                      label: 'Mana Cost',
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _typeController,
                      label: 'Type',
                      required: true,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _textController,
                      label: 'Text',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _powerController,
                            label: 'Power',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: _toughnessController,
                            label: 'Toughness',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _setCodeController,
                            label: 'Set Code',
                            required: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: _numberController,
                            label: 'Number',
                            required: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _rarityController,
                      label: 'Rarity',
                      required: true,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _artistController,
                      label: 'Artist',
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _flavorTextController,
                      label: 'Flavor Text',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _scryfallIdController,
                      label: 'Scryfall ID',
                    ),
                    const SizedBox(height: 16),
                    ScryfallImageGallery(
                      scryfallId: _scryfallIdController.text,
                      cardName: _nameController.text.isEmpty ? 'Card' : _nameController.text,
                      card: _originalCard,
                      key: ValueKey(_scryfallIdController.text),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => context.go('/dashboard/cards'),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveCard,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool required = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      maxLines: maxLines,
      validator: required
          ? (value) {
              if (value == null || value.isEmpty) {
                return '$label is required';
              }
              return null;
            }
          : null,
    );
  }
}