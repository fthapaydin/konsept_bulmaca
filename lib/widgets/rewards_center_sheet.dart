import 'package:material_ui/material_ui.dart';
import '../core/theme/app_theme.dart';
import '../models/retention_models.dart';
import '../screens/background_gallery_screen.dart';
import '../state/app_state.dart';

Future<void> showRewardsCenterSheet(
  BuildContext context,
  AppState appState, {
  int initialTab = 0,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppPalette.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _RewardsAndShopSheet(
      appState: appState,
      parentContext: context,
      initialTab: initialTab,
    ),
  );
}

class _RewardsAndShopSheet extends StatefulWidget {
  const _RewardsAndShopSheet({
    required this.appState,
    required this.parentContext,
    required this.initialTab,
  });

  final AppState appState;
  final BuildContext parentContext;
  final int initialTab;

  @override
  State<_RewardsAndShopSheet> createState() => _RewardsAndShopSheetState();
}

class _RewardsAndShopSheetState extends State<_RewardsAndShopSheet> {
  late int _tabIndex;

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.initialTab;
  }

  void _toast(String msg, {bool isError = false}) {
    if (!widget.parentContext.mounted) return;
    ScaffoldMessenger.of(widget.parentContext)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w700)),
          backgroundColor: isError ? AppPalette.error : AppPalette.ink,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final appState = widget.appState;

    return ListenableBuilder(
      listenable: appState,
      builder: (_, _) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.82,
          minChildSize: 0.55,
          maxChildSize: 0.94,
          builder: (_, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppPalette.hairlineStrong,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 16, 10),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Ödül & Mağaza',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: AppPalette.ink,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppPalette.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppPalette.hairline),
                        ),
                        child: Text(
                          '${appState.score} P',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: AppPalette.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppPalette.brassSoft,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppPalette.brassBorder),
                        ),
                        child: Text(
                          '${appState.coins} Altın',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: AppPalette.brass,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppPalette.cardMuted,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppPalette.hairline),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _TabPill(
                            label: appState.pendingRewardCount > 0
                                ? 'Görevler (${appState.pendingRewardCount})'
                                : 'Görevler',
                            selected: _tabIndex == 0,
                            onTap: () => setState(() => _tabIndex = 0),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _TabPill(
                            label: 'Puan Mağazası',
                            selected: _tabIndex == 1,
                            onTap: () => setState(() => _tabIndex = 1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: _tabIndex == 0
                      ? _buildMissionsTab(scrollController, appState)
                      : _buildShopTab(scrollController, appState),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMissionsTab(
    ScrollController scrollController,
    AppState appState,
  ) {
    final rank = appState.currentRank;
    final stars = appState.totalStars;
    final canGift = appState.canClaimDailyGift;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 26),
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppPalette.ink,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppPalette.brassBright.withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RÜTBE ${rank.level}',
                style: const TextStyle(
                  color: AppPalette.brassBright,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                rank.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                rank.nextStars == null
                    ? 'En yüksek ustalık seviyesine ulaştın!'
                    : 'Sonraki rütbe için $stars/${rank.nextStars} yıldız • En iyi kombo: ${appState.bestCombo}×',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.76),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: rank.progressFor(stars),
                  minHeight: 5.5,
                  backgroundColor: Colors.white.withValues(alpha: 0.16),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppPalette.brassBright,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickCoinCard(
                title: 'Günlük Hediye',
                subtitle: canGift
                    ? '+${MissionCatalog.dailyGiftCoins} altın hazır'
                    : 'Bugün alındı',
                buttonLabel: canGift ? 'Hediyeyi Al' : 'Alındı',
                enabled: canGift,
                onTap: () async {
                  final earned = await appState.claimDailyGift();
                  if (earned > 0) {
                    _toast('+$earned günlük hediye altın eklendi!');
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickCoinCard(
                title: 'Ödüllü Video',
                subtitle: '+${MissionCatalog.rewardedAdCoins} altın (Yakında)',
                buttonLabel: 'Hazırlanıyor',
                enabled: appState.rewardAdService.isAvailable,
                onTap: () async {
                  final earned = await appState.watchRewardedAdForCoins();
                  if (earned > 0) {
                    _toast('+$earned altın kazandın!');
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'İlerleme Görevleri',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: AppPalette.ink,
          ),
        ),
        const SizedBox(height: 8),
        ...MissionCatalog.all.map((mission) {
          final current = appState.missionProgress(mission);
          final claimed = appState.isMissionClaimed(mission);
          final claimable = appState.canClaimMission(mission);
          final progress = (current / mission.target).clamp(0.0, 1.0);

          return Container(
            margin: const EdgeInsets.only(bottom: 9),
            padding: const EdgeInsets.fromLTRB(13, 12, 12, 12),
            decoration: BoxDecoration(
              color: AppPalette.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: claimable ? AppPalette.brass : AppPalette.hairline,
                width: claimable ? 1.6 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mission.title,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: AppPalette.ink,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        mission.description,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppPalette.inkMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 5,
                                backgroundColor: AppPalette.cardMuted,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  claimed
                                      ? AppPalette.correct
                                      : AppPalette.brass,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${current.clamp(0, mission.target)}/${mission.target}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppPalette.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (claimed)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppPalette.correctSoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Alındı',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppPalette.correct,
                      ),
                    ),
                  )
                else if (claimable)
                  FilledButton(
                    onPressed: () async {
                      final earned = await appState.claimMission(mission);
                      if (earned > 0) {
                        _toast('${mission.title} ödülü: +$earned altın!');
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppPalette.ink,
                      foregroundColor: AppPalette.brassBright,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                    ),
                    child: Text(
                      '+${mission.rewardCoins}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppPalette.brassSoft,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppPalette.brassBorder),
                    ),
                    child: Text(
                      '+${mission.rewardCoins}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        color: AppPalette.brass,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildShopTab(
    ScrollController scrollController,
    AppState appState,
  ) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 26),
      children: [
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: AppPalette.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppPalette.hairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mevcut İpucu Hakların',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppPalette.ink,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _TicketPill(
                      label: 'Harf',
                      count: appState.letterHintTickets,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TicketPill(
                      label: 'Kelime',
                      count: appState.wordHintTickets,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TicketPill(
                      label: 'Kontrol',
                      count: appState.checkHintTickets,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 11),
        Material(
          color: AppPalette.ink,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(widget.parentContext).push(
                MaterialPageRoute<void>(
                  builder: (_) => BackgroundGalleryScreen(appState: appState),
                ),
              );
            },
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Arka Plan Temaları',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14.5,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Puan veya altınla 10 farklı temanın kilidini aç',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppPalette.brassBright,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'İpucu Paketleri & Puan Takası',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: AppPalette.ink,
          ),
        ),
        const SizedBox(height: 8),
        ...ShopCatalog.all.map((bundle) {
          final canScore = appState.score >= bundle.scoreCost;
          final canCoin =
              bundle.coinCost > 0 && appState.coins >= bundle.coinCost;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppPalette.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppPalette.hairline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bundle.title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    color: AppPalette.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  bundle.subtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppPalette.inkMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final res = await appState.buyShopBundle(
                            bundle,
                            useScore: true,
                          );
                          _toast(res.message, isError: !res.success);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              canScore ? AppPalette.ink : AppPalette.inkMuted,
                          side: BorderSide(
                            color: canScore
                                ? AppPalette.ink
                                : AppPalette.hairline,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          '${bundle.scoreCost} Puan',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    if (bundle.coinCost > 0) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: () async {
                            final res = await appState.buyShopBundle(
                              bundle,
                              useScore: false,
                            );
                            _toast(res.message, isError: !res.success);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: canCoin
                                ? AppPalette.ink
                                : AppPalette.hairlineStrong,
                            foregroundColor: canCoin
                                ? AppPalette.brassBright
                                : AppPalette.inkMuted,
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            '${bundle.coinCost} Altın',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppPalette.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: selected ? AppPalette.brassBright : AppPalette.inkSoft,
          ),
        ),
      ),
    );
  }
}

class _TicketPill extends StatelessWidget {
  const _TicketPill({
    required this.label,
    required this.count,
  });

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
      decoration: BoxDecoration(
        color: AppPalette.paper,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppPalette.hairline),
      ),
      child: Column(
        children: [
          Text(
            '×$count',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AppPalette.brass,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: AppPalette.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickCoinCard extends StatelessWidget {
  const _QuickCoinCard({
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String buttonLabel;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppPalette.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: enabled ? AppPalette.brassBorder : AppPalette.hairline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
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
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppPalette.inkMuted,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: enabled ? onTap : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppPalette.ink,
                foregroundColor: AppPalette.brassBright,
                disabledBackgroundColor: AppPalette.cardMuted,
                disabledForegroundColor: AppPalette.inkMuted,
                padding: const EdgeInsets.symmetric(vertical: 8),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              child: Text(
                buttonLabel,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
