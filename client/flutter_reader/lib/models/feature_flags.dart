class FeatureFlags {
  const FeatureFlags({required this.lessonsEnabled, required this.ttsEnabled});

  final bool lessonsEnabled;
  final bool ttsEnabled;

  static const none = FeatureFlags(lessonsEnabled: false, ttsEnabled: false);

  factory FeatureFlags.fromHealth(Map<String, dynamic> json) {
    final features = json['features'] as Map<String, dynamic>? ?? const {};
    return FeatureFlags(
      lessonsEnabled: _asBool(features['lessons']),
      ttsEnabled: _asBool(features['tts']),
    );
  }

  static bool _asBool(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final lowered = value.toLowerCase().trim();
      return lowered == '1' || lowered == 'true' || lowered == 'yes';
    }
    return false;
  }
}
