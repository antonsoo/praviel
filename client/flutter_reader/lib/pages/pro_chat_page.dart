import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as frp;
import '../app_providers.dart';
import '../models/chat.dart';
import '../models/chatbot_persona.dart';
import '../models/language.dart';
import '../services/byok_controller.dart';
import '../services/haptic_service.dart';
import '../services/chatbot_persona_service.dart';
import '../services/language_controller.dart';
import '../theme/professional_theme.dart';

/// PROFESSIONAL chat interface - clean like iMessage, organized like Slack
/// No cute avatars or gradients - just clear, functional design
class ProChatPage extends frp.ConsumerStatefulWidget {
  const ProChatPage({super.key});

  @override
  frp.ConsumerState<ProChatPage> createState() => _ProChatPageState();
}

enum _ChatStatus { idle, loading, error }

class _ProChatPageState extends frp.ConsumerState<ProChatPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_DisplayMessage> _messages = [];

  // Limit message history to prevent memory leaks
  static const int _maxMessages = 50;

  String? _selectedPersona;
  _ChatStatus _status = _ChatStatus.idle;
  String? _errorMessage;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  List<ChatbotPersona> _availablePersonas = [];

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

    // Load personas after first frame when we have access to ref
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPersonasForLanguage();
    });
  }

  Widget _buildPersonaSelector(
    ThemeData theme,
    ColorScheme colorScheme,
    String languageName,
  ) {
    if (_availablePersonas.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(ProSpacing.lg),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Select a language to load personas.',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final selectedPersona = _availablePersonas.firstWhere(
      (persona) => persona.id == _selectedPersona,
      orElse: () => _availablePersonas.first,
    );

    return Container(
      margin: const EdgeInsets.only(
        left: ProSpacing.xl,
        right: ProSpacing.xl,
        top: ProSpacing.lg,
        bottom: ProSpacing.lg,
      ),
      padding: const EdgeInsets.fromLTRB(
        ProSpacing.xl,
        ProSpacing.xl,
        ProSpacing.xl,
        ProSpacing.lg,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.45),
            colorScheme.secondaryContainer.withValues(alpha: 0.25),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(ProRadius.xl),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personas for $languageName',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: ProSpacing.md),
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _availablePersonas.length,
              separatorBuilder: (context, index) => const SizedBox(width: ProSpacing.md),
              itemBuilder: (context, index) {
                final persona = _availablePersonas[index];
                final isSelected = persona.id == selectedPersona.id;
                return _PersonaCard(
                  persona: persona,
                  selected: isSelected,
                  onTap: () => _selectPersona(persona.id),
                );
              },
            ),
          ),
          const SizedBox(height: ProSpacing.lg),
          _buildPersonaDetailCard(theme, colorScheme, selectedPersona),
        ],
      ),
    );
  }

  void _loadPersonasForLanguage() {
    final languageAsync = ref.read(languageControllerProvider);
    final languageCode = languageAsync.when(
      data: (code) => code,
      loading: () => 'grc-cls',
      error: (_, _) => 'grc-cls',
    );
    final personas = ChatbotPersonaService.getPersonasForLanguage(languageCode);

    setState(() {
      _availablePersonas = personas;
      if (personas.isEmpty) {
        _selectedPersona = null;
        _messages.clear();
        return;
      }
      final currentId = _selectedPersona;
      if (currentId == null ||
          personas.every((persona) => persona.id != currentId)) {
        _selectedPersona = personas.first.id;
        _messages.clear();
      }
    });
  }

  String _languageDisplayName(String code) {
    try {
      return availableLanguages.firstWhere((lang) => lang.code == code).name;
    } catch (_) {
      return 'this language';
    }
  }

  void _selectPersona(String personaId) {
    if (_selectedPersona == personaId) {
      return;
    }
    setState(() {
      _selectedPersona = personaId;
      _messages.clear();
    });
    HapticService.selection();
  }

  Widget _buildPersonaDetailCard(
    ThemeData theme,
    ColorScheme colorScheme,
    ChatbotPersona persona,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ProSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(ProRadius.lg),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(persona.icon, size: 18, color: colorScheme.primary),
              const SizedBox(width: ProSpacing.sm),
              Expanded(
                child: Text(
                  persona.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _buildDifficultyChip(theme, colorScheme, persona.difficulty),
            ],
          ),
          const SizedBox(height: ProSpacing.xs),
          Text(
            persona.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (persona.tags.isNotEmpty) ...[
            const SizedBox(height: ProSpacing.sm),
            Wrap(
              spacing: ProSpacing.sm,
              runSpacing: ProSpacing.sm,
              children: persona.tags.map((tag) {
                return Chip(
                  avatar: const Icon(Icons.bookmark_outline_rounded, size: 14),
                  label: Text(tag),
                  labelStyle: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  backgroundColor: colorScheme.primaryContainer.withValues(
                    alpha: 0.35,
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDifficultyChip(
    ThemeData theme,
    ColorScheme colorScheme,
    String difficulty,
  ) {
    final normalized = difficulty.toLowerCase();
    Color tone;
    switch (normalized) {
      case 'beginner':
        tone = colorScheme.primary;
        break;
      case 'advanced':
        tone = colorScheme.error;
        break;
      default:
        tone = colorScheme.secondary;
    }
    final label = '${normalized[0].toUpperCase()}${normalized.substring(1)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(ProRadius.sm),
        border: Border.all(color: tone.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_outlined, size: 14, color: tone),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: tone,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty ||
        _status == _ChatStatus.loading ||
        _selectedPersona == null) {
      return;
    }

    HapticService.light();

    final userMessage = _DisplayMessage(
      role: 'user',
      content: text,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      // Trim old messages to prevent memory leak
      if (_messages.length > _maxMessages) {
        _messages.removeRange(0, _messages.length - _maxMessages);
      }
      _status = _ChatStatus.loading;
      _errorMessage = null;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      final api = ref.read(chatApiProvider);
      final settings = await ref.read(byokControllerProvider.future);

      final context = _messages
          .where((m) => m != userMessage)
          .where((m) => m.translationHelp == null && m.grammarNotes.isEmpty)
          .map((m) => ChatMessage(role: m.role, content: m.content))
          .toList();

      final request = ChatConverseRequest(
        message: text,
        persona: _selectedPersona!,
        provider: settings.chatProvider.isEmpty
            ? 'echo'
            : settings.chatProvider,
        model: settings.chatModel,
        context: context.length > 10
            ? context.sublist(context.length - 10)
            : context,
      );

      final response = await api.converse(request, settings);

      if (!mounted) return;

      final botMessage = _DisplayMessage(
        role: 'assistant',
        content: response.reply,
        timestamp: DateTime.now(),
        translationHelp: response.translationHelp,
        grammarNotes: response.grammarNotes,
        providerNote: response.meta.note,
      );

      setState(() {
        _messages.add(botMessage);
        // Trim old messages to prevent memory leak
        if (_messages.length > _maxMessages) {
          _messages.removeRange(0, _messages.length - _maxMessages);
        }
        _status = _ChatStatus.idle;
      });
      _scrollToBottom();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _status = _ChatStatus.error;
        _errorMessage = error.toString();
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final languageState = ref.watch(languageControllerProvider);
    final languageCode = languageState.value ?? 'grc-cls';
    final languageName = _languageDisplayName(languageCode);

    // Watch language changes and reload personas
    ref.listen(languageControllerProvider, (previous, next) {
      next.whenData((languageCode) {
        _loadPersonasForLanguage();
        // Clear conversation when language changes
        setState(() {
          _messages.clear();
        });
      });
    });

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text('Chat', style: theme.textTheme.titleLarge),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: colorScheme.outline),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildPersonaSelector(theme, colorScheme, languageName),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.surfaceContainerLowest,
                      colorScheme.surface,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: _messages.isEmpty
                    ? _buildEmptyState(theme, colorScheme)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: ProSpacing.xl,
                          vertical: ProSpacing.lg,
                        ),
                        itemCount:
                            _messages.length +
                            (_status == _ChatStatus.loading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _messages.length &&
                              _status == _ChatStatus.loading) {
                            return _buildTypingIndicator(theme, colorScheme);
                          }
                          final message = _messages[index];
                          return _buildMessageBubble(
                            theme,
                            colorScheme,
                            message,
                          );
                        },
                      ),
              ),
            ),
            if (_errorMessage != null) _buildErrorBanner(theme, colorScheme),
            _buildInputBar(theme, colorScheme, languageName),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ProSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: ProSpacing.lg),
            Text('Start a conversation', style: theme.textTheme.titleMedium),
            const SizedBox(height: ProSpacing.sm),
            Text(
              _availablePersonas.isEmpty
                  ? 'Select a language to begin chatting'
                  : 'Choose a persona and start practicing!',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    ThemeData theme,
    ColorScheme colorScheme,
    _DisplayMessage message,
  ) {
    final isUser = message.role == 'user';
    final translation = message.translationHelp?.trim();
    final providerNote = message.providerNote?.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: ProSpacing.lg),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _buildAvatar(theme, colorScheme, false),
            const SizedBox(width: ProSpacing.md),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ProSpacing.lg,
                    vertical: ProSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(ProRadius.lg),
                      topRight: const Radius.circular(ProRadius.lg),
                      bottomLeft: Radius.circular(
                        isUser ? ProRadius.lg : ProRadius.sm,
                      ),
                      bottomRight: Radius.circular(
                        isUser ? ProRadius.sm : ProRadius.lg,
                      ),
                    ),
                    border: isUser
                        ? null
                        : Border.all(color: colorScheme.outline, width: 1),
                  ),
                  child: Text(
                    message.content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isUser
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                      height: 1.5,
                    ),
                  ),
                ),
                if (!isUser && translation != null && translation.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: ProSpacing.sm),
                    child: Container(
                      padding: const EdgeInsets.all(ProSpacing.md),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(
                          alpha: 0.35,
                        ),
                        borderRadius: BorderRadius.circular(ProRadius.md),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.translate_outlined,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: ProSpacing.sm),
                          Expanded(
                            child: Text(
                              translation,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (!isUser && message.grammarNotes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: ProSpacing.sm),
                    child: Wrap(
                      spacing: ProSpacing.sm,
                      runSpacing: ProSpacing.sm,
                      children: message.grammarNotes.take(6).map((note) {
                        return Chip(
                          avatar: const Icon(
                            Icons.menu_book_outlined,
                            size: 14,
                          ),
                          label: Text(note),
                          labelStyle: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          backgroundColor: colorScheme.secondaryContainer
                              .withValues(alpha: 0.45),
                        );
                      }).toList(),
                    ),
                  ),
                if (providerNote != null && providerNote.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: ProSpacing.sm),
                    child: Text(
                      providerNote,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.8,
                        ),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                const SizedBox(height: ProSpacing.xs),
                Text(
                  _formatTime(message.timestamp),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: ProSpacing.md),
            _buildAvatar(theme, colorScheme, true),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme, ColorScheme colorScheme, bool isUser) {
    IconData assistantIcon = Icons.psychology_outlined;
    if (!isUser && _selectedPersona != null) {
      final persona = _availablePersonas.firstWhere(
        (p) => p.id == _selectedPersona,
        orElse: () => _availablePersonas.isNotEmpty
            ? _availablePersonas.first
            : ChatbotPersona(
                id: 'default',
                name: 'Teacher',
                description: 'Language teacher',
                icon: Icons.school_outlined,
                systemPrompt: '',
              ),
      );
      assistantIcon = persona.icon;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isUser
            ? null
            : LinearGradient(
                colors: [
                  colorScheme.secondaryContainer.withValues(alpha: 0.65),
                  colorScheme.secondary.withValues(alpha: 0.28),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: isUser
            ? colorScheme.primaryContainer.withValues(alpha: 0.9)
            : null,
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        isUser ? Icons.person_outline : assistantIcon,
        size: 18,
        color: isUser ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildTypingIndicator(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ProSpacing.lg),
      child: Row(
        children: [
          _buildAvatar(theme, colorScheme, false),
          const SizedBox(width: ProSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: ProSpacing.lg,
              vertical: ProSpacing.md,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(ProRadius.lg),
              border: Border.all(color: colorScheme.outline, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(colorScheme, 0),
                const SizedBox(width: 4),
                _buildDot(colorScheme, 1),
                const SizedBox(width: 4),
                _buildDot(colorScheme, 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(ColorScheme colorScheme, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        final offset = (value + index * 0.33) % 1.0;
        final opacity = 0.3 + (offset * 0.7);
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: colorScheme.onSurfaceVariant.withValues(alpha: opacity),
            shape: BoxShape.circle,
          ),
        );
      },
      onEnd: () {
        if (mounted) setState(() {}); // Repeat animation
      },
    );
  }

  Widget _buildErrorBanner(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(ProSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        border: Border(top: BorderSide(color: colorScheme.error, width: 1)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 16, color: colorScheme.error),
          const SizedBox(width: ProSpacing.sm),
          Expanded(
            child: Text(
              _errorMessage!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 16, color: colorScheme.error),
            onPressed: () => setState(() => _errorMessage = null),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(
    ThemeData theme,
    ColorScheme colorScheme,
    String languageName,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(
        ProSpacing.lg,
        ProSpacing.sm,
        ProSpacing.lg,
        ProSpacing.lg,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Write in $languageName…',
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.7,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: ProSpacing.lg,
                    vertical: ProSpacing.md,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ProRadius.lg),
                    borderSide: BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ProRadius.lg),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 1.6,
                    ),
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                enabled: _status != _ChatStatus.loading,
              ),
            ),
            const SizedBox(width: ProSpacing.md),
            FilledButton.icon(
              onPressed: _status == _ChatStatus.loading ? null : _sendMessage,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: ProSpacing.lg,
                  vertical: ProSpacing.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ProRadius.lg),
                ),
              ),
              icon: _status == _ChatStatus.loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send, size: 18),
              label: Text(_status == _ChatStatus.loading ? 'Sending…' : 'Send'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

class _PersonaCard extends StatelessWidget {
  const _PersonaCard({
    required this.persona,
    required this.selected,
    required this.onTap,
  });

  final ChatbotPersona persona;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(ProRadius.lg),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 220,
        padding: const EdgeInsets.all(ProSpacing.md),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary.withValues(alpha: 0.85)
              : colorScheme.surface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(ProRadius.lg),
          border: Border.all(
            color: selected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.18),
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? colorScheme.primary.withValues(alpha: 0.25)
                  : colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: selected ? 24 : 12,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              persona.icon,
              size: 20,
              color: selected ? colorScheme.onPrimary : colorScheme.primary,
            ),
            const SizedBox(height: ProSpacing.sm),
            Text(
              persona.name,
              style: theme.textTheme.titleMedium?.copyWith(
                color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: ProSpacing.xs),
            Text(
              persona.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: selected
                    ? colorScheme.onPrimary.withValues(alpha: 0.85)
                    : colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            if (persona.tags.isNotEmpty)
              Wrap(
                spacing: ProSpacing.xs,
                runSpacing: ProSpacing.xs,
                children: persona.tags.take(2).map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? colorScheme.onPrimary.withValues(alpha: 0.12)
                          : colorScheme.primaryContainer.withValues(
                              alpha: 0.35,
                            ),
                      borderRadius: BorderRadius.circular(ProRadius.sm),
                    ),
                    child: Text(
                      tag,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: selected
                            ? colorScheme.onPrimary
                            : colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _DisplayMessage {
  _DisplayMessage({
    required this.role,
    required this.content,
    required this.timestamp,
    this.translationHelp,
    this.grammarNotes = const [],
    this.providerNote,
  });

  final String role;
  final String content;
  final DateTime timestamp;
  final String? translationHelp;
  final List<String> grammarNotes;
  final String? providerNote;
}
