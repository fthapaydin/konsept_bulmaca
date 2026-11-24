import 'package:material_ui/material_ui.dart';
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

        // Find next playable level (first unlocked & not completed)
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
            conceptSurfaceColor: const Color(0xFFF8F6F1),
            conceptPrimaryColor: pack.primaryColor,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 190,
                  pinned: true,
                  backgroundColor: pack.primaryColor,
                  foregroundColor: Colors.white,
                  title: Text(
                    pack.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  actions: [
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                BackgroundGalleryScreen(appState: appState),
                          ),
                        );
                      },
                      icon: const Icon(Icons.palette_outlined),
                      tooltip: 'Arka Planlar',
                    ),
                  ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [pack.primaryColor, pack.secondaryColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              pack.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13.5,
                                height: 1.3,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                _HeaderChip(
                                  icon: Icons.layers_rounded,
                                  label: '$completed/${pack.levels.length} Seviye',
                                ),
                                _HeaderChip(
                                  icon: Icons.star_rounded,
                                  label: '$earnedStars/$maxStars Yıldız',
                                ),
                                _HeaderChip(
                                  icon: Icons.keyboard_rounded,
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
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: FilledButton.icon(
                      onPressed: () => _openLevel(context, nextPlayableIdx!),
                      style: FilledButton.styleFrom(
                        backgroundColor: pack.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 24),
                      label: Text(
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
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                sliver: SliverGrid.builder(
                  itemCount: pack.levels.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.06,
                  ),
                  itemBuilder: (context, index) {
                    final puzzle = pack.levels[index];
                    final unlocked = appState.isLevelUnlocked(pack, index);
                    final saved = appState.stateFor(puzzle.id);
                    final isNext = index == nextPlayableIdx;

                    return _LevelTile(
                      puzzle: puzzle,
                      pack: pack,
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
                                behavior: SnackBarBehavior.floating,
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
          primaryColor: pack.primaryColor,
          secondaryColor: pack.secondaryColor,
          surfaceColor: pack.surfaceColor,
          isDaily: false,
          appState: appState,
          pack: pack,
          levelIndex: index,
        ),
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.puzzle,
    required this.pack,
    required this.unlocked,
    required this.saved,
    required this.isHighlighted,
    required this.onTap,
  });

  final CrosswordPuzzle puzzle;
  final ConceptPack pack;
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
      color: unlocked ? Colors.white : const Color(0xFFF1EFEA),
      borderRadius: BorderRadius.circular(18),
      elevation: isHighlighted ? 3 : (unlocked ? 1 : 0),
      shadowColor: pack.primaryColor.withValues(alpha: 0.25),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isHighlighted
                  ? pack.primaryColor
                  : completed
                      ? const Color(0xFF16A34A).withValues(alpha: 0.45)
                      : const Color(0xFFE7E5E4),
              width: isHighlighted ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: !unlocked
                          ? const Color(0xFFD6D3D1)
                          : completed
                              ? const Color(0xFF16A34A)
                              : pack.primaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: !unlocked
                        ? const Icon(
                            Icons.lock_rounded,
                            size: 18,
                            color: Colors.white,
                          )
                        : Text(
                            '${puzzle.level}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: unlocked
                          ? pack.surfaceColor
                          : const Color(0xFFE7E5E4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      puzzle.gridSizeLabel,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: unlocked
                            ? pack.primaryColor
                            : const Color(0xFF78716C),
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
                  color: unlocked
                      ? const Color(0xFF1C1917)
                      : const Color(0xFF78716C),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${puzzle.difficulty} • ${puzzle.entries.length} kelime',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF78716C),
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
                        size: 18,
                        color: i < stars
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFFD6D3D1),
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
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF57534E),
                          ),
                        ),
                      ),
                  ],
                )
              else if (inProgress)
                Row(
                  children: [
                    Icon(
                      Icons.timelapse_rounded,
                      size: 15,
                      color: pack.primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Devam Et',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: pack.primaryColor,
                        ),
                      ),
                    ),
                  ],
                )
              else if (unlocked)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isHighlighted ? 'Sıradaki' : 'Açık',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: pack.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: pack.primaryColor,
                    ),
                  ],
                )
              else
                const Text(
                  'Kilitli',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFA8A29E),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
