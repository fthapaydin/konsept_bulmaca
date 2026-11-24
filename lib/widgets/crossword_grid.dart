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
        const double outerPadding = 8.0;
        const double gap = 3.0;
        final availW = math.max(120.0, constraints.maxWidth - outerPadding * 2);
        final availH = math.max(120.0, constraints.maxHeight - outerPadding * 2);

        final maxCellW = (availW - gap * (puzzle.cols - 1)) / puzzle.cols;
        final maxCellH = (availH - gap * (puzzle.rows - 1)) / puzzle.rows;
        final cellSize = math.min(maxCellW, maxCellH).clamp(26.0, 66.0);

        final gridW = cellSize * puzzle.cols + gap * (puzzle.cols - 1);
        final gridH = cellSize * puzzle.rows + gap * (puzzle.rows - 1);

        return Center(
          child: Container(
            padding: const EdgeInsets.all(outerPadding),
            decoration: BoxDecoration(
              color: const Color(0xFF1F1C1A),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: secondaryColor.withValues(alpha: 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
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
    final radius = (size * 0.16).clamp(5.0, 10.0);

    if (!active) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFF2E2A27),
          borderRadius: BorderRadius.circular(radius),
        ),
      );
    }

    final isSelected =
        controller.selectedCell.row == r && controller.selectedCell.col == c;
    final inWord = controller.isInActiveEntry(r, c);
    final locked = controller.isLocked(r, c);
    final wrong = controller.isWrong(r, c);
    final letter = controller.letterAt(r, c) ?? '';
    final number = puzzle.numberAt(r, c);

    final recentId = controller.recentSolvedEntryId;
    final isFlashing = recentId != null &&
        ((puzzle.entryAt(r, c, controller.direction)?.id == recentId) ||
            (puzzle.entryAt(r, c, controller.direction.opposite)?.id == recentId));

    Color bgColor = const Color(0xFFFFFDF9);
    Color textColor = const Color(0xFF1C1917);
    Color borderColor = const Color(0xFFD6D3D1);
    double borderWidth = 1.0;

    if (isFlashing) {
      bgColor = const Color(0xFFDCFCE7);
      borderColor = const Color(0xFF16A34A);
      textColor = const Color(0xFF14532D);
      borderWidth = 1.8;
    } else if (wrong) {
      bgColor = const Color(0xFFFEE2E2);
      borderColor = const Color(0xFFDC2626);
      textColor = const Color(0xFFB91C1C);
      borderWidth = 1.8;
    } else if (isSelected) {
      bgColor = primaryColor;
      borderColor = Colors.white;
      textColor = Colors.white;
      borderWidth = 2.2;
    } else if (inWord) {
      bgColor = Color.alphaBlend(
        primaryColor.withValues(alpha: 0.16),
        const Color(0xFFFFFDF9),
      );
      borderColor = primaryColor.withValues(alpha: 0.55);
      borderWidth = 1.4;
    } else if (locked) {
      bgColor = const Color(0xFFFEF3C7);
      borderColor = const Color(0xFFF59E0B).withValues(alpha: 0.65);
    }

    if (locked && !isSelected && !wrong && !isFlashing) {
      textColor = secondaryColor;
    }

    final numberFontSize = (size * 0.22).clamp(8.5, 13.0);
    final letterFontSize = (size * 0.50).clamp(15.0, 28.0);

    return GestureDetector(
      onTap: () => controller.selectCell(r, c),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.45),
                    blurRadius: 8,
                    spreadRadius: 0.5,
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
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.9)
                        : const Color(0xFF78716C),
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
                    color: primaryColor.withValues(alpha: 0.75),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            Center(
              child: Padding(
                padding: EdgeInsets.only(top: number != null ? size * 0.08 : 0),
                child: Text(
                  letter,
                  style: TextStyle(
                    fontSize: letterFontSize,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                    color: textColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
