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
        ? AppPalette.error
        : fb.status == HintStatus.nothingToDo
            ? AppPalette.inkSoft
            : AppPalette.ink;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            fb.message,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppPalette.card,
            ),
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
                    conceptSurfaceColor: AppPalette.paper,
                    conceptPrimaryColor: AppPalette.brass,
                    child: SafeArea(
                      child: Column(
                        children: [
                          _buildTopBar(isDark: isDark),
                          LinearProgressIndicator(
                            value: _controller.completionProgress,
                            minHeight: 3.0,
                            backgroundColor: isDark
                                ? Colors.white12
                                : AppPalette.hairline,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDark ? AppPalette.brassBright : AppPalette.brass,
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
                                    primaryColor: AppPalette.brass,
                                    secondaryColor: AppPalette.ink,
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
                                                    child: Text(
                                                      _controller
                                                          .recentSolvedBanner!,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        fontSize: 12.5,
                                                      ),
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
                            primaryColor: AppPalette.brass,
                            onPrevious: _controller.previousClue,
                            onNext: _controller.nextClue,
                            onOpenAllClues: () => showAllCluesSheet(
                              context: context,
                              controller: _controller,
                              primaryColor: AppPalette.brass,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildJokerBar(),
                          const SizedBox(height: 6),
                          GameKeyboard(
                            language: widget.language,
                            primaryColor: AppPalette.brass,
                            activeDirection: _controller.direction,
                            isDark: isDark,
                            onLetter: _controller.inputLetter,
                            onBackspace: _controller.backspace,
                            onClearWord: _controller.clearActiveWordEditableCells,
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
          ? AppPalette.ink.withValues(alpha: 0.90)
          : AppPalette.card.withValues(alpha: 0.96),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
            color: isDark ? Colors.white : AppPalette.ink,
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
                    color: isDark ? Colors.white : AppPalette.ink,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : AppPalette.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : AppPalette.cardMuted,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: isDark ? Colors.white12 : AppPalette.hairline,
              ),
            ),
            child: Text(
              TurkishText.formatDuration(_controller.elapsedSeconds),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: isDark ? Colors.white : AppPalette.ink,
              ),
            ),
          ),
          const SizedBox(width: 5),
          InkWell(
            onTap: () => showRewardsCenterSheet(
              context,
              widget.appState,
              initialTab: 1,
            ),
            borderRadius: BorderRadius.circular(11),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : AppPalette.brassSoft,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: isDark
                      ? AppPalette.brassBright.withValues(alpha: 0.35)
                      : AppPalette.brassBorder,
                ),
              ),
              child: Text(
                '${widget.appState.coins} Altın',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  color: isDark ? AppPalette.brassBright : AppPalette.brass,
                ),
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
            icon: const Icon(Icons.palette_outlined, size: 19),
            color: isDark ? Colors.white70 : AppPalette.inkSoft,
            tooltip: 'Arka Planlar',
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            onPressed: _confirmReset,
            icon: const Icon(Icons.refresh_rounded, size: 19),
            color: isDark ? Colors.white70 : AppPalette.inkSoft,
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      color: AppPalette.ink,
      child: Text(
        combo >= 2
            ? '$combo× KOMBO • Sonraki doğru kelime: +${next.coins} Altın & +${next.score} Puan'
            : '1. Kelime Doğru • 2× Kombo için sıradakini ipucusuz bil (+${next.coins} Altın)',
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppPalette.brassBright,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  Widget _buildJokerBar() {
    final letterTickets = widget.appState.letterHintTickets;
    final wordTickets = widget.appState.wordHintTickets;
    final checkTickets = widget.appState.checkHintTickets;
    final hasWrong = _controller.hasWrongCompletedWord;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: _JokerButton(
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
          const SizedBox(width: 6),
          Expanded(
            child: _JokerButton(
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
          const SizedBox(width: 6),
          Expanded(
            child: _JokerButton(
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
          const SizedBox(width: 6),
          Expanded(
            child: _JokerButton(
              label: 'Sorular',
              cost: '${_controller.solvedWordsCount}/${widget.puzzle.entries.length}',
              isTicketBadge: false,
              isNeutralBadge: true,
              color: AppPalette.inkSoft,
              onTap: () => showAllCluesSheet(
                context: context,
                controller: _controller,
                primaryColor: AppPalette.brass,
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
    required this.label,
    required this.cost,
    required this.isTicketBadge,
    required this.color,
    required this.onTap,
    this.highlightBorder = false,
    this.isNeutralBadge = false,
  });

  final String label;
  final String? cost;
  final bool isTicketBadge;
  final Color color;
  final VoidCallback onTap;
  final bool highlightBorder;
  final bool isNeutralBadge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlightBorder ? AppPalette.errorSoft : AppPalette.card,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: highlightBorder
                  ? AppPalette.errorBorder
                  : AppPalette.hairline,
              width: highlightBorder ? 1.4 : 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4.5,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: isNeutralBadge
                        ? AppPalette.cardMuted
                        : isTicketBadge
                            ? AppPalette.correctSoft
                            : AppPalette.brassSoft,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    cost!,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      color: isNeutralBadge
                          ? AppPalette.inkSoft
                          : isTicketBadge
                              ? AppPalette.correct
                              : AppPalette.brass,
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
