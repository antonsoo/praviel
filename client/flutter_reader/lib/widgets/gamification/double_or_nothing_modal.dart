import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/vibrant_colors.dart';
import '../../app_providers.dart';

/// Double or Nothing Challenge Modal
/// Inspired by Duolingo's highly successful engagement mechanic
/// +60% goal completion during challenge (research-backed)
class DoubleOrNothingModal extends ConsumerStatefulWidget {
  const DoubleOrNothingModal({super.key});

  @override
  ConsumerState<DoubleOrNothingModal> createState() => _DoubleOrNothingModalState();
}

class _DoubleOrNothingModalState extends ConsumerState<DoubleOrNothingModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  int _selectedDays = 7;
  int _wagerAmount = 100;

  final List<int> _dayOptions = [7, 14, 30];
  final List<int> _wagerOptions = [100, 200, 500, 1000];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backendServiceAsync = ref.watch(backendChallengeServiceProvider);
    final powerUpServiceAsync = ref.watch(powerUpServiceProvider);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF667EEA),
                  Color(0xFF764BA2),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.casino_rounded,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Double or Nothing',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Wager coins and double your bet if you complete daily goals!',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Content
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(28),
                    ),
                  ),
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Research callout
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              VibrantColors.success.withValues(alpha: 0.1),
                              VibrantColors.primary.withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: VibrantColors.success.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.science_rounded,
                              color: VibrantColors.success,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '+60% goal completion during challenge (Duolingo research)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: VibrantColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Wager selection
                      Text(
                        'Choose Your Wager',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: VibrantColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      powerUpServiceAsync.when(
                        data: (powerUpService) => _buildWagerSelector(powerUpService.coins),
                        loading: () => _buildWagerSelector(0),
                        error: (error, stackTrace) => _buildWagerSelector(0),
                      ),

                      const SizedBox(height: 24),

                      // Days selection
                      Text(
                        'Challenge Duration',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: VibrantColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDaysSelector(),

                      const SizedBox(height: 24),

                      // Potential reward display
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              VibrantColors.xpGold,
                              Color(0xFFFFA500),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Potential Reward',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.monetization_on_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${_wagerAmount * 2}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Win 2x your wager!',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: BorderSide(
                                  color: VibrantColors.textSecondary,
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: VibrantColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: backendServiceAsync.when(
                              data: (service) => powerUpServiceAsync.when(
                                data: (powerUpService) => ElevatedButton(
                                  onPressed: powerUpService.coins >= _wagerAmount
                                      ? () async {
                                          final success = await service.startDoubleOrNothing(
                                            wager: _wagerAmount,
                                            days: _selectedDays,
                                          );
                                          if (context.mounted) {
                                            if (success) {
                                              Navigator.pop(context, true);
                                              _showSuccessSnackbar();
                                            } else {
                                              _showErrorSnackbar();
                                            }
                                          }
                                        }
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: VibrantColors.success,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 4,
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.rocket_launch_rounded, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Start Challenge',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                loading: () => const Center(child: CircularProgressIndicator()),
                                error: (error, stackTrace) => const SizedBox.shrink(),
                              ),
                              loading: () => const Center(child: CircularProgressIndicator()),
                              error: (error, stackTrace) => const SizedBox.shrink(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWagerSelector(int availableCoins) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _wagerOptions.map((amount) {
        final canAfford = availableCoins >= amount;
        final isSelected = _wagerAmount == amount;

        return GestureDetector(
          onTap: canAfford
              ? () {
                  setState(() {
                    _wagerAmount = amount;
                  });
                }
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? VibrantColors.primary
                  : (canAfford
                      ? VibrantColors.primary.withValues(alpha: 0.1)
                      : VibrantColors.textHint.withValues(alpha: 0.1)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? VibrantColors.primary
                    : (canAfford
                        ? VibrantColors.primary.withValues(alpha: 0.3)
                        : VibrantColors.textHint.withValues(alpha: 0.3)),
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  canAfford ? Icons.monetization_on_rounded : Icons.lock_rounded,
                  size: 18,
                  color: isSelected
                      ? Colors.white
                      : (canAfford ? VibrantColors.primary : VibrantColors.textHint),
                ),
                const SizedBox(width: 6),
                Text(
                  '$amount',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.white
                        : (canAfford ? VibrantColors.primary : VibrantColors.textHint),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDaysSelector() {
    return Row(
      children: _dayOptions.map((days) {
        final isSelected = _selectedDays == days;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedDays = days;
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [
                          VibrantColors.gradientStart,
                          VibrantColors.gradientEnd,
                        ],
                      )
                    : null,
                color: isSelected ? null : VibrantColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? VibrantColors.primary
                      : VibrantColors.primary.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '$days',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : VibrantColors.primary,
                    ),
                  ),
                  Text(
                    'days',
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.9)
                          : VibrantColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showSuccessSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.celebration_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Challenge started! Complete daily goals for $_selectedDays days to win ${_wagerAmount * 2} coins!',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: VibrantColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showErrorSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Failed to start challenge. Please try again.',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: VibrantColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
