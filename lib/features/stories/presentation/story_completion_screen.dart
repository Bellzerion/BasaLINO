import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations_context.dart';

class StoryCompletionScreen extends StatelessWidget {
  const StoryCompletionScreen({super.key, required this.storyId});

  final String storyId;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                size: 96,
                color: Color(0xFFD97706),
              ),
              const SizedBox(height: 20),
              Text(
                context.l10n.storyCompletionTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF164D36),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                context.l10n.storyCompletionMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/library'),
                  child: Text(context.l10n.continueAdventure),
                ),
              ),
              TextButton(
                onPressed: () => context.go('/story/$storyId'),
                child: Text(context.l10n.chapterListReturn),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
