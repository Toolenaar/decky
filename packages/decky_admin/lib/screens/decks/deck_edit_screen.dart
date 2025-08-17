import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:decky_core/model/mtg/mtg_deck.dart';
import '../../controllers/deck_controller.dart';

class DeckEditScreen extends StatefulWidget {
  final String? deckId;

  const DeckEditScreen({super.key, this.deckId});

  @override
  State<DeckEditScreen> createState() => _DeckEditScreenState();
}

class _DeckEditScreenState extends State<DeckEditScreen> {
  final DeckController _deckController = GetIt.instance<DeckController>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _setCodeController = TextEditingController();
  final TextEditingController _releaseDateController = TextEditingController();

  MtgDeck? _originalDeck;
  bool _isLoading = false;
  bool _isNewDeck = false;

  @override
  void initState() {
    super.initState();
    _isNewDeck = widget.deckId == null || widget.deckId == 'new';
    if (!_isNewDeck) {
      _loadDeck();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _typeController.dispose();
    _setCodeController.dispose();
    _releaseDateController.dispose();
    super.dispose();
  }

  Future<void> _loadDeck() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final deck = await _deckController.getDeck(widget.deckId!);
      if (deck != null && mounted) {
        setState(() {
          _originalDeck = deck;
          _populateForm(deck);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading deck: $e'),
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

  void _populateForm(MtgDeck deck) {
    _nameController.text = deck.name;
    _codeController.text = deck.code;
    _typeController.text = deck.type;
    _setCodeController.text = deck.setCode;
    _releaseDateController.text = deck.releaseDate ?? '';
  }

  Future<void> _saveDeck() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final deck = _createDeckFromForm();
      bool success;
      
      if (_isNewDeck) {
        success = await _deckController.createDeck(deck);
      } else {
        success = await _deckController.updateDeck(deck);
      }

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isNewDeck 
                ? 'Deck created successfully' 
                : 'Deck updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/dashboard/decks');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isNewDeck 
                ? 'Failed to create deck' 
                : 'Failed to update deck'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving deck: $e'),
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

  MtgDeck _createDeckFromForm() {
    return MtgDeck(
      id: _isNewDeck 
        ? '${_setCodeController.text}_${_codeController.text}' 
        : _originalDeck!.id,
      name: _nameController.text,
      code: _codeController.text,
      type: _typeController.text,
      setCode: _setCodeController.text,
      releaseDate: _releaseDateController.text.isEmpty ? null : _releaseDateController.text,
      // Required fields with defaults or from original
      mainBoard: _originalDeck?.mainBoard ?? [],
      sideBoard: _originalDeck?.sideBoard ?? [],
      commander: _originalDeck?.commander,
      sealedProductUuids: _originalDeck?.sealedProductUuids,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNewDeck ? 'New Deck' : 'Edit Deck'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
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
              onPressed: _saveDeck,
              child: const Text('Save'),
            ),
        ],
      ),
      body: _isLoading && _originalDeck == null
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
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _codeController,
                            label: 'Code',
                            required: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: _setCodeController,
                            label: 'Set Code',
                            required: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _typeController,
                      label: 'Type',
                      required: true,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _releaseDateController,
                      label: 'Release Date',
                    ),
                    const SizedBox(height: 32),
                    if (_originalDeck != null) ...[
                      Text(
                        'Deck Statistics',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Main Board Cards:'),
                                  Text('${_originalDeck!.mainBoard.length}'),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Side Board Cards:'),
                                  Text('${_originalDeck!.sideBoard.length}'),
                                ],
                              ),
                              if (_originalDeck!.commander?.isNotEmpty == true) ...[
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Commander Cards:'),
                                    Text('${_originalDeck!.commander!.length}'),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => context.go('/dashboard/decks'),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveDeck,
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
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
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