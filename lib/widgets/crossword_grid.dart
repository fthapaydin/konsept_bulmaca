import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';
import '../state/game_controller.dart';

class CrosswordGrid extends StatelessWidget {
  const CrosswordGrid({
    super.key,
    required this.controller,
    required this.primaryColor,
    required this.secondaryColor,
  });

  final GameController controller;
  final Color primaryColor;
  final Color secondaryColor;

  @override
  Widget build(BuildContext context) {
    final puzzle = controller.puzzle;

    return LayoutBuilder(
      builder: (context, constraints) {
        const double outerPadding = 7.0;
        const double outerBorder = 1.5;
        const double gap = 2.6;
        final inset = (outerPadding + outerBorder) * 2 + 1.0;
        final availW = math.max(120.0, constraints.maxWidth - inset);
        final availH = math.max(120.0, constraints.maxHeight - inset);

        final maxCellW = (availW - gap * (puzzle.cols - 1)) / puzzle.cols;
        final maxCellH = (availH - gap * (puzzle.rows - 1)) / puzzle.rows;
        final cellSize = math.min(maxCellW, maxCellH).clamp(26.0, 66.0);

        final gridW = cellSize * puzzle.cols + gap * (puzzle.cols - 1);
        final gridH = cellSize * puzzle.rows + gap * (puzzle.rows - 1);

        return Center(
          child: Container(
            padding: const EdgeInsets.all(outerPadding),
            decoration: BoxDecoration(
              // Belirgin, yüksek kontrastlı kare arası çizgiler için koyu tahta zemini
              color: const Color(0xFF14110F),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.14),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 20,
                  offset: const Offset(0, 9),
                ),
              ],
            ),
            child: SizedBox(
              width: gridW,
              height: gridH,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(puzzle.rows, (r) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: r == puzzle.rows - 1 ? 0 : gap),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(puzzle.cols, (c) {
                        return Padding(
                          padding: EdgeInsets.only(right: c == puzzle.cols - 1 ? 0 : gap),
                          child: _buildCell(r, c, cellSize),
                        );
                      }),
                    ),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCell(int r, int c, double size) {
    final puzzle = controller.puzzle;
    final active = puzzle.isActiveCell(r, c);
    final radius = (size * 0.14).clamp(4.5, 9.0);

    if (!active) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFF282320),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: const Color(0xFF1C1816),
            width: 1.0,
          ),
        ),
      );
    }

    final isSelected =
        controller.selectedCell.row == r && controller.selectedCell.col == c;
    final inWord = controller.isInActiveEntry(r, c);
    final locked = controller.isLocked(r, c);
    final wrong = controller.isWrong(r, c);
    final inSolvedWord = controller.isCellInSolvedEntry(r, c);
    final letter = controller.letterAt(r, c) ?? '';
    final number = puzzle.numberAt(r, c);

    final recentId = controller.recentSolvedEntryId;
    final isFlashing = recentId != null &&
        ((puzzle.entryAt(r, c, controller.direction)?.id == recentId) ||
            (puzzle.entryAt(r, c, controller.direction.opposite)?.id == recentId));

    // Yüksek kontrastlı belirgin kare çizgileri
    Color bgColor = Colors.white;
    Color textColor = const Color(0xFF181512);
    Color borderColor = const Color(0xFF9C948C);
    double borderWidth = 1.6;

    if (isFlashing) {
      bgColor = const Color(0xFFBBF7D0);
      borderColor = const Color(0xFF15803D);
      textColor = const Color(0xFF14532D);
      borderWidth = 2.4;
    } else if (wrong) {
      bgColor = const Color(0xFFFEE2E2);
      borderColor = const Color(0xFFDC2626);
      textColor = const Color(0xFFB91C1C);
      borderWidth = 2.2;
    } else if (isSelected) {
      bgColor = primaryColor;
      borderColor = const Color(0xFFFDE68A);
      textColor = Colors.white;
      borderWidth = 2.5;
    } else if (inWord) {
      bgColor = Color.alphaBlend(
        primaryColor.withValues(alpha: 0.17),
        Colors.white,
      );
      borderColor = primaryColor.withValues(alpha: 0.78);
      borderWidth = 1.8;
    } else if (inSolvedWord) {
      bgColor = const Color(0xFFF0FDF4);
      borderColor = const Color(0xFF16A34A).withValues(alpha: 0.65);
      textColor = const Color(0xFF166534);
      borderWidth = 1.6;
    } else if (locked) {
      bgColor = const Color(0xFFFEF3C7);
      borderColor = const Color(0xFFD97706).withValues(alpha: 0.85);
      borderWidth = 1.7;
    }

    if (locked && !isSelected && !wrong && !isFlashing && !inSolvedWord) {
      textColor = secondaryColor;
    }

    final numberFontSize = (size * 0.23).clamp(8.5, 13.0);
    final letterFontSize = (size * 0.51).clamp(15.0, 29.0);

    return GestureDetector(
      onTap: () => controller.selectCell(r, c),
      child: AnimatedScale(
        scale: isFlashing ? 1.09 : (isSelected ? 1.04 : 1.0),
        duration: const Duration(milliseconds: 190),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: isFlashing
                ? [
                    BoxShadow(
                      color: const Color(0xFF16A34A).withValues(alpha: 0.50),
                      blurRadius: 10,
                      spreadRadius: 1.0,
                    ),
                  ]
                : isSelected
                    ? [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.48),
                          blurRadius: 9,
                          spreadRadius: 0.6,
                        ),
                      ]
                    : null,
          ),
          child: Stack(
            children: [
              if (number != null)
                Positioned(
                  top: 2,
                  left: 3.5,
                  child: Text(
                    '$number',
                    style: TextStyle(
                      fontSize: numberFontSize,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.92)
                          : const Color(0xFF57534E),
                    ),
                  ),
                ),
              if (locked && !isSelected)
                Positioned(
                  top: 3,
                  right: 3,
                  child: Container(
                    width: (size * 0.11).clamp(4.0, 6.0),
                    height: (size * 0.11).clamp(4.0, 6.0),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              Center(
                child: Padding(
                  padding: EdgeInsets.only(top: number != null ? size * 0.08 : 0),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    switchInCurve: Curves.easeOutBack,
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: Tween<double>(begin: 0.65, end: 1.0).animate(anim),
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: Text(
                      letter,
                      key: ValueKey<String>('${r}_${c}_$letter'),
                      style: TextStyle(
                        fontSize: letterFontSize,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                        color: textColor,
                      ),
                    ),
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
