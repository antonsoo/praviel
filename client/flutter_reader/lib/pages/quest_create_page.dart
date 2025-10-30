import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/quests_api.dart';
import '../services/haptic_service.dart';

/// Create Quest Page
class QuestCreatePage extends ConsumerStatefulWidget {
  const QuestCreatePage({super.key, required this.questsApi});

  final QuestsApi questsApi;

  @override
  ConsumerState<QuestCreatePage> createState() => _QuestCreatePageState();
}

class _QuestCreatePageState extends ConsumerState<QuestCreatePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _targetController = TextEditingController();
  final _durationController = TextEditingController(text: '30');
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedType = QuestType.lessonCount;
  bool _creating = false;
  String? _error;
  bool _loadingTemplates = false;
  String? _templatesError;
  Map<String, QuestTemplate> _templatesByType = {};
  QuestTemplate? _selectedTemplate;
  QuestPreview? _preview;
  bool _loadingPreview = false;
  String? _previewError;
  Timer? _previewDebounce;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
    _loadTemplates();
    _targetController.addListener(_onFormChanged);
    _durationController.addListener(_onFormChanged);
    _titleController.addListener(_onFormChanged);
    _descriptionController.addListener(_onFormChanged);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _previewDebounce?.cancel();
    _targetController.removeListener(_onFormChanged);
    _durationController.removeListener(_onFormChanged);
    _titleController.removeListener(_onFormChanged);
    _descriptionController.removeListener(_onFormChanged);
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

  Future<void> _loadTemplates() async {
    setState(() {
      _loadingTemplates = true;
      _templatesError = null;
    });

    try {
      final templates = await widget.questsApi.fetchQuestTemplates();
      if (!mounted) return;

      final mapped = <String, QuestTemplate>{
        for (final template in templates) template.questType: template,
      };

      setState(() {
        _templatesByType = mapped;
        _loadingTemplates = false;
      });

      _applyTemplate(_selectedType, force: true, refreshPreview: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingTemplates = false;
        _templatesError = 'Unable to load quest templates: $e';
      });
      // Still schedule a preview with whatever defaults user has.
      _schedulePreview();
    }
  }

  void _applyTemplate(
    String type, {
    bool force = false,
    bool refreshPreview = false,
  }) {
    final template = _templatesByType[type];
    setState(() {
      _selectedTemplate = template;
    });

    if (template != null) {
      final shouldUpdateTarget =
          force ||
          _targetController.text.trim().isEmpty ||
          int.tryParse(_targetController.text) == null;
      if (shouldUpdateTarget) {
        _targetController.text = template.targetValue.toString();
      }

      final shouldUpdateDuration =
          force ||
          _durationController.text.trim().isEmpty ||
          int.tryParse(_durationController.text) == null;
      if (shouldUpdateDuration) {
        _durationController.text = template.durationDays.toString();
      }
    }

    if (refreshPreview) {
      _schedulePreview();
    }
  }

  void _schedulePreview() {
    _previewDebounce?.cancel();
    _previewDebounce = Timer(const Duration(milliseconds: 350), _fetchPreview);
  }

  Future<void> _fetchPreview() async {
    final target = int.tryParse(_targetController.text.trim());
    final duration = int.tryParse(_durationController.text.trim());

    if (target == null || target <= 0 || duration == null || duration <= 0) {
      if (mounted) {
        setState(() {
          _preview = null;
          _previewError = null;
          _loadingPreview = false;
        });
      }
      return;
    }

    setState(() {
      _loadingPreview = true;
      _previewError = null;
    });

    try {
      final preview = await widget.questsApi.previewQuest(
        questType: _selectedType,
        targetValue: target,
        durationDays: duration,
        title: _titleController.text.trim().isEmpty
            ? null
            : _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      if (!mounted) return;
      setState(() {
        _preview = preview;
        _loadingPreview = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingPreview = false;
        _previewError = 'Preview unavailable: $e';
      });
    }
  }

  void _onFormChanged() {
    _schedulePreview();
  }

  void _updateSelectedType(String type) {
    if (_selectedType == type) {
      return;
    }
    setState(() {
      _selectedType = type;
    });
    _applyTemplate(type, force: true, refreshPreview: true);
  }

  Widget _buildPreviewCard(ThemeData theme, ColorScheme colorScheme) {
    final preview = _preview;
    if (preview == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reward Preview',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Chip(
                  backgroundColor: _difficultyColor(
                    preview.difficultyTier,
                    colorScheme,
                  ).withValues(alpha: 0.12),
                  avatar: Icon(
                    Icons.insights,
                    size: 16,
                    color: _difficultyColor(
                      preview.difficultyTier,
                      colorScheme,
                    ),
                  ),
                  label: Text(
                    _formatDifficultyLabel(preview.difficultyTier),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: _difficultyColor(
                        preview.difficultyTier,
                        colorScheme,
                      ),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              preview.title,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (preview.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                preview.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildMetricPill(
                  colorScheme,
                  icon: Icons.bolt,
                  label: 'XP Reward',
                  value: '${preview.xpReward} XP',
                  color: colorScheme.secondary,
                ),
                _buildMetricPill(
                  colorScheme,
                  icon: Icons.stars,
                  label: 'Coin Reward',
                  value: '${preview.coinReward} coins',
                  color: colorScheme.primary,
                ),
                _buildMetricPill(
                  colorScheme,
                  icon: Icons.flag,
                  label: 'Target',
                  value:
                      '${preview.targetValue} ${_unitNameForPreview(preview.questType)}',
                  color: colorScheme.tertiary,
                ),
                _buildMetricPill(
                  colorScheme,
                  icon: Icons.calendar_today,
                  label: 'Duration',
                  value: '${preview.durationDays} days',
                  color: colorScheme.outline,
                ),
              ],
            ),
            if (preview.meta['reward_curve'] is Map<String, dynamic>)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _buildInfoAlert(
                  context,
                  icon: Icons.trending_up,
                  message: _formatRewardCurveMessage(
                    preview.meta['reward_curve'] as Map<String, dynamic>,
                  ),
                  color: colorScheme.primary,
                  background: colorScheme.primary.withValues(alpha: 0.08),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricPill(
    ColorScheme colorScheme, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final foreground = color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: foreground.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: foreground),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: foreground,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoAlert(
    BuildContext context, {
    required IconData icon,
    required String message,
    required Color color,
    required Color background,
  }) {
    final theme = Theme.of(context);
    return Card(
      color: background,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRewardCurveMessage(Map<String, dynamic> curve) {
    final xpUnit = _formatNumber(curve['xp_unit']);
    final multiplier = _formatNumber(curve['type_multiplier']);
    return 'Scaling curve tuned for ${multiplier}x difficulty and $xpUnit base XP per milestone.';
  }

  String _formatNumber(Object? value) {
    if (value is num) {
      if (value == value.roundToDouble()) {
        return value.toInt().toString();
      }
      return value.toStringAsFixed(2);
    }
    return value?.toString() ?? '–';
  }

  String _unitNameForPreview(String questType) {
    switch (questType) {
      case QuestType.dailyStreak:
        return 'days';
      case QuestType.xpMilestone:
        return 'XP';
      case QuestType.lessonCount:
        return 'lessons';
      case QuestType.skillMastery:
        return 'milestones';
      default:
        return 'targets';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Quest')),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Form(
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

            if (_loadingTemplates)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              ),
            if (_templatesError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildInfoAlert(
                  context,
                  icon: Icons.info_outline,
                  message: _templatesError!,
                  color: colorScheme.error,
                  background: colorScheme.errorContainer,
                ),
              ),
            if (_preview != null) ...[
              _buildPreviewCard(theme, colorScheme),
              if (_loadingPreview)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Updating preview...',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
            ] else if (_loadingPreview)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Calculating rewards...',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              )
            else if (_previewError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildInfoAlert(
                  context,
                  icon: Icons.warning_amber,
                  message: _previewError!,
                  color: colorScheme.tertiary,
                  background: colorScheme.tertiaryContainer,
                ),
              ),

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
    final template = _templatesByType[questType];

    return Card(
      elevation: isSelected ? 3 : 1,
      color: isSelected ? color.withValues(alpha: 0.1) : null,
      child: InkWell(
        onTap: () {
          _updateSelectedType(questType);
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
                    if (template != null) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _buildTemplateTag(
                            colorScheme,
                            Icons.flag,
                            '${template.targetValue} ${_unitAbbreviation(questType)} goal',
                          ),
                          _buildTemplateTag(
                            colorScheme,
                            Icons.calendar_today,
                            '${template.durationDays} days',
                          ),
                          _buildTemplateTag(
                            colorScheme,
                            Icons.bolt,
                            '${template.xpReward} XP',
                          ),
                          _buildTemplateTag(
                            colorScheme,
                            Icons.stars,
                            '${template.coinReward} coins',
                          ),
                          _buildTemplateTag(
                            colorScheme,
                            Icons.insights,
                            _formatDifficultyLabel(template.difficultyTier),
                            highlightColor: _difficultyColor(
                              template.difficultyTier,
                              colorScheme,
                            ),
                          ),
                        ],
                      ),
                      if (template.suggestions?['recommended_register'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'Best for ${template.suggestions!['recommended_register']} practice.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.7,
                              ),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
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
    if (_selectedTemplate != null) {
      return _selectedTemplate!.targetValue.toString();
    }
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

  String _unitAbbreviation(String type) {
    switch (type) {
      case QuestType.dailyStreak:
        return 'day';
      case QuestType.xpMilestone:
        return 'XP';
      case QuestType.lessonCount:
        return 'lesson';
      case QuestType.skillMastery:
        return 'skill';
      default:
        return 'goal';
    }
  }

  Color _difficultyColor(String tier, ColorScheme colorScheme) {
    switch (tier) {
      case 'easy':
        return Colors.green.shade600;
      case 'standard':
        return colorScheme.primary;
      case 'hard':
        return Colors.orange.shade600;
      case 'legendary':
        return Colors.purple.shade600;
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  String _formatDifficultyLabel(String tier) {
    switch (tier) {
      case 'easy':
        return 'Easy - Warm-up';
      case 'standard':
        return 'Standard Challenge';
      case 'hard':
        return 'Hard - Heroic Effort';
      case 'legendary':
        return 'Legendary - Epic Quest';
      default:
        if (tier.isEmpty) {
          return 'Custom Quest';
        }
        final capitalized = tier[0].toUpperCase() + tier.substring(1);
        return '$capitalized Quest';
    }
  }

  Widget _buildTemplateTag(
    ColorScheme colorScheme,
    IconData icon,
    String label, {
    Color? highlightColor,
  }) {
    final baseColor = highlightColor ?? colorScheme.onSurfaceVariant;
    return Chip(
      backgroundColor: baseColor.withValues(alpha: 0.12),
      avatar: Icon(icon, size: 16, color: baseColor),
      label: Text(
        label,
        style: TextStyle(color: baseColor, fontWeight: FontWeight.w600),
      ),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      side: BorderSide(color: baseColor.withValues(alpha: 0.24)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
