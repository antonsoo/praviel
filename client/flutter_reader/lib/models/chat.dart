class ChatMessage {
  ChatMessage({required this.role, required this.content});

  final String role;
  final String content;

  Map<String, dynamic> toJson() => {'role': role, 'content': content};

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'] as String? ?? 'user',
      content: json['content'] as String? ?? '',
    );
  }
}

class ChatConverseRequest {
  ChatConverseRequest({
    required this.message,
    this.persona = 'athenian_merchant',
    this.provider = 'echo',
    this.model,
    this.context = const [],
  });

  final String message;
  final String persona;
  final String provider;
  final String? model;
  final List<ChatMessage> context;

  Map<String, dynamic> toJson() => {
    'message': message,
    'persona': persona,
    'provider': provider,
    if (model != null) 'model': model,
    'context': context.map((m) => m.toJson()).toList(),
  };
}

class ChatMeta {
  ChatMeta({
    required this.provider,
    required this.model,
    required this.persona,
    required this.contextLength,
    this.note,
  });

  final String provider;
  final String model;
  final String persona;
  final int contextLength;
  final String? note;

  factory ChatMeta.fromJson(Map<String, dynamic> json) {
    return ChatMeta(
      provider: json['provider'] as String? ?? 'echo',
      model: json['model'] as String? ?? 'echo:v0',
      persona: json['persona'] as String? ?? 'athenian_merchant',
      contextLength: (json['context_length'] as num?)?.toInt() ?? 0,
      note: json['note'] as String?,
    );
  }
}

class ChatConverseResponse {
  ChatConverseResponse({
    required this.reply,
    this.translationHelp,
    this.grammarNotes = const [],
    required this.meta,
  });

  final String reply;
  final String? translationHelp;
  final List<String> grammarNotes;
  final ChatMeta meta;

  factory ChatConverseResponse.fromJson(Map<String, dynamic> json) {
    return ChatConverseResponse(
      reply: json['reply'] as String? ?? '',
      translationHelp: json['translation_help'] as String?,
      grammarNotes: (json['grammar_notes'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      meta: ChatMeta.fromJson(json['meta'] as Map<String, dynamic>),
    );
  }
}
