// THIS IS RESPONSIBLE FOR OVERALL BACKGROUND THEME

import 'package:flutter/material.dart';

/// Shared illustrated canvas used behind every BasaLINO screen.  The shapes are
/// deliberately subtle so reading content keeps a strong contrast.
class BrandBackground extends StatelessWidget {
  const BrandBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF7F3E9), Color(0xFFD3EAE2), Color(0xFFB8DDD1)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const _DecorativeShapes(),
          child,
        ],
      ),
    );
  }
}

class _DecorativeShapes extends StatelessWidget {
  const _DecorativeShapes();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -70,
            child: _blob(const Color(0x665AAB8C), 230),
          ),
          Positioned(
            top: 170,
            left: -105,
            child: _blob(const Color(0x4461B899), 220),
          ),
          Positioned(
            bottom: -95,
            right: -55,
            child: _blob(const Color(0x5570BFA5), 250),
          ),
          Positioned(
            top: 120,
            right: 26,
            child: Transform.rotate(
              angle: -.45,
              child: const Icon(Icons.auto_stories_rounded,
                  size: 90, color: Color(0x2371A994)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob(Color color, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}
