import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import '../core/brand/brand_config.dart';
import '../core/theme/app_theme.dart';
import '../features/notebook/word_notebook_screen.dart';
import '../features/sprint/mini_sprint_screen.dart';
import '../models/puzzle_models.dart';
import '../state/app_state.dart';
import '../utils/turkish_text.dart';
import '../widgets/background_canvas.dart';
import '../widgets/editorial_emblems.dart';
import '../widgets/rewards_center_sheet.dart';
import '../widgets/stats_settings_sheet.dart';
import 'background_gallery_screen.dart';
import 'game_screen.dart';
import 'mega_puzzles_screen.dart';
import 'pack_levels_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final dailyPuzzle = appState.todayDailyPuzzle;
        final dailyDone = appState.isTodayDailyCompleted;
        final activeBg = appState.selectedBackground;
        final isDark = activeBg.isDark;
        final headingColor = isDark ? Colors.white : AppPalette.ink;
        final mutedColor = isDark ? Colors.white60 : AppPalette.inkMuted;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: isDark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: BackgroundCanvas(
              background: activeBg,
              child: SafeArea(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
                        child: _buildHeader(context, isDark: isDark),
                      ),
                    ),
                    if (dailyPuzzle != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
                          child: _DailyChallengeCard(
                            puzzle: dailyPuzzle,
                            completed: dailyDone,
                            streak: appState.dailyStreak,
                            onPlay: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => GameScreen(
                                    puzzle: dailyPuzzle,
                                    storageKey: appState.todayDailyStorageKey,
                                    language: 'tr',
                                    packTitle: 'Günün Bulmacası',
                                    primaryColor: AppPalette.brass,
                                    secondaryColor: AppPalette.ink,
                                    surfaceColor: AppPalette.paper,
                                    isDaily: true,
                                    appState: appState,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                        child: _RankAndMissionsStrip(
                          appState: appState,
                          isDark: isDark,
                          onTap: () => showRewardsCenterSheet(context, appState),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                        child: _QuickModulesRow(
                          appState: appState,
                          isDark: isDark,
                          onOpenSprint: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    MiniSprintScreen(appState: appState),
                              ),
                            );
                          },
                          onOpenNotebook: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    WordNotebookScreen(appState: appState),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Expanded(
                              child: Text(
                                'Konsept Dünyaları',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: headingColor,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                            Text(
                              '${appState.packs.length} Paket • ${appState.totalStars} Yıldız',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: mutedColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                      sliver: SliverList.separated(
                        itemCount: appState.packs.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 11),
                        itemBuilder: (context, index) {
                          final pack = appState.packs[index];
                          return _ConceptPackCard(
                            pack: pack,
                            isDark: isDark,
                            completedLevels:
                                appState.completedCountForPack(pack),
                            earnedStars: appState.starsForPack(pack),
                            maxStars: appState.maxStarsForPack(pack),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => PackLevelsScreen(
                                    pack: pack,
                                    appState: appState,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    if (appState.shouldShowCloudBackupBanner &&
                        appState.isCloudAvailable)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                          child: _GentleBackupStrip(
                            isDark: isDark,
                            onConnect: () async {
                              final res =
                                  await appState.signInWithGoogleAndSync();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        res.message,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                              }
                            },
                            onDismiss: appState.dismissCloudBackupBanner,
                          ),
                        ),
                      ),
                    if (appState.megaBank != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 2, 18, 28),
                          child: _MegaArenaBanner(
                            appState: appState,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      MegaPuzzlesScreen(appState: appState),
                                ),
                              );
                            },
                          ),
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

  Widget _buildHeader(BuildContext context, {required bool isDark}) {
    final titleColor = isDark ? Colors.white : AppPalette.ink;
    final subtitleColor = isDark ? Colors.white70 : AppPalette.inkMuted;
    final btnBg =
        isDark ? Colors.white.withValues(alpha: 0.1) : AppPalette.card;
    final btnBorder =
        isDark ? Colors.white24 : AppPalette.hairline;
    final btnFg = isDark ? Colors.white : AppPalette.ink;

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: isDark ? Colors.white30 : AppPalette.ink,
              width: 1.2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              BrandConfig.iconAssetPath,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                BrandConfig.appName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: titleColor,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                BrandConfig.tagline,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: subtitleColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        InkWell(
          onTap: () => showRewardsCenterSheet(context, appState, initialTab: 1),
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : AppPalette.brassSoft,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? AppPalette.brassBright.withValues(alpha: 0.4)
                        : AppPalette.brassBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppPalette.brassBright,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${appState.coins}',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : AppPalette.ink,
                      ),
                    ),
                  ],
                ),
              ),
              if (appState.pendingRewardCount > 0)
                Positioned(
                  top: -3,
                  right: -3,
                  child: Container(
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(
                      color: AppPalette.brass,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppPalette.card, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${appState.pendingRewardCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        _HeaderIconButton(
          icon: Icons.palette_outlined,
          tooltip: 'Arka Planlar',
          bg: btnBg,
          border: btnBorder,
          fg: btnFg,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => BackgroundGalleryScreen(appState: appState),
              ),
            );
          },
        ),
        const SizedBox(width: 6),
        _HeaderIconButton(
          icon: Icons.tune_rounded,
          tooltip: 'İstatistikler ve Ayarlar',
          bg: btnBg,
          border: btnBorder,
          fg: btnFg,
          onTap: () => showStatsAndSettingsSheet(context, appState),
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.bg,
    required this.border,
    required this.fg,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color bg;
  final Color border;
  final Color fg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(icon, size: 19, color: fg),
          ),
        ),
      ),
    );
  }
}

class _DailyChallengeCard extends StatelessWidget {
  const _DailyChallengeCard({
    required this.puzzle,
    required this.completed,
    required this.streak,
    required this.onPlay,
  });

  final CrosswordPuzzle puzzle;
  final bool completed;
  final int streak;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final todayLabel = TurkishText.formatTurkishDate(DateTime.now());

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPlay,
        borderRadius: BorderRadius.circular(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: CustomPaint(
            foregroundPainter: const CrosswordWatermarkPainter(
              color: Color(0xFFFDE68A),
              opacity: 0.08,
            ),
            child: Ink(
              padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF231E1A), Color(0xFF161311)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppPalette.brassBright.withValues(alpha: 0.25),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        todayLabel.toUpperCase(),
                        style: const TextStyle(
                          color: AppPalette.brassBright,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.14),
                          ),
                        ),
                        child: Text(
                          '$streak Gün Seri',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Günün Bulmacası',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Karma konsept • ${puzzle.gridSizeLabel} • ${puzzle.entries.length} kelime • 2× Altın',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.72),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: completed
                              ? AppPalette.correctSoft
                              : AppPalette.brassBright,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          completed ? 'Çözüldü' : 'Başla',
                          style: TextStyle(
                            color: completed
                                ? AppPalette.correct
                                : AppPalette.ink,
                            fontWeight: FontWeight.w900,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RankAndMissionsStrip extends StatelessWidget {
  const _RankAndMissionsStrip({
    required this.appState,
    required this.isDark,
    required this.onTap,
  });

  final AppState appState;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rank = appState.currentRank;
    final stars = appState.totalStars;
    final pending = appState.pendingRewardCount;

    return Material(
      color: isDark ? Colors.white.withValues(alpha: 0.1) : AppPalette.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white12 : AppPalette.hairline,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.14)
                      : AppPalette.brassSoft,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? Colors.white24 : AppPalette.brassBorder,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  'S${rank.level}',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: isDark ? AppPalette.brassBright : AppPalette.brass,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rank.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppPalette.ink,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      rank.nextStars == null
                          ? '$stars Yıldız • ${appState.score} Puan'
                          : '$stars/${rank.nextStars} Yıldız • ${appState.score} Puan',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? Colors.white60
                            : AppPalette.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: rank.progressFor(stars),
                        minHeight: 4.5,
                        backgroundColor:
                            isDark ? Colors.white12 : AppPalette.cardMuted,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppPalette.brass,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: pending > 0
                      ? AppPalette.ink
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.14)
                          : AppPalette.cardMuted),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  pending > 0 ? 'Ödül ($pending)' : 'Mağaza',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: pending > 0
                        ? AppPalette.brassBright
                        : (isDark ? Colors.white : AppPalette.ink),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickModulesRow extends StatelessWidget {
  const _QuickModulesRow({
    required this.appState,
    required this.isDark,
    required this.onOpenSprint,
    required this.onOpenNotebook,
  });

  final AppState appState;
  final bool isDark;
  final VoidCallback onOpenSprint;
  final VoidCallback onOpenNotebook;

  @override
  Widget build(BuildContext context) {
    final bestSprint = appState.bestSprintScore;
    final enCount = appState.learnedEnglishCount;

    return Row(
      children: [
        Expanded(
          child: _QuickModuleCard(
            title: 'Mini Sprint',
            subtitle: bestSprint > 0
                ? 'Rekor: $bestSprint puan'
                : '5×5 Hız & Kombo',
            badge: '90 SN',
            emblemKind: EmblemKind.sprint,
            isDark: isDark,
            onTap: onOpenSprint,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: _QuickModuleCard(
            title: 'Kelime Defteri',
            subtitle: enCount > 0
                ? '$enCount kelime • Sözlük'
                : 'EN – TR Sözlük',
            badge: 'A1–B1',
            emblemKind: EmblemKind.dictionary,
            isDark: isDark,
            onTap: onOpenNotebook,
          ),
        ),
      ],
    );
  }
}

class _QuickModuleCard extends StatelessWidget {
  const _QuickModuleCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.emblemKind,
    required this.isDark,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String badge;
  final EmblemKind emblemKind;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? Colors.white.withValues(alpha: 0.1) : AppPalette.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(13, 13, 12, 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? Colors.white12 : AppPalette.hairline,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  EditorialEmblem(
                    kind: emblemKind,
                    size: 36,
                    accentColor:
                        isDark ? AppPalette.brassBright : AppPalette.brass,
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : AppPalette.cardMuted,
                    borderColor: isDark ? Colors.white24 : AppPalette.hairline,
                    onDark: isDark,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : AppPalette.brassSoft,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: isDark
                            ? Colors.white24
                            : AppPalette.brassBorder,
                      ),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        color:
                            isDark ? AppPalette.brassBright : AppPalette.brass,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark ? Colors.white : AppPalette.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark ? Colors.white60 : AppPalette.inkMuted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConceptPackCard extends StatelessWidget {
  const _ConceptPackCard({
    required this.pack,
    required this.isDark,
    required this.completedLevels,
    required this.earnedStars,
    required this.maxStars,
    required this.onTap,
  });

  final ConceptPack pack;
  final bool isDark;
  final int completedLevels;
  final int earnedStars;
  final int maxStars;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final totalLevels = pack.levels.length;
    final progress = totalLevels == 0 ? 0.0 : completedLevels / totalLevels;
    final minGrid = pack.levels.first.gridSizeLabel;
    final maxGrid = pack.levels.last.gridSizeLabel;
    final accent = AppPalette.editorialAccentForPack(pack.id);

    return Material(
      color: isDark ? Colors.white.withValues(alpha: 0.1) : AppPalette.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? Colors.white12 : AppPalette.hairline,
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 4, color: accent),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              EditorialEmblem(
                                kind: emblemKindForPack(pack.id),
                                size: 44,
                                accentColor: accent,
                                backgroundColor: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : AppPalette.cardMuted,
                                borderColor: isDark
                                    ? Colors.white24
                                    : AppPalette.hairline,
                                onDark: isDark,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            pack.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: isDark
                                                  ? Colors.white
                                                  : AppPalette.ink,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? Colors.white
                                                    .withValues(alpha: 0.12)
                                                : AppPalette.cardMuted,
                                            borderRadius:
                                                BorderRadius.circular(5),
                                          ),
                                          child: Text(
                                            pack.language.toUpperCase(),
                                            style: TextStyle(
                                              color: isDark
                                                  ? Colors.white70
                                                  : AppPalette.inkSoft,
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      pack.subtitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white60
                                            : AppPalette.inkMuted,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: isDark
                                    ? Colors.white54
                                    : AppPalette.inkMuted,
                                size: 22,
                              ),
                            ],
                          ),
                          const SizedBox(height: 11),
                          Row(
                            children: [
                              Text(
                                '$completedLevels/$totalLevels Seviye',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? Colors.white
                                      : AppPalette.inkSoft,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$minGrid–$maxGrid',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white54
                                      : AppPalette.inkMuted,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '$earnedStars/$maxStars',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? Colors.white70
                                      : AppPalette.inkSoft,
                                ),
                              ),
                              const SizedBox(width: 3),
                              const Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: AppPalette.brassBright,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 5,
                              backgroundColor: isDark
                                  ? Colors.white12
                                  : AppPalette.cardMuted,
                              valueColor: AlwaysStoppedAnimation<Color>(accent),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GentleBackupStrip extends StatelessWidget {
  const _GentleBackupStrip({
    required this.isDark,
    required this.onConnect,
    required this.onDismiss,
  });

  final bool isDark;
  final VoidCallback onConnect;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 10, 8, 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.1) : AppPalette.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white12 : AppPalette.brassBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.14)
                  : AppPalette.brassSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              'G',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: isDark ? AppPalette.brassBright : AppPalette.brass,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'İlerlemeni Google ile buluta yedekle',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppPalette.ink,
              ),
            ),
          ),
          TextButton(
            onPressed: onConnect,
            style: TextButton.styleFrom(
              foregroundColor: AppPalette.brassBright,
              backgroundColor: AppPalette.ink,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            child: const Text(
              'Bağla',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: Icon(
              Icons.close_rounded,
              size: 17,
              color: isDark ? Colors.white54 : AppPalette.inkMuted,
            ),
            visualDensity: VisualDensity.compact,
            tooltip: 'Kapat',
          ),
        ],
      ),
    );
  }
}

class _MegaArenaBanner extends StatelessWidget {
  const _MegaArenaBanner({
    required this.appState,
    required this.onTap,
  });

  final AppState appState;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final items = appState.megaBank?.items ?? const <MegaPuzzleItem>[];
    final unlockedCount = items.where(appState.isMegaUnlocked).length;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF26201C), Color(0xFF181412)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppPalette.brassBright.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              EditorialEmblem(
                kind: EmblemKind.megaGrid,
                size: 46,
                accentColor: AppPalette.brassBright,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                borderColor: Colors.white24,
                onDark: true,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Flexible(
                          child: Text(
                            'Dev Bulmacalar',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppPalette.brassBright,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '12×12–20×20',
                            style: TextStyle(
                              color: AppPalette.ink,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$unlockedCount/${items.length} açık • Yakınlaştır & Kaydır • 3× Ödül',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white54,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
