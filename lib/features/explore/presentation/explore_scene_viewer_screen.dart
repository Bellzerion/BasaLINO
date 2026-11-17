import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ExploreSceneViewerScreen extends StatefulWidget {
  const ExploreSceneViewerScreen({super.key});

  @override
  State<ExploreSceneViewerScreen> createState() =>
      _ExploreSceneViewerScreenState();
}

class _ExploreSceneViewerScreenState extends State<ExploreSceneViewerScreen>
    with WidgetsBindingObserver {
  static const _models = <_ExploreModel>[
    _ExploreModel(
      title: 'Mayon Volcano',
      src: 'assets/models/mount_mayon_animated.gltf',
      alt: 'Animated 3D illustration of Mount Mayon',
      animationName: 'Mayon_Eruption_Loop',
      cameraOrbit: '0deg 75deg 2.5m',
      cameraTarget: '0m 0.5m 0m',
      scale: '0.08 0.08 0.08',
    ),
    _ExploreModel(
      title: 'Daragang Magayon',
      src: 'assets/models/daragang_magayon.gltf',
      alt: '3D scene of Daragang Magayon with falling petals',
      animationName: 'Petals_Drifting_Down',
    ),
    _ExploreModel(
      title: 'Spring Encounter',
      src: 'assets/models/spring_encounter.gltf',
      alt: '3D scene of the spring encounter',
    ),
    _ExploreModel(
      title: 'Village Rally',
      src: 'assets/models/village_rally.gltf',
      alt: '3D scene of a village rally',
    ),
  ];

  static const _hotspots = <_ExploreHotspot>[
    _ExploreHotspot(
      title: 'Volcano Facts',
      description:
          'Mount Mayon is an active volcano in Albay, in the Bicol Region of '
          'the Philippines. Its near-symmetrical cone is one of the country’s '
          'most recognizable landmarks.',
      icon: Icons.landscape_rounded,
    ),
    _ExploreHotspot(
      title: 'Daragang Magayon',
      description:
          'The Bikol legend tells of Daragang Magayon and Panganoron. Their '
          'story is remembered in the mountain’s name and in generations of '
          'storytelling.',
      icon: Icons.auto_stories_rounded,
    ),
    _ExploreHotspot(
      title: 'Cultural Significance',
      description:
          'Stories of Mayon connect local landscape, language, and cultural '
          'memory. The legend is one way communities pass knowledge and '
          'identity between generations.',
      icon: Icons.diversity_3_rounded,
    ),
  ];

  CameraController? _cameraController;
  WebViewController? _modelViewerController;
  _ExploreModel _selectedModel = _models.first;
  bool _cameraLoading = true;
  bool _cameraUnavailable = false;
  bool _cameraStarting = false;
  int _cameraGeneration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initializeCamera());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _stopCamera();
    } else if (state == AppLifecycleState.resumed) {
      unawaited(_initializeCamera());
    }
  }

  Future<void> _initializeCamera() async {
    if (_cameraStarting || !mounted) return;
    _cameraStarting = true;
    final generation = ++_cameraGeneration;
    setState(() {
      _cameraLoading = true;
      _cameraUnavailable = false;
    });

    CameraController? controller;
    try {
      final cameras = await availableCameras();
      if (!mounted || generation != _cameraGeneration) return;
      if (cameras.isEmpty) {
        setState(() {
          _cameraLoading = false;
          _cameraUnavailable = true;
        });
        return;
      }

      final camera = cameras.firstWhere(
        (item) => item.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      controller = CameraController(
        camera,
        ResolutionPreset.low,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted || generation != _cameraGeneration) {
        await controller.dispose();
        return;
      }
      setState(() {
        _cameraController = controller;
        _cameraLoading = false;
        _cameraUnavailable = false;
      });
    } on CameraException catch (error, stackTrace) {
      if (generation == _cameraGeneration && mounted) {
        if (!error.code.startsWith('CameraAccessDenied')) {
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: error,
              stack: stackTrace,
              library: 'camera-based Mayon exploration',
            ),
          );
        }
        setState(() {
          _cameraLoading = false;
          _cameraUnavailable = true;
        });
      }
      if (controller != null) await controller.dispose();
    } catch (error, stackTrace) {
      if (generation == _cameraGeneration && mounted) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'camera-based Mayon exploration',
          ),
        );
        setState(() {
          _cameraLoading = false;
          _cameraUnavailable = true;
        });
      }
      if (controller != null) await controller.dispose();
    } finally {
      if (generation == _cameraGeneration) _cameraStarting = false;
    }
  }

  void _stopCamera() {
    _cameraGeneration++;
    _cameraStarting = false;
    final controller = _cameraController;
    _cameraController = null;
    if (mounted) {
      setState(() {
        _cameraLoading = true;
        _cameraUnavailable = false;
      });
    }
    if (controller != null) unawaited(controller.dispose());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraGeneration++;
    final controller = _cameraController;
    if (controller != null) unawaited(controller.dispose());
    super.dispose();
  }

  Future<void> _resetModelView() async {
    final controller = _modelViewerController;
    if (controller == null) return;
    final model = _selectedModel;
    try {
      await controller.runJavaScript('''
        const viewer = document.querySelector('model-viewer');
        if (viewer) {
          viewer.cameraOrbit = '${model.cameraOrbit ?? 'auto auto auto'}';
          viewer.cameraTarget = '${model.cameraTarget ?? 'auto auto auto'}';
          viewer.jumpCameraToGoal();
        }
      ''');
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: '3D model view reset',
        ),
      );
    }
  }

  void _selectModel(_ExploreModel model) {
    if (model == _selectedModel) return;
    setState(() {
      _selectedModel = model;
      _modelViewerController = null;
    });
  }

  void _showHotspot(_ExploreHotspot hotspot) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(hotspot.icon, color: const Color(0xFF075C31), size: 30),
              const SizedBox(height: 12),
              Text(
                hotspot.title,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Text(
                hotspot.description,
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(height: 1.55),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraBackground() {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return Stack(
        fit: StackFit.expand,
        children: [
          SvgPicture.asset(
            'assets/images/mayon/mountain_formation.svg',
            fit: BoxFit.cover,
          ),
          const ColoredBox(color: Color(0x66031516)),
        ],
      );
    }

    final previewSize = controller.value.previewSize;
    if (previewSize == null) return CameraPreview(controller);
    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final aspectRatio = controller.value.aspectRatio;
          final scale = math
              .max(
                constraints.maxWidth / (constraints.maxHeight * aspectRatio),
                constraints.maxHeight / (constraints.maxWidth / aspectRatio),
              )
              .toDouble();
          return Center(
            child: Transform.scale(
              scale: scale,
              child: AspectRatio(
                aspectRatio: aspectRatio,
                child: CameraPreview(controller),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: const Color(0xFF07150F),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: _buildCameraBackground()),
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xAA03150C),
                      Colors.transparent,
                      Color(0xCC03150C),
                    ],
                    stops: [0, 0.45, 1],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Row(
                    children: [
                      IconButton.filledTonal(
                        tooltip: 'Back to Mayon scene',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedModel.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            shadows: [
                              Shadow(blurRadius: 8, color: Colors.black),
                            ],
                          ),
                        ),
                      ),
                      PopupMenuButton<_ExploreModel>(
                        tooltip: 'Choose model',
                        icon: const Icon(Icons.view_in_ar_rounded),
                        onSelected: _selectModel,
                        itemBuilder: (context) => [
                          for (final model in _models)
                            PopupMenuItem(
                              value: model,
                              child: Row(
                                children: [
                                  Expanded(child: Text(model.title)),
                                  if (model == _selectedModel)
                                    const Icon(Icons.check_rounded, size: 18),
                                ],
                              ),
                            ),
                        ],
                      ),
                      IconButton.filledTonal(
                        tooltip: 'Reset model view',
                        onPressed: _resetModelView,
                        icon: const Icon(Icons.center_focus_weak_rounded),
                      ),
                    ],
                  ),
                ),
                if (_cameraUnavailable)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Material(
                      color: colors.surface.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.photo_camera_outlined),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Camera unavailable. You can still explore '
                                'the model on the illustrated background.',
                              ),
                            ),
                            TextButton(
                              onPressed: _initializeCamera,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else if (_cameraLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: LinearProgressIndicator(
                      color: Color(0xFFFF8D28),
                      backgroundColor: Color(0x55333333),
                    ),
                  ),
                Expanded(
                  child: ModelViewer(
                    key: ValueKey(_selectedModel.src),
                    src: _selectedModel.src,
                    alt: _selectedModel.alt,
                    backgroundColor: Colors.transparent,
                    ar: false,
                    autoRotate: false,
                    autoPlay: _selectedModel.animationName != null,
                    animationName: _selectedModel.animationName,
                    cameraControls: true,
                    disablePan: true,
                    disableZoom: false,
                    touchAction: TouchAction.none,
                    cameraOrbit: _selectedModel.cameraOrbit ?? 'auto auto auto',
                    cameraTarget:
                        _selectedModel.cameraTarget ?? 'auto auto auto',
                    scale: _selectedModel.scale ?? '1 1 1',
                    shadowIntensity: 0.8,
                    interactionPrompt: InteractionPrompt.none,
                    debugLogging: false,
                    onWebViewCreated: (controller) {
                      _modelViewerController = controller;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: Text(
                    'Drag to rotate · Pinch to zoom',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      shadows: const [
                        Shadow(blurRadius: 8, color: Colors.black),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final hotspot in _hotspots)
                        ActionChip(
                          avatar: Icon(hotspot.icon, size: 18),
                          label: Text(hotspot.title),
                          backgroundColor: colors.surface.withValues(
                            alpha: 0.95,
                          ),
                          onPressed: () => _showHotspot(hotspot),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExploreModel {
  const _ExploreModel({
    required this.title,
    required this.src,
    required this.alt,
    this.animationName,
    this.cameraOrbit,
    this.cameraTarget,
    this.scale,
  });

  final String title;
  final String src;
  final String alt;
  final String? animationName;
  final String? cameraOrbit;
  final String? cameraTarget;
  final String? scale;
}

class _ExploreHotspot {
  const _ExploreHotspot({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;
}
