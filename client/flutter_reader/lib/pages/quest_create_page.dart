import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/quests_api.dart';
import '../services/haptic_service.dart';

/// Create Quest Page
class QuestCreatePage extends ConsumerStatefulWidget {
  const QuestCreatePage({
    super.key,
    required this.questsApi,
  });

  final QuestsApi questsApi;

  @override
  ConsumerState<QuestCreatePage> createState() => _QuestCreatePageState();
}

class _QuestCreatePageState extends ConsumerState<QuestCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _targetController = TextEditingController();
  final _durationController = TextEditingController(text: '30');
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedType = QuestType.lessonCount;
  bool _creating = false;
  String? _error;

  @override
  void dispose() {
    _targetController.dispose();
    _durationController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createQuest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _creating = true;
      _error = null;
    });

    try {
      final target = int.parse(_targetController.text);
      final duration = int.parse(_durationController.text);
      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();

      await widget.questsApi.createQuest(
        questType: _selectedType,
        targetValue: target,
        durationDays: duration,
        title: title.isNotEmpty ? title : null,
        description: description.isNotEmpty ? description : null,
      );

      HapticService.success();

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to create quest: $e';
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
        title: const Text('Create Quest'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Quest Type Selection
            Text(
              'Quest Type',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            _buildQuestTypeCard(
              theme,
              colorScheme,
              QuestType.dailyStreak,
              'Daily Streak',
              'Maintain your learning streak',
              Icons.local_fire_department,
              Colors.orange,
            ),
            const SizedBox(height: 8),

            _buildQuestTypeCard(
              theme,
              colorScheme,
              QuestType.xpMilestone,
              'XP Milestone',
              'Reach a total XP goal',
              Icons.bolt,
              colorScheme.secondary,
            ),
            const SizedBox(height: 8),

            _buildQuestTypeCard(
              theme,
              colorScheme,
              QuestType.lessonCount,
              'Lesson Count',
              'Complete a number of lessons',
              Icons.school,
              colorScheme.primary,
            ),
            const SizedBox(height: 8),

            _buildQuestTypeCard(
              theme,
              colorScheme,
              QuestType.skillMastery,
              'Skill Mastery',
              'Master specific skills',
              Icons.workspace_premium,
              Colors.purple,
            ),

            const SizedBox(height: 24),

            // Target Value
            Text(
              'Target ${_getUnitName()}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _targetController,
              decoration: InputDecoration(
                hintText: _getTargetHint(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                suffixText: _getUnitName(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a target value';
                }
                final num = int.tryParse(value);
                if (num == null || num <= 0) {
                  return 'Please enter a valid positive number';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Duration
            Text(
              'Duration (Days)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _durationController,
              decoration: InputDecoration(
                hintText: '30',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                helperText: 'How many days to complete this quest',
                suffixText: 'days',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a duration';
                }
                final num = int.tryParse(value);
                if (num == null || num <= 0) {
                  return 'Please enter a valid positive number';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Title (optional)
            Text(
              'Custom Title (Optional)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'My Quest Title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                helperText: 'Leave empty for auto-generated title',
              ),
              textCapitalization: TextCapitalization.words,
            ),

            const SizedBox(height: 24),

            // Description (optional)
            Text(
              'Description (Optional)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                hintText: 'Add a description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
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
              onPressed: _creating ? null : _createQuest,
              icon: _creating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.flag),
              label: Text(_creating ? 'Creating...' : 'Create Quest'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestTypeCard(
    ThemeData theme,
    ColorScheme colorScheme,
    String questType,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedType == questType;

    return Card(
      elevation: isSelected ? 3 : 1,
      color: isSelected ? color.withValues(alpha: 0.1) : null,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedType = questType;
          });
          HapticService.light();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? color : null,
                      ),
                    ),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: color, size: 28)
              else
                Icon(
                  Icons.radio_button_unchecked,
                  color: colorScheme.outline,
                  size: 28,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getUnitName() {
    switch (_selectedType) {
      case QuestType.dailyStreak:
        return 'days';
      case QuestType.xpMilestone:
        return 'XP';
      case QuestType.lessonCount:
        return 'lessons';
      case QuestType.skillMastery:
        return 'points';
      default:
        return 'points';
    }
  }

  String _getTargetHint() {
    switch (_selectedType) {
      case QuestType.dailyStreak:
        return '7';
      case QuestType.xpMilestone:
        return '1000';
      case QuestType.lessonCount:
        return '20';
      case QuestType.skillMastery:
        return '100';
      default:
        return '10';
    }
  }
}
