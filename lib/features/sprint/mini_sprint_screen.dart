import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../models/puzzle_models.dart';
import '../../state/app_state.dart';
import '../../state/game_controller.dart';
import '../../utils/turkish_text.dart';
import '../../widgets/background_canvas.dart';
import '../../widgets/clue_banner.dart';
import '../../widgets/confetti_overlay.dart';
import '../../widgets/crossword_grid.dart';
import '../../widgets/game_keyboard.dart';

/// 90 Saniyede ardışık 5×5 mini bulmaca çözme hız modu (Mini Sprint).
class MiniSprintScreen extends StatefulWidget {
  const MiniSprintScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<MiniSprintScreen> createState() => _MiniSprintScreenState();
}

class _MiniSprintScreenState extends State<MiniSprintScreen> {
  static const int _initialSeconds = 90;
  static const int _wordBonusSeconds = 5;
  static const int _boardBonusSeconds = 15;
  static const int _skipPenaltySeconds = 5;

  late List<SprintPuzzleItem> _deck;
  int _deckIndex = 0;
  GameController? _boardController;
  Timer? _countdownTimer;

  int _remainingSeconds = _initialSeconds;
  int _sprintScore = 0;
  int _sprintCoins = 0;
  int _puzzlesSolved = 0;
  int _wordsSolved = 0;
  int _currentCombo = 0;
  int _maxCombo = 0;
  bool _isFinished = false;
  String? _bonusFlashText;
  Timer? _bonusFlashTimer;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _startNewRun();
  }

  void _startNewRun() {
    _countdownTimer?.cancel();
    _bonusFlashTimer?.cancel();
    _boardController?.dispose();

    final bankItems = List<SprintPuzzleItem>.from(
      widget.appState.sprintBank?.items ?? const [],
    );
    // Ayrıca konsept paketlerinin 5×5 başlangıç bulmacalarını da havuza ekleyerek zenginleştir
    for (final pack in widget.appState.packs) {
      for (final lvl in pack.levels) {
        if (lvl.rows == 5 && lvl.cols == 5) {
          bankItems.add(
            SprintPuzzleItem(
              language: pack.language,
              primaryColor: pack.primaryColor,
              secondaryColor: pack.secondaryColor,
              surfaceColor: pack.surfaceColor,
              puzzle: lvl,
            ),
          );
        }
      }
    }
    bankItems.shuffle(math.Random());

    _deck = bankItems;
    _deckIndex = 0;
    _remainingSeconds = _initialSeconds;
    _sprintScore = 0;
    _sprintCoins = 0;
    _puzzlesSolved = 0;
    _wordsSolved = 0;
    _currentCombo = 0;
    _maxCombo = 0;
    _isFinished = false;
    _bonusFlashText = null;

    _loadCurrentBoard();
    _startCountdown();
  }

  void _loadCurrentBoard() {
    _boardController?.dispose();
    if (_deck.isEmpty) return;
    final item = _deck[_deckIndex % _deck.length];
    _boardController = GameController(
      puzzle: item.puzzle,
      storageKey: 'sprint_session_${_deckIndex}_${item.puzzle.id}',
      language: item.language,
      isDaily: false,
      appState: widget.appState,
      persistSession: false,
      enableInternalTimer: false,
      initialComboCount: _currentCombo,
      onWordSolved: (newCombo, coins, score) {
        if (!mounted || _isFinished) return;
        setState(() {
          _wordsSolved++;
          _currentCombo = newCombo;
          if (newCombo > _maxCombo) _maxCombo = newCombo;
          _sprintScore += score;
          _sprintCoins += coins;
          _remainingSeconds = (_remainingSeconds + _wordBonusSeconds).clamp(0, 180);
        });
        _showBonusFlash('+$_wordBonusSeconds sn • $newCombo× Kombo! +$score Puan');
      },
      onPuzzleCompleted: (_) {
        if (!mounted || _isFinished) return;
        setState(() {
          _puzzlesSolved++;
          _sprintScore += 100;
          _sprintCoins += 20;
          _remainingSeconds =
              (_remainingSeconds + _boardBonusSeconds).clamp(0, 180);
          _deckIndex++;
        });
        _showBonusFlash('Bölüm Bitti! +$_boardBonusSeconds sn • +100 Puan');
        Future<void>.delayed(const Duration(milliseconds: 350), () {
          if (!mounted || _isFinished) return;
          setState(_loadCurrentBoard);
        });
      },
    );
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _isFinished) return;
      if (_remainingSeconds <= 1) {
        setState(() {
          _remainingSeconds = 0;
          _isFinished = true;
        });
        _countdownTimer?.cancel();
        _finishSprint();
      } else {
        setState(() {
          _remainingSeconds--;
        });
        if (_remainingSeconds <= 12) {
          widget.appState.feedback.sprintTick();
        }
      }
    });
  }

  Future<void> _finishSprint() async {
    widget.appState.feedback.puzzleSolved();
    final isNewRecord = await widget.appState.recordSprintResult(
      sprintScore: _sprintScore,
      puzzlesSolved: _puzzlesSolved,
      coinsBonus: _sprintCoins,
      maxCombo: _maxCombo,
    );
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dCtx) => Dialog(
        backgroundColor: AppPalette.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppPalette.hairline),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                decoration: BoxDecoration(
                  color: AppPalette.brassSoft,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppPalette.brassBorder),
                ),
                child: Text(
                  isNewRecord && _sprintScore > 0
                      ? 'YENİ SPRINT REKORU'
                      : 'Süre Doldu • Mini Sprint',
                  style: const TextStyle(
                    color: AppPalette.brass,
                    fontWeight: FontWeight.w900,
                    fontSize: 11.5,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$_sprintScore Puan',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: AppPalette.ink,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _SprintStat(
                      value: '$_puzzlesSolved',
                      label: 'Bulmaca',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SprintStat(
                      value: '$_maxCombo×',
                      label: 'En İyi Kombo',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SprintStat(
                      value: '+$_sprintCoins',
                      label: 'Altın',
                      highlight: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '$_wordsSolved kelime çözüldü • Rekorun: ${widget.appState.bestSprintScore} Puan',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppPalette.inkMuted,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(dCtx).pop();
                    setState(_startNewRun);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppPalette.ink,
                    foregroundColor: AppPalette.brassBright,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Tekrar Yarış (90 sn)',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(dCtx).pop();
                    Navigator.of(context).pop();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Ana Menüye Dön',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _skipCurrentBoard() {
    if (_isFinished || _deck.isEmpty) return;
    widget.appState.feedback.errorPulse();
    setState(() {
      _currentCombo = 0;
      _remainingSeconds = math.max(1, _remainingSeconds - _skipPenaltySeconds);
      _deckIndex++;
      _loadCurrentBoard();
    });
    _showBonusFlash('Pas geçildi (-$_skipPenaltySeconds sn)');
  }

  void _showBonusFlash(String text) {
    _bonusFlashTimer?.cancel();
    setState(() => _bonusFlashText = text);
    _bonusFlashTimer = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() => _bonusFlashText = null);
    });
  }

  void _onPhysicalKey(KeyEvent event) {
    if (event is! KeyDownEvent || _isFinished) return;
    final ctrl = _boardController;
    if (ctrl == null) return;
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      ctrl.backspace();
    } else if (event.logicalKey == LogicalKeyboardKey.space) {
      ctrl.toggleDirection();
    } else if (event.character != null && event.character!.isNotEmpty) {
      ctrl.inputLetter(event.character!);
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _bonusFlashTimer?.cancel();
    _boardController?.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _boardController;
    if (ctrl == null || _deck.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Mini Sprint bulmacası yüklenemedi.')),
      );
    }

    final currentItem = _deck[_deckIndex % _deck.length];
    final activeBg = widget.appState.selectedBackground;
    final isDark = activeBg.isDark;
    final lowTime = _remainingSeconds <= 15;

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _onPhysicalKey,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
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
                  child: ListenableBuilder(
                    listenable: Listenable.merge([ctrl, widget.appState]),
                    builder: (context, _) {
                      return Column(
                        children: [
                          // Sprint HUD Üst Barı
                          Container(
                            padding: const EdgeInsets.fromLTRB(4, 6, 10, 6),
                            color: isDark
                                ? AppPalette.ink.withValues(alpha: 0.90)
                                : AppPalette.card.withValues(alpha: 0.96),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 21,
                                  ),
                                  color: isDark ? Colors.white : AppPalette.ink,
                                  tooltip: 'Çık',
                                  visualDensity: VisualDensity.compact,
                                ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 11,
                                    vertical: 5.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: lowTime
                                        ? AppPalette.error
                                        : AppPalette.ink,
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  child: Text(
                                    TurkishText.formatDuration(
                                      _remainingSeconds,
                                    ),
                                    style: TextStyle(
                                      color: lowTime
                                          ? Colors.white
                                          : AppPalette.brassBright,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13.5,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '$_sprintScore P',
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w900,
                                          color: isDark
                                              ? Colors.white
                                              : AppPalette.ink,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _currentCombo >= 2
                                              ? AppPalette.brassSoft
                                              : AppPalette.cardMuted,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: _currentCombo >= 2
                                                ? AppPalette.brassBorder
                                                : AppPalette.hairline,
                                          ),
                                        ),
                                        child: Text(
                                          '${math.max(1, _currentCombo)}×',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w900,
                                            color: _currentCombo >= 2
                                                ? AppPalette.brass
                                                : AppPalette.inkSoft,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: _skipCurrentBoard,
                                  style: TextButton.styleFrom(
                                    foregroundColor: isDark
                                        ? Colors.white70
                                        : AppPalette.inkSoft,
                                    backgroundColor: isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : AppPalette.cardMuted,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    minimumSize: Size.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                  ),
                                  child: const Text(
                                    'Pas (-5s)',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Kalan süre çubuğu
                          LinearProgressIndicator(
                            value: (_remainingSeconds / _initialSeconds)
                                .clamp(0.0, 1.0),
                            minHeight: 3.5,
                            backgroundColor: isDark
                                ? Colors.white12
                                : AppPalette.hairline,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              lowTime ? AppPalette.error : AppPalette.brass,
                            ),
                          ),
                          Expanded(
                            child: Stack(
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(12, 10, 12, 8),
                                  child: CrosswordGrid(
                                    controller: ctrl,
                                    primaryColor: AppPalette.brass,
                                    secondaryColor: AppPalette.ink,
                                  ),
                                ),
                                if (_bonusFlashText != null)
                                  Positioned(
                                    top: 8,
                                    left: 0,
                                    right: 0,
                                    child: IgnorePointer(
                                      child: Center(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 7,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppPalette.correct,
                                            borderRadius:
                                                BorderRadius.circular(18),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.2),
                                                blurRadius: 8,
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            _bonusFlashText!,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w900,
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
                            entry: ctrl.activeEntry,
                            primaryColor: AppPalette.brass,
                            onPrevious: ctrl.previousClue,
                            onNext: ctrl.nextClue,
                            onOpenAllClues: () => showAllCluesSheet(
                              context: context,
                              controller: ctrl,
                              primaryColor: AppPalette.brass,
                            ),
                          ),
                          const SizedBox(height: 6),
                          GameKeyboard(
                            language: currentItem.language,
                            primaryColor: AppPalette.brass,
                            activeDirection: ctrl.direction,
                            isDark: isDark,
                            onLetter: ctrl.inputLetter,
                            onBackspace: ctrl.backspace,
                            onClearWord: ctrl.clearActiveWordEditableCells,
                            onToggleDirection: ctrl.toggleDirection,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              ConfettiOverlay(active: _isFinished && _puzzlesSolved > 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _SprintStat extends StatelessWidget {
  const _SprintStat({
    required this.value,
    required this.label,
    this.highlight = false,
  });

  final String value;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
      decoration: BoxDecoration(
        color: AppPalette.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight ? AppPalette.brassBorder : AppPalette.hairline,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: highlight ? AppPalette.brass : AppPalette.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppPalette.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}
