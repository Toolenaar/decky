import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../providers/search_provider.dart';

class RangeFilter extends StatefulWidget {
  final SearchProvider searchProvider;
  final String title;
  final double min;
  final double max;
  final int divisions;
  final String Function(double) formatValue;
  final void Function(double?, double?) onChanged;
  final double? currentMin;
  final double? currentMax;

  const RangeFilter({
    super.key,
    required this.searchProvider,
    required this.title,
    required this.min,
    required this.max,
    this.divisions = 20,
    required this.formatValue,
    required this.onChanged,
    this.currentMin,
    this.currentMax,
  });

  @override
  State<RangeFilter> createState() => _RangeFilterState();
}

class _RangeFilterState extends State<RangeFilter> {
  late RangeValues _currentRangeValues;
  late TextEditingController _minController;
  late TextEditingController _maxController;
  bool _isRangeActive = false;

  @override
  void initState() {
    super.initState();
    _isRangeActive = widget.currentMin != null || widget.currentMax != null;
    _currentRangeValues = RangeValues(
      widget.currentMin ?? widget.min,
      widget.currentMax ?? widget.max,
    );
    _minController = TextEditingController(
      text: widget.currentMin?.toString() ?? '',
    );
    _maxController = TextEditingController(
      text: widget.currentMax?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _updateRange(RangeValues values) {
    setState(() {
      _currentRangeValues = values;
      _minController.text = values.start.round().toString();
      _maxController.text = values.end.round().toString();
    });
    
    if (_isRangeActive) {
      widget.onChanged(values.start, values.end);
    }
  }

  void _updateFromTextFields() {
    final minValue = double.tryParse(_minController.text);
    final maxValue = double.tryParse(_maxController.text);
    
    if (minValue != null && maxValue != null) {
      final clampedMin = minValue.clamp(widget.min, widget.max);
      final clampedMax = maxValue.clamp(widget.min, widget.max);
      
      setState(() {
        _currentRangeValues = RangeValues(clampedMin, clampedMax);
      });
      
      if (_isRangeActive) {
        widget.onChanged(clampedMin, clampedMax);
      }
    }
  }

  void _toggleRange(bool active) {
    setState(() {
      _isRangeActive = active;
    });
    
    if (active) {
      widget.onChanged(_currentRangeValues.start, _currentRangeValues.end);
    } else {
      widget.onChanged(null, null);
    }
  }

  void _resetRange() {
    setState(() {
      _isRangeActive = false;
      _currentRangeValues = RangeValues(widget.min, widget.max);
      _minController.clear();
      _maxController.clear();
    });
    widget.onChanged(null, null);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Switch(
                  value: _isRangeActive,
                  onChanged: _toggleRange,
                ),
              ],
            ),
            if (_isRangeActive) ...[
              const SizedBox(height: 16),
              RangeSlider(
                values: _currentRangeValues,
                min: widget.min,
                max: widget.max,
                divisions: widget.divisions,
                labels: RangeLabels(
                  widget.formatValue(_currentRangeValues.start),
                  widget.formatValue(_currentRangeValues.end),
                ),
                onChanged: _updateRange,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minController,
                      decoration: const InputDecoration(
                        labelText: 'Min',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      onFieldSubmitted: (_) => _updateFromTextFields(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('to'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _maxController,
                      decoration: const InputDecoration(
                        labelText: 'Max',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      onFieldSubmitted: (_) => _updateFromTextFields(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: _resetRange,
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear'),
                  ),
                  const Spacer(),
                  Text(
                    '${widget.formatValue(_currentRangeValues.start)} - ${widget.formatValue(_currentRangeValues.end)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ManaValueFilter extends StatelessWidget {
  final SearchProvider searchProvider;

  const ManaValueFilter({
    super.key,
    required this.searchProvider,
  });

  @override
  Widget build(BuildContext context) {
    return RangeFilter(
      searchProvider: searchProvider,
      title: 'Mana Value',
      min: 0,
      max: 16,
      divisions: 16,
      formatValue: (value) => value.round().toString(),
      onChanged: searchProvider.setManaValueRange,
      currentMin: searchProvider.manaValueRange?.min,
      currentMax: searchProvider.manaValueRange?.max,
    );
  }
}

class PriceFilter extends StatelessWidget {
  final SearchProvider searchProvider;

  const PriceFilter({
    super.key,
    required this.searchProvider,
  });

  @override
  Widget build(BuildContext context) {
    return RangeFilter(
      searchProvider: searchProvider,
      title: 'Price (USD)',
      min: 0,
      max: 100,
      divisions: 20,
      formatValue: (value) => '\$${value.toStringAsFixed(0)}',
      onChanged: searchProvider.setPriceRange,
      currentMin: searchProvider.priceRange?.min,
      currentMax: searchProvider.priceRange?.max,
    );
  }
}