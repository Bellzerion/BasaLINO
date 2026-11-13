import 'dart:async';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
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
                          if (scene.soundEffectAsset?.isNotEmpty ?? false)
                            _SceneSoundEffectButton(
                                  assetPath: scene.soundEffectAsset!,
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
                              if (scene.vocabularyContext?.isNotEmpty ??
                                  false) ...[
                                const SizedBox(height: 16),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'WORD TO REMEMBER',
                                        style: TextStyle(
                                          color: Colors.amberAccent,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.7,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        scene.vocabularyContext!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: Colors.white,
                                              height: 1.4,
                                            ),
                                      ),
                                    ],
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

class _SceneSoundEffectButton extends StatefulWidget {
  const _SceneSoundEffectButton({required this.assetPath});

  final String assetPath;

  @override
  State<_SceneSoundEffectButton> createState() =>
      _SceneSoundEffectButtonState();
}

class _SceneSoundEffectButtonState extends State<_SceneSoundEffectButton> {
  late final AudioPlayer _player;
  StreamSubscription<PlayerState>? _stateSubscription;
  bool _isLoading = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _stateSubscription = _player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state == PlayerState.playing;
        if (state == PlayerState.stopped ||
            state == PlayerState.completed ||
            state == PlayerState.paused) {
          _isLoading = false;
        }
      });
    });
  }

  Future<void> _toggle() async {
    if (_isPlaying) {
      await _player.stop();
      return;
    }
    setState(() => _isLoading = true);
    try {
      final asset = widget.assetPath.startsWith('assets/')
          ? widget.assetPath.substring('assets/'.length)
          : widget.assetPath;
      await _player.play(AssetSource(asset));
      if (mounted) setState(() => _isLoading = false);
    } catch (error, stackTrace) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Scene sound could not be played.')),
        );
      }
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'scene sound effect',
        ),
      );
    }
  }

  @override
  void dispose() {
    unawaited(_stateSubscription?.cancel());
    unawaited(_player.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: _isPlaying ? 'Stop scene sound' : 'Play scene sound',
    onPressed: _isLoading ? null : _toggle,
    color: Colors.white,
    icon: _isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(_isPlaying ? Icons.volume_off_rounded : Icons.volume_up_rounded),
  );
}
