import 'package:material_ui/material_ui.dart';
import '../core/theme/app_theme.dart';
import '../models/puzzle_models.dart';
import '../state/game_controller.dart';

class ClueBanner extends StatelessWidget {
  const ClueBanner({
    super.key,
    required this.entry,
    required this.primaryColor,
    required this.onPrevious,
    required this.onNext,
    required this.onOpenAllClues,
  });

  final PuzzleEntry? entry;
  final Color primaryColor;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onOpenAllClues;

  @override
  Widget build(BuildContext context) {
    final current = entry;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppPalette.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.hairlineStrong),
        boxShadow: [
          BoxShadow(
            color: AppPalette.ink.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrevious,
            icon: Icon(Icons.chevron_left_rounded, color: primaryColor, size: 28),
            tooltip: 'Önceki İpucu',
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: InkWell(
              onTap: onOpenAllClues,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
                child: current == null
                    ? const Text(
                        'Bir kare seçin',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppPalette.inkMuted),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${current.number} ${current.direction.labelTr}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${current.length} harf',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppPalette.inkMuted,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.format_list_bulleted_rounded,
                                size: 15,
                                color: primaryColor.withValues(alpha: 0.75),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            current.clue,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppPalette.ink,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: Icon(Icons.chevron_right_rounded, color: primaryColor, size: 28),
            tooltip: 'Sonraki İpucu',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

enum _ClueFilterTab { all, across, down }

Future<void> showAllCluesSheet({
  required BuildContext context,
  required GameController controller,
  required Color primaryColor,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppPalette.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _AllCluesSheet(
      controller: controller,
      primaryColor: primaryColor,
    ),
  );
}

class _AllCluesSheet extends StatefulWidget {
  const _AllCluesSheet({
    required this.controller,
    required this.primaryColor,
  });

  final GameController controller;
  final Color primaryColor;

  @override
  State<_AllCluesSheet> createState() => _AllCluesSheetState();
}

class _AllCluesSheetState extends State<_AllCluesSheet> {
  final GlobalKey _activeClueKey = GlobalKey();
  late _ClueFilterTab _selectedTab;

  @override
  void initState() {
    super.initState();
    final activeDir = widget.controller.activeEntry?.direction;
    if (activeDir == WordDirection.across) {
      _selectedTab = _ClueFilterTab.across;
    } else if (activeDir == WordDirection.down) {
      _selectedTab = _ClueFilterTab.down;
    } else {
      _selectedTab = _ClueFilterTab.all;
    }
    _scheduleScrollToActive(animate: false);
  }

  void _scheduleScrollToActive({required bool animate}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _activeClueKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.06,
          duration: animate ? const Duration(milliseconds: 220) : Duration.zero,
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  String _progressPreview(PuzzleEntry entry) {
    final buf = StringBuffer();
    for (var i = 0; i < entry.cells.length; i++) {
      final c = entry.cells[i];
      final ch = widget.controller.letterAt(c.row, c.col);
      buf.write((ch != null && ch.isNotEmpty) ? ch : '·');
      if (i < entry.cells.length - 1) buf.write(' ');
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final puzzle = controller.puzzle;
    final primaryColor = widget.primaryColor;
    final activeEntry = controller.activeEntry;
    final activeId = activeEntry?.id;

    Widget buildEntryCard(PuzzleEntry entry) {
      final solved = controller.isEntrySolved(entry);
      final isActive = entry.id == activeId;
      final filledCount = entry.cells
          .where((c) => (controller.letterAt(c.row, c.col) ?? '').isNotEmpty)
          .length;

      return Padding(
        key: isActive ? _activeClueKey : ValueKey<String>('clue_${entry.id}'),
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: isActive
              ? AppPalette.brassSoft
              : AppPalette.card,
          borderRadius: BorderRadius.circular(13),
          child: InkWell(
            borderRadius: BorderRadius.circular(13),
            onTap: () {
              controller.selectEntry(entry);
              Navigator.of(context).pop();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: isActive
                      ? primaryColor
                      : AppPalette.hairline,
                  width: isActive ? 1.8 : 1.0,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: CircleAvatar(
                      radius: 13.5,
                      backgroundColor: solved
                          ? AppPalette.correct
                          : isActive
                              ? primaryColor
                              : primaryColor.withValues(alpha: 0.14),
                      child: solved
                          ? const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: Colors.white,
                            )
                          : Text(
                              '${entry.number}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: isActive ? Colors.white : primaryColor,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isActive)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppPalette.ink,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    'AKTİF • ${entry.number} ${entry.direction.labelTr}',
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.4,
                                      color: AppPalette.brassBright,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _progressPreview(entry),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppPalette.brass,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Text(
                          entry.clue,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight:
                                isActive ? FontWeight.w700 : FontWeight.w600,
                            color: solved ? AppPalette.inkMuted : AppPalette.ink,
                            decoration:
                                solved ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '(${entry.length})',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppPalette.inkMuted,
                        ),
                      ),
                      if (!solved && filledCount > 0 && !isActive)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '$filledCount/${entry.length}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppPalette.brass,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    Widget buildSection(String title, List<PuzzleEntry> list) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.9,
                color: primaryColor,
              ),
            ),
          ),
          ...list.map(buildEntryCard),
        ],
      );
    }

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.68,
      minChildSize: 0.42,
      maxChildSize: 0.90,
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
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
              child: Row(
                children: [
                  const Text(
                    'Sorular',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppPalette.ink,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppPalette.cardMuted,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${controller.solvedWordsCount}/${puzzle.entries.length} çözüldü',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 21),
                    color: AppPalette.inkSoft,
                    tooltip: 'Kapat',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            // Yön sekmeleri — aktif sorunun yönü otomatik seçilir
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Row(
                children: [
                  _TabChip(
                    label: 'Yatay (${puzzle.acrossEntries.length})',
                    selected: _selectedTab == _ClueFilterTab.across,
                    onTap: () {
                      setState(() => _selectedTab = _ClueFilterTab.across);
                      _scheduleScrollToActive(animate: true);
                    },
                  ),
                  const SizedBox(width: 6),
                  _TabChip(
                    label: 'Dikey (${puzzle.downEntries.length})',
                    selected: _selectedTab == _ClueFilterTab.down,
                    onTap: () {
                      setState(() => _selectedTab = _ClueFilterTab.down);
                      _scheduleScrollToActive(animate: true);
                    },
                  ),
                  const SizedBox(width: 6),
                  _TabChip(
                    label: 'Tümü',
                    selected: _selectedTab == _ClueFilterTab.all,
                    onTap: () {
                      setState(() => _selectedTab = _ClueFilterTab.all);
                      _scheduleScrollToActive(animate: true);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_selectedTab == _ClueFilterTab.across)
                      buildSection('YATAY', puzzle.acrossEntries)
                    else if (_selectedTab == _ClueFilterTab.down)
                      buildSection('DİKEY', puzzle.downEntries)
                    else ...[
                      buildSection('YATAY', puzzle.acrossEntries),
                      const SizedBox(height: 8),
                      buildSection('DİKEY', puzzle.downEntries),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected ? AppPalette.ink : AppPalette.card,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? AppPalette.ink : AppPalette.hairline,
              ),
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: selected ? AppPalette.brassBright : AppPalette.inkSoft,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
