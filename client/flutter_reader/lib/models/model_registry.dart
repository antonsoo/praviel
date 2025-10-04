class LessonProvider {
  const LessonProvider({
    required this.id,
    required this.label,
    required this.requiresKey,
  });

  final String id;
  final String label;
  final bool requiresKey;
}

class LessonModelPreset {
  const LessonModelPreset({
    required this.id,
    required this.label,
    required this.provider,
  });

  final String id;
  final String label;
  final String provider;
}

const List<LessonProvider> kLessonProviders = <LessonProvider>[
  LessonProvider(id: 'echo', label: 'Hosted echo', requiresKey: false),
  LessonProvider(
    id: 'anthropic',
    label: 'Anthropic (Claude)',
    requiresKey: true,
  ),
  LessonProvider(id: 'openai', label: 'OpenAI (GPT)', requiresKey: true),
  LessonProvider(id: 'google', label: 'Google (Gemini)', requiresKey: true),
];

const List<LessonModelPreset> kLessonModelPresets = <LessonModelPreset>[
  // Anthropic Claude models
  LessonModelPreset(
    id: 'claude-sonnet-4-5',
    label: 'Claude Sonnet 4.5',
    provider: 'anthropic',
  ),
  LessonModelPreset(
    id: 'claude-opus-4-1-20250805',
    label: 'Claude Opus 4.1',
    provider: 'anthropic',
  ),
  LessonModelPreset(
    id: 'claude-sonnet-4',
    label: 'Claude Sonnet 4',
    provider: 'anthropic',
  ),
  LessonModelPreset(
    id: 'claude-opus-4',
    label: 'Claude Opus 4',
    provider: 'anthropic',
  ),
  // OpenAI GPT-5 models
  LessonModelPreset(id: 'gpt-5', label: 'GPT-5', provider: 'openai'),
  LessonModelPreset(id: 'gpt-5-mini', label: 'GPT-5 mini', provider: 'openai'),
  LessonModelPreset(id: 'gpt-5-nano', label: 'GPT-5 nano', provider: 'openai'),
  // Google Gemini models
  LessonModelPreset(
    id: 'gemini-2.5-flash',
    label: 'Gemini 2.5 Flash',
    provider: 'google',
  ),
  LessonModelPreset(
    id: 'gemini-2.5-flash-lite',
    label: 'Gemini 2.5 Flash-Lite',
    provider: 'google',
  ),
  LessonModelPreset(
    id: 'gemini-2.5-flash-preview-09-2025',
    label: 'Gemini 2.5 Flash Preview',
    provider: 'google',
  ),
];
