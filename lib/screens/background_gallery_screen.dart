import 'package:material_ui/material_ui.dart';
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
        final titleColor = isDark ? Colors.white : const Color(0xFF1C1917);
        final subtitleColor =
            isDark ? Colors.white70 : const Color(0xFF57534E);

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
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
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
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  color: titleColor,
                                ),
                              ),
                              Text(
                                '${appState.unlockedBackgroundCount}/${BackgroundCatalog.all.length} tema açık • İlerleyerek veya altınla aç',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: subtitleColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(18),
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
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                            ],
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
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.68,
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
                          canAfford: appState.coins >= bg.coinCost,
                          onSelect: () async {
                            await appState.selectBackground(bg.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  SnackBar(
                                    content: Text('${bg.name} uygulandı!'),
                                    duration: const Duration(milliseconds: 1400),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                            }
                          },
                          onUnlockWithCoins: () =>
                              _confirmCoinUnlock(context, bg),
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

  Future<void> _confirmCoinUnlock(BuildContext context, AppBackground bg) async {
    if (appState.coins < bg.coinCost) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Bu arka planı açmak için ${bg.coinCost} altın gerekli (veya ${bg.unlockRequirementLabel.toLowerCase()}).',
            ),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${bg.name} Açılsın mı?'),
        content: Text(
          '${bg.coinCost} altın harcayarak bu arka planı hemen açabilir ve kullanabilirsin.\n\n(İstersen ${bg.unlockRequirementLabel.toLowerCase()} hedefiyle ücretsiz de kazanabilirsin.)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('${bg.coinCost} Altın ile Aç'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final res = await appState.unlockBackgroundWithCoins(bg);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(res.message),
              backgroundColor:
                  res.success ? const Color(0xFF15803D) : const Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    }
  }
}

class _BackgroundCard extends StatelessWidget {
  const _BackgroundCard({
    required this.background,
    required this.unlocked,
    required this.selected,
    required this.currentMetric,
    required this.canAfford,
    required this.onSelect,
    required this.onUnlockWithCoins,
  });

  final AppBackground background;
  final bool unlocked;
  final bool selected;
  final int currentMetric;
  final bool canAfford;
  final VoidCallback onSelect;
  final VoidCallback onUnlockWithCoins;

  @override
  Widget build(BuildContext context) {
    final target = background.unlockTarget;
    final progress =
        target <= 0 ? 1.0 : (currentMetric / target).clamp(0.0, 1.0);

    return Material(
      color: Colors.white,
      elevation: selected ? 5 : 2,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: unlocked ? onSelect : onUnlockWithCoins,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? const Color(0xFF16A34A)
                  : const Color(0xFFE7E5E4),
              width: selected ? 2.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Live miniature artwork preview
              Expanded(
                flex: 9,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  child: BackgroundCanvas(
                    background: background,
                    child: Stack(
                      children: [
                        // Miniature crossword tiles floating on the preview
                        Center(
                          child: _MiniGridPreview(
                            accentColor: background.accentColor,
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
                                color: const Color(0xFF16A34A),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_rounded,
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 2),
                                  Text(
                                    'Aktif',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
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
                                color: Colors.black.withValues(alpha: 0.52),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.lock_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              // Card info & unlock progress
              Expanded(
                flex: 11,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(11, 9, 11, 9),
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
                          color: Color(0xFF1C1917),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        background.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.8,
                          height: 1.2,
                          color: Color(0xFF78716C),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      if (unlocked)
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                selected ? 'Şu an seçili' : 'Kullanmak için dokun',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: selected
                                      ? const Color(0xFF15803D)
                                      : const Color(0xFFB45309),
                                ),
                              ),
                            ),
                          ],
                        )
                      else ...[
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${background.unlockRequirementLabel} (${currentMetric.clamp(0, target)}/$target)',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF57534E),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 5,
                            backgroundColor: const Color(0xFFE7E5E4),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              background.accentColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: canAfford
                                ? const Color(0xFFFEF3C7)
                                : const Color(0xFFF5F5F4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.monetization_on_rounded,
                                size: 13,
                                color: canAfford
                                    ? const Color(0xFFD97706)
                                    : const Color(0xFFA8A29E),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${background.coinCost} ile Aç',
                                style: TextStyle(
                                  fontSize: 10.8,
                                  fontWeight: FontWeight.w800,
                                  color: canAfford
                                      ? const Color(0xFF92400E)
                                      : const Color(0xFF78716C),
                                ),
                              ),
                            ],
                          ),
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
          color: highlight ? accentColor : const Color(0xFFFFFDF9),
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: Text(
          ch,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: highlight ? Colors.white : const Color(0xFF1C1917),
          ),
        ),
      );
    }

    return Opacity(
      opacity: locked ? 0.72 : 0.96,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1C1A).withValues(alpha: 0.86),
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
