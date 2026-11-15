import 'package:flutter/material.dart';

class ArInstructionOverlay extends StatelessWidget {
  const ArInstructionOverlay({super.key, required this.placed, this.message});

  final bool placed;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final instruction =
        message ??
        (placed
            ? 'Mount Mayon is placed. Tap it to explore.'
            : 'Move your phone slowly to find a flat surface, then tap it.');

    return IgnorePointer(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              message == null
                  ? Icons.info_outline_rounded
                  : Icons.warning_amber_rounded,
              color: message == null ? colors.primary : colors.error,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                instruction,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
