import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/srs_api.dart';
import '../services/haptic_service.dart';

/// Create SRS Flashcard Page
class SrsCreateCardPage extends ConsumerStatefulWidget {
  const SrsCreateCardPage({
    super.key,
    required this.srsApi,
  });

  final SrsApi srsApi;

  @override
  ConsumerState<SrsCreateCardPage> createState() => _SrsCreateCardPageState();
}

class _SrsCreateCardPageState extends ConsumerState<SrsCreateCardPage> {
  final _formKey = GlobalKey<FormState>();
  final _frontController = TextEditingController();
  final _backController = TextEditingController();
  final _deckController = TextEditingController(text: 'default');
  final _tagsController = TextEditingController();

  bool _creating = false;
  String? _error;

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    _deckController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _createCard() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _creating = true;
      _error = null;
    });

    try {
      // Parse tags (comma-separated)
      final tagsText = _tagsController.text.trim();
      final tags = tagsText.isEmpty
          ? <String>[]
          : tagsText.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();

      await widget.srsApi.createCard(
        front: _frontController.text.trim(),
        back: _backController.text.trim(),
        deck: _deckController.text.trim(),
        tags: tags,
      );

      HapticService.success();

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to create card: $e';
        _creating = false;
      });
      HapticService.error();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Flashcard'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Front (Question)
            Text(
              'Front (Question)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _frontController,
              decoration: InputDecoration(
                hintText: 'What is the capital of France?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the front of the card';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Back (Answer)
            Text(
              'Back (Answer)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _backController,
              decoration: InputDecoration(
                hintText: 'Paris',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the back of the card';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Deck
            Text(
              'Deck',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _deckController,
              decoration: InputDecoration(
                hintText: 'default',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                helperText: 'Organize cards into decks',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a deck name';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Tags (optional)
            Text(
              'Tags (optional)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _tagsController,
              decoration: InputDecoration(
                hintText: 'geography, europe, capitals',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                helperText: 'Comma-separated tags for filtering',
              ),
            ),

            const SizedBox(height: 32),

            // Error message
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Card(
                  color: colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _error!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Create button
            FilledButton.icon(
              onPressed: _creating ? null : _createCard,
              icon: _creating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.add),
              label: Text(_creating ? 'Creating...' : 'Create Card'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Tips card
            Card(
              color: colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tips for Better Cards',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTip(
                      theme,
                      colorScheme,
                      'Keep it simple: One concept per card',
                    ),
                    _buildTip(
                      theme,
                      colorScheme,
                      'Use clear, concise language',
                    ),
                    _buildTip(
                      theme,
                      colorScheme,
                      'Add context when needed',
                    ),
                    _buildTip(
                      theme,
                      colorScheme,
                      'Use decks to organize topics',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(ThemeData theme, ColorScheme colorScheme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Icon(
              Icons.check_circle,
              size: 16,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
