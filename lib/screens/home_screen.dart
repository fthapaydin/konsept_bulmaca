import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import '../models/background_models.dart';
import '../models/puzzle_models.dart';
import '../state/app_state.dart';
import '../utils/turkish_text.dart';
import '../widgets/background_canvas.dart';
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
        final headingColor = isDark ? Colors.white : const Color(0xFF1C1917);

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
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
                        child: _buildHeader(context, isDark: isDark),
                      ),
                    ),
                    if (dailyPuzzle != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
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
                                    primaryColor: const Color(0xFFD97706),
                                    secondaryColor: const Color(0xFF9A3412),
                                    surfaceColor: const Color(0xFFFFFBEB),
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
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Konsept Dünyaları',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  color: headingColor,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => BackgroundGalleryScreen(
                                      appState: appState,
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.14)
                                      : Colors.white.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white24
                                        : const Color(0xFFE7E5E4),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.palette_rounded,
                                      size: 15,
                                      color: isDark
                                          ? activeBg.accentColor
                                          : const Color(0xFFB45309),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${appState.unlockedBackgroundCount}/${BackgroundCatalog.all.length}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF44403C),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.14)
                                    : const Color(0xFFE7E5E4),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 15,
                                    color: Color(0xFFF59E0B),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${appState.totalStars}',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF44403C),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                      sliver: SliverList.separated(
                        itemCount: appState.packs.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final pack = appState.packs[index];
                          return _ConceptPackCard(
                            pack: pack,
                            completedLevels: appState.completedCountForPack(pack),
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
    final titleColor = isDark ? Colors.white : const Color(0xFF1C1917);
    final subtitleColor = isDark ? Colors.white70 : const Color(0xFF78716C);
    final iconBg = isDark ? Colors.white.withValues(alpha: 0.14) : Colors.white;
    final iconFg = isDark ? Colors.white : const Color(0xFF44403C);

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFB45309), Color(0xFF7C2D12)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(13),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFB45309).withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.grid_view_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Konsept Bulmaca',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: titleColor,
                  letterSpacing: -0.4,
                ),
              ),
              Text(
                'Tematik Kare Bulmaca Dünyası',
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
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.45),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.monetization_on_rounded,
                      size: 16,
                      color: Color(0xFFD97706),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${appState.coins}',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF92400E),
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
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
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
        const SizedBox(width: 5),
        IconButton.filledTonal(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => BackgroundGalleryScreen(appState: appState),
              ),
            );
          },
          style: IconButton.styleFrom(
            backgroundColor: iconBg,
            foregroundColor: iconFg,
          ),
          icon: const Icon(Icons.palette_outlined, size: 21),
          tooltip: 'Arka Planlar',
        ),
        const SizedBox(width: 4),
        IconButton.filledTonal(
          onPressed: () => showStatsAndSettingsSheet(context, appState),
          style: IconButton.styleFrom(
            backgroundColor: iconBg,
            foregroundColor: iconFg,
          ),
          icon: const Icon(Icons.bar_chart_rounded, size: 21),
          tooltip: 'İstatistikler ve Ayarlar',
        ),
      ],
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
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFEA580C), Color(0xFFB45309), Color(0xFF7C2D12)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFB45309).withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.wb_sunny_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          todayLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_fire_department_rounded,
                          size: 15,
                          color: Color(0xFFFDE047),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$streak Gün',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
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
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Karma konsept • ${puzzle.gridSizeLabel} • ${puzzle.entries.length} kelime • 2× Altın',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          completed
                              ? Icons.check_circle_rounded
                              : Icons.play_arrow_rounded,
                          size: 18,
                          color: completed
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFB45309),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          completed ? 'Çözüldü' : 'Başla',
                          style: TextStyle(
                            color: completed
                                ? const Color(0xFF15803D)
                                : const Color(0xFF9A3412),
                            fontWeight: FontWeight.w900,
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
    required this.completedLevels,
    required this.earnedStars,
    required this.maxStars,
    required this.onTap,
  });

  final ConceptPack pack;
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

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 1.5,
      shadowColor: pack.secondaryColor.withValues(alpha: 0.14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: pack.primaryColor.withValues(alpha: 0.18)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [pack.primaryColor, pack.secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(19),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(pack.icon, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  pack.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17.5,
                                    fontWeight: FontWeight.w900,
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
                                  color: Colors.black.withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  pack.language.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            pack.subtitle,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.88),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white70,
                      size: 18,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '$completedLevels/$totalLevels Seviye',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF292524),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: pack.surfaceColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$minGrid–$maxGrid',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: pack.primaryColor,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '$earnedStars/$maxStars',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF57534E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 7,
                        backgroundColor: const Color(0xFFE7E5E4),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          pack.primaryColor,
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
      color: isDark
          ? Colors.white.withValues(alpha: 0.12)
          : Colors.white.withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: pending > 0
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.7)
                  : (isDark ? Colors.white12 : const Color(0xFFE7E5E4)),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: rank.color.withValues(alpha: isDark ? 0.35 : 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  rank.icon,
                  color: isDark ? Colors.white : rank.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            rank.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1C1917),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.star_rounded,
                          size: 13,
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          rank.nextStars == null
                              ? '$stars'
                              : '$stars/${rank.nextStars}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF78716C),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.bolt_rounded,
                          size: 13,
                          color: Color(0xFF7C3AED),
                        ),
                        Text(
                          '${appState.score}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: isDark
                                ? const Color(0xFFC4B5FD)
                                : const Color(0xFF5B21B6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: rank.progressFor(stars),
                        minHeight: 5,
                        backgroundColor: isDark
                            ? Colors.white12
                            : const Color(0xFFE7E5E4),
                        valueColor: AlwaysStoppedAnimation<Color>(rank.color),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: pending > 0
                      ? const Color(0xFFEA580C)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : const Color(0xFFF5F5F4)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      pending > 0
                          ? Icons.card_giftcard_rounded
                          : Icons.emoji_events_outlined,
                      size: 14,
                      color: pending > 0
                          ? Colors.white
                          : (isDark ? Colors.white : const Color(0xFF44403C)),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      pending > 0 ? 'Ödül ($pending)' : 'Görevler',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: pending > 0
                            ? Colors.white
                            : (isDark
                                ? Colors.white
                                : const Color(0xFF44403C)),
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
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF881337), Color(0xFF4C1D95), Color(0xFF1E1B4B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4C1D95).withValues(alpha: 0.32),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.grid_4x4_rounded,
                  color: Color(0xFFFDE047),
                  size: 30,
                ),
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
                              fontSize: 17.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDE047),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: const Text(
                            '12×12–20×20',
                            style: TextStyle(
                              color: Color(0xFF1C1917),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$unlockedCount/${items.length} açık • Yakınlaştır & Kaydır • 3× Ödül',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.86),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white70,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
