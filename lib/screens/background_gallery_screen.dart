import 'package:material_ui/material_ui.dart';
import '../core/theme/app_theme.dart';
import '../models/background_models.dart';
import '../state/app_state.dart';
import '../widgets/background_canvas.dart';

class BackgroundGalleryScreen extends StatelessWidget {
  const BackgroundGalleryScreen({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final activeBg = appState.selectedBackground;
        final isDark = activeBg.isDark;
        final titleColor = isDark ? Colors.white : AppPalette.ink;
        final subtitleColor = isDark ? Colors.white70 : AppPalette.inkMuted;

        return Scaffold(
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
                                'Arka Plan Galerisi',
                                style: TextStyle(
                                  fontSize: 18.5,
                                  fontWeight: FontWeight.w900,
                                  color: titleColor,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              Text(
                                '${appState.unlockedBackgroundCount}/${BackgroundCatalog.all.length} tema açık • İlerleyerek, puanla veya altınla aç',
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppPalette.card,
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(color: AppPalette.hairline),
                          ),
                          child: Text(
                            '${appState.score} P',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              color: AppPalette.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppPalette.brassSoft,
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(color: AppPalette.brassBorder),
                          ),
                          child: Text(
                            '${appState.coins} Altın',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              color: AppPalette.brass,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 26),
                      physics: const BouncingScrollPhysics(),
                      itemCount: BackgroundCatalog.all.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 13,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.66,
                      ),
                      itemBuilder: (context, index) {
                        final bg = BackgroundCatalog.all[index];
                        final unlocked = appState.isBackgroundUnlocked(bg);
                        final selected = activeBg.id == bg.id;
                        final currentMetric =
                            appState.backgroundMetricValue(bg.unlockMetric);

                        return _BackgroundCard(
                          background: bg,
                          unlocked: unlocked,
                          selected: selected,
                          currentMetric: currentMetric,
                          canAffordCoins: appState.coins >= bg.coinCost,
                          canAffordScore: appState.score >= bg.scoreCost,
                          onSelect: () async {
                            await appState.selectBackground(bg.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  SnackBar(
                                    content: Text('${bg.name} uygulandı!'),
                                    duration:
                                        const Duration(milliseconds: 1400),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                            }
                          },
                          onUnlockOptions: () =>
                              _showUnlockChoiceDialog(context, bg),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showUnlockChoiceDialog(
    BuildContext context,
    AppBackground bg,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${bg.name} Temasını Aç'),
        content: Text(
          '${bg.subtitle}\n\n• İlerleyerek ücretsiz: ${bg.unlockRequirementLabel}\n• Puan ile hemen aç: ${bg.scoreCost} Puan\n• Altın ile hemen aç: ${bg.coinCost} Altın',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Kapat'),
          ),
          OutlinedButton(
            onPressed: () async {
              final res = await appState.unlockBackgroundWithScore(bg);
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
            child: Text('${bg.scoreCost} Puan'),
          ),
          FilledButton(
            onPressed: () async {
              final res = await appState.unlockBackgroundWithCoins(bg);
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
            child: Text('${bg.coinCost} Altın'),
          ),
        ],
      ),
    );
  }
}

class _BackgroundCard extends StatelessWidget {
  const _BackgroundCard({
    required this.background,
    required this.unlocked,
    required this.selected,
    required this.currentMetric,
    required this.canAffordCoins,
    required this.canAffordScore,
    required this.onSelect,
    required this.onUnlockOptions,
  });

  final AppBackground background;
  final bool unlocked;
  final bool selected;
  final int currentMetric;
  final bool canAffordCoins;
  final bool canAffordScore;
  final VoidCallback onSelect;
  final VoidCallback onUnlockOptions;

  @override
  Widget build(BuildContext context) {
    final target = background.unlockTarget;
    final progress =
        target <= 0 ? 1.0 : (currentMetric / target).clamp(0.0, 1.0);

    return Material(
      color: AppPalette.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: unlocked ? onSelect : onUnlockOptions,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppPalette.ink : AppPalette.hairline,
              width: selected ? 2.0 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 9,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                  child: BackgroundCanvas(
                    background: background,
                    child: Stack(
                      children: [
                        Center(
                          child: _MiniGridPreview(
                            accentColor: AppPalette.brass,
                            locked: !unlocked,
                          ),
                        ),
                        if (selected)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppPalette.ink,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Aktif',
                                style: TextStyle(
                                  color: AppPalette.brassBright,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          )
                        else if (!unlocked)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: AppPalette.ink.withValues(alpha: 0.62),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.lock_outline_rounded,
                                size: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 11,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        background.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          color: AppPalette.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        background.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.6,
                          height: 1.2,
                          color: AppPalette.inkMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      if (unlocked)
                        Text(
                          selected ? 'Şu an seçili' : 'Kullanmak için dokun',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: selected
                                ? AppPalette.ink
                                : AppPalette.brass,
                          ),
                        )
                      else ...[
                        Text(
                          '${background.unlockRequirementLabel} (${currentMetric.clamp(0, target)}/$target)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppPalette.inkSoft,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 4.5,
                            backgroundColor: AppPalette.cardMuted,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppPalette.brass,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: canAffordScore
                                      ? AppPalette.paper
                                      : AppPalette.cardMuted,
                                  borderRadius: BorderRadius.circular(7),
                                  border: Border.all(
                                    color: canAffordScore
                                        ? AppPalette.inkSoft
                                        : AppPalette.hairline,
                                  ),
                                ),
                                child: Text(
                                  '${background.scoreCost} P',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: canAffordScore
                                        ? AppPalette.ink
                                        : AppPalette.inkMuted,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: canAffordCoins
                                      ? AppPalette.brassSoft
                                      : AppPalette.cardMuted,
                                  borderRadius: BorderRadius.circular(7),
                                  border: Border.all(
                                    color: canAffordCoins
                                        ? AppPalette.brassBorder
                                        : AppPalette.hairline,
                                  ),
                                ),
                                child: Text(
                                  '${background.coinCost} Altın',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: canAffordCoins
                                        ? AppPalette.brass
                                        : AppPalette.inkMuted,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
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

class _MiniGridPreview extends StatelessWidget {
  const _MiniGridPreview({
    required this.accentColor,
    required this.locked,
  });

  final Color accentColor;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    Widget cell(String ch, {bool highlight = false}) {
      return Container(
        width: 22,
        height: 22,
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: highlight ? accentColor : AppPalette.card,
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: Text(
          ch,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: highlight ? Colors.white : AppPalette.ink,
          ),
        ),
      );
    }

    return Opacity(
      opacity: locked ? 0.72 : 0.96,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppPalette.ink.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                cell('K', highlight: true),
                cell('A'),
                cell('R'),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                cell('E'),
                const SizedBox(width: 25, height: 25),
                cell('E'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
