import 'dart:async';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../ar/models/ar_content_model.dart';
import '../../ar/presentation/ar_explorer_screen.dart';
import '../../ar/services/ar_service.dart';
import '../../../core/models/scene_annotation_model.dart';
import '../../../core/models/scene_hotspot_model.dart';
import '../../../core/models/vocab_hint_model.dart';
import '../../../core/services/story_discovery_tracker.dart';
import 'character_discovery_card.dart';
import 'chapter_scene_widget.dart';
import 'vocabulary_card.dart';

class SceneViewerScreen extends StatefulWidget {
  const SceneViewerScreen({
    super.key,
    required this.scene,
    required this.storyTitle,
    required this.heroTag,
    this.storyId = '',
    this.languageCode = 'en',
    this.vocabularyHints = const [],
    this.discoveryTracker,
    this.arAvailabilityService = const PlatformArService(),
  });

  final SceneAnnotationModel scene;
  final String storyTitle;
  final String heroTag;
  final String storyId;
  final String languageCode;
  final List<VocabHintModel> vocabularyHints;
  final StoryDiscoveryTracker? discoveryTracker;
  final ArAvailabilityService arAvailabilityService;

  @override
  State<SceneViewerScreen> createState() => _SceneViewerScreenState();
}

class _SceneViewerScreenState extends State<SceneViewerScreen> {
  SceneHotspotModel? _selectedHotspot;
  VocabHintModel? _activeVocabularyHint;
  bool _checkingArSupport = false;
  bool _arSupported = false;

  bool get _isMayonVolcano =>
      widget.storyId == 'mayon' &&
      widget.scene.sceneType?.toLowerCase() == 'volcano';

  @override
  void initState() {
    super.initState();
    if (_isMayonVolcano) {
      _checkingArSupport = true;
      unawaited(_checkArSupport());
    }
  }

  Future<void> _checkArSupport() async {
    try {
      final supported = await widget.arAvailabilityService.isSupported();
      if (!mounted) return;
      setState(() {
        _arSupported = supported;
        _checkingArSupport = false;
      });
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'AR availability check',
        ),
      );
      if (mounted) setState(() => _checkingArSupport = false);
    }
  }

  void _openArExplorer() {
    SceneHotspotModel? hotspot;
    for (final item in widget.scene.hotspots) {
      if (item.category == 'location' &&
          item.title.toLowerCase().contains('mount mayon')) {
        hotspot = item;
        break;
      }
    }
    final content = ArContentModel.fromScene(
      scene: widget.scene,
      storyId: widget.storyId,
      hotspot: hotspot,
    );
    final navigator = Navigator.of(context);
    navigator.push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ArExplorerScreen(
          content: content,
          discoveryTracker: widget.discoveryTracker ?? StoryDiscoveryTracker(),
          availabilityService: widget.arAvailabilityService,
          onReturnToReader: () {
            if (navigator.canPop()) navigator.pop();
            if (navigator.canPop()) navigator.pop();
          },
        ),
      ),
    );
  }

  void _selectHotspot(SceneHotspotModel hotspot) {
    final closing = _selectedHotspot?.id == hotspot.id;
    setState(() => _selectedHotspot = closing ? null : hotspot);
    if (closing || widget.discoveryTracker == null) return;
    unawaited(_recordDiscovery('${widget.storyId}/${hotspot.id}'));
  }

  Future<void> _recordDiscovery(String id) async {
    try {
      await widget.discoveryTracker!.markDiscovered(id);
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'story discovery tracking',
        ),
      );
    }
  }

  void _showVocabulary(VocabHintModel hint) {
    setState(() => _activeVocabularyHint = hint);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final title = widget.scene.title ?? widget.scene.label ?? widget.storyTitle;
    final artworkHeight = (MediaQuery.sizeOf(context).height * 0.38).clamp(
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
                              widget.storyTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.88),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          if (widget.scene.ambientAudioAsset?.isNotEmpty ??
                              false)
                            _SceneAmbienceButton(
                              assetPath: widget.scene.ambientAudioAsset!,
                            ),
                          if (widget.scene.soundEffectAsset?.isNotEmpty ??
                              false)
                            _SceneSoundEffectButton(
                              assetPath: widget.scene.soundEffectAsset!,
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
                                child: SizedBox(
                                  height: artworkHeight.toDouble(),
                                  width: double.infinity,
                                  child: LayoutBuilder(
                                    builder: (context, constraints) => Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Hero(
                                          tag: widget.heroTag,
                                          child: Material(
                                            elevation: 18,
                                            shadowColor: Colors.black54,
                                            color: Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              28,
                                            ),
                                            clipBehavior: Clip.antiAlias,
                                            child: SceneArtwork(
                                              scene: widget.scene,
                                              height: artworkHeight.toDouble(),
                                              playAnimation: !reducedMotion,
                                            ),
                                          ),
                                        ),
                                        for (final hotspot
                                            in widget.scene.hotspots)
                                          Positioned(
                                            left: _hotspotOffset(
                                              hotspot.positionX,
                                              constraints.maxWidth,
                                            ),
                                            top: _hotspotOffset(
                                              hotspot.positionY,
                                              constraints.maxHeight,
                                            ),
                                            child: _HotspotIndicator(
                                              hotspot: hotspot,
                                              selected:
                                                  _selectedHotspot?.id ==
                                                  hotspot.id,
                                              onTap: () =>
                                                  _selectHotspot(hotspot),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              AnimatedSwitcher(
                                duration: reducedMotion
                                    ? Duration.zero
                                    : const Duration(milliseconds: 220),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                transitionBuilder: (child, animation) =>
                                    FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(0, 0.06),
                                          end: Offset.zero,
                                        ).animate(animation),
                                        child: child,
                                      ),
                                    ),
                                child: _selectedHotspot == null
                                    ? const SizedBox.shrink(
                                        key: ValueKey('no-hotspot-selected'),
                                      )
                                    : Padding(
                                        key: ValueKey(_selectedHotspot!.id),
                                        padding: const EdgeInsets.only(top: 14),
                                        child: _buildHotspotCard(
                                          context,
                                          _selectedHotspot!,
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
                              if (widget.scene.description?.isNotEmpty ??
                                  false) ...[
                                const SizedBox(height: 12),
                                Text(
                                  widget.scene.description!,
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
                              if (widget.scene.vocabularyContext?.isNotEmpty ??
                                  false) ...[
                                const SizedBox(height: 16),
                                _SceneNote(
                                  title: 'WORD TO REMEMBER',
                                  icon: Icons.translate_rounded,
                                  color: Colors.amberAccent,
                                  text: widget.scene.vocabularyContext!,
                                ),
                              ],
                              if (widget.scene.educationalNote?.isNotEmpty ??
                                  false) ...[
                                const SizedBox(height: 16),
                                _SceneNote(
                                  title: 'DID YOU KNOW?',
                                  icon: Icons.lightbulb_outline_rounded,
                                  color: Colors.amberAccent,
                                  text: widget.scene.educationalNote!,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_isMayonVolcano && _arSupported)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _openArExplorer,
                              icon: const Icon(Icons.view_in_ar_rounded),
                              label: const Text('Explore in AR'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.72),
                                ),
                                minimumSize: const Size.fromHeight(50),
                              ),
                            ),
                          ),
                        ),
                      if (_isMayonVolcano &&
                          !_checkingArSupport &&
                          !_arSupported)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            'AR not supported on this device.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.white70),
                          ),
                        ),
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
          if (_activeVocabularyHint != null)
            VocabularyCardOverlay(
              key: ValueKey(_activeVocabularyHint!.vocabularyId),
              hint: _activeVocabularyHint!,
              languageCode: widget.languageCode,
              exampleSentence: _activeVocabularyHint!.exampleSentence ?? '',
              onClose: () {
                if (mounted) setState(() => _activeVocabularyHint = null);
              },
            ),
        ],
      ),
    );
  }

  double _hotspotOffset(double coordinate, double extent) {
    final maximum = (extent - 48).clamp(0.0, double.infinity);
    return (coordinate.clamp(0.0, 1.0) * extent - 24)
        .clamp(0.0, maximum)
        .toDouble();
  }

  Widget _buildHotspotCard(BuildContext context, SceneHotspotModel hotspot) {
    final info = hotspot.category == 'character'
        ? CharacterDiscoveryCard(
            hotspot: hotspot,
            storyTitle: widget.storyTitle,
            vocabularyHints: widget.vocabularyHints,
            onVocabularySelected: _showVocabulary,
          )
        : _SceneHotspotInformationCard(
            hotspot: hotspot,
            storyTitle: widget.storyTitle,
            vocabularyHints: widget.vocabularyHints,
            onVocabularySelected: _showVocabulary,
          );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            tooltip: 'Dismiss story information',
            onPressed: () => setState(() => _selectedHotspot = null),
            color: Colors.white,
            icon: const Icon(Icons.close_rounded),
          ),
        ),
        info,
      ],
    );
  }
}

class _HotspotIndicator extends StatelessWidget {
  const _HotspotIndicator({
    required this.hotspot,
    required this.selected,
    required this.onTap,
  });

  final SceneHotspotModel hotspot;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: 'Explore ${hotspot.title}',
      child: Tooltip(
        message: hotspot.title,
        child: AnimatedScale(
          scale: selected ? 1.12 : 1,
          duration: const Duration(milliseconds: 180),
          child: Material(
            color: colors.primaryContainer.withValues(alpha: 0.96),
            shape: const CircleBorder(),
            elevation: 5,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  _iconForCategory(hotspot.category),
                  color: colors.onPrimaryContainer,
                  size: 23,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconForCategory(String? category) => switch (category) {
    'character' => Icons.person_rounded,
    'location' => Icons.landscape_rounded,
    'creature' => Icons.pets_rounded,
    'culture' => Icons.auto_stories_rounded,
    _ => Icons.explore_rounded,
  };
}

class _SceneHotspotInformationCard extends StatelessWidget {
  const _SceneHotspotInformationCard({
    required this.hotspot,
    required this.storyTitle,
    required this.vocabularyHints,
    required this.onVocabularySelected,
  });

  final SceneHotspotModel hotspot;
  final String storyTitle;
  final List<VocabHintModel> vocabularyHints;
  final ValueChanged<VocabHintModel> onVocabularySelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final relatedHints = vocabularyHints
        .where((hint) => hotspot.vocabularyIds.contains(hint.vocabularyId))
        .toList();
    return Card(
      margin: EdgeInsets.zero,
      color: colors.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hotspot.title,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              '$storyTitle · ${hotspot.category ?? 'story element'}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              hotspot.description,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: colors.onSurfaceVariant, height: 1.4),
            ),
            if (hotspot.educationalNote?.isNotEmpty ?? false) ...[
              const SizedBox(height: 10),
              Text(
                'Did you know? ${hotspot.educationalNote}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (relatedHints.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 7,
                children: relatedHints
                    .map(
                      (hint) => ActionChip(
                        label: Text(hint.word),
                        avatar: const Icon(Icons.volume_up_outlined, size: 16),
                        onPressed: () => onVocabularySelected(hint),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SceneNote extends StatelessWidget {
  const _SceneNote({
    required this.title,
    required this.icon,
    required this.color,
    required this.text,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: Colors.white, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    ),
  );
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
      await _player.play(AssetSource(_assetSource(widget.assetPath)));
      if (mounted) setState(() => _isLoading = false);
    } catch (error, stackTrace) {
      _reportAudioError(error, stackTrace, 'scene sound effect');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Scene sound could not be played.')),
        );
      }
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

class _SceneAmbienceButton extends StatefulWidget {
  const _SceneAmbienceButton({required this.assetPath});

  final String assetPath;

  @override
  State<_SceneAmbienceButton> createState() => _SceneAmbienceButtonState();
}

class _SceneAmbienceButtonState extends State<_SceneAmbienceButton> {
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
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource(_assetSource(widget.assetPath)));
      if (mounted) setState(() => _isLoading = false);
    } catch (error, stackTrace) {
      _reportAudioError(error, stackTrace, 'scene ambience');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Scene ambience could not be played.')),
        );
      }
    }
  }

  Future<void> _stopAndDispose() async {
    await _player.stop();
    await _player.dispose();
  }

  @override
  void dispose() {
    unawaited(_stateSubscription?.cancel());
    unawaited(_stopAndDispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: _isPlaying ? 'Stop ambience' : 'Play ambience',
    onPressed: _isLoading ? null : _toggle,
    color: Colors.white,
    icon: _isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(
            _isPlaying
                ? Icons.spatial_audio_off_rounded
                : Icons.spatial_audio_rounded,
          ),
  );
}

String _assetSource(String assetPath) => assetPath.startsWith('assets/')
    ? assetPath.substring('assets/'.length)
    : assetPath;

void _reportAudioError(Object error, StackTrace stackTrace, String library) {
  FlutterError.reportError(
    FlutterErrorDetails(exception: error, stack: stackTrace, library: library),
  );
}
