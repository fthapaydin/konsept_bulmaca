import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import '../core/theme/app_theme.dart';
import '../models/puzzle_models.dart';
import '../state/app_state.dart';
import '../state/game_controller.dart';
import '../utils/turkish_text.dart';
import '../widgets/background_canvas.dart';
import '../widgets/clue_banner.dart';
import '../widgets/completion_dialog.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/crossword_grid.dart';
import '../widgets/game_keyboard.dart';
import '../widgets/rewards_center_sheet.dart';
import 'background_gallery_screen.dart';

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
    this.rewardMultiplier = 1,
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
  final int rewardMultiplier;
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
      rewardMultiplier: widget.rewardMultiplier,
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
    _controller.pauseTimer(silent: true);
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
          onApplyBackground: (bg) async {
            await widget.appState.selectBackground(bg.id);
            if (mounted) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text('${bg.name} arka planı uygulandı!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
            }
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
      child: ListenableBuilder(
        listenable: Listenable.merge([_controller, widget.appState]),
        builder: (context, _) {
          final activeBg = widget.appState.selectedBackground;
          final isDark = activeBg.isDark;

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: isDark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Stack(
                fit: StackFit.expand,
                children: [
                  BackgroundCanvas(
                    background: activeBg,
                    conceptSurfaceColor: widget.surfaceColor,
                    conceptPrimaryColor: widget.primaryColor,
                    child: SafeArea(
                      child: Column(
                        children: [
                          _buildTopBar(isDark: isDark),
                          LinearProgressIndicator(
                            value: _controller.completionProgress,
                            minHeight: 3.5,
                            backgroundColor: isDark
                                ? Colors.white12
                                : widget.primaryColor.withValues(alpha: 0.14),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDark
                                  ? activeBg.accentColor
                                  : widget.primaryColor,
                            ),
                          ),
                          if (_controller.wordComboCount >= 1)
                            _buildComboStrip(isDark: isDark),
                          Expanded(
                            child: Stack(
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(12, 10, 12, 8),
                                  child: CrosswordGrid(
                                    controller: _controller,
                                    primaryColor: widget.primaryColor,
                                    secondaryColor: widget.secondaryColor,
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  left: 0,
                                  right: 0,
                                  child: IgnorePointer(
                                    child: Center(
                                      child: AnimatedSwitcher(
                                        duration:
                                            const Duration(milliseconds: 220),
                                        transitionBuilder: (child, anim) =>
                                            ScaleTransition(
                                          scale: CurvedAnimation(
                                            parent: anim,
                                            curve: Curves.easeOutBack,
                                          ),
                                          child: FadeTransition(
                                            opacity: anim,
                                            child: child,
                                          ),
                                        ),
                                        child: _controller.activeErrorBanner !=
                                                null
                                            ? Container(
                                                key: ValueKey<String>(
                                                  'err_${_controller.activeErrorBanner!}',
                                                ),
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 18,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 13,
                                                  vertical: 7,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppPalette.error,
                                                  borderRadius:
                                                      BorderRadius.circular(18),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withValues(
                                                              alpha: 0.25),
                                                      blurRadius: 10,
                                                      offset:
                                                          const Offset(0, 4),
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons
                                                          .error_outline_rounded,
                                                      size: 16,
                                                      color: Colors.white,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Flexible(
                                                      child: Text(
                                                        _controller
                                                            .activeErrorBanner!,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : _controller.recentSolvedBanner ==
                                                    null
                                                ? const SizedBox.shrink()
                                                : Container(
                                                    key: ValueKey<String>(
                                                      _controller
                                                          .recentSolvedBanner!,
                                                    ),
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 14,
                                                      vertical: 7,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: AppPalette.correct,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withValues(
                                                                  alpha: 0.25),
                                                          blurRadius: 10,
                                                          offset: const Offset(
                                                              0, 4),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        const Icon(
                                                          Icons
                                                              .check_circle_outline_rounded,
                                                          size: 16,
                                                          color: Color(
                                                              0xFFFDE047),
                                                        ),
                                                        const SizedBox(
                                                            width: 6),
                                                        Text(
                                                          _controller
                                                              .recentSolvedBanner!,
                                                          style:
                                                              const TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.w900,
                                                            fontSize: 12.5,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
                            isDark: isDark,
                            onLetter: _controller.inputLetter,
                            onBackspace: _controller.backspace,
                            onToggleDirection: _controller.toggleDirection,
                          ),
                        ],
                      ),
                    ),
                  ),
                  ConfettiOverlay(active: _controller.isCompleted),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopBar({required bool isDark}) {
    final subtitle = widget.isDaily
        ? '${widget.puzzle.gridSizeLabel} • 2× Altın'
        : 'Sv. ${widget.puzzle.level} • ${widget.puzzle.title} (${widget.puzzle.gridSizeLabel})';

    return Container(
      padding: const EdgeInsets.fromLTRB(4, 6, 6, 6),
      color: isDark
          ? const Color(0xFF141418).withValues(alpha: 0.85)
          : Colors.white.withValues(alpha: 0.94),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: isDark ? Colors.white : const Color(0xFF1C1917),
            tooltip: 'Geri',
            visualDensity: VisualDensity.compact,
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
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : widget.secondaryColor,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF78716C),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : const Color(0xFFF5F5F4),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 13.5,
                  color: isDark ? Colors.white70 : const Color(0xFF57534E),
                ),
                const SizedBox(width: 3),
                Text(
                  TurkishText.formatDuration(_controller.elapsedSeconds),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: isDark ? Colors.white : const Color(0xFF292524),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          InkWell(
            onTap: () => showRewardsCenterSheet(
              context,
              widget.appState,
              initialTab: 1,
            ),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.monetization_on_rounded,
                    size: 14.5,
                    color: Color(0xFFD97706),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${widget.appState.coins}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      BackgroundGalleryScreen(appState: widget.appState),
                ),
              );
            },
            icon: const Icon(Icons.palette_outlined, size: 20),
            color: isDark ? Colors.white70 : const Color(0xFF57534E),
            tooltip: 'Arka Planlar',
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            onPressed: _confirmReset,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            color: isDark ? Colors.white70 : const Color(0xFF57534E),
            tooltip: 'Temizle',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildComboStrip({required bool isDark}) {
    final combo = _controller.wordComboCount;
    final next = _controller.nextComboReward;
    final bgColor = combo >= 4
        ? const Color(0xFFBE123C)
        : combo >= 2
            ? const Color(0xFFEA580C)
            : const Color(0xFF15803D);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      color: bgColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            combo >= 2
                ? Icons.whatshot_rounded
                : Icons.auto_awesome_rounded,
            size: 15,
            color: const Color(0xFFFDE047),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              combo >= 2
                  ? '$combo× KOMBO! Sonraki doğru kelime: +${next.coins} Altın & +${next.score} Puan'
                  : '1. Kelime Doğru! 2× Kombo için sıradakini ipucusuz bil (+${next.coins} Altın)',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJokerBar() {
    final letterTickets = widget.appState.letterHintTickets;
    final wordTickets = widget.appState.wordHintTickets;
    final checkTickets = widget.appState.checkHintTickets;
    final hasWrong = _controller.hasWrongCompletedWord;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Expanded(
            child: _JokerButton(
              icon: Icons.lightbulb_outline_rounded,
              label: 'Harf',
              cost: letterTickets > 0
                  ? '×$letterTickets'
                  : '${_controller.nextLetterHintCoins}',
              isTicketBadge: letterTickets > 0,
              color: AppPalette.ink,
              onTap: () async {
                final fb = await _controller.revealSelectedCell();
                _showHintFeedback(fb);
              },
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: _JokerButton(
              icon: Icons.auto_awesome_rounded,
              label: 'Kelime',
              cost: wordTickets > 0
                  ? '×$wordTickets'
                  : '${_controller.nextWordHintCoins}',
              isTicketBadge: wordTickets > 0,
              color: AppPalette.ink,
              onTap: () async {
                final fb = await _controller.revealActiveWord();
                _showHintFeedback(fb);
              },
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: _JokerButton(
              icon: Icons.fact_check_outlined,
              label: 'Kontrol',
              cost: checkTickets > 0
                  ? '×$checkTickets'
                  : '${_controller.nextCheckHintCoins}',
              isTicketBadge: checkTickets > 0,
              color: hasWrong ? AppPalette.error : AppPalette.ink,
              highlightBorder: hasWrong,
              onTap: () async {
                final fb = await _controller.checkMistakes();
                _showHintFeedback(fb);
              },
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: _JokerButton(
              icon: Icons.list_alt_rounded,
              label:
                  '${_controller.solvedWordsCount}/${widget.puzzle.entries.length}',
              cost: null,
              isTicketBadge: false,
              color: AppPalette.inkSoft,
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
    required this.isTicketBadge,
    required this.color,
    required this.onTap,
    this.highlightBorder = false,
  });

  final IconData icon;
  final String label;
  final String? cost;
  final bool isTicketBadge;
  final Color color;
  final VoidCallback onTap;
  final bool highlightBorder;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlightBorder ? AppPalette.errorSoft : AppPalette.card,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: highlightBorder ? AppPalette.errorBorder : AppPalette.hairline,
              width: highlightBorder ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
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
                    color: isTicketBadge
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    cost!,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      color: isTicketBadge
                          ? const Color(0xFF15803D)
                          : const Color(0xFF92400E),
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
