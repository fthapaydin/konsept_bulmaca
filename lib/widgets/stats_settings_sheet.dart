import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import '../core/brand/brand_config.dart';
import '../core/theme/app_theme.dart';
import '../state/app_state.dart';

Future<void> showStatsAndSettingsSheet(
  BuildContext context,
  AppState appState,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppPalette.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return ListenableBuilder(
        listenable: appState,
        builder: (_, _) {
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.9,
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppPalette.hairlineStrong,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'İstatistikler ve Ayarlar',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: AppPalette.ink,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: const Icon(Icons.close_rounded, size: 22),
                          color: AppPalette.inkSoft,
                          tooltip: 'Kapat',
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 2.7,
                      children: [
                        _MetricTile(
                          label: 'Çözülen Bulmaca',
                          value: '${appState.totalSolvedPuzzles}',
                        ),
                        _MetricTile(
                          label: 'Toplam Yıldız',
                          value: '${appState.totalStars}',
                          highlight: true,
                        ),
                        _MetricTile(
                          label: 'Günlük Seri',
                          value: '${appState.dailyStreak} gün',
                        ),
                        _MetricTile(
                          label: 'Toplam Puan',
                          value: '${appState.score}',
                          highlight: true,
                        ),
                        _MetricTile(
                          label: 'En İyi Kombo',
                          value: '${appState.bestCombo}×',
                        ),
                        _MetricTile(
                          label: 'Dev Bulmaca',
                          value: '${appState.completedMegaCount}',
                        ),
                        _MetricTile(
                          label: 'Sprint Rekoru',
                          value: '${appState.bestSprintScore}',
                          highlight: true,
                        ),
                        _MetricTile(
                          label: 'EN Sözlük',
                          value: '${appState.learnedEnglishCount}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Material(
                      color: AppPalette.card,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppPalette.hairline),
                      ),
                      child: Column(
                        children: [
                          SwitchListTile(
                            dense: true,
                            activeThumbColor: AppPalette.brass,
                            value: appState.hapticsEnabled,
                            onChanged: appState.toggleHaptics,
                            title: const Text(
                              'Titreşim (Haptik)',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppPalette.ink,
                              ),
                            ),
                            subtitle: const Text(
                              'Tuş ve kutu seçiminde hafif titreşim',
                              style: TextStyle(color: AppPalette.inkMuted),
                            ),
                          ),
                          const Divider(height: 1, color: AppPalette.hairline),
                          SwitchListTile(
                            dense: true,
                            activeThumbColor: AppPalette.brass,
                            value: appState.soundEnabled,
                            onChanged: appState.toggleSound,
                            title: const Text(
                              'Ses Efektleri',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppPalette.ink,
                              ),
                            ),
                            subtitle: const Text(
                              'Tuş, kombo, ipucu ve kutlama sesleri',
                              style: TextStyle(color: AppPalette.inkMuted),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppPalette.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppPalette.hairline),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppPalette.ink,
                                    width: 1.0,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(9),
                                  child: Image.asset(
                                    BrandConfig.iconAssetPath,
                                    width: 38,
                                    height: 38,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 11),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${BrandConfig.appName} ${BrandConfig.versionLabel}',
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w900,
                                        color: AppPalette.ink,
                                      ),
                                    ),
                                    Text(
                                      'Geliştirici: ${BrandConfig.developerName}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppPalette.inkMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 18, color: AppPalette.hairline),
                          Row(
                            children: [
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'İLETİŞİM & DESTEK',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.7,
                                        color: AppPalette.inkMuted,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      BrandConfig.contactEmail,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: AppPalette.ink,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  await Clipboard.setData(
                                    const ClipboardData(
                                      text: BrandConfig.contactEmail,
                                    ),
                                  );
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx)
                                      ..hideCurrentSnackBar()
                                      ..showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            '${BrandConfig.contactEmail} panoya kopyalandı!',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                  }
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: AppPalette.brass,
                                  backgroundColor: AppPalette.brassSoft,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 7,
                                  ),
                                  minimumSize: Size.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: const BorderSide(
                                      color: AppPalette.brassBorder,
                                    ),
                                  ),
                                ),
                                child: const Text(
                                  'Kopyala',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
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
                                  onPressed: () =>
                                      Navigator.of(dCtx).pop(false),
                                  child: const Text('Vazgeç'),
                                ),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppPalette.error,
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
                          foregroundColor: AppPalette.error,
                        ),
                        child: const Text(
                          'Tüm İlerlemeyi Sıfırla',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
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
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: AppPalette.card,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: highlight ? AppPalette.brassBorder : AppPalette.hairline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: highlight ? AppPalette.brass : AppPalette.ink,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppPalette.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}
