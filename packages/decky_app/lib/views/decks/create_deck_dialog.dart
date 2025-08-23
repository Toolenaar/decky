import 'package:flutter/material.dart';
import 'package:decky_core/model/user_deck.dart';
import 'package:easy_localization/easy_localization.dart';

class CreateDeckDialog extends StatefulWidget {
  const CreateDeckDialog({super.key});

  @override
  State<CreateDeckDialog> createState() => _CreateDeckDialogState();
}

class _CreateDeckDialogState extends State<CreateDeckDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  MtgFormat _selectedFormat = MtgFormat.standard;

  final Map<MtgFormat, String> _formatDisplayNames = {
    MtgFormat.standard: 'Standard',
    MtgFormat.pioneer: 'Pioneer',
    MtgFormat.modern: 'Modern',
    MtgFormat.legacy: 'Legacy',
    MtgFormat.vintage: 'Vintage',
    MtgFormat.commander: 'Commander',
    MtgFormat.commanderOnehundred: 'Commander 1v1',
    MtgFormat.pauper: 'Pauper',
    MtgFormat.pauperCommander: 'Pauper Commander',
    MtgFormat.historic: 'Historic',
    MtgFormat.alchemy: 'Alchemy',
    MtgFormat.explorer: 'Explorer',
    MtgFormat.brawl: 'Brawl',
    MtgFormat.standardBrawl: 'Standard Brawl',
    MtgFormat.limited: 'Limited',
    MtgFormat.cube: 'Cube',
    MtgFormat.custom: 'Custom',
  };

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;
    
    return Dialog(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 500 : double.infinity,
          maxHeight: isDesktop ? 400 : MediaQuery.of(context).size.height * 0.8,
        ),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'decks.create_deck.title'.tr(),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'decks.create_deck.name_label'.tr(),
                  hintText: 'decks.create_deck.name_hint'.tr(),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.edit),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'decks.create_deck.name_required'.tr();
                  }
                  if (value.trim().length < 3) {
                    return 'decks.create_deck.name_too_short'.tr();
                  }
                  if (value.trim().length > 50) {
                    return 'decks.create_deck.name_too_long'.tr();
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
                maxLength: 50,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<MtgFormat>(
                initialValue: _selectedFormat,
                decoration: InputDecoration(
                  labelText: 'decks.create_deck.format_label'.tr(),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.category),
                ),
                items: MtgFormat.values.map((format) {
                  return DropdownMenuItem(
                    value: format,
                    child: Row(
                      children: [
                        Text(_formatDisplayNames[format] ?? format.toString()),
                        if (_isCommanderFormat(format)) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '100',
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ] else if (_isConstructedFormat(format)) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '60+',
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context).colorScheme.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (format) {
                  if (format != null) {
                    setState(() {
                      _selectedFormat = format;
                    });
                  }
                },
              ),
              const SizedBox(height: 8),
              Text(
                _getFormatDescription(_selectedFormat),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('common.cancel'.tr()),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _createDeck,
                    icon: const Icon(Icons.add),
                    label: Text('decks.create_deck.create_button'.tr()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isCommanderFormat(MtgFormat format) {
    return format == MtgFormat.commander ||
        format == MtgFormat.commanderOnehundred ||
        format == MtgFormat.pauperCommander ||
        format == MtgFormat.brawl ||
        format == MtgFormat.standardBrawl;
  }

  bool _isConstructedFormat(MtgFormat format) {
    return format == MtgFormat.standard ||
        format == MtgFormat.pioneer ||
        format == MtgFormat.modern ||
        format == MtgFormat.legacy ||
        format == MtgFormat.vintage ||
        format == MtgFormat.historic ||
        format == MtgFormat.alchemy ||
        format == MtgFormat.explorer ||
        format == MtgFormat.pauper;
  }

  String _getFormatDescription(MtgFormat format) {
    switch (format) {
      case MtgFormat.commander:
        return 'decks.formats.commander_desc'.tr();
      case MtgFormat.standard:
        return 'decks.formats.standard_desc'.tr();
      case MtgFormat.modern:
        return 'decks.formats.modern_desc'.tr();
      case MtgFormat.pioneer:
        return 'decks.formats.pioneer_desc'.tr();
      case MtgFormat.legacy:
        return 'decks.formats.legacy_desc'.tr();
      case MtgFormat.vintage:
        return 'decks.formats.vintage_desc'.tr();
      case MtgFormat.pauper:
        return 'decks.formats.pauper_desc'.tr();
      case MtgFormat.limited:
        return 'decks.formats.limited_desc'.tr();
      default:
        return '';
    }
  }

  void _createDeck() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop({
        'name': _nameController.text.trim(),
        'format': _selectedFormat,
      });
    }
  }
}