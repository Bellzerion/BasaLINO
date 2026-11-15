import 'dart:async';

import 'package:ar_flutter_plugin_plus/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_plus/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin_plus/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_plus/models/ar_anchor.dart';
import 'package:ar_flutter_plugin_plus/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin_plus/models/ar_node.dart';
import 'package:ar_flutter_plugin_plus/widgets/ar_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

import '../../../core/services/story_discovery_tracker.dart';
import '../models/ar_content_model.dart';
import '../services/ar_service.dart';
import '../widgets/ar_instruction_overlay.dart';
import '../widgets/ar_placement_indicator.dart';

class ArExplorerScreen extends StatefulWidget {
  const ArExplorerScreen({
    super.key,
    required this.content,
    required this.discoveryTracker,
    this.availabilityService = const PlatformArService(),
    this.onReturnToReader,
  });

  final ArContentModel content;
  final StoryDiscoveryTracker discoveryTracker;
  final ArAvailabilityService availabilityService;
  final VoidCallback? onReturnToReader;

  @override
  State<ArExplorerScreen> createState() => _ArExplorerScreenState();
}

class _ArExplorerScreenState extends State<ArExplorerScreen> {
  ARSessionManager? _sessionManager;
  ARAnchorManager? _anchorManager;
  ARObjectManager? _objectManager;
  bool _checkingSupport = true;
  bool _supported = false;
  bool _placing = false;
  bool _placed = false;
  bool _showInformation = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    unawaited(_checkSupport());
  }

  Future<void> _checkSupport() async {
    try {
      final supported = await widget.availabilityService.isSupported();
      if (!mounted) return;
      setState(() {
        _supported = supported;
        _checkingSupport = false;
      });
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'AR explorer support check',
        ),
      );
      if (mounted) {
        setState(() {
          _supported = false;
          _checkingSupport = false;
          _errorMessage = 'AR could not be started on this device.';
        });
      }
    }
  }

  @override
  void dispose() {
    final sessionManager = _sessionManager;
    if (sessionManager != null) unawaited(sessionManager.dispose());
    super.dispose();
  }

  void _onArViewCreated(
    ARSessionManager sessionManager,
    ARObjectManager objectManager,
    ARAnchorManager anchorManager,
    ARLocationManager locationManager,
  ) {
    _sessionManager = sessionManager;
    _objectManager = objectManager;
    _anchorManager = anchorManager;
    sessionManager.onPlaneOrPointTap = _placeOnSurface;
    objectManager.onNodeTap = (_) {
      if (mounted && _placed) setState(() => _showInformation = true);
    };
    unawaited(_initializeManagers(sessionManager, objectManager));
  }

  Future<void> _initializeManagers(
    ARSessionManager sessionManager,
    ARObjectManager objectManager,
  ) async {
    try {
      await sessionManager.onInitialize(
        showFeaturePoints: false,
        showPlanes: true,
        showWorldOrigin: false,
        handleTaps: true,
      );
      await objectManager.onInitialize();
    } catch (error, stackTrace) {
      _reportArError(error, stackTrace, 'AR session initialization');
    }
  }

  Future<void> _placeOnSurface(List<ARHitTestResult> hits) async {
    if (_placing || _placed || !mounted) return;
    final planeHits = hits
        .where((hit) => hit.type == ARHitTestResultType.plane)
        .toList();
    if (planeHits.isEmpty) {
      setState(
        () => _errorMessage =
            'No surface found. Move the phone slowly and try again.',
      );
      return;
    }

    final anchorManager = _anchorManager;
    final objectManager = _objectManager;
    if (anchorManager == null || objectManager == null) return;

    setState(() {
      _placing = true;
      _errorMessage = null;
    });

    final anchor = ARPlaneAnchor(
      transformation: planeHits.first.worldTransform,
    );
    var anchorAdded = false;
    try {
      anchorAdded = await anchorManager.addAnchor(anchor) == true;
      if (anchorAdded != true) {
        throw StateError(
          'The Mount Mayon surface anchor could not be created.',
        );
      }

      final node = ARNode(
        name: 'mayon-ar-billboard',
        type: NodeType.localGLTF2,
        uri: 'assets/models/mayon_billboard.gltf',
        scale: Vector3(0.65, 0.65, 0.65),
      );
      final nodeAdded = await objectManager.addNode(node, planeAnchor: anchor);
      if (nodeAdded != true) {
        throw StateError('The Mount Mayon illustration could not be placed.');
      }

      if (!mounted) return;
      setState(() {
        _placing = false;
        _placed = true;
      });
      await _recordDiscovery();
    } catch (error, stackTrace) {
      if (anchorAdded) anchorManager.removeAnchor(anchor);
      _reportArError(error, stackTrace, 'AR placement');
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  Future<void> _recordDiscovery() async {
    try {
      await widget.discoveryTracker.markDiscovered(widget.content.id);
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'AR local discovery tracking',
        ),
      );
      if (mounted) {
        setState(
          () => _errorMessage =
              'Mayon is placed, but discovery could not be saved.',
        );
      }
    }
  }

  void _reportArError(Object error, StackTrace stackTrace, String library) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: library,
      ),
    );
    if (mounted) {
      setState(() {
        _placing = false;
        _errorMessage = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingSupport) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_supported) return _buildUnsupported(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          ARView(
            planeDetectionConfig: PlaneDetectionConfig.horizontal,
            onARViewCreated: _onArViewCreated,
          ),
          if (!_placed) const ArPlacementIndicator(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton.filledTonal(
                      tooltip: 'Return to scene viewer',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Explore Mount Mayon',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          shadows: const [
                            Shadow(color: Colors.black54, blurRadius: 8),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                ArInstructionOverlay(placed: _placed, message: _errorMessage),
                const Spacer(),
                if (_showInformation) _buildInformationCard(context),
                if (_placing)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnsupported(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.view_in_ar_outlined,
                  size: 64,
                  color: colors.primary,
                ),
                const SizedBox(height: 18),
                Text(
                  'AR not supported on this device.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(_errorMessage!, textAlign: TextAlign.center),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed:
                      widget.onReturnToReader ??
                      () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.menu_book_rounded),
                  label: const Text('Return to Reader'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInformationCard(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Card(
        color: colors.surface.withValues(alpha: 0.96),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(width: 92, height: 100, child: _buildArtwork()),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.content.title,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close Mount Mayon information',
                          onPressed: () =>
                              setState(() => _showInformation = false),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    Text(
                      widget.content.description,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(height: 1.4),
                    ),
                    if (widget.content.educationalNote?.isNotEmpty ??
                        false) ...[
                      const SizedBox(height: 10),
                      Text(
                        widget.content.educationalNote!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArtwork() {
    if (widget.content.imageAsset.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(widget.content.imageAsset, fit: BoxFit.cover);
    }
    return Image.asset(widget.content.imageAsset, fit: BoxFit.cover);
  }
}
