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
  static const Set<String> _officialPersonaTags = {
    'politics',
    'law',
    'rhetoric',
    'military',
    'religion',
    'philosophy',
    'scholarship',
    'science',
    'history',
    'governance',
    'administration',
    'diplomacy',
    'theology',
    'statecraft',
    'government',
    'strategy',
    'warfare',
  };

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
    final hasPersonas = _availablePersonas.isNotEmpty;
    final selectedPersona = hasPersonas
        ? _availablePersonas.firstWhere(
            (persona) => persona.id == _selectedPersona,
            orElse: () => _availablePersonas.first,
          )
        : null;

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
            'Chat personas',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: ProSpacing.xs),
          Text(
            selectedPersona == null
                ? 'Personas will appear here as soon as we ship them for $languageName.'
                : 'Currently chatting with ${selectedPersona.name}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.78),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: ProSpacing.lg),
          if (selectedPersona != null)
            _buildPersonaDetailCard(theme, colorScheme, selectedPersona)
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(ProSpacing.lg),
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(ProRadius.lg),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.08),
                ),
              ),
              child: Text(
                'No personas are available for $languageName yet. We\'re training them now!',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          const SizedBox(height: ProSpacing.lg),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: hasPersonas
                  ? () => _openPersonaLibrary(languageName)
                  : null,
              icon: const Icon(Icons.face_retouching_natural),
              label: Text(
                hasPersonas ? 'Choose persona' : 'No personas available',
              ),
            ),
          ),
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

  void _openPersonaLibrary(String languageName) {
    if (_availablePersonas.isEmpty) {
      if (!mounted) return;
      HapticService.light();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No personas available for $languageName yet. We\'re working on it!',
          ),
        ),
      );
      return;
    }

    HapticService.light();
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: _PersonaPickerSheet(
            personas: _availablePersonas,
            selectedId: _selectedPersona,
            languageName: languageName,
            officialTags: _officialPersonaTags,
            onSelected: (personaId) {
              Navigator.of(context).pop();
              _selectPersona(personaId);
            },
          ),
        );
      },
    );
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
              _DifficultyChip(difficulty: persona.difficulty),
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
              children: persona.tags
                  .take(4)
                  .map((tag) => _TagChip(label: tag))
                  .toList(),
            ),
          ],
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
                  : 'Use "Choose persona" to decide who you want to practice with.',
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

enum _PersonaCategory { everyday, official }

class _PersonaPickerSheet extends StatefulWidget {
  const _PersonaPickerSheet({
    required this.personas,
    required this.selectedId,
    required this.languageName,
    required this.officialTags,
    required this.onSelected,
  });

  final List<ChatbotPersona> personas;
  final String? selectedId;
  final String languageName;
  final Set<String> officialTags;
  final ValueChanged<String> onSelected;

  @override
  State<_PersonaPickerSheet> createState() => _PersonaPickerSheetState();
}

class _PersonaPickerSheetState extends State<_PersonaPickerSheet> {
  _PersonaCategory _category = _PersonaCategory.everyday;

  bool _isOfficial(ChatbotPersona persona) {
    final tags = persona.tags.map((tag) => tag.toLowerCase()).toSet();
    if (tags.any(widget.officialTags.contains)) {
      return true;
    }
    return persona.difficulty.toLowerCase() == 'advanced';
  }

  List<ChatbotPersona> get _filteredPersonas {
    switch (_category) {
      case _PersonaCategory.official:
        return widget.personas.where(_isOfficial).toList();
      case _PersonaCategory.everyday:
        return widget.personas
            .where((persona) => !_isOfficial(persona))
            .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final personas = _filteredPersonas;

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.2),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: ProSpacing.sm),
            Container(
              width: 48,
              height: 4,
              margin: const EdgeInsets.only(bottom: ProSpacing.md),
              decoration: BoxDecoration(
                color: colorScheme.outline.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ProSpacing.xl,
                0,
                ProSpacing.xl,
                ProSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose a persona',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: ProSpacing.xs),
                  Text(
                    'Personas for ${widget.languageName}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: ProSpacing.lg),
                  SegmentedButton<_PersonaCategory>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: _PersonaCategory.everyday,
                        label: Text('Everyday & casual'),
                        icon: Icon(Icons.people_outline),
                      ),
                      ButtonSegment(
                        value: _PersonaCategory.official,
                        label: Text('Formal & official'),
                        icon: Icon(Icons.gavel_outlined),
                      ),
                    ],
                    selected: {_category},
                    onSelectionChanged: (selection) {
                      setState(() => _category = selection.first);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: personas.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(ProSpacing.xl),
                        child: Text(
                          'No personas in this category yet. Try the other view.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        ProSpacing.xl,
                        ProSpacing.md,
                        ProSpacing.xl,
                        ProSpacing.xl,
                      ),
                      itemCount: personas.length,
                      separatorBuilder: (context, _) =>
                          const SizedBox(height: ProSpacing.md),
                      itemBuilder: (context, index) {
                        final persona = personas[index];
                        return _PersonaListEntry(
                          persona: persona,
                          selected: persona.id == widget.selectedId,
                          onTap: () => widget.onSelected(persona.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonaListEntry extends StatelessWidget {
  const _PersonaListEntry({
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
    final tags = persona.tags.take(3).toList();

    return InkWell(
      borderRadius: BorderRadius.circular(ProRadius.lg),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(ProSpacing.lg),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primaryContainer.withValues(alpha: 0.45)
              : colorScheme.surface.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(ProRadius.lg),
          border: Border.all(
            color: selected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.14),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  persona.icon,
                  size: 20,
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: ProSpacing.sm),
                Expanded(
                  child: Text(
                    persona.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (selected)
                  Icon(
                    Icons.check_circle,
                    size: 18,
                    color: colorScheme.primary,
                  ),
              ],
            ),
            const SizedBox(height: ProSpacing.xs),
            Text(
              persona.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: ProSpacing.sm),
            Wrap(
              spacing: ProSpacing.sm,
              runSpacing: ProSpacing.sm,
              children: [
                _DifficultyChip(difficulty: persona.difficulty, compact: true),
                for (final tag in tags) _TagChip(label: tag),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DifficultyChip extends StatelessWidget {
  const _DifficultyChip({required this.difficulty, this.compact = false});

  final String difficulty;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
    final label = normalized.isEmpty
        ? 'Any'
        : '${normalized[0].toUpperCase()}${normalized.substring(1)}';
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            size: compact ? 12 : 14,
            color: tone,
          ),
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
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
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
