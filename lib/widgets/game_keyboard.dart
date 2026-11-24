import 'package:material_ui/material_ui.dart';

class GameKeyboard extends StatelessWidget {
  const GameKeyboard({
    super.key,
    required this.language,
    required this.primaryColor,
    required this.onLetter,
    required this.onBackspace,
    required this.onToggleDirection,
    this.isDark = false,
  });

  final String language;
  final Color primaryColor;
  final ValueChanged<String> onLetter;
  final VoidCallback onBackspace;
  final VoidCallback onToggleDirection;
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

    return Container(
      padding: const EdgeInsets.fromLTRB(5, 8, 5, 8),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF141418).withValues(alpha: 0.94)
            : const Color(0xFFE7E5E4),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white12 : const Color(0xFFD6D3D1),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLetterRow(row1),
          const SizedBox(height: 6),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isEn ? 14 : 0),
            child: _buildLetterRow(row2),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _ActionKey(
                flex: 15,
                backgroundColor: isDark
                    ? primaryColor.withValues(alpha: 0.28)
                    : primaryColor.withValues(alpha: 0.14),
                foregroundColor: isDark ? Colors.white : primaryColor,
                icon: Icons.swap_horiz_rounded,
                tooltip: 'Yön Değiştir',
                onTap: onToggleDirection,
              ),
              ...row3.map(
                (ch) => _LetterKey(
                  letter: ch,
                  isDark: isDark,
                  onTap: () => onLetter(ch),
                ),
              ),
              _ActionKey(
                flex: 16,
                backgroundColor: isDark
                    ? const Color(0xFF3F3F46)
                    : const Color(0xFFD6D3D1),
                foregroundColor: isDark ? Colors.white : const Color(0xFF292524),
                icon: Icons.backspace_outlined,
                tooltip: 'Sil',
                onTap: onBackspace,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLetterRow(List<String> keys) {
    return Row(
      children: keys
          .map(
            (ch) => _LetterKey(
              letter: ch,
              isDark: isDark,
              onTap: () => onLetter(ch),
            ),
          )
          .toList(),
    );
  }
}

class _LetterKey extends StatelessWidget {
  const _LetterKey({
    required this.letter,
    required this.isDark,
    required this.onTap,
  });

  final String letter;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 10,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.2),
        child: Material(
          color: isDark ? const Color(0xFF27272A) : Colors.white,
          elevation: 1.2,
          shadowColor: Colors.black26,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: Container(
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? const Color(0xFF09090B)
                        : const Color(0xFFD6D3D1),
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                letter,
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1C1917),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionKey extends StatelessWidget {
  const _ActionKey({
    required this.flex,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final int flex;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.2),
        child: Tooltip(
          message: tooltip,
          child: Material(
            color: backgroundColor,
            elevation: 1,
            shadowColor: Colors.black26,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onTap,
              child: SizedBox(
                height: 44,
                child: Icon(icon, size: 21, color: foregroundColor),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
