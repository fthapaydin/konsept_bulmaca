import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';
import '../models/puzzle_models.dart';
import '../state/game_controller.dart';

class CrosswordGrid extends StatefulWidget {
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
  State<CrosswordGrid> createState() => _CrosswordGridState();
}

class _CrosswordGridState extends State<CrosswordGrid> {
  final TransformationController _transformController =
      TransformationController();
  CellCoord? _lastFocusedCell;
  Size _lastViewportSize = Size.zero;
  double _currentScale = 1.0;

  bool get _isLargeGrid =>
      widget.controller.puzzle.rows > 9 || widget.controller.puzzle.cols > 9;

  double get _largeCellSize {
    final dim = math.max(
      widget.controller.puzzle.rows,
      widget.controller.puzzle.cols,
    );
    if (dim >= 18) return 34.0;
    if (dim >= 14) return 36.0;
    return 38.0;
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant CrosswordGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
      _lastFocusedCell = null;
      _currentScale = 1.0;
      _transformController.value = Matrix4.identity();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _transformController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!_isLargeGrid || _lastViewportSize == Size.zero) return;
    final sel = widget.controller.selectedCell;
    if (sel != _lastFocusedCell) {
      _lastFocusedCell = sel;
      _focusCell(sel, scale: _currentScale);
    }
  }

  void _focusCell(CellCoord cell, {required double scale}) {
    final puzzle = widget.controller.puzzle;
    const outerPadding = 7.0;
    const gap = 2.6;
    final cellSize = _largeCellSize;

    final boardW =
        cellSize * puzzle.cols + gap * (puzzle.cols - 1) + outerPadding * 2;
    final boardH =
        cellSize * puzzle.rows + gap * (puzzle.rows - 1) + outerPadding * 2;

    final cellCenterX =
        outerPadding + cell.col * (cellSize + gap) + cellSize / 2;
    final cellCenterY =
        outerPadding + cell.row * (cellSize + gap) + cellSize / 2;

    final vw = _lastViewportSize.width;
    final vh = _lastViewportSize.height;

    final scaledW = boardW * scale;
    final scaledH = boardH * scale;

    double tx = vw / 2 - cellCenterX * scale;
    double ty = vh / 2 - cellCenterY * scale;

    if (scaledW <= vw) {
      tx = (vw - scaledW) / 2;
    } else {
      tx = tx.clamp(vw - scaledW - 12, 12.0);
    }

    if (scaledH <= vh) {
      ty = (vh - scaledH) / 2;
    } else {
      ty = ty.clamp(vh - scaledH - 12, 12.0);
    }

    _currentScale = scale;
    final m = Matrix4.identity();
    m.storage[0] = scale;
    m.storage[5] = scale;
    m.storage[12] = tx;
    m.storage[13] = ty;
    _transformController.value = m;
  }

  void _fitWholeBoard() {
    if (_lastViewportSize == Size.zero) return;
    final puzzle = widget.controller.puzzle;
    const outerPadding = 7.0;
    const gap = 2.6;
    final cellSize = _largeCellSize;
    final boardW =
        cellSize * puzzle.cols + gap * (puzzle.cols - 1) + outerPadding * 2;
    final boardH =
        cellSize * puzzle.rows + gap * (puzzle.rows - 1) + outerPadding * 2;

    final fitScale = math
        .min(
          (_lastViewportSize.width - 8) / boardW,
          (_lastViewportSize.height - 8) / boardH,
        )
        .clamp(0.42, 1.0);
    final tx = (_lastViewportSize.width - boardW * fitScale) / 2;
    final ty = (_lastViewportSize.height - boardH * fitScale) / 2;

    setState(() {
      _currentScale = fitScale;
      final m = Matrix4.identity();
      m.storage[0] = fitScale;
      m.storage[5] = fitScale;
      m.storage[12] = tx;
      m.storage[13] = ty;
      _transformController.value = m;
    });
  }

  void _adjustZoom(double delta) {
    final next = (_currentScale + delta).clamp(0.45, 1.6);
    setState(() {
      _focusCell(widget.controller.selectedCell, scale: next);
    });
  }

  @override
  Widget build(BuildContext context) {
    final puzzle = widget.controller.puzzle;

    return LayoutBuilder(
      builder: (context, constraints) {
        const double outerPadding = 7.0;
        const double outerBorder = 1.5;
        const double gap = 2.6;

        if (_isLargeGrid) {
          final vp = Size(constraints.maxWidth, constraints.maxHeight);
          if (_lastViewportSize != vp) {
            _lastViewportSize = vp;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _lastFocusedCell = widget.controller.selectedCell;
              _focusCell(widget.controller.selectedCell, scale: 1.0);
            });
          }

          final cellSize = _largeCellSize;
          final board = _buildBoardContainer(
            puzzle: puzzle,
            cellSize: cellSize,
            outerPadding: outerPadding,
            gap: gap,
          );

          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: InteractiveViewer(
                  transformationController: _transformController,
                  constrained: false,
                  minScale: 0.42,
                  maxScale: 1.75,
                  boundaryMargin: const EdgeInsets.all(60),
                  onInteractionEnd: (_) {
                    _currentScale =
                        _transformController.value.getMaxScaleOnAxis();
                  },
                  child: board,
                ),
              ),
              Positioned(
                right: 6,
                bottom: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF181512).withValues(alpha: 0.86),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ZoomChipButton(
                        icon: Icons.remove_rounded,
                        tooltip: 'Uzaklaştır',
                        onTap: () => _adjustZoom(-0.2),
                      ),
                      _ZoomChipButton(
                        icon: Icons.fit_screen_rounded,
                        tooltip: 'Tüm Tahtayı Gör',
                        onTap: _fitWholeBoard,
                      ),
                      _ZoomChipButton(
                        icon: Icons.my_location_rounded,
                        tooltip: 'Aktif Kelimeye Odaklan',
                        onTap: () => _focusCell(
                          widget.controller.selectedCell,
                          scale: 1.05,
                        ),
                      ),
                      _ZoomChipButton(
                        icon: Icons.add_rounded,
                        tooltip: 'Yakınlaştır',
                        onTap: () => _adjustZoom(0.2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        final inset = (outerPadding + outerBorder) * 2 + 1.0;
        final availW = math.max(120.0, constraints.maxWidth - inset);
        final availH = math.max(120.0, constraints.maxHeight - inset);

        final maxCellW = (availW - gap * (puzzle.cols - 1)) / puzzle.cols;
        final maxCellH = (availH - gap * (puzzle.rows - 1)) / puzzle.rows;
        final cellSize = math.min(maxCellW, maxCellH).clamp(26.0, 66.0);

        return Center(
          child: _buildBoardContainer(
            puzzle: puzzle,
            cellSize: cellSize,
            outerPadding: outerPadding,
            gap: gap,
          ),
        );
      },
    );
  }

  Widget _buildBoardContainer({
    required CrosswordPuzzle puzzle,
    required double cellSize,
    required double outerPadding,
    required double gap,
  }) {
    final gridW = cellSize * puzzle.cols + gap * (puzzle.cols - 1);
    final gridH = cellSize * puzzle.rows + gap * (puzzle.rows - 1);

    return Container(
      padding: EdgeInsets.all(outerPadding),
      decoration: BoxDecoration(
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
                    padding: EdgeInsets.only(
                      right: c == puzzle.cols - 1 ? 0 : gap,
                    ),
                    child: _buildCell(r, c, cellSize),
                  );
                }),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildCell(int r, int c, double size) {
    final controller = widget.controller;
    final puzzle = controller.puzzle;
    final active = puzzle.isActiveCell(r, c);
    final radius = (size * 0.14).clamp(4.0, 9.0);

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
      bgColor = widget.primaryColor;
      borderColor = const Color(0xFFFDE68A);
      textColor = Colors.white;
      borderWidth = 2.5;
    } else if (inWord) {
      bgColor = Color.alphaBlend(
        widget.primaryColor.withValues(alpha: 0.17),
        Colors.white,
      );
      borderColor = widget.primaryColor.withValues(alpha: 0.78);
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
      textColor = widget.secondaryColor;
    }

    final numberFontSize = (size * 0.23).clamp(7.5, 13.0);
    final letterFontSize = (size * 0.51).clamp(14.0, 29.0);

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
                          color: widget.primaryColor.withValues(alpha: 0.48),
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
                  top: 1.5,
                  left: 3,
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
                  top: 2.5,
                  right: 2.5,
                  child: Container(
                    width: (size * 0.11).clamp(3.8, 6.0),
                    height: (size * 0.11).clamp(3.8, 6.0),
                    decoration: BoxDecoration(
                      color: widget.primaryColor.withValues(alpha: 0.8),
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

class _ZoomChipButton extends StatelessWidget {
  const _ZoomChipButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 17, color: Colors.white),
        ),
      ),
    );
  }
}
