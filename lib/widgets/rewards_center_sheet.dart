import 'package:material_ui/material_ui.dart';
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
    backgroundColor: const Color(0xFFFAF8F5),
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
          backgroundColor:
              isError ? const Color(0xFFDC2626) : const Color(0xFF15803D),
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
                    color: const Color(0xFFD6D3D1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 16, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Ödül & Mağaza',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1C1917),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE9FE),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.bolt_rounded,
                              size: 15,
                              color: Color(0xFF5B21B6),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${appState.score}',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF5B21B6),
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
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.monetization_on_rounded,
                              size: 15,
                              color: Color(0xFFD97706),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${appState.coins}',
                              style: const TextStyle(
                                fontSize: 12.5,
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
                // Sekme Seçici: Görevler | Mağaza (Puan & Altın)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7E5E4),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _TabPill(
                            label: appState.pendingRewardCount > 0
                                ? 'Görevler (${appState.pendingRewardCount})'
                                : 'Görevler',
                            icon: Icons.emoji_events_rounded,
                            selected: _tabIndex == 0,
                            onTap: () => setState(() => _tabIndex = 0),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _TabPill(
                            label: 'Puan Mağazası',
                            icon: Icons.storefront_rounded,
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
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                rank.color,
                Color.alphaBlend(
                  Colors.black.withValues(alpha: 0.28),
                  rank.color,
                ),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(rank.icon, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rütbe ${rank.level} • ${rank.title}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          rank.nextStars == null
                              ? 'En yüksek ustalık seviyesine ulaştın!'
                              : 'Sonraki rütbe için $stars / ${rank.nextStars} yıldız • En iyi kombo: ${appState.bestCombo}×',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: rank.progressFor(stars),
                  minHeight: 7,
                  backgroundColor: Colors.white.withValues(alpha: 0.24),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFFFDE047),
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
                icon: Icons.card_giftcard_rounded,
                iconColor: const Color(0xFFEA580C),
                title: 'Günlük Hediye',
                subtitle: canGift
                    ? '+${MissionCatalog.dailyGiftCoins} altın hazır'
                    : 'Bugün alındı',
                buttonLabel: canGift ? 'Hediyeyi Al' : 'Alındı',
                enabled: canGift,
                accentColor: const Color(0xFFEA580C),
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
                icon: Icons.play_circle_filled_rounded,
                iconColor: const Color(0xFF1D4ED8),
                title: 'Ödüllü Video',
                subtitle: '+${MissionCatalog.rewardedAdCoins} altın (Yakında)',
                buttonLabel: 'Hazırlanıyor',
                enabled: appState.rewardAdService.isAvailable,
                accentColor: const Color(0xFF1D4ED8),
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
            color: Color(0xFF1C1917),
          ),
        ),
        const SizedBox(height: 8),
        ...MissionCatalog.all.map((mission) {
          final current = appState.missionProgress(mission);
          final claimed = appState.isMissionClaimed(mission);
          final claimable = appState.canClaimMission(mission);
          final progress = (current / mission.target).clamp(0.0, 1.0);

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: claimable
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFE7E5E4),
                width: claimable ? 1.8 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: mission.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(mission.icon, color: mission.color, size: 22),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mission.title,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1C1917),
                        ),
                      ),
                      Text(
                        mission.description,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF78716C),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 6,
                                backgroundColor: const Color(0xFFE7E5E4),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  claimed
                                      ? const Color(0xFF16A34A)
                                      : mission.color,
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
                              color: Color(0xFF57534E),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (claimed)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF16A34A),
                    size: 24,
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
                      backgroundColor: const Color(0xFF16A34A),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                    ),
                    child: Text(
                      '+${mission.rewardCoins}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12.5,
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
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '+${mission.rewardCoins}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF92400E),
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
        // İpucu Stok Özeti
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE7E5E4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mevcut İpucu Hakların',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1C1917),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _TicketPill(
                      icon: Icons.lightbulb_rounded,
                      label: 'Harf',
                      count: appState.letterHintTickets,
                      color: const Color(0xFFB45309),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TicketPill(
                      icon: Icons.auto_awesome_rounded,
                      label: 'Kelime',
                      count: appState.wordHintTickets,
                      color: const Color(0xFF6D28D9),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TicketPill(
                      icon: Icons.fact_check_rounded,
                      label: 'Kontrol',
                      count: appState.checkHintTickets,
                      color: const Color(0xFF0F766E),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Arka Planlara Hızlı Geçiş (Puan & Altın ile!)
        Material(
          color: const Color(0xFF1E1B4B),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(widget.parentContext).push(
                MaterialPageRoute<void>(
                  builder: (_) => BackgroundGalleryScreen(appState: appState),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.palette_rounded,
                      color: Color(0xFFFDE047),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 11),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Arka Plan Temaları',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
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
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white70,
                    size: 16,
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
            color: Color(0xFF1C1917),
          ),
        ),
        const SizedBox(height: 8),
        ...ShopCatalog.all.map((bundle) {
          final canScore = appState.score >= bundle.scoreCost;
          final canCoin = bundle.coinCost > 0 && appState.coins >= bundle.coinCost;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE7E5E4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: bundle.color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(bundle.icon, color: bundle.color, size: 22),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bundle.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1C1917),
                            ),
                          ),
                          Text(
                            bundle.subtitle,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF78716C),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final res = await appState.buyShopBundle(
                            bundle,
                            useScore: true,
                          );
                          _toast(res.message, isError: !res.success);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: canScore
                              ? const Color(0xFF5B21B6)
                              : const Color(0xFF78716C),
                          side: BorderSide(
                            color: canScore
                                ? const Color(0xFF7C3AED)
                                : const Color(0xFFD6D3D1),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                        icon: const Icon(Icons.bolt_rounded, size: 16),
                        label: Text(
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
                        child: FilledButton.icon(
                          onPressed: () async {
                            final res = await appState.buyShopBundle(
                              bundle,
                              useScore: false,
                            );
                            _toast(res.message, isError: !res.success);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: canCoin
                                ? const Color(0xFFD97706)
                                : const Color(0xFFA8A29E),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                          ),
                          icon: const Icon(
                            Icons.monetization_on_rounded,
                            size: 16,
                          ),
                          label: Text(
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
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected
                  ? const Color(0xFFB45309)
                  : const Color(0xFF78716C),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  color: selected
                      ? const Color(0xFF1C1917)
                      : const Color(0xFF78716C),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketPill extends StatelessWidget {
  const _TicketPill({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(height: 3),
          Text(
            '×$count',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF57534E),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickCoinCard extends StatelessWidget {
  const _QuickCoinCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.enabled,
    required this.accentColor,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final bool enabled;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: enabled
              ? accentColor.withValues(alpha: 0.45)
              : const Color(0xFFE7E5E4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1C1917),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF78716C),
            ),
          ),
          const SizedBox(height: 9),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: enabled ? onTap : null,
              style: FilledButton.styleFrom(
                backgroundColor: accentColor,
                padding: const EdgeInsets.symmetric(vertical: 8),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
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
