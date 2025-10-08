import 'package:flutter/material.dart';

/// Avatar customization model
class Avatar {
  const Avatar({
    required this.skinTone,
    required this.hairStyle,
    required this.hairColor,
    required this.eyes,
    required this.outfit,
    this.accessory,
    this.background,
  });

  final SkinTone skinTone;
  final HairStyle hairStyle;
  final HairColor hairColor;
  final Eyes eyes;
  final Outfit outfit;
  final Accessory? accessory;
  final AvatarBackground? background;

  Avatar copyWith({
    SkinTone? skinTone,
    HairStyle? hairStyle,
    HairColor? hairColor,
    Eyes? eyes,
    Outfit? outfit,
    Accessory? accessory,
    AvatarBackground? background,
  }) {
    return Avatar(
      skinTone: skinTone ?? this.skinTone,
      hairStyle: hairStyle ?? this.hairStyle,
      hairColor: hairColor ?? this.hairColor,
      eyes: eyes ?? this.eyes,
      outfit: outfit ?? this.outfit,
      accessory: accessory ?? this.accessory,
      background: background ?? this.background,
    );
  }

  Map<String, String> toJson() {
    return {
      'skinTone': skinTone.name,
      'hairStyle': hairStyle.name,
      'hairColor': hairColor.name,
      'eyes': eyes.name,
      'outfit': outfit.name,
      if (accessory != null) 'accessory': accessory!.name,
      if (background != null) 'background': background!.name,
    };
  }

  static Avatar fromJson(Map<String, dynamic> json) {
    return Avatar(
      skinTone: SkinTone.values.firstWhere((e) => e.name == json['skinTone']),
      hairStyle: HairStyle.values.firstWhere(
        (e) => e.name == json['hairStyle'],
      ),
      hairColor: HairColor.values.firstWhere(
        (e) => e.name == json['hairColor'],
      ),
      eyes: Eyes.values.firstWhere((e) => e.name == json['eyes']),
      outfit: Outfit.values.firstWhere((e) => e.name == json['outfit']),
      accessory: json['accessory'] != null
          ? Accessory.values.firstWhere((e) => e.name == json['accessory'])
          : null,
      background: json['background'] != null
          ? AvatarBackground.values.firstWhere(
              (e) => e.name == json['background'],
            )
          : null,
    );
  }

  static Avatar get defaultAvatar => Avatar(
    skinTone: SkinTone.light,
    hairStyle: HairStyle.short,
    hairColor: HairColor.brown,
    eyes: Eyes.normal,
    outfit: Outfit.casual,
  );
}

/// Skin tones
enum SkinTone {
  light(Color(0xFFFFDCB2)),
  medium(Color(0xFFE0AC69)),
  tan(Color(0xFFC68642)),
  dark(Color(0xFF8D5524));

  const SkinTone(this.color);
  final Color color;
}

/// Hair styles
enum HairStyle { short, long, curly, bun, ponytail, bald }

/// Hair colors
enum HairColor {
  black(Color(0xFF1A1A1A)),
  brown(Color(0xFF654321)),
  blonde(Color(0xFFF5DEB3)),
  red(Color(0xFFDC143C)),
  blue(Color(0xFF4169E1)),
  pink(Color(0xFFFF69B4)),
  purple(Color(0xFF9370DB)),
  green(Color(0xFF228B22));

  const HairColor(this.color);
  final Color color;
}

/// Eye styles
enum Eyes { normal, happy, surprised, cool }

/// Outfits
enum Outfit {
  casual(Color(0xFF4A90E2)),
  formal(Color(0xFF2C3E50)),
  sporty(Color(0xFFE74C3C)),
  elegant(Color(0xFF9B59B6)),
  ninja(Color(0xFF34495E)),
  scholar(Color(0xFF16A085));

  const Outfit(this.color);
  final Color color;
}

/// Accessories (unlockable)
enum Accessory { glasses, sunglasses, hat, crown, headphones, flower }

/// Backgrounds (unlockable)
enum AvatarBackground {
  none(Color(0xFFECF0F1)),
  gradient1(null),
  gradient2(null),
  stars(null),
  books(null),
  trophy(null);

  const AvatarBackground(this.color);
  final Color? color;

  Gradient? get gradient {
    switch (this) {
      case AvatarBackground.gradient1:
        return const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AvatarBackground.gradient2:
        return const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFFFA500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return null;
    }
  }
}
