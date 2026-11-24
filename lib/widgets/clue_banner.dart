import 'package:material_ui/material_ui.dart';
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primaryColor.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                        style: TextStyle(color: Color(0xFF78716C)),
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
                                  color: Color(0xFF78716C),
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.format_list_bulleted_rounded,
                                size: 15,
                                color: primaryColor.withValues(alpha: 0.7),
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
                              color: Color(0xFF1C1917),
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

Future<void> showAllCluesSheet({
  required BuildContext context,
  required GameController controller,
  required Color primaryColor,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFFFAF8F5),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      final puzzle = controller.puzzle;
      final activeId = controller.activeEntry?.id;

      Widget buildSection(String title, List<PuzzleEntry> list) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: primaryColor,
                ),
              ),
            ),
            ...list.map((entry) {
              final solved = controller.isEntrySolved(entry);
              final isActive = entry.id == activeId;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: isActive
                      ? primaryColor.withValues(alpha: 0.12)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      controller.selectEntry(entry);
                      Navigator.of(ctx).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive
                              ? primaryColor
                              : const Color(0xFFE7E5E4),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 13,
                            backgroundColor: solved
                                ? const Color(0xFF16A34A)
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
                                      fontWeight: FontWeight.w800,
                                      color: primaryColor,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              entry.clue,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: solved
                                    ? const Color(0xFF78716C)
                                    : const Color(0xFF1C1917),
                                decoration: solved
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${entry.length})',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF78716C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      }

      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.88,
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
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                child: Row(
                  children: [
                    const Text(
                      'Tüm İpuçları',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1C1917),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${controller.solvedWordsCount}/${puzzle.entries.length} çözüldü',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    buildSection('YATAY', puzzle.acrossEntries),
                    const SizedBox(height: 8),
                    buildSection('DİKEY', puzzle.downEntries),
                  ],
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
