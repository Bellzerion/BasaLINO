import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/models/vocab_hint_model.dart';

class VocabularyCardOverlay extends StatefulWidget {
  const VocabularyCardOverlay({
    super.key,
    required this.hint,
    required this.languageCode,
    required this.exampleSentence,
    required this.onClose,
  });

  final VocabHintModel hint;
  final String languageCode;
  final String exampleSentence;
  final VoidCallback onClose;

  @override
  State<VocabularyCardOverlay> createState() => _VocabularyCardOverlayState();
}

class _VocabularyCardOverlayState extends State<VocabularyCardOverlay> {
  bool _isClosing = false;
  Timer? _closeTimer;

  void _close() {
    if (_isClosing) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      widget.onClose();
      return;
    }
    setState(() => _isClosing = true);
    _closeTimer = Timer(const Duration(milliseconds: 190), widget.onClose);
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final card = StoryVocabularyCard(
      hint: widget.hint,
      languageCode: widget.languageCode,
      exampleSentence: widget.exampleSentence,
      onClose: _close,
    );
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final closingDuration = reducedMotion
        ? Duration.zero
        : const Duration(milliseconds: 180);

    return AnimatedOpacity(
      opacity: _isClosing ? 0 : 1,
      duration: closingDuration,
      child: AnimatedScale(
        scale: _isClosing ? 0.96 : 1,
        duration: closingDuration,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            minimum: const EdgeInsets.fromLTRB(12, 12, 12, 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 520,
                maxHeight: size.height * 0.58,
              ),
              child: reducedMotion
                  ? card
                  : card
                        .animate()
                        .scale(
                          begin: const Offset(0.94, 0.94),
                          duration: 150.ms,
                          curve: Curves.easeOutCubic,
                        )
                        .then()
                        .fadeIn(duration: 110.ms)
                        .then()
                        .slideY(
                          begin: 0.16,
                          end: 0,
                          duration: 150.ms,
                          curve: Curves.easeOutCubic,
                        ),
            ),
          ),
        ),
      ),
    );
  }
}

class StoryVocabularyCard extends StatelessWidget {
  const StoryVocabularyCard({
    super.key,
    required this.hint,
    required this.languageCode,
    required this.exampleSentence,
    required this.onClose,
    this.onPlayAudio,
  });

  final VocabHintModel hint;
  final String languageCode;
  final String exampleSentence;
  final VoidCallback onClose;
  final VoidCallback? onPlayAudio;

  String get _languageName => switch (languageCode) {
    'tl' => 'Tagalog',
    'bik' => 'Bikol',
    'en' => 'English',
    _ => languageCode.toUpperCase(),
  };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final cardColor =
        Theme.of(context).cardTheme.color ?? colors.surfaceContainerHigh;
    final tagalogTranslation =
        hint.tagalogTranslation ?? (languageCode == 'tl' ? hint.word : '—');
    final englishTranslation =
        hint.englishTranslation ?? (languageCode == 'en' ? hint.word : '—');
    final illustration = hint.illustrationAsset;

    return Material(
      color: cardColor,
      elevation: 14,
      shadowColor: AppTheme.primaryColor.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(26),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    hint.partOfSpeech?.toUpperCase() ?? _languageName,
                    style: TextStyle(
                      color: colors.onSecondaryContainer,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                if (hint.audioAsset != null)
                  IconButton(
                    tooltip: 'Play pronunciation',
                    onPressed: onPlayAudio,
                    icon: const Icon(Icons.volume_up_rounded),
                  ),
                IconButton(
                  tooltip: 'Close vocabulary card',
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            if (illustration != null) ...[
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: illustration.toLowerCase().endsWith('.svg')
                    ? SvgPicture.asset(
                        illustration,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholderBuilder: (context) => const SizedBox(
                          height: 120,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      )
                    : Image.asset(
                        illustration,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox.shrink(),
                      ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              hint.word,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              _languageName,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            _TranslationRow(
              label: 'Tagalog',
              value: tagalogTranslation,
              color: colors.primaryContainer,
            ),
            const SizedBox(height: 8),
            _TranslationRow(
              label: 'English',
              value: englishTranslation,
              color: colors.secondaryContainer,
            ),
            if (hint.definition.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                hint.definition,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: colors.onSurfaceVariant, height: 1.45),
              ),
            ],
            if (exampleSentence.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'IN THE STORY',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exampleSentence,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurface,
                        height: 1.4,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TranslationRow extends StatelessWidget {
  const _TranslationRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
