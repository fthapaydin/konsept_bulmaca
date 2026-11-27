import 'package:material_ui/material_ui.dart';
import '../core/theme/app_theme.dart';
import '../features/notebook/word_notebook_screen.dart';
import '../models/puzzle_models.dart';
import '../state/app_state.dart';
import '../utils/turkish_text.dart';
import '../widgets/background_canvas.dart';
import 'background_gallery_screen.dart';
import 'game_screen.dart';

class PackLevelsScreen extends StatelessWidget {
  const PackLevelsScreen({
    super.key,
    required this.pack,
    required this.appState,
  });

  final ConceptPack pack;
  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final completed = appState.completedCountForPack(pack);
        final earnedStars = appState.starsForPack(pack);
        final maxStars = appState.maxStarsForPack(pack);

        int? nextPlayableIdx;
        for (var i = 0; i < pack.levels.length; i++) {
          if (appState.isLevelUnlocked(pack, i) &&
              !appState.isLevelCompleted(pack.levels[i])) {
            nextPlayableIdx = i;
            break;
          }
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: BackgroundCanvas(
            background: appState.selectedBackground,
            conceptSurfaceColor: AppPalette.paper,
            conceptPrimaryColor: AppPalette.brass,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 176,
                  pinned: true,
                  backgroundColor: AppPalette.ink,
                  foregroundColor: AppPalette.card,
                  title: Text(
                    pack.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  actions: [
                    if (pack.language == 'en')
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  WordNotebookScreen(appState: appState),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppPalette.brassBright,
                        ),
                        child: const Text(
                          'Sözlük',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                BackgroundGalleryScreen(appState: appState),
                          ),
                        );
                      },
                      icon: const Icon(Icons.palette_outlined, size: 20),
                      tooltip: 'Arka Planlar',
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      color: AppPalette.ink,
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 54, 20, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                pack.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 13,
                                  height: 1.32,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 7,
                                runSpacing: 6,
                                children: [
                                  _HeaderTag(
                                    label: '$completed/${pack.levels.length} Seviye',
                                  ),
                                  _HeaderTag(
                                    label: '$earnedStars/$maxStars Yıldız',
                                  ),
                                  _HeaderTag(
                                    label: pack.language == 'en'
                                        ? 'EN Klavye'
                                        : 'TR Klavye',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (nextPlayableIdx != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                      child: FilledButton(
                        onPressed: () => _openLevel(context, nextPlayableIdx!),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppPalette.ink,
                          foregroundColor: AppPalette.brassBright,
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          appState
                                      .stateFor(pack.levels[nextPlayableIdx].id)
                                      ?.hasProgress ==
                                  true
                              ? 'Devam Et — Seviye ${pack.levels[nextPlayableIdx].level}: ${pack.levels[nextPlayableIdx].title}'
                              : 'Oyna — Seviye ${pack.levels[nextPlayableIdx].level}: ${pack.levels[nextPlayableIdx].title}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  sliver: SliverGrid.builder(
                    itemCount: pack.levels.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 11,
                      crossAxisSpacing: 11,
                      childAspectRatio: 1.08,
                    ),
                    itemBuilder: (context, index) {
                      final puzzle = pack.levels[index];
                      final unlocked = appState.isLevelUnlocked(pack, index);
                      final saved = appState.stateFor(puzzle.id);
                      final isNext = index == nextPlayableIdx;

                      return _LevelTile(
                        puzzle: puzzle,
                        unlocked: unlocked,
                        saved: saved,
                        isHighlighted: isNext,
                        onTap: () {
                          if (!unlocked) {
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Seviye ${puzzle.level} için önce Seviye ${puzzle.level - 1} tamamlanmalı.',
                                  ),
                                ),
                              );
                            return;
                          }
                          _openLevel(context, index);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openLevel(BuildContext context, int index) {
    final puzzle = pack.levels[index];
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(
          puzzle: puzzle,
          storageKey: puzzle.id,
          language: pack.language,
          packTitle: pack.name,
          primaryColor: AppPalette.brass,
          secondaryColor: AppPalette.ink,
          surfaceColor: AppPalette.paper,
          isDaily: false,
          appState: appState,
          pack: pack,
          levelIndex: index,
        ),
      ),
    );
  }
}

class _HeaderTag extends StatelessWidget {
  const _HeaderTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.puzzle,
    required this.unlocked,
    required this.saved,
    required this.isHighlighted,
    required this.onTap,
  });

  final CrosswordPuzzle puzzle;
  final bool unlocked;
  final PuzzleSaveState? saved;
  final bool isHighlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final completed = saved?.completed ?? false;
    final inProgress = saved?.hasProgress ?? false;
    final stars = saved?.stars ?? 0;

    return Material(
      color: unlocked ? AppPalette.card : AppPalette.cardMuted,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHighlighted
                  ? AppPalette.brass
                  : completed
                      ? AppPalette.correct.withValues(alpha: 0.45)
                      : AppPalette.hairline,
              width: isHighlighted ? 1.8 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: !unlocked
                          ? AppPalette.hairlineStrong
                          : completed
                              ? AppPalette.correct
                              : isHighlighted
                                  ? AppPalette.ink
                                  : AppPalette.cardMuted,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    alignment: Alignment.center,
                    child: !unlocked
                        ? const Icon(
                            Icons.lock_outline_rounded,
                            size: 16,
                            color: AppPalette.inkSoft,
                          )
                        : Text(
                            puzzle.level.toString().padLeft(2, '0'),
                            style: TextStyle(
                              color: completed
                                  ? Colors.white
                                  : isHighlighted
                                      ? AppPalette.brassBright
                                      : AppPalette.ink,
                              fontWeight: FontWeight.w900,
                              fontSize: 13.5,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: unlocked
                          ? AppPalette.paper
                          : AppPalette.hairline.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: AppPalette.hairline),
                    ),
                    child: Text(
                      puzzle.gridSizeLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: unlocked
                            ? AppPalette.inkSoft
                            : AppPalette.inkMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                puzzle.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: unlocked ? AppPalette.ink : AppPalette.inkMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${puzzle.difficulty} • ${puzzle.entries.length} kelime',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppPalette.inkMuted,
                ),
              ),
              const Spacer(),
              if (completed)
                Row(
                  children: [
                    ...List.generate(
                      3,
                      (i) => Icon(
                        i < stars
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 16,
                        color: i < stars
                            ? AppPalette.brassBright
                            : AppPalette.hairlineStrong,
                      ),
                    ),
                    const Spacer(),
                    if (saved?.bestTimeSeconds != null)
                      Flexible(
                        child: Text(
                          TurkishText.formatDuration(saved!.bestTimeSeconds!),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppPalette.inkSoft,
                          ),
                        ),
                      ),
                  ],
                )
              else if (inProgress)
                const Text(
                  'Devam Et',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppPalette.brass,
                  ),
                )
              else if (unlocked)
                Text(
                  isHighlighted ? 'Sıradaki' : 'Açık',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isHighlighted ? AppPalette.brass : AppPalette.inkSoft,
                  ),
                )
              else
                const Text(
                  'Kilitli',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.inkMuted,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
