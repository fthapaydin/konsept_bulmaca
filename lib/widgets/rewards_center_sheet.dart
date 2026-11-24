import 'package:material_ui/material_ui.dart';
import '../models/retention_models.dart';
import '../state/app_state.dart';

Future<void> showRewardsCenterSheet(
  BuildContext context,
  AppState appState,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFFFAF8F5),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return ListenableBuilder(
        listenable: appState,
        builder: (_, _) {
          final rank = appState.currentRank;
          final stars = appState.totalStars;
          final canGift = appState.canClaimDailyGift;

          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.78,
            minChildSize: 0.5,
            maxChildSize: 0.92,
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
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Görevler & Jeton Merkezi',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1C1917),
                            ),
                          ),
                        ),
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
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 26),
                      children: [
                        // Oyuncu Rütbesi Kartı
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
                                    child: Icon(
                                      rank.icon,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                              : 'Sonraki rütbe için $stars / ${rank.nextStars} yıldız',
                                          style: TextStyle(
                                            color: Colors.white
                                                .withValues(alpha: 0.88),
                                            fontSize: 12,
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
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.24),
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    Color(0xFFFDE047),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Günlük Hediye Altın + Ödüllü Video (AdMob Hazır)
                        Row(
                          children: [
                            Expanded(
                              child: _QuickCoinCard(
                                icon: Icons.card_giftcard_rounded,
                                iconColor: const Color(0xFFEA580C),
                                title: 'Günlük Hediye',
                                subtitle: canGift
                                    ? '+${MissionCatalog.dailyGiftCoins} altın hazır'
                                    : 'Bugün alındı ✓',
                                buttonLabel: canGift ? 'Hediyeyi Al' : 'Alındı',
                                enabled: canGift,
                                accentColor: const Color(0xFFEA580C),
                                onTap: () async {
                                  final earned = await appState.claimDailyGift();
                                  if (earned > 0 && ctx.mounted) {
                                    ScaffoldMessenger.of(context)
                                      ..hideCurrentSnackBar()
                                      ..showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '+$earned günlük hediye altın eklendi!',
                                          ),
                                          backgroundColor:
                                              const Color(0xFF15803D),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
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
                                  final earned = await appState
                                      .watchRewardedAdForCoins();
                                  if (earned > 0 && ctx.mounted) {
                                    ScaffoldMessenger.of(context)
                                      ..hideCurrentSnackBar()
                                      ..showSnackBar(
                                        SnackBar(
                                          content: Text('+$earned altın kazandın!'),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
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
                          final progress =
                              (current / mission.target).clamp(0.0, 1.0);

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
                                  child: Icon(
                                    mission.icon,
                                    color: mission.color,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 11),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              child: LinearProgressIndicator(
                                                value: progress,
                                                minHeight: 6,
                                                backgroundColor:
                                                    const Color(0xFFE7E5E4),
                                                valueColor:
                                                    AlwaysStoppedAnimation<Color>(
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
                                      final earned =
                                          await appState.claimMission(mission);
                                      if (earned > 0 && ctx.mounted) {
                                        ScaffoldMessenger.of(context)
                                          ..hideCurrentSnackBar()
                                          ..showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                '${mission.title} ödülü: +$earned altın!',
                                              ),
                                              backgroundColor:
                                                  const Color(0xFF15803D),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                            ),
                                          );
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
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    },
  );
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
