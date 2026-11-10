import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/bootstrap/cloud_data_provider.dart';
import '../../../app/bootstrap/providers.dart';
import '../../../core/config/auth_mode.dart';
import '../../../l10n/app_localizations_context.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final currentLang = ref.watch(appLanguageProvider);
    final cloudDataAsync = ref.watch(cloudDataProvider);
    final cloudReadsEnabled = ref.watch(dataModeProvider) == DataMode.cloud;
    final cloudData = cloudDataAsync.asData?.value;
    final cloudProfile = cloudData?.profile;
    final displayName = cloudProfile?.nickname.isNotEmpty == true
        ? cloudProfile!.nickname
        : user?.nickname ?? context.l10n.profileLearner;
    final email = cloudProfile?.email.isNotEmpty == true
        ? cloudProfile!.email
        : user?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.profileTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (cloudReadsEnabled && cloudDataAsync.isLoading)
              const _CloudStatusBanner(
                message:
                    'Loading your cloud profile. Local data remains available.',
              )
            else if (cloudReadsEnabled && cloudData?.message != null)
              _CloudStatusBanner(message: cloudData!.message!),
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: const Color(0xFFFEF3C7),
                    child: Text(
                      (user?.nickname.isNotEmpty == true
                              ? user!.nickname[0]
                              : 'B')
                          .toUpperCase(),
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
              displayName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            Text(
              email,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
            ),
            const SizedBox(height: 32),
            Text(
              context.l10n.profileLanguagePreference,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            _LanguageTile(
              label: context.l10n.profileLanguageEn,
              sublabel: context.l10n.profileEnglishDescription,
              code: 'en',
              selected: currentLang == 'en',
              onSelect: () {
                ref.read(appLanguageProvider.notifier).state = 'en';
              },
            ),
            _LanguageTile(
              label: context.l10n.profileLanguageTl,
              sublabel: context.l10n.profileTagalogDescription,
              code: 'tl',
              selected: currentLang == 'tl',
              onSelect: () {
                ref.read(appLanguageProvider.notifier).state = 'tl';
              },
            ),
            _LanguageTile(
              label: context.l10n.profileBikolCentral,
              sublabel: context.l10n.profileBikolDescription,
              code: 'bik',
              selected: currentLang == 'bik',
              onSelect: () {
                ref.read(appLanguageProvider.notifier).state = 'bik';
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
              label: Text(
                context.l10n.authSignOut,
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

class _CloudStatusBanner extends StatelessWidget {
  const _CloudStatusBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(message, style: const TextStyle(color: Color(0xFF9A3412))),
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
