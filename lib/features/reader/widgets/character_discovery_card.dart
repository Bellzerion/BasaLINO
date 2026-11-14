import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/models/scene_hotspot_model.dart';
import '../../../core/models/vocab_hint_model.dart';

class CharacterDiscoveryCard extends StatelessWidget {
  const CharacterDiscoveryCard({
    super.key,
    required this.hotspot,
    required this.storyTitle,
    required this.vocabularyHints,
    this.onVocabularySelected,
  });

  final SceneHotspotModel hotspot;
  final String storyTitle;
  final List<VocabHintModel> vocabularyHints;
  final ValueChanged<VocabHintModel>? onVocabularySelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final illustration = hotspot.imageAsset;
    final relatedHints = vocabularyHints
        .where((hint) => hotspot.vocabularyIds.contains(hint.vocabularyId))
        .toList();

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shadowColor: colors.primary.withValues(alpha: 0.16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (illustration != null && illustration.isNotEmpty)
            SizedBox(
              height: 128,
              child: illustration.toLowerCase().endsWith('.svg')
                  ? SvgPicture.asset(
                      illustration,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _ArtworkFallback(color: colors.secondaryContainer),
                    )
                  : Image.asset(
                      illustration,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _ArtworkFallback(color: colors.secondaryContainer),
                    ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      hotspot.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (hotspot.role?.isNotEmpty ?? false)
                      Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text(hotspot.role!),
                        backgroundColor: colors.secondaryContainer,
                        labelStyle: TextStyle(
                          color: colors.onSecondaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  storyTitle,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  hotspot.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                if (hotspot.educationalNote?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: colors.tertiaryContainer.withValues(alpha: 0.62),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 19,
                          color: colors.onTertiaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            hotspot.educationalNote!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: colors.onTertiaryContainer,
                                  height: 1.4,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (relatedHints.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'RELATED VOCABULARY',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 7,
                    runSpacing: 2,
                    children: relatedHints
                        .map(
                          (hint) => ActionChip(
                            avatar: const Icon(
                              Icons.volume_up_outlined,
                              size: 16,
                            ),
                            label: Text(hint.word),
                            onPressed: onVocabularySelected == null
                                ? null
                                : () => onVocabularySelected!(hint),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtworkFallback extends StatelessWidget {
  const _ArtworkFallback({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: color,
    child: const Center(child: Icon(Icons.auto_awesome_rounded, size: 36)),
  );
}
