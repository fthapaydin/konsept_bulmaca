import 'package:material_ui/material_ui.dart';
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
        ? 'Mükemmel Çözüm!'
        : reward.stars == 2
            ? 'Harika İş!'
            : 'Bulmaca Tamamlandı!';

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                title,
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              headline,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1C1917),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                final earned = i < reward.stars;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Icon(
                    earned ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: i == 1 ? 52 : 42,
                    color: earned
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFFD6D3D1),
                  ),
                );
              }),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _StatPill(
                    icon: Icons.timer_outlined,
                    label: 'Süre',
                    value: TurkishText.formatDuration(reward.elapsedSeconds),
                    color: const Color(0xFF0F766E),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatPill(
                    icon: Icons.spellcheck_rounded,
                    label: 'Kelime',
                    value: '$wordCount',
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatPill(
                    icon: Icons.monetization_on_rounded,
                    label: 'Ödül',
                    value: '+${reward.coinsEarned}',
                    color: const Color(0xFFD97706),
                  ),
                ),
              ],
            ),
            if (reward.newDailyStreak != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      color: Color(0xFFEA580C),
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${reward.newDailyStreak} Günlük Seri!',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF9A3412),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (reward.newlyUnlockedBackgrounds.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...reward.newlyUnlockedBackgrounds.map((bg) {
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                    vertical: 9,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: bg.gradientColors.length >= 2
                          ? [bg.gradientColors.first, bg.gradientColors.last]
                          : [primaryColor, primaryColor],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE7E5E4)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.palette_rounded,
                        size: 20,
                        color: bg.isDark ? Colors.white : const Color(0xFF1C1917),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Yeni Arka Plan Kazanıldı!',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: bg.isDark
                                    ? Colors.white70
                                    : const Color(0xFF57534E),
                              ),
                            ),
                            Text(
                              bg.name,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                color: bg.isDark
                                    ? Colors.white
                                    : const Color(0xFF1C1917),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (onApplyBackground != null)
                        TextButton(
                          onPressed: () => onApplyBackground!(bg),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1C1917),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
            const SizedBox(height: 20),
            if (hasNextLevel) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onNextLevel,
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text(
                    'Sonraki Seviye',
                    style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
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
                  foregroundColor: const Color(0xFF44403C),
                  side: const BorderSide(color: Color(0xFFD6D3D1)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
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
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7E5E4)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF78716C),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
