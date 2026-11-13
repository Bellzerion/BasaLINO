import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/models/scene_annotation_model.dart';
import 'scene_viewer_screen.dart';

class ChapterSceneWidget extends StatefulWidget {
  const ChapterSceneWidget({
    super.key,
    required this.scene,
    required this.storyTitle,
    required this.heroTag,
    this.showExplorePrompt = false,
    this.onExplorePromptShown,
    this.storybookMode = false,
  });

  final SceneAnnotationModel scene;
  final String storyTitle;
  final String heroTag;
  final bool showExplorePrompt;
  final VoidCallback? onExplorePromptShown;
  final bool storybookMode;

  @override
  State<ChapterSceneWidget> createState() => _ChapterSceneWidgetState();
}

class _ChapterSceneWidgetState extends State<ChapterSceneWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  Timer? _promptTimer;
  bool _entranceStarted = false;
  bool _promptVisible = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    if (widget.showExplorePrompt) {
      _promptVisible = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onExplorePromptShown?.call();
        _promptTimer = Timer(const Duration(seconds: 5), () {
          if (mounted) setState(() => _promptVisible = false);
        });
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entranceStarted) return;
    _entranceStarted = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _fadeController.value = 1;
    } else {
      _fadeController.forward();
    }
  }

  @override
  void dispose() {
    _promptTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  void _openScene() {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black87,
        barrierDismissible: false,
        transitionDuration: reducedMotion
            ? Duration.zero
            : const Duration(milliseconds: 420),
        reverseTransitionDuration: reducedMotion
            ? Duration.zero
            : const Duration(milliseconds: 260),
        pageBuilder: (context, animation, secondaryAnimation) =>
            SceneViewerScreen(
              scene: widget.scene,
              storyTitle: widget.storyTitle,
              heroTag: widget.heroTag,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final title = widget.scene.title ?? widget.scene.label;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);

    return FadeTransition(
      opacity: _fadeController,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Material(
          color: theme.cardTheme.color ?? colors.surfaceContainerLow,
          elevation: 2,
          shadowColor: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _openScene,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  children: [
                    Hero(
                      tag: widget.heroTag,
                      child: SceneArtwork(
                        scene: widget.scene,
                        height: widget.storybookMode ? 280 : 190,
                        playAnimation: false,
                      ),
                    ),
                    if (widget.showExplorePrompt)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: AnimatedOpacity(
                          opacity: _promptVisible ? 1 : 0,
                          duration: reducedMotion
                              ? Duration.zero
                              : const Duration(milliseconds: 350),
                          child: IgnorePointer(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: colors.surface.withValues(alpha: 0.94),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.touch_app_outlined,
                                    size: 15,
                                    color: colors.primary,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Explore scene',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: colors.primary,
                                          fontWeight: FontWeight.w700,
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
                if (title != null && title.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 16,
                          color: colors.secondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: colors.onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        Icon(
                          Icons.open_in_full_rounded,
                          size: 16,
                          color: colors.onSurfaceVariant,
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
}

class SceneArtwork extends StatelessWidget {
  const SceneArtwork({
    super.key,
    required this.scene,
    required this.height,
    this.playAnimation = false,
    this.fit = BoxFit.cover,
  });

  final SceneAnnotationModel scene;
  final double height;
  final bool playAnimation;
  final BoxFit fit;

  Widget _illustration(BuildContext context, String path) {
    if (path.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(
        path,
        height: height,
        width: double.infinity,
        fit: fit,
        placeholderBuilder: (context) => const _ScenePlaceholder(),
      );
    }
    return Image.asset(
      path,
      height: height,
      width: double.infinity,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => const _ScenePlaceholder(),
    );
  }

  Widget _animation(BuildContext context) {
    if (scene.assetKey.isEmpty) return const SizedBox.shrink();
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return Lottie.asset(
      scene.assetKey,
      fit: BoxFit.contain,
      repeat: false,
      animate: playAnimation && !reducedMotion,
      frameRate: FrameRate(30),
      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
    );
  }

  Widget _fallback(BuildContext context) {
    if (scene.assetKey.isNotEmpty && playAnimation) {
      return _animation(context);
    }
    final imagePath = scene.imageAssetKey;
    if (imagePath?.isNotEmpty ?? false) {
      return _illustration(context, imagePath!);
    }
    return const _ScenePlaceholder();
  }

  @override
  Widget build(BuildContext context) {
    final hasIllustration = scene.imageAssetKey?.isNotEmpty ?? false;
    final hasGif = scene.gifAsset?.isNotEmpty ?? false;
    final hasAnimation = scene.assetKey.isNotEmpty;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);

    if (reducedMotion) {
      if (hasIllustration) return _illustration(context, scene.imageAssetKey!);
      if (hasAnimation) {
        return SizedBox(
          height: height,
          width: double.infinity,
          child: Center(
            child: SizedBox(
              width: height * 1.5,
              height: height,
              child: _animation(context),
            ),
          ),
        );
      }
      return const _ScenePlaceholder();
    }

    if (hasGif) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: Image.asset(
                scene.gifAsset!,
                width: double.infinity,
                height: height,
                fit: fit,
                errorBuilder: (context, error, stackTrace) =>
                    _fallback(context),
              ),
            ),
            if (playAnimation && hasAnimation)
              Positioned.fill(
                child: Opacity(opacity: 0.4, child: _animation(context)),
              ),
          ],
        ),
      );
    }

    final background = Container(
      height: height,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryContainer, AppTheme.secondaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: hasIllustration
          ? _illustration(context, scene.imageAssetKey!)
          : hasAnimation
          ? Center(
              child: SizedBox(
                width: height * 1.5,
                height: height,
                child: _animation(context),
              ),
            )
          : const _ScenePlaceholder(),
    );

    if (!hasIllustration || !hasAnimation) {
      if (hasIllustration && playAnimation) {
        return Stack(
          children: [
            background,
            Positioned.fill(
              child: SceneMotionOverlay(sceneType: scene.sceneType ?? ''),
            ),
          ],
        );
      }
      return background;
    }
    if (!playAnimation) return background;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(child: background),
          Positioned.fill(
            child: SceneMotionOverlay(sceneType: scene.sceneType ?? ''),
          ),
          Positioned(
            top: 0,
            right: 0,
            width: height * 0.75,
            height: height * 0.75,
            child: Opacity(opacity: 0.45, child: _animation(context)),
          ),
        ],
      ),
    );
  }
}

class SceneMotionOverlay extends StatefulWidget {
  const SceneMotionOverlay({super.key, required this.sceneType});

  final String sceneType;

  @override
  State<SceneMotionOverlay> createState() => _SceneMotionOverlayState();
}

class _SceneMotionOverlayState extends State<SceneMotionOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return const SizedBox.expand();
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => CustomPaint(
        painter: _SceneMotionPainter(widget.sceneType, _controller.value),
      ),
    );
  }
}

class _SceneMotionPainter extends CustomPainter {
  const _SceneMotionPainter(this.sceneType, this.progress);

  final String sceneType;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final type = sceneType.toLowerCase();
    if (type.contains('volcano')) {
      _paintEmbers(canvas, size);
    } else if (type.contains('water') || type.contains('meeting')) {
      _paintWater(canvas, size);
    } else if (type.contains('celebration') || type.contains('victory')) {
      _paintConfetti(canvas, size);
    } else if (type.contains('monster') || type.contains('conflict')) {
      _paintGlowingEyes(canvas, size);
    } else if (type.contains('landmark') || type.contains('nature')) {
      _paintClouds(canvas, size);
    } else {
      _paintLeaves(canvas, size);
    }
  }

  void _paintEmbers(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFB15C).withValues(alpha: 0.62);
    for (var i = 0; i < 7; i++) {
      final phase = (progress + i * 0.17) % 1;
      final x = size.width * (0.28 + (i % 5) * 0.11);
      final y = size.height * (0.68 - phase * 0.35);
      canvas.drawCircle(Offset(x, y), 2 + (i % 3), paint);
    }
  }

  void _paintWater(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var i = 0; i < 4; i++) {
      final y = size.height * (0.63 + i * 0.065);
      final drift = (progress - 0.5) * size.width * 0.12;
      final path = Path()
        ..moveTo(size.width * 0.18 + drift, y)
        ..quadraticBezierTo(
          size.width * 0.31 + drift,
          y - 5,
          size.width * 0.44 + drift,
          y,
        )
        ..quadraticBezierTo(
          size.width * 0.58 + drift,
          y + 5,
          size.width * 0.72 + drift,
          y,
        );
      canvas.drawPath(path, paint);
    }
  }

  void _paintConfetti(Canvas canvas, Size size) {
    final colors = [
      const Color(0xFFFFD166),
      const Color(0xFFFA8B62),
      const Color(0xFFB8E0C8),
      const Color(0xFFF7E4B5),
    ];
    for (var i = 0; i < 10; i++) {
      final phase = (progress + i * 0.13) % 1;
      final x = size.width * ((i * 0.137 + 0.08) % 0.86);
      final y = size.height * (phase * 0.72);
      final paint = Paint()..color = colors[i % colors.length];
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y), width: 5, height: 10),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  void _paintGlowingEyes(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFD276)
          .withValues(alpha: 0.35 + progress * 0.35);
    final center = Offset(size.width * 0.5, size.height * 0.47);
    canvas.drawCircle(center.translate(-13, 0), 3.5, paint);
    canvas.drawCircle(center.translate(13, 0), 3.5, paint);
  }

  void _paintClouds(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.28);
    for (var i = 0; i < 3; i++) {
      final x = size.width * (0.12 + i * 0.34 + progress * 0.12);
      final y = size.height * (0.14 + (i % 2) * 0.08);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x % size.width, y),
          width: size.width * 0.12,
          height: size.height * 0.045,
        ),
        paint,
      );
    }
  }

  void _paintLeaves(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD8EAC6).withValues(alpha: 0.4);
    for (var i = 0; i < 4; i++) {
      final x = size.width * (0.18 + i * 0.19);
      final y = size.height * (0.34 + ((progress + i * 0.21) % 1) * 0.28);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate((progress - 0.5) * 0.7);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 8, height: 15),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _SceneMotionPainter oldDelegate) =>
      sceneType != oldDelegate.sceneType || progress != oldDelegate.progress;
}

class _ScenePlaceholder extends StatelessWidget {
  const _ScenePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryContainer, AppTheme.secondaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.auto_awesome_mosaic_outlined,
          size: 42,
          color: AppTheme.secondaryColor,
        ),
      ),
    );
  }
}
