import 'package:flutter/material.dart';

/// Represents a chatbot persona/character for language practice
class ChatbotPersona {
  const ChatbotPersona({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.systemPrompt,
    this.difficulty = 'intermediate',
    this.tags = const [],
  });

  final String id;
  final String name;
  final String description;
  final IconData icon;
  final String systemPrompt;
  final String difficulty; // beginner, intermediate, advanced
  final List<String> tags;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'difficulty': difficulty,
        'tags': tags,
        'systemPrompt': systemPrompt,
      };

  factory ChatbotPersona.fromJson(Map<String, dynamic> json) {
    return ChatbotPersona(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: _iconFromString(json['icon'] as String? ?? 'person'),
      systemPrompt: json['systemPrompt'] as String,
      difficulty: json['difficulty'] as String? ?? 'intermediate',
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  static IconData _iconFromString(String iconName) {
    switch (iconName) {
      case 'storefront':
        return Icons.storefront_outlined;
      case 'shield':
        return Icons.shield_outlined;
      case 'psychology':
        return Icons.psychology_outlined;
      case 'school':
        return Icons.school_outlined;
      case 'gavel':
        return Icons.gavel_outlined;
      case 'theater':
        return Icons.theater_comedy_outlined;
      case 'military':
        return Icons.military_tech_outlined;
      case 'temple':
        return Icons.temple_buddhist_outlined;
      case 'book':
        return Icons.menu_book_outlined;
      case 'balance':
        return Icons.balance_outlined;
      case 'healing':
        return Icons.healing_outlined;
      case 'agriculture':
        return Icons.agriculture_outlined;
      case 'palette':
        return Icons.palette_outlined;
      case 'music':
        return Icons.music_note_outlined;
      case 'science':
        return Icons.science_outlined;
      case 'sports':
        return Icons.sports_outlined;
      case 'home':
        return Icons.home_outlined;
      case 'work':
        return Icons.work_outline;
      default:
        return Icons.person_outline;
    }
  }
}
