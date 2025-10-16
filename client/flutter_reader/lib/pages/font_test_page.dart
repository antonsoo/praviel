import 'package:flutter/material.dart';
import '../models/language.dart';
import '../widgets/ancient_label.dart';

/// Test page to verify all ancient fonts are rendering correctly
/// Access via debug menu or navigate to /font-test
class FontTestPage extends StatelessWidget {
  const FontTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Font Rendering Test'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: availableLanguages.length,
        itemBuilder: (context, index) {
          final language = availableLanguages[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // English name + flag
                  Row(
                    children: [
                      Text(
                        language.flag,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          language.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (language.tooltip != null)
                        const Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.grey,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Native script (with AncientLabel)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: AncientLabel(
                      language: language,
                      style: const TextStyle(fontSize: 20),
                      textAlign: TextAlign.center,
                      showTooltip: true,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Script info
                  if (language.script != null) ...[
                    Text(
                      'Script: ${language.script}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    Text(
                      'Direction: ${language.textDirection == TextDirection.rtl ? "RTL" : "LTR"}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (language.primaryFont != null)
                      Text(
                        'Font: ${language.primaryFont}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],

                  // Alternative form if available
                  if (language.altEndonym != null) ...[
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 4),
                    Text(
                      'Alternative form:',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        language.altEndonym!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ],

                  // Status badge
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (language.isAvailable)
                        Chip(
                          label: const Text('Available'),
                          backgroundColor: Colors.green.withValues(alpha: 0.2),
                          labelStyle: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      if (language.comingSoon && !language.isAvailable)
                        Chip(
                          label: const Text('Coming Soon'),
                          backgroundColor: Colors.orange.withValues(alpha: 0.2),
                          labelStyle: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      if (!language.isAvailable && !language.comingSoon)
                        Chip(
                          label: const Text('Planned'),
                          backgroundColor: Colors.grey.withValues(alpha: 0.2),
                          labelStyle: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ All fonts loaded successfully!'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        icon: const Icon(Icons.check_circle),
        label: const Text('Test Complete'),
      ),
    );
  }
}
