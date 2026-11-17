import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ExploreSceneScreen extends StatelessWidget {
  const ExploreSceneScreen({super.key});

  static const _forest = Color(0xFF075C31);
  static const _orange = Color(0xFFFF8D28);
  static const _description =
      'Discover Mount Mayon, an active volcano in Albay, and the Bikol legend '
      'of Daragang Magayon.';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explore in AR-Style')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: AspectRatio(
                aspectRatio: 1.15,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    SvgPicture.asset(
                      'assets/images/mayon/mountain_formation.svg',
                      fit: BoxFit.cover,
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xCC032516)],
                        ),
                      ),
                    ),
                    const Positioned(
                      left: 20,
                      right: 20,
                      bottom: 20,
                      child: Text(
                        'Mayon Volcano',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _description,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 14),
            const _FeatureNote(
              icon: Icons.threed_rotation_rounded,
              text: 'Rotate and zoom the animated volcano model.',
            ),
            const SizedBox(height: 8),
            const _FeatureNote(
              icon: Icons.camera_alt_outlined,
              text: 'Use your camera, or explore over the illustrated scene.',
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push('/explore/mayon/viewer'),
              icon: const Icon(Icons.explore_rounded),
              label: const Text('Explore in AR-Style'),
              style: FilledButton.styleFrom(
                backgroundColor: _forest,
                minimumSize: const Size.fromHeight(54),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Camera preview stays on your device. BasaLINO does not capture '
              'or save photos or video in this experience.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'A story companion, not a replacement for reading.',
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: _orange, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureNote extends StatelessWidget {
  const _FeatureNote({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF075C31)),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    );
  }
}
