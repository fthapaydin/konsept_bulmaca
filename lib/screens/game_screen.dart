import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import '../models/puzzle_models.dart';
import '../state/app_state.dart';
import '../state/game_controller.dart';
import '../utils/turkish_text.dart';
import '../widgets/clue_banner.dart';
import '../widgets/completion_dialog.dart';
import '../widgets/crossword_grid.dart';
import '../widgets/game_keyboard.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.puzzle,
    required this.storageKey,
    required this.language,
    required this.packTitle,
    required this.primaryColor,
    required this.secondaryColor,
    required this.surfaceColor,
    required this.isDaily,
    required this.appState,
    this.pack,
    this.levelIndex,
  });

  final CrosswordPuzzle puzzle;
  final String storageKey;
  final String language;
  final String packTitle;
  final Color primaryColor;
  final Color secondaryColor;
  final Color surfaceColor;
  final bool isDaily;
  final AppState appState;
  final ConceptPack? pack;
  final int? levelIndex;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final GameController _controller;
  final FocusNode _focusNode = FocusNode();

  bool get _hasNextLevel =>
      widget.pack != null &&
      widget.levelIndex != null &&
      widget.levelIndex! + 1 < widget.pack!.levels.length;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = GameController(
      puzzle: widget.puzzle,
      storageKey: widget.storageKey,
      language: widget.language,
      isDaily: widget.isDaily,
      appState: widget.appState,
      onPuzzleCompleted: _handlePuzzleCompleted,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _controller.pauseTimer();
    } else if (state == AppLifecycleState.resumed) {
      _controller.resumeTimer();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.pauseTimer();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handlePuzzleCompleted(CompletionReward reward) {
    if (!mounted) return;
    Future<void>.delayed(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dCtx) => CompletionDialog(
          title: widget.isDaily
              ? 'Günün Bulmacası'
              : '${widget.packTitle} • Seviye ${widget.puzzle.level}',
          wordCount: widget.puzzle.entries.length,
          reward: reward,
          primaryColor: widget.primaryColor,
          hasNextLevel: _hasNextLevel,
          onNextLevel: () {
            Navigator.of(dCtx).pop();
            final nextIdx = widget.levelIndex! + 1;
            final nextPuzzle = widget.pack!.levels[nextIdx];
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => GameScreen(
                  puzzle: nextPuzzle,
                  storageKey: nextPuzzle.id,
                  language: widget.language,
                  packTitle: widget.packTitle,
                  primaryColor: widget.primaryColor,
                  secondaryColor: widget.secondaryColor,
                  surfaceColor: widget.surfaceColor,
                  isDaily: false,
                  appState: widget.appState,
                  pack: widget.pack,
                  levelIndex: nextIdx,
                ),
              ),
            );
          },
          onBackToMap: () {
            Navigator.of(dCtx).pop();
            Navigator.of(context).pop();
          },
        ),
      );
    });
  }

  void _showHintFeedback(HintFeedback fb) {
    if (!mounted) return;
    final bg = fb.status == HintStatus.insufficientCoins
        ? const Color(0xFFDC2626)
        : fb.status == HintStatus.nothingToDo
            ? const Color(0xFF44403C)
            : widget.secondaryColor;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            fb.message,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          backgroundColor: bg,
          duration: const Duration(milliseconds: 1800),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  void _onPhysicalKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      _controller.backspace();
      return;
    }
    if (event.logicalKey == LogicalKeyboardKey.tab) {
      _controller.nextClue();
      return;
    }
    if (event.logicalKey == LogicalKeyboardKey.space) {
      _controller.toggleDirection();
      return;
    }
    final char = event.character;
    if (char != null && char.isNotEmpty) {
      _controller.inputLetter(char);
    }
  }

  Future<void> _confirmReset() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bulmacayı Temizle?'),
        content: const Text(
          'Yazdığın harfler ve süre sıfırlanacak. Emin misin?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: widget.primaryColor),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Temizle'),
          ),
        ],
      ),
    );
    if (yes == true) {
      await _controller.resetBoard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _onPhysicalKey,
      child: Scaffold(
        backgroundColor: widget.surfaceColor,
        body: SafeArea(
          child: ListenableBuilder(
            listenable: Listenable.merge([_controller, widget.appState]),
            builder: (context, _) {
              return Column(
                children: [
                  _buildTopBar(),
                  LinearProgressIndicator(
                    value: _controller.completionProgress,
                    minHeight: 3.5,
                    backgroundColor: widget.primaryColor.withValues(alpha: 0.14),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.primaryColor,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                      child: CrosswordGrid(
                        controller: _controller,
                        primaryColor: widget.primaryColor,
                        secondaryColor: widget.secondaryColor,
                      ),
                    ),
                  ),
                  ClueBanner(
                    entry: _controller.activeEntry,
                    primaryColor: widget.primaryColor,
                    onPrevious: _controller.previousClue,
                    onNext: _controller.nextClue,
                    onOpenAllClues: () => showAllCluesSheet(
                      context: context,
                      controller: _controller,
                      primaryColor: widget.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildJokerBar(),
                  const SizedBox(height: 6),
                  GameKeyboard(
                    language: widget.language,
                    primaryColor: widget.primaryColor,
                    onLetter: _controller.inputLetter,
                    onBackspace: _controller.backspace,
                    onToggleDirection: _controller.toggleDirection,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final subtitle = widget.isDaily
        ? '${widget.puzzle.gridSizeLabel} • 2× Altın'
        : 'Sv. ${widget.puzzle.level} • ${widget.puzzle.title} (${widget.puzzle.gridSizeLabel})';

    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 10, 6),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: const Color(0xFF1C1917),
            tooltip: 'Geri',
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.packTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: widget.secondaryColor,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF78716C),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F4),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.timer_outlined,
                  size: 14,
                  color: Color(0xFF57534E),
                ),
                const SizedBox(width: 4),
                Text(
                  TurkishText.formatDuration(_controller.elapsedSeconds),
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    fontFeatures: [FontFeature.tabularFigures()],
                    color: Color(0xFF292524),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.monetization_on_rounded,
                  size: 15,
                  color: Color(0xFFD97706),
                ),
                const SizedBox(width: 3),
                Text(
                  '${widget.appState.coins}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF92400E),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _confirmReset,
            icon: const Icon(Icons.refresh_rounded, size: 21),
            color: const Color(0xFF57534E),
            tooltip: 'Temizle',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildJokerBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: _JokerButton(
              icon: Icons.lightbulb_outline_rounded,
              label: 'Harf Aç',
              cost: '${AppState.letterHintCost}',
              color: widget.primaryColor,
              onTap: () async {
                final fb = await _controller.revealSelectedCell();
                _showHintFeedback(fb);
              },
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _JokerButton(
              icon: Icons.auto_awesome_rounded,
              label: 'Kelime',
              cost: '${AppState.wordHintCost}',
              color: widget.secondaryColor,
              onTap: () async {
                final fb = await _controller.revealActiveWord();
                _showHintFeedback(fb);
              },
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _JokerButton(
              icon: Icons.fact_check_outlined,
              label: 'Kontrol',
              cost: '${AppState.checkMistakesCost}',
              color: const Color(0xFF0F766E),
              onTap: () async {
                final fb = await _controller.checkMistakes();
                _showHintFeedback(fb);
              },
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _JokerButton(
              icon: Icons.list_alt_rounded,
              label:
                  '${_controller.solvedWordsCount}/${widget.puzzle.entries.length}',
              cost: null,
              color: const Color(0xFF44403C),
              onTap: () => showAllCluesSheet(
                context: context,
                controller: _controller,
                primaryColor: widget.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JokerButton extends StatelessWidget {
  const _JokerButton({
    required this.icon,
    required this.label,
    required this.cost,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String? cost;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
              if (cost != null) ...[
                const SizedBox(width: 3),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    cost!,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
