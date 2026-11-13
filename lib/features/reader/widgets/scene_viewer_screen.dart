import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/models/scene_annotation_model.dart';
import 'chapter_scene_widget.dart';

class SceneViewerScreen extends StatelessWidget {
  const SceneViewerScreen({
    super.key,
    required this.scene,
    required this.storyTitle,
    required this.heroTag,
  });

  final SceneAnnotationModel scene;
  final String storyTitle;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final title = scene.title ?? scene.label ?? storyTitle;
    final height = (MediaQuery.sizeOf(context).height * 0.38).clamp(
      180.0,
      340.0,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: ColoredBox(color: colors.scrim.withValues(alpha: 0.76)),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Return to reading',
                            onPressed: () => Navigator.of(context).pop(),
                            color: Colors.white,
                            icon: const Icon(Icons.close_rounded),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              storyTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.88),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: -5, end: 5),
                                duration: reducedMotion
                                    ? Duration.zero
                                    : const Duration(seconds: 7),
                                curve: Curves.easeInOut,
                                builder: (context, offset, child) =>
                                    Transform.translate(
                                      offset: Offset(offset, 0),
                                      child: child,
                                    ),
                                child: Hero(
                                  tag: heroTag,
                                  child: Material(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(28),
                                    clipBehavior: Clip.antiAlias,
                                    child: SceneArtwork(
                                      scene: scene,
                                      height: height.toDouble(),
                                      playAnimation: !reducedMotion,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 26),
                              Text(
                                title,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              if (scene.description?.isNotEmpty ?? false) ...[
                                const SizedBox(height: 12),
                                Text(
                                  scene.description!,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                        height: 1.5,
                                      ),
                                ),
                              ],
                              if (scene.educationalNote?.isNotEmpty ??
                                  false) ...[
                                const SizedBox(height: 16),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.lightbulb_outline_rounded,
                                        color: Colors.amberAccent,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          scene.educationalNote!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: Colors.white,
                                                height: 1.4,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.menu_book_rounded),
                          label: const Text('Return to Reading'),
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.primaryContainer,
                            foregroundColor: colors.onPrimaryContainer,
                            minimumSize: const Size.fromHeight(52),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
