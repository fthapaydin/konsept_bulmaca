import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEDD5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isNewRecord && _sprintScore > 0
                      ? 'YENİ SPRINT REKORU!'
                      : 'Süre Doldu • Mini Sprint',
                  style: const TextStyle(
                    color: Color(0xFF9A3412),
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '$_sprintScore Puan',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1C1917),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _SprintStat(
                      icon: Icons.grid_view_rounded,
                      color: const Color(0xFFEA580C),
                      value: '$_puzzlesSolved',
                      label: 'Bulmaca',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SprintStat(
                      icon: Icons.whatshot_rounded,
                      color: const Color(0xFFBE123C),
                      value: '$_maxCombo×',
                      label: 'En İyi Kombo',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SprintStat(
                      icon: Icons.monetization_on_rounded,
                      color: const Color(0xFFD97706),
                      value: '+$_sprintCoins',
                      label: 'Altın',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '$_wordsSolved kelime çözüldü • Rekorun: ${widget.appState.bestSprintScore} Puan',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF78716C),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(dCtx).pop();
                    setState(_startNewRun);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFEA580C),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.bolt_rounded),
                  label: const Text(
                    'Tekrar Yarış (90 sn)',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
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
                      borderRadius: BorderRadius.circular(14),
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
                conceptSurfaceColor: currentItem.surfaceColor,
                conceptPrimaryColor: currentItem.primaryColor,
                child: SafeArea(
                  child: ListenableBuilder(
                    listenable: Listenable.merge([ctrl, widget.appState]),
                    builder: (context, _) {
                      return Column(
                        children: [
                          // Sprint HUD Üst Barı
                          Container(
                            padding: const EdgeInsets.fromLTRB(4, 6, 8, 6),
                            color: isDark
                                ? const Color(0xFF141418)
                                    .withValues(alpha: 0.88)
                                : Colors.white.withValues(alpha: 0.95),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 22,
                                  ),
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1C1917),
                                  tooltip: 'Çık',
                                  visualDensity: VisualDensity.compact,
                                ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 11,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: lowTime
                                        ? const Color(0xFFDC2626)
                                        : const Color(0xFFEA580C),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.timer_rounded,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        TurkishText.formatDuration(
                                          _remainingSeconds,
                                        ),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14,
                                          fontFeatures: [
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.bolt_rounded,
                                        size: 16,
                                        color: Color(0xFF7C3AED),
                                      ),
                                      Text(
                                        '$_sprintScore',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF1C1917),
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
                                              ? const Color(0xFFBE123C)
                                              : const Color(0xFFE7E5E4),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '${math.max(1, _currentCombo)}×',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w900,
                                            color: _currentCombo >= 2
                                                ? Colors.white
                                                : const Color(0xFF44403C),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: _skipCurrentBoard,
                                  style: TextButton.styleFrom(
                                    foregroundColor: isDark
                                        ? Colors.white70
                                        : const Color(0xFF57534E),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    minimumSize: Size.zero,
                                  ),
                                  icon: const Icon(
                                    Icons.skip_next_rounded,
                                    size: 18,
                                  ),
                                  label: const Text(
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
                            minHeight: 4,
                            backgroundColor: isDark
                                ? Colors.white12
                                : const Color(0xFFFED7AA),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              lowTime
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFFEA580C),
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
                                    primaryColor: currentItem.primaryColor,
                                    secondaryColor: currentItem.secondaryColor,
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
                                            color: const Color(0xFF15803D),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.25),
                                                blurRadius: 10,
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
                            primaryColor: currentItem.primaryColor,
                            onPrevious: ctrl.previousClue,
                            onNext: ctrl.nextClue,
                            onOpenAllClues: () => showAllCluesSheet(
                              context: context,
                              controller: ctrl,
                              primaryColor: currentItem.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          GameKeyboard(
                            language: currentItem.language,
                            primaryColor: currentItem.primaryColor,
                            isDark: isDark,
                            onLetter: ctrl.inputLetter,
                            onBackspace: ctrl.backspace,
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
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7E5E4)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF78716C),
            ),
          ),
        ],
      ),
    );
  }
}
