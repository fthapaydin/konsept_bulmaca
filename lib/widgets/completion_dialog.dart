import 'package:material_ui/material_ui.dart';
import '../core/theme/app_theme.dart';
import '../models/background_models.dart';
import '../state/app_state.dart';
import '../utils/turkish_text.dart';

class CompletionDialog extends StatelessWidget {
  const CompletionDialog({
    super.key,
    required this.title,
    required this.wordCount,
    required this.reward,
    required this.primaryColor,
    required this.hasNextLevel,
    required this.onNextLevel,
    required this.onBackToMap,
    this.onApplyBackground,
  });

  final String title;
  final int wordCount;
  final CompletionReward reward;
  final Color primaryColor;
  final bool hasNextLevel;
  final VoidCallback onNextLevel;
  final VoidCallback onBackToMap;
  final ValueChanged<AppBackground>? onApplyBackground;

  @override
  Widget build(BuildContext context) {
    final headline = reward.stars == 3
        ? 'Mükemmel Çözüm'
        : reward.stars == 2
            ? 'Harika İş'
            : 'Bulmaca Tamamlandı';

    return Dialog(
      backgroundColor: AppPalette.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppPalette.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
              decoration: BoxDecoration(
                color: AppPalette.brassSoft,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppPalette.brassBorder),
              ),
              child: Text(
                title,
                style: const TextStyle(
                  color: AppPalette.brass,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 11),
            Text(
              headline,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppPalette.ink,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                final earned = i < reward.stars;
                return TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.25, end: 1.0),
                  duration: Duration(milliseconds: 420 + i * 180),
                  curve: Curves.elasticOut,
                  builder: (_, scale, child) => Transform.scale(
                    scale: earned ? scale : 1.0,
                    child: child,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Icon(
                      earned ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: i == 1 ? 48 : 38,
                      color: earned
                          ? AppPalette.brassBright
                          : AppPalette.hairlineStrong,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatPill(
                    label: 'Süre',
                    value: TurkishText.formatDuration(reward.elapsedSeconds),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatPill(
                    label: 'Kelime',
                    value: '$wordCount',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatPill(
                    label: 'Altın',
                    value: '+${reward.totalCoinsWon}',
                    highlight: true,
                  ),
                ),
              ],
            ),
            if (reward.scoreEarned > 0 || reward.maxCombo >= 2) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
                decoration: BoxDecoration(
                  color: AppPalette.paper,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: AppPalette.hairline),
                ),
                child: Text(
                  reward.maxCombo >= 2
                      ? '+${reward.scoreEarned} Puan  •  ${reward.maxCombo}× Kombo (+${reward.comboCoinsEarned} Altın)'
                      : '+${reward.scoreEarned} Puan',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                    color: AppPalette.ink,
                  ),
                ),
              ),
            ],
            if (reward.newDailyStreak != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: AppPalette.brassSoft,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: AppPalette.brassBorder),
                ),
                child: Text(
                  '${reward.newDailyStreak} Günlük Seri',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12.5,
                    color: AppPalette.brass,
                  ),
                ),
              ),
            ],
            if (reward.newlyUnlockedBackgrounds.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...reward.newlyUnlockedBackgrounds.map((bg) {
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                    vertical: 9,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppPalette.paper,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppPalette.brassBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'YENİ ARKA PLAN AÇILDI',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: AppPalette.brass,
                              ),
                            ),
                            Text(
                              bg.name,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                color: AppPalette.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (onApplyBackground != null)
                        TextButton(
                          onPressed: () => onApplyBackground!(bg),
                          style: TextButton.styleFrom(
                            backgroundColor: AppPalette.ink,
                            foregroundColor: AppPalette.brassBright,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 6,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                          child: const Text(
                            'Kullan',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 18),
            if (hasNextLevel) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onNextLevel,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppPalette.ink,
                    foregroundColor: AppPalette.brassBright,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Sonraki Seviye',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onBackToMap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppPalette.inkSoft,
                  side: const BorderSide(color: AppPalette.hairlineStrong),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  hasNextLevel ? 'Seviyelere Dön' : 'Ana Menüye Dön',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
      decoration: BoxDecoration(
        color: AppPalette.paper,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: highlight ? AppPalette.brassBorder : AppPalette.hairline,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w900,
              color: highlight ? AppPalette.brass : AppPalette.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppPalette.inkMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
