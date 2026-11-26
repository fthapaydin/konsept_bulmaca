import 'package:material_ui/material_ui.dart';
import '../core/theme/app_theme.dart';
import '../models/puzzle_models.dart';

class GameKeyboard extends StatelessWidget {
  const GameKeyboard({
    super.key,
    required this.language,
    required this.primaryColor,
    required this.onLetter,
    required this.onBackspace,
    required this.onToggleDirection,
    this.onClearWord,
    this.activeDirection,
    this.isDark = false,
  });

  final String language;
  final Color primaryColor;
  final ValueChanged<String> onLetter;
  final VoidCallback onBackspace;
  final VoidCallback onToggleDirection;
  final VoidCallback? onClearWord;
  final WordDirection? activeDirection;
  final bool isDark;

  static const List<String> _trRow1 = [
    'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', 'Ğ', 'Ü',
  ];
  static const List<String> _trRow2 = [
    'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'Ş', 'İ',
  ];
  static const List<String> _trRow3 = [
    'Z', 'C', 'V', 'B', 'N', 'M', 'Ö', 'Ç',
  ];

  static const List<String> _enRow1 = [
    'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P',
  ];
  static const List<String> _enRow2 = [
    'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L',
  ];
  static const List<String> _enRow3 = [
    'Z', 'X', 'C', 'V', 'B', 'N', 'M',
  ];

  @override
  Widget build(BuildContext context) {
    final isEn = language == 'en';
    final row1 = isEn ? _enRow1 : _trRow1;
    final row2 = isEn ? _enRow2 : _trRow2;
    final row3 = isEn ? _enRow3 : _trRow3;
    final maxCols = isEn ? 10 : 11;

    final screenH = MediaQuery.of(context).size.height;
    final keyHeight = screenH < 700 ? 43.0 : (screenH > 950 ? 52.0 : 47.0);
    final rowGap = screenH < 700 ? 6.0 : 7.5;

    final trayBg = isDark
        ? const Color(0xFF151210).withValues(alpha: 0.96)
        : const Color(0xFFEBE4D6);
    final trayBorder = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : const Color(0xFFD8CEBC);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(6, 9, 6, 10),
      decoration: BoxDecoration(
        color: trayBg,
        border: Border(top: BorderSide(color: trayBorder, width: 1.0)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const double hGap = 4.2;
          // Tüm 3 satırdaki harf tuşları alt piksele kadar eşit genişlikte hesaplanır
          final double availW = constraints.maxWidth;
          final double unitW = (availW - hGap * (maxCols - 1)) / maxCols;
          final double row3LettersW =
              row3.length * unitW + (row3.length - 1) * hGap;
          final double actionW =
              ((availW - row3LettersW - hGap * 2) / 2).clamp(unitW, unitW * 1.9);

          final directionIcon = activeDirection == WordDirection.down
              ? Icons.swap_vert_rounded
              : Icons.swap_horiz_rounded;
          final directionLabel = activeDirection == WordDirection.down
              ? 'DİK'
              : 'YAT';

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCenteredLetterRow(
                keys: row1,
                keyWidth: unitW,
                keyHeight: keyHeight,
                gap: hGap,
              ),
              SizedBox(height: rowGap),
              _buildCenteredLetterRow(
                keys: row2,
                keyWidth: unitW,
                keyHeight: keyHeight,
                gap: hGap,
              ),
              SizedBox(height: rowGap),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ActionKey(
                    width: actionW,
                    height: keyHeight,
                    backgroundColor: isDark
                        ? const Color(0xFF33291F)
                        : const Color(0xFFF7ECD9),
                    pressedColor: isDark
                        ? AppPalette.brass
                        : const Color(0xFFEFD9B6),
                    borderColor: isDark
                        ? AppPalette.brassBright.withValues(alpha: 0.35)
                        : const Color(0xFFDDC296),
                    bottomLipColor: isDark
                        ? const Color(0xFF1A140F)
                        : const Color(0xFFCDB081),
                    foregroundColor:
                        isDark ? AppPalette.brassBright : AppPalette.brass,
                    icon: directionIcon,
                    subLabel: activeDirection != null ? directionLabel : null,
                    tooltip: 'Yön Değiştir (Yatay / Dikey)',
                    onTap: onToggleDirection,
                  ),
                  const SizedBox(width: hGap),
                  for (var i = 0; i < row3.length; i++) ...[
                    _LetterKey(
                      letter: row3[i],
                      width: unitW,
                      height: keyHeight,
                      isDark: isDark,
                      onTap: () => onLetter(row3[i]),
                    ),
                    if (i < row3.length - 1) const SizedBox(width: hGap),
                  ],
                  const SizedBox(width: hGap),
                  _ActionKey(
                    width: actionW,
                    height: keyHeight,
                    backgroundColor: isDark
                        ? const Color(0xFF39322C)
                        : AppPalette.ink,
                    pressedColor: isDark
                        ? const Color(0xFF52473E)
                        : const Color(0xFF3A322C),
                    borderColor: isDark
                        ? Colors.white.withValues(alpha: 0.14)
                        : const Color(0xFF2D2723),
                    bottomLipColor: isDark
                        ? const Color(0xFF0E0C0B)
                        : const Color(0xFF0A0807),
                    foregroundColor: const Color(0xFFFFFDF9),
                    icon: Icons.backspace_outlined,
                    tooltip: 'Sil (Uzun bas: kelimeyi temizle)',
                    onTap: onBackspace,
                    onLongPress: onClearWord,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCenteredLetterRow({
    required List<String> keys,
    required double keyWidth,
    required double keyHeight,
    required double gap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < keys.length; i++) ...[
          _LetterKey(
            letter: keys[i],
            width: keyWidth,
            height: keyHeight,
            isDark: isDark,
            onTap: () => onLetter(keys[i]),
          ),
          if (i < keys.length - 1) SizedBox(width: gap),
        ],
      ],
    );
  }
}

class _LetterKey extends StatefulWidget {
  const _LetterKey({
    required this.letter,
    required this.width,
    required this.height,
    required this.isDark,
    required this.onTap,
  });

  final String letter;
  final double width;
  final double height;
  final bool isDark;
  final VoidCallback onTap;

  @override
  State<_LetterKey> createState() => _LetterKeyState();
}

class _LetterKeyState extends State<_LetterKey> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) {
      setState(() => _pressed = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = _pressed
        ? (widget.isDark ? AppPalette.brass : const Color(0xFFFBF2E2))
        : (widget.isDark ? const Color(0xFF2A2521) : const Color(0xFFFFFDF9));

    final borderCol = _pressed
        ? (widget.isDark ? AppPalette.brassBright : AppPalette.brass)
        : (widget.isDark
            ? Colors.white.withValues(alpha: 0.08)
            : const Color(0xFFDDD3C2));

    final lipCol = widget.isDark
        ? const Color(0xFF0E0C0A)
        : const Color(0xFFC5B9A4);

    final textCol = _pressed
        ? (widget.isDark ? Colors.white : AppPalette.brass)
        : (widget.isDark ? const Color(0xFFF6F2EA) : AppPalette.ink);

    final fontSize = (widget.width * 0.52).clamp(15.5, 19.0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) {
        _setPressed(false);
        widget.onTap();
      },
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 70),
        curve: Curves.easeOut,
        child: Container(
          width: widget.width,
          height: widget.height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: borderCol, width: _pressed ? 1.2 : 0.8),
            boxShadow: _pressed
                ? null
                : [
                    BoxShadow(
                      color: lipCol,
                      offset: const Offset(0, 2.0),
                      blurRadius: 0,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: widget.isDark ? 0.28 : 0.06,
                      ),
                      offset: const Offset(0, 3),
                      blurRadius: 4,
                    ),
                  ],
          ),
          child: Text(
            widget.letter,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: textCol,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionKey extends StatefulWidget {
  const _ActionKey({
    required this.width,
    required this.height,
    required this.backgroundColor,
    required this.pressedColor,
    required this.borderColor,
    required this.bottomLipColor,
    required this.foregroundColor,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.subLabel,
    this.onLongPress,
  });

  final double width;
  final double height;
  final Color backgroundColor;
  final Color pressedColor;
  final Color borderColor;
  final Color bottomLipColor;
  final Color foregroundColor;
  final IconData icon;
  final String? subLabel;
  final String tooltip;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  State<_ActionKey> createState() => _ActionKeyState();
}

class _ActionKeyState extends State<_ActionKey> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) {
      setState(() => _pressed = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) {
          _setPressed(false);
          widget.onTap();
        },
        onTapCancel: () => _setPressed(false),
        onLongPress: widget.onLongPress == null
            ? null
            : () {
                _setPressed(false);
                widget.onLongPress!();
              },
        child: AnimatedScale(
          scale: _pressed ? 0.93 : 1.0,
          duration: const Duration(milliseconds: 70),
          curve: Curves.easeOut,
          child: Container(
            width: widget.width,
            height: widget.height,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _pressed ? widget.pressedColor : widget.backgroundColor,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: widget.borderColor, width: 0.9),
              boxShadow: _pressed
                  ? null
                  : [
                      BoxShadow(
                        color: widget.bottomLipColor,
                        offset: const Offset(0, 2.0),
                        blurRadius: 0,
                      ),
                    ],
            ),
            child: widget.subLabel != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(widget.icon, size: 17, color: widget.foregroundColor),
                      Text(
                        widget.subLabel!,
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                          height: 1.0,
                          color: widget.foregroundColor,
                        ),
                      ),
                    ],
                  )
                : Icon(widget.icon, size: 20, color: widget.foregroundColor),
          ),
        ),
      ),
    );
  }
}
