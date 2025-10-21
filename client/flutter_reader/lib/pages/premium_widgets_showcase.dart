import 'package:flutter/material.dart';
import '../theme/vibrant_theme.dart';
import '../widgets/premium_micro_interactions.dart';
import '../widgets/premium_celebrations.dart';
import '../widgets/premium_3d_animations.dart';
import '../widgets/premium_progress_animations.dart';
import '../widgets/premium_list_animations.dart';
import '../widgets/premium_fab_menu.dart';

/// Showcase page demonstrating all premium widgets
/// Created for Ancient Languages App - October 2025
class PremiumWidgetsShowcase extends StatefulWidget {
  const PremiumWidgetsShowcase({super.key});

  @override
  State<PremiumWidgetsShowcase> createState() => _PremiumWidgetsShowcaseState();
}

class _PremiumWidgetsShowcaseState extends State<PremiumWidgetsShowcase> {
  bool _showParticleBurst = false;
  bool _showConfetti = false;
  bool _showStarBurst = false;
  bool _showFirework = false;
  bool _showCheckmark = false;
  bool _isFlipped = false;
  double _progress = 0.7;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Widgets Showcase'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(VibrantSpacing.lg),
        children: [
          _buildSection(
            'Micro-Interactions',
            [
              _buildCard(
                'Shimmer Button',
                ShimmerButton(
                  onPressed: () {},
                  child: const Text(
                    'Shimmer Effect',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              _buildCard(
                'Particle Burst',
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() => _showParticleBurst = true);
                        Future.delayed(const Duration(milliseconds: 800), () {
                          if (mounted) {
                            setState(() => _showParticleBurst = false);
                          }
                        });
                      },
                      child: const Text('Trigger Burst'),
                    ),
                    ParticleBurst(isActive: _showParticleBurst),
                  ],
                ),
              ),
              _buildCard(
                'Pulsing Dot',
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PulseDot(color: Colors.green),
                    SizedBox(width: 8),
                    Text('Live'),
                  ],
                ),
              ),
              _buildCard(
                'Bouncing Arrow',
                const BouncingArrow(direction: AxisDirection.down),
              ),
            ],
          ),
          const SizedBox(height: VibrantSpacing.xl),
          _buildSection(
            'Celebration Animations',
            [
              _buildCard(
                'Confetti Burst',
                Stack(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() => _showConfetti = true);
                        Future.delayed(const Duration(seconds: 3), () {
                          if (mounted) {
                            setState(() => _showConfetti = false);
                          }
                        });
                      },
                      child: const Text('Celebrate!'),
                    ),
                    ConfettiBurst(isActive: _showConfetti),
                  ],
                ),
              ),
              _buildCard(
                'Star Burst',
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() => _showStarBurst = true);
                        Future.delayed(const Duration(milliseconds: 1200), () {
                          if (mounted) {
                            setState(() => _showStarBurst = false);
                          }
                        });
                      },
                      child: const Text('Achievement!'),
                    ),
                    StarBurst(isActive: _showStarBurst),
                  ],
                ),
              ),
              _buildCard(
                'Firework',
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() => _showFirework = true);
                        Future.delayed(const Duration(milliseconds: 1000), () {
                          if (mounted) {
                            setState(() => _showFirework = false);
                          }
                        });
                      },
                      child: const Text('Firework!'),
                    ),
                    FireworkExplosion(isActive: _showFirework),
                  ],
                ),
              ),
              _buildCard(
                'Success Checkmark',
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() => _showCheckmark = true);
                        Future.delayed(const Duration(milliseconds: 600), () {
                          if (mounted) {
                            setState(() => _showCheckmark = false);
                          }
                        });
                      },
                      child: const Text('Complete!'),
                    ),
                    SuccessCheckmark(isActive: _showCheckmark),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: VibrantSpacing.xl),
          _buildSection(
            '3D Animations',
            [
              _buildCard(
                'Flip Card',
                FlipCard(
                  isFlipped: _isFlipped,
                  onFlip: () => setState(() => _isFlipped = !_isFlipped),
                  front: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      gradient: VibrantTheme.heroGradient,
                      borderRadius: BorderRadius.circular(VibrantRadius.lg),
                    ),
                    child: const Center(
                      child: Text(
                        'Front',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  back: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      gradient: VibrantTheme.xpGradient,
                      borderRadius: BorderRadius.circular(VibrantRadius.lg),
                    ),
                    child: const Center(
                      child: Text(
                        'Back',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _buildCard(
                'Rotating Card (Hover)',
                RotatingCard(
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      gradient: VibrantTheme.violetGradient,
                      borderRadius: BorderRadius.circular(VibrantRadius.lg),
                    ),
                    child: const Center(
                      child: Text(
                        'Hover to tilt',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: VibrantSpacing.xl),
          _buildSection(
            'Progress Indicators',
            [
              _buildCard(
                'Morphing Circular Progress',
                Column(
                  children: [
                    MorphingCircularProgress(
                      progress: _progress,
                      gradient: VibrantTheme.premiumGradient,
                    ),
                    const SizedBox(height: VibrantSpacing.md),
                    Slider(
                      value: _progress,
                      onChanged: (value) => setState(() => _progress = value),
                    ),
                  ],
                ),
              ),
              _buildCard(
                'Wave Progress',
                WaveProgressIndicator(
                  progress: _progress,
                  color: VibrantTheme.oceanGradient.colors.first,
                ),
              ),
              _buildCard(
                'Segmented Progress',
                SegmentedProgressBar(
                  progress: _progress,
                  segmentCount: 5,
                ),
              ),
              _buildCard(
                'Pulsing Loader',
                const PulsingLoader(),
              ),
            ],
          ),
          const SizedBox(height: VibrantSpacing.xl),
          _buildSection(
            'List Animations',
            [
              _buildCard(
                'Staggered Fade-In',
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    itemCount: 3,
                    itemBuilder: (context, index) {
                      return StaggeredListAnimation(
                        index: index,
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(child: Text('${index + 1}')),
                            title: Text('Item ${index + 1}'),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: VibrantSpacing.xxxl),
        ],
      ),
      floatingActionButton: const ExpandableFab(
        children: [
          FabMenuItem(
            icon: Icons.add,
            label: 'Add',
            backgroundColor: Colors.blue,
          ),
          FabMenuItem(
            icon: Icons.edit,
            label: 'Edit',
            backgroundColor: Colors.green,
          ),
          FabMenuItem(
            icon: Icons.delete,
            label: 'Delete',
            backgroundColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: VibrantSpacing.md),
        ...children,
      ],
    );
  }

  Widget _buildCard(String title, Widget child) {
    return Card(
      margin: const EdgeInsets.only(bottom: VibrantSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(VibrantSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: VibrantSpacing.md),
            Center(child: child),
          ],
        ),
      ),
    );
  }
}
