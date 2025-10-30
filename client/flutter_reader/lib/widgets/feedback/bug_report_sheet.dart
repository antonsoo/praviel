import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_providers.dart';
import '../../models/language.dart';
import '../../services/haptic_service.dart';
import '../../services/support_api.dart';
import '../../services/language_controller.dart';

class BugReportSheet extends ConsumerStatefulWidget {
  const BugReportSheet({super.key, required this.rootContext});

  final BuildContext rootContext;

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => BugReportSheet(rootContext: context),
    );
  }

  @override
  ConsumerState<BugReportSheet> createState() => _BugReportSheetState();
}

class _BugReportSheetState extends ConsumerState<BugReportSheet> {
  final _formKey = GlobalKey<FormState>();
  final _summaryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _emailController = TextEditingController();

  bool _submitting = false;

  @override
  void dispose() {
    _summaryController.dispose();
    _descriptionController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final languageCode =
        ref.watch(languageControllerProvider).value ?? 'grc-cls';
    final languageName = _languageName(languageCode);
    final platformLabel = defaultTargetPlatform.name.toUpperCase();
    const appVersion = 'Alpha Test – Oct 2025';

    return AnimatedPadding(
      duration: const Duration(milliseconds: 260),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Material(
        color: colorScheme.surface,
        elevation: 6,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Report a bug',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: _submitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Found something odd? Send details straight to the PRAVIEL team. '
                    'We read every report during the alpha.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _summaryController,
                    enabled: !_submitting,
                    decoration: const InputDecoration(
                      labelText: 'Short summary',
                      hintText: 'Lesson generator fails when using demo key',
                    ),
                    textInputAction: TextInputAction.next,
                    maxLength: 120,
                    validator: (value) {
                      final trimmed = value?.trim() ?? '';
                      if (trimmed.length < 5) {
                        return 'Please describe the issue briefly (5+ characters).';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    enabled: !_submitting,
                    decoration: const InputDecoration(
                      labelText: 'What happened?',
                      hintText:
                          'Include steps to reproduce, expected behaviour, and anything else that helps us debug.',
                      alignLabelWithHint: true,
                    ),
                    maxLines: 6,
                    minLines: 4,
                    maxLength: 1000,
                    validator: (value) {
                      final trimmed = value?.trim() ?? '';
                      if (trimmed.length < 20) {
                        return 'Help us reproduce it—20+ characters appreciated.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    enabled: !_submitting,
                    decoration: const InputDecoration(
                      labelText: 'Reply-to email (optional)',
                      hintText: 'support@praviel.com',
                    ),
                    textInputAction: TextInputAction.done,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      final trimmed = value?.trim() ?? '';
                      if (trimmed.isEmpty) {
                        return null;
                      }
                      final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                      if (!emailRegex.hasMatch(trimmed)) {
                        return 'Enter a valid email address or leave blank.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  _MetadataChips(
                    language: languageName,
                    platform: platformLabel,
                    appVersion: appVersion,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      TextButton(
                        onPressed: _submitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: _submitting
                            ? null
                            : () => _submit(
                                appVersion: appVersion,
                                platform: platformLabel,
                                languageCode: languageCode,
                              ),
                        icon: _submitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.send),
                        label: Text(
                          _submitting ? 'Sending...' : 'Send to PRAVIEL',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit({
    required String appVersion,
    required String platform,
    required String languageCode,
  }) async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      HapticService.error();
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);

    try {
      final supportApi = ref.read(supportApiProvider);
      final rootScaffoldMessenger = ScaffoldMessenger.of(widget.rootContext);
      await supportApi.submitBugReport(
        summary: _summaryController.text.trim(),
        description: _descriptionController.text.trim(),
        contactEmail: _emailController.text.trim(),
        appVersion: appVersion,
        platform: platform,
        language: languageCode,
      );
      HapticService.success();
      if (!mounted) return;
      Navigator.of(context).pop();
      rootScaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Thanks! We\'ll look into it shortly.')),
      );
    } on SupportApiException catch (error) {
      HapticService.error();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
      setState(() => _submitting = false);
    } catch (error) {
      HapticService.error();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not send report: $error')));
      setState(() => _submitting = false);
    }
  }

  String _languageName(String code) {
    try {
      return availableLanguages.firstWhere((lang) => lang.code == code).name;
    } catch (_) {
      return 'Unknown language';
    }
  }
}

class _MetadataChips extends StatelessWidget {
  const _MetadataChips({
    required this.language,
    required this.platform,
    required this.appVersion,
  });

  final String language;
  final String platform;
  final String appVersion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final chipStyle = theme.textTheme.labelSmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );

    Widget chip(IconData icon, String label) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: colorScheme.primary),
            const SizedBox(width: 6),
            Text(label, style: chipStyle),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        chip(Icons.language_outlined, language),
        chip(Icons.bug_report_outlined, platform),
        chip(Icons.science_outlined, appVersion),
      ],
    );
  }
}
