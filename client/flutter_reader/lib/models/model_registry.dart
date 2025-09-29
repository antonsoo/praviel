class LessonModelPreset {
  const LessonModelPreset({required this.id, required this.label});

  final String id;
  final String label;
}

const List<LessonModelPreset> kLessonModelPresets = <LessonModelPreset>[
  LessonModelPreset(id: 'gpt-5-mini', label: 'GPT-5 mini (fast)'),
  LessonModelPreset(id: 'gpt-5-small', label: 'GPT-5 small (balanced)'),
  LessonModelPreset(id: 'gpt-5-medium', label: 'GPT-5 medium (quality)'),
  LessonModelPreset(id: 'gpt-5-high', label: 'GPT-5 high (max)'),
];
