/// Script display preferences for ancient language text rendering.
///
/// These preferences control how ancient texts are displayed, including
/// options for scriptio continua, interpuncts, nomina sacra, and authentic mode.
library;

class ScriptDisplayMode {
  /// Remove all word spaces (continuous writing as ancients wrote)
  final bool useScriptioContinua;

  /// Replace spaces with interpuncts (·) for inscription-style display
  final bool useInterpuncts;

  /// Convert iota subscripts to full iota (ᾳ → ΑΙ, ῳ → ΩΙ) [Greek only]
  final bool useIotaAdscript;

  /// Apply nomina sacra abbreviations with overlines (Θ͞Σ͞ for ΘΕΟΣ) [Koine only]
  final bool useNominaSacra;

  /// Remove modern punctuation marks (?, !, commas, etc.)
  final bool removeModernPunctuation;

  const ScriptDisplayMode({
    this.useScriptioContinua = false,
    this.useInterpuncts = false,
    this.useIotaAdscript = true,
    this.useNominaSacra = false,
    this.removeModernPunctuation = false,
  });

  factory ScriptDisplayMode.fromJson(Map<String, dynamic> json) {
    return ScriptDisplayMode(
      useScriptioContinua: json['use_scriptio_continua'] as bool? ?? false,
      useInterpuncts: json['use_interpuncts'] as bool? ?? false,
      useIotaAdscript: json['use_iota_adscript'] as bool? ?? true,
      useNominaSacra: json['use_nomina_sacra'] as bool? ?? false,
      removeModernPunctuation: json['remove_modern_punctuation'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'use_scriptio_continua': useScriptioContinua,
      'use_interpuncts': useInterpuncts,
      'use_iota_adscript': useIotaAdscript,
      'use_nomina_sacra': useNominaSacra,
      'remove_modern_punctuation': removeModernPunctuation,
    };
  }

  ScriptDisplayMode copyWith({
    bool? useScriptioContinua,
    bool? useInterpuncts,
    bool? useIotaAdscript,
    bool? useNominaSacra,
    bool? removeModernPunctuation,
  }) {
    return ScriptDisplayMode(
      useScriptioContinua: useScriptioContinua ?? this.useScriptioContinua,
      useInterpuncts: useInterpuncts ?? this.useInterpuncts,
      useIotaAdscript: useIotaAdscript ?? this.useIotaAdscript,
      useNominaSacra: useNominaSacra ?? this.useNominaSacra,
      removeModernPunctuation: removeModernPunctuation ?? this.removeModernPunctuation,
    );
  }
}

class ScriptPreferences {
  /// Master toggle for authentic ancient scripts
  ///
  /// When enabled, uses historically accurate rendering (uppercase, no accents, etc.)
  /// based on language configuration
  final bool authenticMode;

  /// Script display settings for Classical Latin (lat)
  final ScriptDisplayMode latin;

  /// Script display settings for Classical Greek (grc)
  final ScriptDisplayMode greekClassical;

  /// Script display settings for Koine Greek (grc-koi)
  final ScriptDisplayMode greekKoine;

  const ScriptPreferences({
    this.authenticMode = false,
    this.latin = const ScriptDisplayMode(),
    this.greekClassical = const ScriptDisplayMode(),
    this.greekKoine = const ScriptDisplayMode(),
  });

  factory ScriptPreferences.fromJson(Map<String, dynamic> json) {
    return ScriptPreferences(
      authenticMode: json['authentic_mode'] as bool? ?? false,
      latin: json['latin'] != null
          ? ScriptDisplayMode.fromJson(json['latin'] as Map<String, dynamic>)
          : const ScriptDisplayMode(),
      greekClassical: json['greek_classical'] != null
          ? ScriptDisplayMode.fromJson(json['greek_classical'] as Map<String, dynamic>)
          : const ScriptDisplayMode(),
      greekKoine: json['greek_koine'] != null
          ? ScriptDisplayMode.fromJson(json['greek_koine'] as Map<String, dynamic>)
          : const ScriptDisplayMode(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'authentic_mode': authenticMode,
      'latin': latin.toJson(),
      'greek_classical': greekClassical.toJson(),
      'greek_koine': greekKoine.toJson(),
    };
  }

  ScriptPreferences copyWith({
    bool? authenticMode,
    ScriptDisplayMode? latin,
    ScriptDisplayMode? greekClassical,
    ScriptDisplayMode? greekKoine,
  }) {
    return ScriptPreferences(
      authenticMode: authenticMode ?? this.authenticMode,
      latin: latin ?? this.latin,
      greekClassical: greekClassical ?? this.greekClassical,
      greekKoine: greekKoine ?? this.greekKoine,
    );
  }

  /// Get display mode for a specific language code
  ScriptDisplayMode getModeForLanguage(String languageCode) {
    switch (languageCode) {
      case 'lat':
        return latin;
      case 'grc':
        return greekClassical;
      case 'grc-koi':
        return greekKoine;
      default:
        return const ScriptDisplayMode();
    }
  }
}
