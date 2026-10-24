import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/bootstrap/providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final currentLang = ref.watch(appLanguageProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: const Color(0xFFFEF3C7),
                    child: Text(
                      (user?.nickname.isNotEmpty == true ? user!.nickname[0] : 'B').toUpperCase(),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user?.nickname ?? 'Learner',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            Text(
              user?.email ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
            ),
            const SizedBox(height: 32),
            const Text(
              'Preferred Reading Language',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            _LanguageTile(
              label: 'English',
              sublabel: 'Default content & quizzes',
              code: 'en',
              selected: currentLang == 'en',
              onSelect: () {
                ref.read(appLanguageProvider.notifier).state = 'en';
                ref.read(authRepositoryProvider).updateLanguage('en');
              },
            ),
            _LanguageTile(
              label: 'Tagalog',
              sublabel: 'Wikang Pambansa',
              code: 'tl',
              selected: currentLang == 'tl',
              onSelect: () {
                ref.read(appLanguageProvider.notifier).state = 'tl';
                ref.read(authRepositoryProvider).updateLanguage('tl');
              },
            ),
            _LanguageTile(
              label: 'Bikol (Central)',
              sublabel: 'Bikol Sentral Translation',
              code: 'bik',
              selected: currentLang == 'bik',
              onSelect: () {
                ref.read(appLanguageProvider.notifier).state = 'bik';
                ref.read(authRepositoryProvider).updateLanguage('bik');
              },
            ),
            const SizedBox(height: 36),
            OutlinedButton.icon(
              onPressed: () async {
                await ref.read(authRepositoryProvider).signOut();
                if (context.mounted) {
                  context.go('/login');
                }
              },
              icon: const Icon(Icons.logout, color: Color(0xFFEF4444)),
              label: const Text(
                'Sign Out',
                style: TextStyle(color: Color(0xFFEF4444)),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFEF4444)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.label,
    required this.sublabel,
    required this.code,
    required this.selected,
    required this.onSelect,
  });

  final String label;
  final String sublabel;
  final String code;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? const Color(0xFFD97706) : const Color(0xFFE5E7EB),
          width: selected ? 2 : 1,
        ),
      ),
      child: ListTile(
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(sublabel),
        trailing: selected
            ? const Icon(Icons.check_circle, color: Color(0xFFD97706))
            : null,
        onTap: onSelect,
      ),
    );
  }
}
