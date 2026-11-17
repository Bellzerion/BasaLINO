import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/scene_annotation_model.dart';
import '../../../core/models/scene_hotspot_model.dart';
import '../../../core/models/vocab_hint_model.dart';
import '../../../core/services/story_discovery_tracker.dart';
import '../widgets/character_discovery_card.dart';
import '../widgets/vocabulary_card.dart';

class StoryCodexScreen extends StatefulWidget {
  const StoryCodexScreen({
    super.key,
    required this.storyId,
    required this.languageCode,
    required this.discoveryTracker,
  });

  final String storyId;
  final String languageCode;
  final StoryDiscoveryTracker discoveryTracker;

  @override
  State<StoryCodexScreen> createState() => _StoryCodexScreenState();
}

class _StoryCodexScreenState extends State<StoryCodexScreen> {
  late Future<_CodexSnapshot> _snapshotFuture;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? _selectedCategory;
  VocabHintModel? _activeVocabularyHint;

  String get _storyTitle => switch (widget.storyId) {
    'mayon' => 'The Legend of Mount Mayon',
    'ibalong' => 'The Heroes of Ibalong',
    _ => 'Story Discovery',
  };

  @override
  void initState() {
    super.initState();
    _snapshotFuture = _loadSnapshot();
  }

  @override
  void didUpdateWidget(covariant StoryCodexScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.storyId != widget.storyId ||
        oldWidget.languageCode != widget.languageCode) {
      _snapshotFuture = _loadSnapshot();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<_CodexSnapshot> _loadSnapshot() async {
    final source = await rootBundle.loadString('assets/data/chapters.json');
    final chapters = jsonDecode(source) as List<dynamic>;
    final entries = <String, SceneHotspotModel>{};
    final vocabularyById = <String, VocabHintModel>{};

    for (final rawChapter in chapters.cast<Map<String, dynamic>>()) {
      if (rawChapter['storyId'] != widget.storyId) continue;

      final translations =
          rawChapter['translations'] as Map<String, dynamic>? ?? const {};
      final translation =
          translations[widget.languageCode] as Map<String, dynamic>? ??
          translations['en'] as Map<String, dynamic>? ??
          const <String, dynamic>{};
      for (final rawHint
          in (translation['vocabularyHints'] as List? ?? const [])) {
        final hint = VocabHintModel.fromMap(rawHint as Map<String, dynamic>);
        vocabularyById.putIfAbsent(hint.vocabularyId, () => hint);
      }

      for (final rawScene in (rawChapter['scenes'] as List? ?? const [])) {
        final scene = SceneAnnotationModel.fromMap(
          rawScene as Map<String, dynamic>,
        );
        for (final hotspot in scene.hotspots) {
          if (hotspot.id.isNotEmpty) {
            entries.putIfAbsent(hotspot.id, () => hotspot);
          }
        }
      }
    }

    final discoveredIds = await widget.discoveryTracker.getDiscoveredIds();
    final sortedEntries = entries.values.toList()
      ..sort((first, second) => first.title.compareTo(second.title));
    return _CodexSnapshot(
      entries: sortedEntries,
      vocabularyById: vocabularyById,
      discoveredIds: discoveredIds,
    );
  }

  void _showVocabulary(VocabHintModel hint) {
    setState(() => _activeVocabularyHint = hint);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Story Codex'),
        actions: [
          if (widget.storyId == 'mayon')
            IconButton(
              tooltip: 'Explore in AR-Style',
              onPressed: () => context.push('/explore/mayon'),
              icon: const Icon(Icons.threed_rotation_rounded),
            ),
          IconButton(
            tooltip: 'Clear search',
            onPressed: _query.isEmpty
                ? null
                : () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
            icon: const Icon(Icons.search_off_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          FutureBuilder<_CodexSnapshot>(
            future: _snapshotFuture,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Story discoveries could not be loaded.'),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final codex = snapshot.data!;
              final categories =
                  codex.entries
                      .map((entry) => entry.category ?? 'culture')
                      .toSet()
                      .toList()
                    ..sort();
              final filtered = codex.entries.where((entry) {
                final matchesCategory =
                    _selectedCategory == null ||
                    entry.category == _selectedCategory;
                final matchesQuery =
                    _query.isEmpty ||
                    entry.title.toLowerCase().contains(_query.toLowerCase()) ||
                    entry.description.toLowerCase().contains(
                      _query.toLowerCase(),
                    );
                return matchesCategory && matchesQuery;
              }).toList();

              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _storyTitle,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${codex.discoveredIds.where((id) => id.startsWith('${widget.storyId}/')).length} discoveries found',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: colors.onSurfaceVariant),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _searchController,
                            onChanged: (value) =>
                                setState(() => _query = value),
                            decoration: InputDecoration(
                              hintText:
                                  'Search characters, places, creatures...',
                              prefixIcon: const Icon(Icons.search_rounded),
                              filled: true,
                              fillColor: colors.surfaceContainerHighest,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            children: [
                              ChoiceChip(
                                label: const Text('All'),
                                selected: _selectedCategory == null,
                                onSelected: (_) =>
                                    setState(() => _selectedCategory = null),
                              ),
                              for (final category in categories)
                                ChoiceChip(
                                  label: Text(_categoryLabel(category)),
                                  selected: _selectedCategory == category,
                                  onSelected: (_) => setState(
                                    () => _selectedCategory = category,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (filtered.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text('No story elements found.')),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      sliver: SliverList.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final entry = filtered[index];
                          final discovered = codex.discoveredIds.contains(
                            '${widget.storyId}/${entry.id}',
                          );
                          final hints = entry.vocabularyIds
                              .map((id) => codex.vocabularyById[id])
                              .whereType<VocabHintModel>()
                              .toList();
                          if (!discovered) {
                            return _LockedCodexCard(
                              entry: entry,
                              storyTitle: _storyTitle,
                            );
                          }
                          if (entry.category == 'character') {
                            return CharacterDiscoveryCard(
                              hotspot: entry,
                              storyTitle: _storyTitle,
                              vocabularyHints: hints,
                              onVocabularySelected: _showVocabulary,
                            );
                          }
                          return _CodexTopicCard(
                            entry: entry,
                            storyTitle: _storyTitle,
                            vocabularyHints: hints,
                            onVocabularySelected: _showVocabulary,
                          );
                        },
                      ),
                    ),
                ],
              );
            },
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

  String _categoryLabel(String category) => switch (category) {
    'character' => 'Characters',
    'location' => 'Locations',
    'creature' => 'Creatures',
    'culture' => 'Culture',
    _ => category[0].toUpperCase() + category.substring(1),
  };
}

class _CodexSnapshot {
  const _CodexSnapshot({
    required this.entries,
    required this.vocabularyById,
    required this.discoveredIds,
  });

  final List<SceneHotspotModel> entries;
  final Map<String, VocabHintModel> vocabularyById;
  final Set<String> discoveredIds;
}

class _LockedCodexCard extends StatelessWidget {
  const _LockedCodexCard({required this.entry, required this.storyTitle});

  final SceneHotspotModel entry;
  final String storyTitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 112,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (entry.imageAsset != null)
                  Opacity(
                    opacity: 0.2,
                    child: _CodexArtwork(path: entry.imageAsset!),
                  )
                else
                  ColoredBox(color: colors.surfaceContainerHighest),
                Center(
                  child: Icon(
                    Icons.lock_outline_rounded,
                    size: 32,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            title: Text(entry.title),
            subtitle: Text('Discover in $_storyTitle to unlock'),
            trailing: const Icon(Icons.auto_awesome_outlined),
          ),
        ],
      ),
    );
  }

  String get _storyTitle =>
      storyTitle == 'The Legend of Mount Mayon' ? 'Mayon' : 'Ibalong';
}

class _CodexTopicCard extends StatelessWidget {
  const _CodexTopicCard({
    required this.entry,
    required this.storyTitle,
    required this.vocabularyHints,
    required this.onVocabularySelected,
  });

  final SceneHotspotModel entry;
  final String storyTitle;
  final List<VocabHintModel> vocabularyHints;
  final ValueChanged<VocabHintModel> onVocabularySelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (entry.imageAsset != null)
            SizedBox(
              height: 132,
              child: _CodexArtwork(path: entry.imageAsset!),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  '${entry.category ?? 'Story'} · $storyTitle',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(entry.description),
                if (entry.educationalNote?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Did you know? ${entry.educationalNote}',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
                if (vocabularyHints.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: vocabularyHints
                        .map(
                          (hint) => ActionChip(
                            label: Text(hint.word),
                            avatar: const Icon(
                              Icons.volume_up_outlined,
                              size: 16,
                            ),
                            onPressed: () => onVocabularySelected(hint),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CodexArtwork extends StatelessWidget {
  const _CodexArtwork({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    if (path.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const ColoredBox(color: Color(0xFFE7E5E4)),
      );
    }
    return Image.asset(
      path,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          const ColoredBox(color: Color(0xFFE7E5E4)),
    );
  }
}
