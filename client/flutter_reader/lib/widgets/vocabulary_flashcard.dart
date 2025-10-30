import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/vibrant_animations.dart';

/// 3D flip card for vocabulary practice (2025 gamified learning UX)
class VocabularyFlashcard extends StatefulWidget {
  const VocabularyFlashcard({
    super.key,
    required this.word,
    required this.translation,
    this.pronunciation,
    this.example,
    this.onFlip,
  });

  final String word;
  final String translation;
  final String? pronunciation;
  final String? example;
  final VoidCallback? onFlip;

  @override
  State<VocabularyFlashcard> createState() => _VocabularyFlashcardState();
}

class _VocabularyFlashcardState extends State<VocabularyFlashcard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _flipAnimation;
  bool _showFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: VibrantDuration.moderate,
    );
    _flipAnimation = Tween<double>(begin: 0, end: pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    if (_showFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() => _showFront = !_showFront);
    widget.onFlip?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _flipAnimation,
        builder: (context, child) {
          final angle = _flipAnimation.value;
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001) // perspective
            ..rotateY(angle);

          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: angle <= pi / 2
                ? _buildFront(theme, colorScheme)
                : Transform(
                    transform: Matrix4.identity()..rotateY(pi),
                    alignment: Alignment.center,
                    child: _buildBack(theme, colorScheme),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildFront(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.word,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: colorScheme.onPrimaryContainer,
            ),
            textAlign: TextAlign.center,
          ),
          if (widget.pronunciation != null) ...[
            const SizedBox(height: 12),
            Text(
              widget.pronunciation!,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          Icon(
            Icons.touch_app,
            color: colorScheme.onPrimaryContainer.withValues(alpha: 0.5),
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap to reveal',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBack(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.tertiaryContainer,
            colorScheme.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.translation,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.onTertiaryContainer,
            ),
            textAlign: TextAlign.center,
          ),
          if (widget.example != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.example!,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onTertiaryContainer.withValues(alpha: 0.9),
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Swipeable flashcard stack for practice mode
class FlashcardStack extends StatefulWidget {
  const FlashcardStack({
    super.key,
    required this.cards,
    this.onComplete,
  });

  final List<VocabularyFlashcard> cards;
  final VoidCallback? onComplete;

  @override
  State<FlashcardStack> createState() => _FlashcardStackState();
}

class _FlashcardStackState extends State<FlashcardStack> {
  int _currentIndex = 0;
  final List<GlobalKey> _cardKeys = [];

  @override
  void initState() {
    super.initState();
    _cardKeys.addAll(
      List.generate(widget.cards.length, (_) => GlobalKey()),
    );
  }

  void _nextCard() {
    if (_currentIndex < widget.cards.length - 1) {
      setState(() => _currentIndex++);
    } else {
      widget.onComplete?.call();
    }
  }

  void _previousCard() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Progress indicator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '${_currentIndex + 1} / ${widget.cards.length}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: LinearProgressIndicator(
                  value: (_currentIndex + 1) / widget.cards.length,
                  borderRadius: BorderRadius.circular(8),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Card stack
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Stack(
              children: [
                // Show current card
                if (_currentIndex < widget.cards.length)
                  widget.cards[_currentIndex],
              ],
            ),
          ),
        ),

        // Navigation buttons
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton.filled(
                onPressed: _currentIndex > 0 ? _previousCard : null,
                icon: const Icon(Icons.arrow_back),
                iconSize: 32,
              ),
              IconButton.filled(
                onPressed: _nextCard,
                icon: Icon(
                  _currentIndex < widget.cards.length - 1
                      ? Icons.arrow_forward
                      : Icons.check,
                ),
                iconSize: 32,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Memory game with flashcards
class FlashcardMemoryGame extends StatefulWidget {
  const FlashcardMemoryGame({
    super.key,
    required this.cards,
    this.onComplete,
  });

  final List<({String word, String translation})> cards;
  final Function(int correctAnswers)? onComplete;

  @override
  State<FlashcardMemoryGame> createState() => _FlashcardMemoryGameState();
}

class _FlashcardMemoryGameState extends State<FlashcardMemoryGame> {
  late List<_MemoryCard> _gameCards;
  int? _firstSelectedIndex;
  int? _secondSelectedIndex;
  int _matchedPairs = 0;
  int _attempts = 0;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    _gameCards = [];

    // Create pairs
    for (int i = 0; i < widget.cards.length; i++) {
      _gameCards.add(_MemoryCard(
        id: i * 2,
        content: widget.cards[i].word,
        pairId: i,
        isWord: true,
      ));
      _gameCards.add(_MemoryCard(
        id: i * 2 + 1,
        content: widget.cards[i].translation,
        pairId: i,
        isWord: false,
      ));
    }

    // Shuffle
    _gameCards.shuffle();
  }

  void _onCardTap(int index) {
    if (_gameCards[index].isMatched || _gameCards[index].isRevealed) return;
    if (_secondSelectedIndex != null) return;

    setState(() {
      _gameCards[index].isRevealed = true;

      if (_firstSelectedIndex == null) {
        _firstSelectedIndex = index;
      } else {
        _secondSelectedIndex = index;
        _attempts++;
        _checkMatch();
      }
    });
  }

  void _checkMatch() {
    final first = _gameCards[_firstSelectedIndex!];
    final second = _gameCards[_secondSelectedIndex!];

    if (first.pairId == second.pairId) {
      // Match!
      setState(() {
        first.isMatched = true;
        second.isMatched = true;
        _matchedPairs++;
        _firstSelectedIndex = null;
        _secondSelectedIndex = null;
      });

      if (_matchedPairs == widget.cards.length) {
        widget.onComplete?.call(_attempts);
      }
    } else {
      // No match - hide after delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            first.isRevealed = false;
            second.isRevealed = false;
            _firstSelectedIndex = null;
            _secondSelectedIndex = null;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Attempts: $_attempts',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                'Matched: $_matchedPairs / ${widget.cards.length}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _gameCards.length,
            itemBuilder: (context, index) {
              return _buildMemoryCard(context, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMemoryCard(BuildContext context, int index) {
    final card = _gameCards[index];
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _onCardTap(index),
      child: AnimatedContainer(
        duration: VibrantDuration.normal,
        decoration: BoxDecoration(
          gradient: card.isRevealed || card.isMatched
              ? LinearGradient(
                  colors: [
                    theme.colorScheme.primaryContainer,
                    theme.colorScheme.secondaryContainer,
                  ],
                )
              : LinearGradient(
                  colors: [
                    theme.colorScheme.surfaceContainerHighest,
                    theme.colorScheme.surfaceContainerHigh,
                  ],
                ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: card.isMatched
                ? Colors.green
                : theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 2,
          ),
        ),
        child: Center(
          child: card.isRevealed || card.isMatched
              ? Text(
                  card.content,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                )
              : Icon(
                  Icons.question_mark,
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
        ),
      ),
    );
  }
}

class _MemoryCard {
  _MemoryCard({
    required this.id,
    required this.content,
    required this.pairId,
    required this.isWord,
  });

  final int id;
  final String content;
  final int pairId;
  final bool isWord;
  bool isRevealed = false;
  bool isMatched = false;
}
