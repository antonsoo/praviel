import 'package:flutter/material.dart';
import '../services/music_service.dart';
import '../theme/vibrant_theme.dart';

/// Floating music controls widget that appears in the bottom-right corner
class MusicControls extends StatefulWidget {
  const MusicControls({super.key});

  @override
  State<MusicControls> createState() => _MusicControlsState();
}

class _MusicControlsState extends State<MusicControls> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Positioned(
      right: VibrantSpacing.md,
      bottom: VibrantSpacing.md,
      child: AnimatedBuilder(
        animation: MusicService.instance,
        builder: (context, _) {
          final musicService = MusicService.instance;

          if (_expanded) {
            // Expanded view with all controls
            return Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(VibrantRadius.lg),
              color: colorScheme.surfaceContainerHigh,
              child: Container(
                padding: const EdgeInsets.all(VibrantSpacing.sm),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Collapse button
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Audio Controls',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: VibrantSpacing.xs),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () => setState(() => _expanded = false),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: VibrantSpacing.xs),

                    // Music control
                    _buildControlRow(
                      icon: musicService.musicEnabled
                          ? Icons.music_note_rounded
                          : Icons.music_off_rounded,
                      label: 'Music',
                      enabled: musicService.musicEnabled,
                      onTap: musicService.toggleMusic,
                    ),

                    const SizedBox(height: VibrantSpacing.xs),

                    // Sound effects control
                    _buildControlRow(
                      icon: musicService.sfxEnabled
                          ? Icons.volume_up_rounded
                          : Icons.volume_off_rounded,
                      label: 'Sound FX',
                      enabled: musicService.sfxEnabled,
                      onTap: musicService.toggleSfx,
                    ),

                    const SizedBox(height: VibrantSpacing.xs),

                    // Mute all control
                    _buildControlRow(
                      icon: musicService.muteAll
                          ? Icons.volume_mute_rounded
                          : Icons.volume_up_rounded,
                      label: 'Mute All',
                      enabled: !musicService.muteAll,
                      onTap: musicService.toggleMuteAll,
                    ),
                  ],
                ),
              ),
            );
          } else {
            // Collapsed view - small floating button
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Quick toggle for music
                if (musicService.musicEnabled && !musicService.muteAll)
                  _buildFloatingButton(
                    icon: Icons.music_note_rounded,
                    color: colorScheme.primary,
                    onPressed: musicService.toggleMusic,
                    tooltip: 'Pause music',
                  ),
                if (!musicService.musicEnabled || musicService.muteAll)
                  _buildFloatingButton(
                    icon: Icons.music_off_rounded,
                    color: colorScheme.surfaceContainerHighest,
                    onPressed: musicService.toggleMusic,
                    tooltip: 'Play music',
                  ),

                const SizedBox(width: VibrantSpacing.xs),

                // Expand button
                _buildFloatingButton(
                  icon: Icons.tune_rounded,
                  color: colorScheme.secondaryContainer,
                  onPressed: () => setState(() => _expanded = true),
                  tooltip: 'Audio settings',
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildControlRow({
    required IconData icon,
    required String label,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(VibrantRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: VibrantSpacing.md,
          vertical: VibrantSpacing.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: enabled ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: VibrantSpacing.sm),
            SizedBox(
              width: 80,
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: enabled ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                  fontWeight: enabled ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            Switch(
              value: enabled,
              onChanged: (_) => onTap(),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        elevation: 4,
        shape: const CircleBorder(),
        color: color,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(VibrantSpacing.sm),
            child: Icon(icon, size: 20, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
