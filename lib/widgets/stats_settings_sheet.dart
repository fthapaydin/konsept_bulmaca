import 'package:material_ui/material_ui.dart';
import '../state/app_state.dart';
import '../utils/turkish_text.dart';

Future<void> showStatsAndSettingsSheet(
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
          final fastest = appState.fastestSolveSeconds;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD6D3D1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'İstatistikler ve Ayarlar',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1C1917),
                    ),
                  ),
                  const SizedBox(height: 14),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.2,
                    children: [
                      _MetricTile(
                        icon: Icons.check_circle_rounded,
                        color: const Color(0xFF0F766E),
                        label: 'Çözülen Bulmaca',
                        value: '${appState.totalSolvedPuzzles}',
                      ),
                      _MetricTile(
                        icon: Icons.star_rounded,
                        color: const Color(0xFFF59E0B),
                        label: 'Toplam Yıldız',
                        value: '${appState.totalStars}',
                      ),
                      _MetricTile(
                        icon: Icons.local_fire_department_rounded,
                        color: const Color(0xFFEA580C),
                        label: 'Günlük Seri',
                        value: '${appState.dailyStreak} gün',
                      ),
                      _MetricTile(
                        icon: Icons.bolt_rounded,
                        color: const Color(0xFF6D28D9),
                        label: 'Toplam Puan',
                        value: '${appState.score}',
                      ),
                      _MetricTile(
                        icon: Icons.whatshot_rounded,
                        color: const Color(0xFFBE123C),
                        label: 'En İyi Kombo',
                        value: '${appState.bestCombo}×',
                      ),
                      _MetricTile(
                        icon: Icons.timer_rounded,
                        color: const Color(0xFF1D4ED8),
                        label: 'En Hızlı Çözüm',
                        value: fastest == null
                            ? '--:--'
                            : TurkishText.formatDuration(fastest),
                      ),
                      _MetricTile(
                        icon: Icons.grid_4x4_rounded,
                        color: const Color(0xFF0E7490),
                        label: 'Dev Bulmaca',
                        value: '${appState.completedMegaCount}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE7E5E4)),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          value: appState.hapticsEnabled,
                          onChanged: appState.toggleHaptics,
                          title: const Text(
                            'Titreşim (Haptik)',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: const Text('Tuş ve kutu seçiminde hafif titreşim'),
                          secondary: const Icon(Icons.vibration_rounded),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          value: appState.soundEnabled,
                          onChanged: appState.toggleSound,
                          title: const Text(
                            'Tuş Sesleri',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: const Text('Klavye dokunuş tıklama sesi'),
                          secondary: const Icon(Icons.volume_up_rounded),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: ctx,
                          builder: (dCtx) => AlertDialog(
                            title: const Text('İlerlemeyi Sıfırla?'),
                            content: const Text(
                              'Tüm çözülen seviyeler, yıldızlar ve günlük seri başlangıç durumuna dönecektir.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(dCtx).pop(false),
                                child: const Text('Vazgeç'),
                              ),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFFDC2626),
                                ),
                                onPressed: () => Navigator.of(dCtx).pop(true),
                                child: const Text('Sıfırla'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await appState.resetAllProgress();
                          if (ctx.mounted) Navigator.of(ctx).pop();
                        }
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                      ),
                      icon: const Icon(Icons.restart_alt_rounded, size: 19),
                      label: const Text(
                        'Tüm İlerlemeyi Sıfırla',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7E5E4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1C1917),
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF78716C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
