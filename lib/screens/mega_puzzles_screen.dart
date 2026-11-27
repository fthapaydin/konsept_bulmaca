import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import '../core/theme/app_theme.dart';
import '../models/puzzle_models.dart';
import '../state/app_state.dart';
import '../utils/turkish_text.dart';
import '../widgets/background_canvas.dart';
import 'game_screen.dart';

class MegaPuzzlesScreen extends StatelessWidget {
  const MegaPuzzlesScreen({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final activeBg = appState.selectedBackground;
        final isDark = activeBg.isDark;
        final titleColor = isDark ? Colors.white : AppPalette.ink;
        final subColor = isDark ? Colors.white70 : AppPalette.inkMuted;
        final items = appState.megaBank?.items ?? const <MegaPuzzleItem>[];

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: isDark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: BackgroundCanvas(
              background: activeBg,
              child: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 19,
                            ),
                            color: titleColor,
                            tooltip: 'Geri',
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Dev Bulmacalar',
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                    color: titleColor,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                Text(
                                  '12×12–20×20 • Yakınlaştır & Kaydır destekli',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: subColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          _BalanceChip(
                            label: '${appState.score} P',
                            bg: AppPalette.card,
                            border: AppPalette.hairline,
                            fg: AppPalette.ink,
                          ),
                          const SizedBox(width: 5),
                          _BalanceChip(
                            label: '${appState.coins} Altın',
                            bg: AppPalette.brassSoft,
                            border: AppPalette.brassBorder,
                            fg: AppPalette.brass,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
                        physics: const BouncingScrollPhysics(),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final unlocked = appState.isMegaUnlocked(item);
                          final saved = appState.stateFor(item.puzzle.id);
                          return _MegaPuzzleCard(
                            item: item,
                            unlocked: unlocked,
                            saved: saved,
                            totalSolved: appState.totalSolvedPuzzles,
                            onPlay: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => GameScreen(
                                    key: ValueKey<String>(item.puzzle.id),
                                    puzzle: item.puzzle,
                                    storageKey: item.puzzle.id,
                                    language: item.language,
                                    packTitle: item.puzzle.title,
                                    primaryColor: AppPalette.brass,
                                    secondaryColor: AppPalette.ink,
                                    surfaceColor: AppPalette.paper,
                                    isDaily: false,
                                    rewardMultiplier: item.rewardMultiplier,
                                    appState: appState,
                                  ),
                                ),
                              );
                            },
                            onUnlockTap: () => _showUnlockDialog(context, item),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showUnlockDialog(
    BuildContext context,
    MegaPuzzleItem item,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${item.puzzle.title} (${item.puzzle.gridSizeLabel})'),
        content: Text(
          'Bu dev bulmacayı ${item.requiredSolved} bulmaca çözerek ücretsiz açabilir (${appState.totalSolvedPuzzles}/${item.requiredSolved}), ya da altın veya puanla hemen kilidini açabilirsin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Vazgeç'),
          ),
          OutlinedButton(
            onPressed: () async {
              final res = await appState.unlockMegaEarly(item, useScore: true);
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(res.message),
                      backgroundColor:
                          res.success ? AppPalette.ink : AppPalette.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
              }
            },
            child: Text('${item.earlyUnlockScore} Puan'),
          ),
          FilledButton(
            onPressed: () async {
              final res = await appState.unlockMegaEarly(item, useScore: false);
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(res.message),
                      backgroundColor:
                          res.success ? AppPalette.ink : AppPalette.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
              }
            },
            child: Text('${item.earlyUnlockCoins} Altın'),
          ),
        ],
      ),
    );
  }
}

class _BalanceChip extends StatelessWidget {
  const _BalanceChip({
    required this.label,
    required this.bg,
    required this.border,
    required this.fg,
  });

  final String label;
  final Color bg;
  final Color border;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
          color: fg,
        ),
      ),
    );
  }
}

class _MegaPuzzleCard extends StatelessWidget {
  const _MegaPuzzleCard({
    required this.item,
    required this.unlocked,
    required this.saved,
    required this.totalSolved,
    required this.onPlay,
    required this.onUnlockTap,
  });

  final MegaPuzzleItem item;
  final bool unlocked;
  final PuzzleSaveState? saved;
  final int totalSolved;
  final VoidCallback onPlay;
  final VoidCallback onUnlockTap;

  @override
  Widget build(BuildContext context) {
    final puzzle = item.puzzle;
    final completed = saved?.completed ?? false;
    final inProgress = saved?.hasProgress ?? false;
    final progress = (totalSolved / item.requiredSolved).clamp(0.0, 1.0);

    return Material(
      color: AppPalette.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: unlocked ? onPlay : onUnlockTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: unlocked ? AppPalette.brassBorder : AppPalette.hairline,
              width: unlocked ? 1.3 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
                decoration: BoxDecoration(
                  color: unlocked ? AppPalette.ink : AppPalette.inkSoft,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.16),
                        ),
                      ),
                      child: Text(
                        puzzle.gridSizeLabel,
                        style: const TextStyle(
                          color: AppPalette.brassBright,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            puzzle.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${puzzle.entries.length} kelime • ${item.language.toUpperCase()} • ${item.rewardMultiplier}× Ödül',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!unlocked)
                      const Icon(
                        Icons.lock_outline_rounded,
                        color: Colors.white70,
                        size: 20,
                      )
                    else
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppPalette.brassBright,
                        size: 22,
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
                child: unlocked
                    ? Row(
                        children: [
                          if (completed) ...[
                            ...List.generate(
                              3,
                              (i) => Icon(
                                i < (saved?.stars ?? 0)
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 17,
                                color: AppPalette.brassBright,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (saved?.bestTimeSeconds != null)
                              Text(
                                TurkishText.formatDuration(
                                  saved!.bestTimeSeconds!,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppPalette.inkSoft,
                                  fontSize: 12,
                                ),
                              ),
                          ] else if (inProgress)
                            const Text(
                              'Devam Ediyor • Kaldığın yerden sürdür',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppPalette.brass,
                              ),
                            )
                          else
                            const Text(
                              'Açık • Yakınlaştır & Kaydır ile çöz',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppPalette.inkSoft,
                              ),
                            ),
                          const Spacer(),
                          Text(
                            completed ? 'Tekrar' : 'Oyna',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              color: AppPalette.brass,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Ücretsiz açılış: ${totalSolved.clamp(0, item.requiredSolved)}/${item.requiredSolved} bulmaca',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppPalette.inkSoft,
                                  ),
                                ),
                              ),
                              Text(
                                '${item.earlyUnlockScore} P / ${item.earlyUnlockCoins} Altın',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppPalette.brass,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 5,
                              backgroundColor: AppPalette.cardMuted,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppPalette.brass,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
