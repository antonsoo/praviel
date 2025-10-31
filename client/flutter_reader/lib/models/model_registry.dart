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
    this.tier,
    this.description,
  });

  final String id;
  final String label;
  final String provider;
  final String? tier; // 'budget', 'balanced', 'premium'
  final String? description; // Short description for UI
}

/// Recommended defaults surfaced in BYOK flows per provider.
const Map<String, String> kPreferredLessonModels = <String, String>{
  'openai': 'gpt-5-nano',
  'anthropic': 'claude-sonnet-4-5-20250929',
  'google': 'gemini-2.5-flash',
};

// Lesson generation providers (all supported)
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

// Chat providers (October 2025 - all providers supported)
const List<LessonProvider> kChatProviders = <LessonProvider>[
  LessonProvider(id: 'echo', label: 'Hosted echo', requiresKey: false),
  LessonProvider(id: 'openai', label: 'OpenAI (GPT)', requiresKey: true),
  LessonProvider(
    id: 'anthropic',
    label: 'Anthropic (Claude)',
    requiresKey: true,
  ),
  LessonProvider(id: 'google', label: 'Google (Gemini)', requiresKey: true),
];

// October 2025 Model Registry - Complete lineup with pricing tiers
// NOTE: Models are ordered by tier (premium first) for better UX in dropdowns
const List<LessonModelPreset> kLessonModelPresets = <LessonModelPreset>[
  // ===== OpenAI GPT-5 Models (October 2025) =====
  // Premium Tier - Full models (highest capability) - SHOWN FIRST
  LessonModelPreset(
    id: 'gpt-5',
    label: 'GPT-5',
    provider: 'openai',
    tier: 'premium',
    description: 'Full capability with reasoning (auto-updates)',
  ),
  LessonModelPreset(
    id: 'gpt-5-2025-08-07',
    label: 'GPT-5 (dated)',
    provider: 'openai',
    tier: 'premium',
    description: 'Full capability with reasoning (stable dated version)',
  ),

  // Specialized GPT-5 models
  LessonModelPreset(
    id: 'gpt-5-codex',
    label: 'GPT-5 Codex',
    provider: 'openai',
    tier: 'premium',
    description: 'Code-specialized (requires registration)',
  ),

  // Balanced Tier - Mini models (best price-performance)
  LessonModelPreset(
    id: 'gpt-5-mini',
    label: 'GPT-5 Mini',
    provider: 'openai',
    tier: 'balanced',
    description: 'Balanced speed & quality (auto-updates)',
  ),
  LessonModelPreset(
    id: 'gpt-5-mini-2025-08-07',
    label: 'GPT-5 Mini (dated)',
    provider: 'openai',
    tier: 'balanced',
    description: 'Balanced speed & quality (stable dated version)',
  ),
  LessonModelPreset(
    id: 'gpt-5-chat-latest',
    label: 'GPT-5 Chat Latest',
    provider: 'openai',
    tier: 'balanced',
    description: 'Optimized for conversation (non-reasoning)',
  ),

  // Budget Tier - Nano models (fastest, lowest cost)
  LessonModelPreset(
    id: 'gpt-5-nano',
    label: 'GPT-5 Nano',
    provider: 'openai',
    tier: 'budget',
    description: 'Fastest, most cost-efficient (auto-updates)',
  ),
  LessonModelPreset(
    id: 'gpt-5-nano-2025-08-07',
    label: 'GPT-5 Nano (dated)',
    provider: 'openai',
    tier: 'budget',
    description: 'Fastest, most cost-efficient (stable dated version)',
  ),

  // ===== Anthropic Claude Models (October 2025) =====
  // Premium Tier - Latest Sonnet (recommended)
  LessonModelPreset(
    id: 'claude-sonnet-4-5-20250929',
    label: 'Claude Sonnet 4.5 (dated)',
    provider: 'anthropic',
    tier: 'premium',
    description: 'Latest, most advanced reasoning (stable dated version)',
  ),
  LessonModelPreset(
    id: 'claude-sonnet-4-5',
    label: 'Claude Sonnet 4.5',
    provider: 'anthropic',
    tier: 'premium',
    description: 'Latest, most advanced reasoning (auto-updates)',
  ),

  // Premium Tier - Opus 4.1 (highest capability)
  LessonModelPreset(
    id: 'claude-opus-4-1-20250805',
    label: 'Claude Opus 4.1 (dated)',
    provider: 'anthropic',
    tier: 'premium',
    description: 'Improved over Opus 4 (stable dated version)',
  ),
  LessonModelPreset(
    id: 'claude-opus-4-1',
    label: 'Claude Opus 4.1',
    provider: 'anthropic',
    tier: 'premium',
    description: 'Improved over Opus 4 (auto-updates)',
  ),

  // Legacy models (for compatibility)
  LessonModelPreset(
    id: 'claude-sonnet-4-20250514',
    label: 'Claude Sonnet 4',
    provider: 'anthropic',
    tier: 'balanced',
    description: 'Previous Sonnet version',
  ),
  LessonModelPreset(
    id: 'claude-opus-4',
    label: 'Claude Opus 4',
    provider: 'anthropic',
    tier: 'premium',
    description: 'Previous Opus version',
  ),

  // ===== Google Gemini 2.5 Models (October 2025) =====
  // Premium Tier - Pro models (highest quality)
  LessonModelPreset(
    id: 'gemini-2.5-pro',
    label: 'Gemini 2.5 Pro',
    provider: 'google',
    tier: 'premium',
    description: 'Highest quality, best reasoning (stable GA)',
  ),
  LessonModelPreset(
    id: 'gemini-2.5-pro-exp-03-25',
    label: 'Gemini 2.5 Pro (thinking)',
    provider: 'google',
    tier: 'premium',
    description: 'Experimental with extended thinking mode',
  ),

  // Balanced Tier - Flash models (best price-performance, recommended)
  LessonModelPreset(
    id: 'gemini-2.5-flash',
    label: 'Gemini 2.5 Flash',
    provider: 'google',
    tier: 'balanced',
    description: 'Best price-performance (stable GA, recommended)',
  ),
  LessonModelPreset(
    id: 'gemini-2.5-flash-preview-09-2025',
    label: 'Gemini 2.5 Flash (preview)',
    provider: 'google',
    tier: 'balanced',
    description: 'Preview with improved tool use',
  ),
  LessonModelPreset(
    id: 'gemini-2.5-flash-latest',
    label: 'Gemini 2.5 Flash (latest)',
    provider: 'google',
    tier: 'balanced',
    description: 'Auto-updating to latest Flash version',
  ),

  // Budget Tier - Flash-Lite models (most cost-efficient)
  LessonModelPreset(
    id: 'gemini-2.5-flash-lite-preview-09-2025',
    label: 'Gemini 2.5 Flash-Lite (latest preview)',
    provider: 'google',
    tier: 'budget',
    description: 'Most cost-efficient (September 2025 preview)',
  ),
  LessonModelPreset(
    id: 'gemini-2.5-flash-lite-preview-06-17',
    label: 'Gemini 2.5 Flash-Lite (June preview)',
    provider: 'google',
    tier: 'budget',
    description: 'Most cost-efficient (June 2025 preview)',
  ),
];

// TTS providers (only providers that support TTS)
const List<LessonProvider> kTtsProviders = <LessonProvider>[
  LessonProvider(id: 'echo', label: 'Hosted echo', requiresKey: false),
  LessonProvider(id: 'openai', label: 'OpenAI (GPT)', requiresKey: true),
  LessonProvider(id: 'google', label: 'Google (Gemini)', requiresKey: true),
];

// TTS Model Registry - Text-to-Speech models only
const List<LessonModelPreset> kTtsModelPresets = <LessonModelPreset>[
  // ===== OpenAI TTS Models =====
  // Standard quality (fast, cost-efficient)
  LessonModelPreset(
    id: 'tts-1',
    label: 'TTS-1',
    provider: 'openai',
    tier: 'balanced',
    description: 'Fast, cost-efficient text-to-speech',
  ),
  // High-definition quality (best quality)
  LessonModelPreset(
    id: 'tts-1-hd',
    label: 'TTS-1 HD',
    provider: 'openai',
    tier: 'premium',
    description: 'High-definition, highest quality voice',
  ),

  // ===== Google Gemini TTS Models =====
  // Flash TTS (recommended, fast and cost-efficient)
  LessonModelPreset(
    id: 'gemini-2.5-flash-preview-tts',
    label: 'Gemini 2.5 Flash Preview TTS',
    provider: 'google',
    tier: 'balanced',
    description: 'Fast, cost-efficient (recommended)',
  ),
  // Pro TTS (highest quality, more expressive)
  LessonModelPreset(
    id: 'gemini-2.5-pro-preview-tts',
    label: 'Gemini 2.5 Pro Preview TTS',
    provider: 'google',
    tier: 'premium',
    description: 'Highest quality, more expressive',
  ),
];
