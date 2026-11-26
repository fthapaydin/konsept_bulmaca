import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:konsept_bulmaca/core/brand/brand_config.dart';
import 'package:konsept_bulmaca/core/economy/hint_pricing.dart';
import 'package:konsept_bulmaca/core/models/notebook_models.dart';
import 'package:konsept_bulmaca/core/models/profile_merger.dart';
import 'package:konsept_bulmaca/features/notebook/word_notebook_screen.dart';
import 'package:konsept_bulmaca/features/sprint/mini_sprint_screen.dart';
import 'package:konsept_bulmaca/main.dart';
import 'package:konsept_bulmaca/models/background_models.dart';
import 'package:konsept_bulmaca/models/puzzle_models.dart';
import 'package:konsept_bulmaca/models/retention_models.dart';
import 'package:konsept_bulmaca/services/auth_service.dart';
import 'package:konsept_bulmaca/services/cloud_sync_service.dart';
import 'package:konsept_bulmaca/services/feedback_service.dart';
import 'package:konsept_bulmaca/services/puzzle_repository.dart';
import 'package:konsept_bulmaca/state/app_state.dart';
import 'package:konsept_bulmaca/state/game_controller.dart';
import 'package:konsept_bulmaca/utils/turkish_text.dart';
import 'package:konsept_bulmaca/widgets/clue_banner.dart';
import 'package:konsept_bulmaca/widgets/game_keyboard.dart';

AppState _createSilentAppState({
  AuthService? authService,
  CloudSyncService? cloudSyncService,
}) =>
    AppState(
      feedback: FeedbackService(enableAudioEngine: false),
      authService: authService ?? const OfflineAuthService(),
      cloudSyncService: cloudSyncService ?? const NoOpCloudSyncService(),
    );

class _FakeAuthService implements AuthService {
  _FakeAuthService();

  AuthUserInfo? _user;
  bool shouldFailDelete = false;

  @override
  bool get isCloudAvailable => true;

  @override
  AuthUserInfo? get currentUser => _user;

  @override
  Future<void> initialize() async {}

  @override
  Future<AuthResult> signInWithGoogle() async {
    _user = const AuthUserInfo(
      uid: 'uid_test_1',
      displayName: 'Fatih Test',
      email: 'fatih@example.com',
    );
    return AuthResult(
      success: true,
      message: 'Google hesabın bağlandı!',
      user: _user,
    );
  }

  @override
  Future<void> signOut() async {
    _user = null;
  }

  @override
  Future<AuthResult> deleteCurrentUser() async {
    if (shouldFailDelete) {
      return const AuthResult(
        success: false,
        cancelled: true,
        message: 'Hesap silme doğrulaması iptal edildi.',
      );
    }
    _user = null;
    return const AuthResult(
      success: true,
      message: 'Hesap silindi.',
    );
  }
}

class _FakeCloudSyncService implements CloudSyncService {
  _FakeCloudSyncService({Map<String, PlayerProfile>? initial})
      : store = Map<String, PlayerProfile>.from(initial ?? const {});

  final Map<String, PlayerProfile> store;

  @override
  Future<PlayerProfile?> fetchProfile(String uid) async => store[uid];

  @override
  Future<bool> pushProfile(String uid, PlayerProfile profile) async {
    store[uid] = profile;
    return true;
  }

  @override
  Future<void> deleteCloudProfile(String uid) async {
    store.remove(uid);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TurkishText, ComboEconomy & HintPricingCurve', () {
    test('normalizes Turkish and English letters accurately', () {
      expect(TurkishText.normalizeLetter('i', language: 'tr'), 'İ');
      expect(TurkishText.normalizeLetter('ı', language: 'tr'), 'I');
      expect(TurkishText.normalizeLetter('ş', language: 'tr'), 'Ş');
      expect(TurkishText.normalizeLetter('ğ', language: 'tr'), 'Ğ');
      expect(TurkishText.normalizeLetter('w', language: 'tr'), '');

      expect(TurkishText.normalizeLetter('i', language: 'en'), 'I');
      expect(TurkishText.normalizeLetter('w', language: 'en'), 'W');
      expect(TurkishText.normalizeLetter('ş', language: 'en'), '');
    });

    test('combo rewards escalate exponentially at 2x, 3x, 4x+', () {
      final c1 = ComboEconomy.rewardFor(1);
      final c2 = ComboEconomy.rewardFor(2);
      final c3 = ComboEconomy.rewardFor(3);
      final c4 = ComboEconomy.rewardFor(4);
      final c5 = ComboEconomy.rewardFor(5);

      expect(c1.coins, 5);
      expect(c2.coins, 10);
      expect(c3.coins, 20);
      expect(c4.coins, 40);
      expect(c5.coins, greaterThan(c4.coins));
      expect(c4.score, greaterThan(c3.score));
      expect(c3.score, greaterThan(c2.score));
    });

    test('hint pricing escalates 10 -> 15 -> 25 -> 40 -> 60 and scales score 4x',
        () {
      expect(HintPricingCurve.coinCostFor(HintTicketType.letter, 0), 10);
      expect(HintPricingCurve.coinCostFor(HintTicketType.letter, 1), 15);
      expect(HintPricingCurve.coinCostFor(HintTicketType.letter, 2), 25);
      expect(HintPricingCurve.coinCostFor(HintTicketType.letter, 3), 40);
      expect(HintPricingCurve.coinCostFor(HintTicketType.letter, 4), 60);
      expect(HintPricingCurve.scoreCostFor(HintTicketType.letter, 1), 60);

      expect(HintPricingCurve.coinCostFor(HintTicketType.word, 0), 25);
      expect(HintPricingCurve.coinCostFor(HintTicketType.word, 1), 40);
      expect(HintPricingCurve.coinCostFor(HintTicketType.word, 2), 60);
    });
  });

  group('PuzzleRepository & Zero-Repeat Assets', () {
    test(
        'loads 117 puzzles (4x20 concept + 15 daily + 16 sprint + 6 mega) with ZERO word repeats per pack',
        () async {
      final repo = PuzzleRepository();
      final content = await repo.loadAll();

      expect(content.packs.length, 4);
      expect(content.dailyBank.puzzles.length, 15);
      expect(content.sprintBank.items.length, 16);
      expect(content.megaBank.items.length, 6);

      for (final pack in content.packs) {
        expect(pack.levels.length, 20, reason: '${pack.id} must have 20 levels');
        expect(pack.levels.first.rows, 5);
        expect(pack.levels.last.rows, 8);

        final seenAnswers = <String>{};
        for (final lvl in pack.levels) {
          for (final entry in lvl.entries) {
            expect(
              seenAnswers.add(entry.answer),
              isTrue,
              reason:
                  'Duplicate answer "${entry.answer}" found in pack ${pack.id} level ${lvl.level}',
            );
          }
        }
      }

      for (final item in content.sprintBank.items) {
        expect(item.puzzle.rows, 5);
        expect(item.puzzle.cols, 5);
      }

      final megaSizes =
          content.megaBank.items.map((i) => i.puzzle.rows).toSet();
      expect(megaSizes, containsAll([12, 15, 20]));
      expect(
        content.megaBank.items.last.puzzle.entries.length,
        greaterThanOrEqualTo(35),
      );
    });
  });

  group('GameController, Escalating Hints, Notebook & Mini Sprint', () {
    test(
        'awards escalating combo coins & score on consecutive solved words and unlocks next level',
        () async {
      final appState = _createSilentAppState();
      await appState.initialize();

      final yesilcam = appState.packs.firstWhere((p) => p.id == 'yesilcam');
      final lvl1 = yesilcam.levels.first;
      CompletionReward? receivedReward;
      final controller = GameController(
        puzzle: lvl1,
        storageKey: lvl1.id,
        language: yesilcam.language,
        isDaily: false,
        appState: appState,
        onPuzzleCompleted: (r) => receivedReward = r,
      );

      final startCoins = appState.coins;
      final startScore = appState.score;

      for (final entry in lvl1.entries) {
        if (controller.isCompleted) break;
        final chars = entry.answer.characters.toList();
        for (var i = 0; i < entry.cells.length; i++) {
          if (controller.isCompleted) break;
          final cell = entry.cells[i];
          if (controller.letterAt(cell.row, cell.col) != chars[i]) {
            controller.selectCell(cell.row, cell.col);
            await controller.inputLetter(chars[i]);
          }
        }
      }

      expect(controller.isCompleted, isTrue);
      expect(controller.maxComboInSession, greaterThanOrEqualTo(2));
      expect(controller.sessionComboCoins, greaterThan(10));
      expect(appState.score, greaterThan(startScore));
      expect(appState.coins, greaterThan(startCoins));
      expect(receivedReward, isNotNull);
      expect(receivedReward!.comboCoinsEarned, controller.sessionComboCoins);
      expect(receivedReward!.scoreEarned, greaterThan(100));
      expect(appState.isLevelUnlocked(yesilcam, 1), isTrue);

      controller.dispose();
      appState.dispose();
    });

    test(
        'escalates hint price 10 -> 15 -> 25 -> 40 after free ticket and falls back to Puan when coins run out',
        () async {
      final appState = _createSilentAppState();
      await appState.initialize();

      // Use Level 5 (6x6) so we have plenty of unrevealed cells for 4+ hints
      final lvl = appState.packs.first.levels[4];
      final controller = GameController(
        puzzle: lvl,
        storageKey: lvl.id,
        language: 'tr',
        isDaily: false,
        appState: appState,
      );

      expect(appState.letterHintTickets, 1);
      expect(controller.nextLetterHintCoins, 10);
      final coinsStart = appState.coins; // 120

      // 1) Free ticket used -> 0 coins spent, price stays 10
      final r0 = await controller.revealSelectedCell();
      expect(r0.status, HintStatus.ok);
      expect(appState.letterHintTickets, 0);
      expect(appState.coins, coinsStart);
      expect(controller.nextLetterHintCoins, 10);

      // 2) First paid hint -> 10 coins spent, next becomes 15
      final r1 = await controller.revealSelectedCell();
      expect(r1.status, HintStatus.ok);
      expect(appState.coins, coinsStart - 10);
      expect(controller.nextLetterHintCoins, 15);

      // 3) Second paid hint -> 15 coins spent, next becomes 25
      final r2 = await controller.revealSelectedCell();
      expect(r2.status, HintStatus.ok);
      expect(appState.coins, coinsStart - 25);
      expect(controller.nextLetterHintCoins, 25);

      // 4) Third paid hint -> 25 coins spent, next becomes 40
      final r3 = await controller.revealSelectedCell();
      expect(r3.status, HintStatus.ok);
      expect(appState.coins, coinsStart - 50);
      expect(controller.nextLetterHintCoins, 40);

      // Drain remaining coins and grant score to verify automatic Puan fallback!
      await appState.spendCoins(appState.coins);
      expect(appState.coins, 0);
      await appState.awardComboWord(
        comboCount: 3,
        coinsEarned: 0,
        scoreEarned: 200,
      );

      // 5) Fourth paid hint (40 coins = 160 Puan) -> paid automatically with Puan!
      final r4 = await controller.revealSelectedCell();
      expect(r4.status, HintStatus.ok);
      expect(appState.score, 40);
      expect(controller.nextLetterHintCoins, 60);

      controller.dispose();
      appState.dispose();
    });

    test(
        'automatically records solved English words into Word Notebook and saves Mini Sprint records',
        () async {
      final appState = _createSilentAppState();
      await appState.initialize();

      final ingilizce = appState.packs.firstWhere((p) => p.id == 'ingilizce');
      final lvl1 = ingilizce.levels.first;
      final controller = GameController(
        puzzle: lvl1,
        storageKey: lvl1.id,
        language: 'en',
        isDaily: false,
        appState: appState,
      );

      expect(appState.learnedEnglishCount, 0);

      for (final entry in lvl1.entries) {
        if (controller.isCompleted) break;
        final chars = entry.answer.characters.toList();
        for (var i = 0; i < entry.cells.length; i++) {
          if (controller.isCompleted) break;
          final cell = entry.cells[i];
          if (controller.letterAt(cell.row, cell.col) != chars[i]) {
            controller.selectCell(cell.row, cell.col);
            await controller.inputLetter(chars[i]);
          }
        }
      }

      expect(controller.isCompleted, isTrue);
      expect(appState.learnedEnglishCount, lvl1.entries.length);

      final firstWord = appState.learnedEnglishWords.first;
      expect(firstWord.meaning, isNotEmpty);
      expect(firstWord.isFavorite, isFalse);

      await appState.toggleWordFavorite(firstWord.word);
      final updated = appState.learnedEnglishWords
          .firstWhere((w) => w.word == firstWord.word);
      expect(updated.isFavorite, isTrue);

      // Mini Sprint record persistence
      final isRecord = await appState.recordSprintResult(
        sprintScore: 360,
        puzzlesSolved: 3,
        coinsBonus: 45,
        maxCombo: 5,
      );
      expect(isRecord, isTrue);
      expect(appState.bestSprintScore, 360);
      expect(appState.bestSprintPuzzles, 3);
      expect(appState.bestCombo, greaterThanOrEqualTo(5));

      controller.dispose();
      appState.dispose();
    });

    test(
        'detects completed wrong words immediately and pinpoints exact wrong cells on Kontrol',
        () async {
      final appState = _createSilentAppState();
      await appState.initialize();

      final lvl1 = appState.packs.first.levels.first;
      final controller = GameController(
        puzzle: lvl1,
        storageKey: lvl1.id,
        language: 'tr',
        isDaily: false,
        appState: appState,
      );

      final entry = lvl1.orderedEntries.first;
      final chars = entry.answer.characters.toList();
      CellCoord? sabotagedCell;

      // Fill entry with 1 deliberate wrong letter on an unlocked cell
      for (var i = 0; i < entry.cells.length; i++) {
        final cell = entry.cells[i];
        if (controller.isLocked(cell.row, cell.col)) continue;
        controller.selectCell(cell.row, cell.col);
        if (sabotagedCell == null) {
          sabotagedCell = cell;
          final wrongChar = chars[i] == 'Z' ? 'M' : 'Z';
          await controller.inputLetter(wrongChar);
        } else {
          await controller.inputLetter(chars[i]);
        }
      }

      expect(sabotagedCell, isNotNull);
      expect(controller.hasWrongCompletedWord, isTrue);
      expect(
        controller.isCellInWrongEntry(sabotagedCell!.row, sabotagedCell.col),
        isTrue,
      );
      expect(controller.activeErrorBanner, isNotNull);

      // Run Kontrol -> pinpoints ONLY the exact wrong letter!
      final checkRes = await controller.checkMistakes();
      expect(checkRes.status, HintStatus.ok);
      expect(controller.wrongMarkedCellCount, 1);
      expect(
        controller.isWrong(sabotagedCell.row, sabotagedCell.col),
        isTrue,
      );

      // Fix the wrong letter -> clears error and solves word!
      final rightIdx = entry.indexOfCell(sabotagedCell.row, sabotagedCell.col);
      controller.selectCell(sabotagedCell.row, sabotagedCell.col);
      await controller.inputLetter(chars[rightIdx]);
      expect(controller.isWrong(sabotagedCell.row, sabotagedCell.col), isFalse);
      expect(controller.isEntrySolved(entry), isTrue);

      controller.dispose();
      appState.dispose();
    });

    test(
        'protects solved crossing word letters from backspace, overwrite, and word clear',
        () async {
      final appState = _createSilentAppState();
      await appState.initialize();

      // Use Level 5 (6x6) and find an across/down crossing pair where across has editable cells too
      final puzzle = appState.packs.first.levels[4];
      final controller = GameController(
        puzzle: puzzle,
        storageKey: 'test_protect_${puzzle.id}',
        language: 'tr',
        isDaily: false,
        appState: appState,
        persistSession: false,
      );

      PuzzleEntry? targetAcross;
      PuzzleEntry? solvedDown;
      CellCoord? intersection;

      outer:
      for (final a in puzzle.acrossEntries) {
        for (final d in puzzle.downEntries) {
          for (final cell in a.cells) {
            if (d.containsCell(cell.row, cell.col) &&
                !puzzle.isInitialRevealed(cell.row, cell.col)) {
              targetAcross = a;
              solvedDown = d;
              intersection = cell;
              break outer;
            }
          }
        }
      }

      expect(targetAcross, isNotNull);
      expect(solvedDown, isNotNull);
      expect(intersection, isNotNull);

      // 1) Solve the crossing down word completely so it becomes green/protected
      final downChars = solvedDown!.answer.characters.toList();
      for (var i = 0; i < solvedDown.cells.length; i++) {
        final c = solvedDown.cells[i];
        if (!controller.isCellProtected(c.row, c.col)) {
          controller.selectCell(c.row, c.col);
          await controller.inputLetter(downChars[i]);
        }
      }
      expect(controller.isEntrySolved(solvedDown), isTrue);
      expect(
        controller.isCellProtected(intersection!.row, intersection.col),
        isTrue,
      );
      final protectedChar = controller.letterAt(intersection.row, intersection.col)!;

      // 2) Switch to targetAcross and fill editable cells with wrong letters
      controller.selectEntry(targetAcross!);
      for (final c in targetAcross.cells) {
        if (!controller.isCellProtected(c.row, c.col)) {
          controller.selectCell(c.row, c.col);
          await controller.inputLetter('Z');
        }
      }
      // Try typing directly on the protected intersection cell -> must NOT overwrite it!
      controller.selectCell(intersection.row, intersection.col);
      await controller.inputLetter(protectedChar == 'M' ? 'K' : 'M');
      expect(
        controller.letterAt(intersection.row, intersection.col),
        protectedChar,
      );

      // 3) Repeatedly press backspace from the last cell of targetAcross
      final lastCell = targetAcross.cells.last;
      controller.selectCell(lastCell.row, lastCell.col);
      for (var k = 0; k < targetAcross.cells.length + 2; k++) {
        controller.backspace();
      }

      // Solved crossing letter MUST still be intact and down word MUST remain solved!
      expect(
        controller.letterAt(intersection.row, intersection.col),
        protectedChar,
      );
      expect(controller.isEntrySolved(solvedDown), isTrue);

      // 4) Refill wrong letters and test long-press clearActiveWordEditableCells()
      for (final c in targetAcross.cells) {
        if (!controller.isCellProtected(c.row, c.col)) {
          controller.selectCell(c.row, c.col);
          await controller.inputLetter('Z');
        }
      }
      controller.selectEntry(targetAcross);
      controller.clearActiveWordEditableCells();
      expect(
        controller.letterAt(intersection.row, intersection.col),
        protectedChar,
      );
      for (final c in targetAcross.cells) {
        if (!controller.isCellProtected(c.row, c.col)) {
          expect(controller.letterAt(c.row, c.col), isNull);
        }
      }

      controller.dispose();
      appState.dispose();
    });

    test('buys bundles, unlocks backgrounds & mega puzzles with Puan', () async {
      final appState = _createSilentAppState();
      await appState.initialize();

      await appState.awardComboWord(
        comboCount: 4,
        coinsEarned: 40,
        scoreEarned: 1000,
      );

      final letterBundle = ShopCatalog.all.first;
      final buyRes = await appState.buyShopBundle(letterBundle, useScore: true);
      expect(buyRes.success, isTrue);
      expect(appState.letterHintTickets, 1 + letterBundle.quantity);

      final yesilcamBg = BackgroundCatalog.byId('yesilcam_sinema');
      final bgRes = await appState.unlockBackgroundWithScore(yesilcamBg);
      expect(bgRes.success, isTrue);
      expect(appState.isBackgroundUnlocked(yesilcamBg), isTrue);

      final firstMega = appState.megaBank!.items.first;
      expect(appState.isMegaUnlocked(firstMega), isFalse);
      final megaRes = await appState.unlockMegaEarly(firstMega, useScore: true);
      expect(megaRes.success, isTrue);
      expect(appState.isMegaUnlocked(firstMega), isTrue);

      appState.dispose();
    });

    test('daily puzzle completion increments streak and doubles coins', () async {
      final appState = _createSilentAppState();
      await appState.initialize();
      final daily = appState.todayDailyPuzzle!;

      CompletionReward? reward;
      final controller = GameController(
        puzzle: daily,
        storageKey: appState.todayDailyStorageKey,
        language: 'tr',
        isDaily: true,
        appState: appState,
        onPuzzleCompleted: (r) => reward = r,
      );

      for (var r = 0; r < daily.rows; r++) {
        for (var c = 0; c < daily.cols; c++) {
          if (controller.isCompleted) break;
          final sol = daily.solutionAt(r, c);
          if (sol != null && controller.letterAt(r, c) != sol) {
            controller.selectCell(r, c);
            await controller.inputLetter(sol);
          }
        }
      }

      expect(controller.isCompleted, isTrue);
      expect(appState.isTodayDailyCompleted, isTrue);
      expect(appState.dailyStreak, 1);
      expect(reward!.stars, 3);
      expect(reward!.coinsEarned, 80);
      expect(reward!.newDailyStreak, 1);

      controller.dispose();
      appState.dispose();
    });
  });

  group('Widget Flow Smoke Tests', () {
    testWidgets('opens Background Gallery (10 themes) and switches cleanly',
        (tester) async {
      tester.view.physicalSize = const Size(412, 892);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final appState = _createSilentAppState();
      await tester.runAsync(() => appState.initialize());

      await tester.pumpWidget(KonseptBulmacaApp(appState: appState));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Arka Planlar'));
      await tester.pumpAndSettle();

      expect(find.text('Arka Plan Galerisi'), findsOneWidget);
      expect(find.text('Gece Yarısı'), findsOneWidget);

      await tester.tap(find.text('Gece Yarısı'));
      await tester.pumpAndSettle();
      expect(appState.selectedBackground.id, 'gece_yarisi');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      appState.dispose();
    });

    testWidgets(
        'renders eKare Bulmaca Home, launches Mini Sprint, Word Notebook, and Yeşilçam Level 1',
        (tester) async {
      tester.view.physicalSize = const Size(412, 892);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final appState = _createSilentAppState();
      await tester.runAsync(() => appState.initialize());

      // Pre-populate a few English words so Word Notebook renders filled cards
      final enLvl1 = appState.packs
          .firstWhere((p) => p.id == 'ingilizce')
          .levels
          .first;
      await tester.runAsync(
        () => appState.recordLearnedEnglishWords(enLvl1.entries),
      );

      await tester.pumpWidget(KonseptBulmacaApp(appState: appState));
      await tester.pumpAndSettle();

      expect(find.text(BrandConfig.appName), findsOneWidget);
      expect(find.text('Mini Sprint'), findsOneWidget);
      expect(find.text('Kelime Defteri'), findsOneWidget);
      expect(find.text('Yeşilçam Klasikleri'), findsOneWidget);

      // 0) Open Stats & Settings sheet and verify Guest Mode + FatalSoft Inc. contact email
      await tester.tap(find.byTooltip('İstatistikler ve Ayarlar'));
      await tester.pumpAndSettle();
      expect(find.text('Misafir Modu'), findsOneWidget);
      expect(find.text('Google ile Bağla & Yedekle'), findsOneWidget);
      expect(find.text(BrandConfig.contactEmail), findsOneWidget);
      expect(find.text('Geliştirici: ${BrandConfig.developerName}'), findsOneWidget);
      await tester.tap(find.byTooltip('Kapat'));
      await tester.pumpAndSettle();

      // 1) Launch Word Notebook + Flashcard review dialog
      await tester.tap(find.text('Kelime Defteri'));
      await tester.pumpAndSettle();
      expect(find.byType(WordNotebookScreen), findsOneWidget);
      expect(find.text('Tekrar Et'), findsOneWidget);
      await tester.tap(find.text('Tekrar Et'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Geri'));
      await tester.pumpAndSettle();

      // 2) Launch 90s Mini Sprint
      await tester.tap(find.text('Mini Sprint'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(MiniSprintScreen), findsOneWidget);
      expect(find.byType(GameKeyboard), findsOneWidget);
      await tester.tap(find.byTooltip('Çık'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // 3) Launch Yeşilçam Level 1 with Turkish keyboard
      await tester.tap(find.text('Yeşilçam Klasikleri'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('İlk Perde'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final keyboard = find.byType(GameKeyboard);
      expect(keyboard, findsOneWidget);
      expect(
        find.descendant(of: keyboard, matching: find.text('Ğ')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: keyboard, matching: find.text('Ş')),
        findsOneWidget,
      );

      await tester.tap(find.descendant(of: keyboard, matching: find.text('A')));
      await tester.pump();

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      appState.dispose();
    });

    testWidgets(
        'showAllCluesSheet opens directly on active clue direction tab and scrolls active clue into view',
        (tester) async {
      tester.view.physicalSize = const Size(412, 892);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final appState = _createSilentAppState();
      await tester.runAsync(() => appState.initialize());

      // Pick a 15x15 Mega puzzle so there are many across & down clues
      final mega15 = appState.megaBank!.items[3].puzzle;
      final controller = GameController(
        puzzle: mega15,
        storageKey: 'test_clues_sheet_${mega15.id}',
        language: 'tr',
        isDaily: false,
        appState: appState,
        persistSession: false,
      );

      // Select a late DOWN clue (near the bottom of the down list!)
      final lateDown = mega15.downEntries[mega15.downEntries.length - 2];
      controller.selectEntry(lateDown);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => Center(
                child: ElevatedButton(
                  onPressed: () => showAllCluesSheet(
                    context: ctx,
                    controller: controller,
                    primaryColor: const Color(0xFFA85513),
                  ),
                  child: const Text('Aç'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();

      // Active clue badge must be immediately visible inside the viewport!
      final activeBadge = find.text('AKTİF • ${lateDown.number} DİKEY');
      expect(activeBadge, findsOneWidget);
      final badgeRect = tester.getRect(activeBadge);
      expect(badgeRect.top, greaterThanOrEqualTo(0));
      expect(badgeRect.bottom, lessThanOrEqualTo(892));

      controller.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      appState.dispose();
    });
  });

  group('Optional Google Sign-In, ProfileMerger & Cloud Sync', () {
    test('ProfileMerger preserves highest metrics, word notebook union, and best puzzle states',
        () {
      const local = PlayerProfile(
        coins: 240,
        score: 500,
        bestCombo: 4,
        bestSprintScore: 310,
        bestSprintPuzzles: 3,
        dailyStreak: 2,
        lastDailyDate: '2026-11-24',
        completedDailyDates: {'2026-11-23', '2026-11-24'},
        soundEnabled: false,
        selectedBackgroundId: 'gece_yarisi',
        unlockedBackgroundIds: {'klasik_kagit', 'gece_yarisi'},
        unlockedMegaIds: {'mega_1'},
        claimedMissionIds: {'m_1'},
        learnedEnglishWords: {
          'APPLE': LearnedWord(
            word: 'APPLE',
            meaning: 'Elma',
            cefrLevel: 'A1',
            timesSolved: 3,
            isFavorite: true,
            firstLearnedIso: '2026-11-20T10:00:00',
          ),
          'LOCAL': LearnedWord(
            word: 'LOCAL',
            meaning: 'Yerel',
            cefrLevel: 'A2',
            timesSolved: 1,
            firstLearnedIso: '2026-11-24T10:00:00',
          ),
        },
        puzzleStates: {
          'y_1': PuzzleSaveState(
            puzzleId: 'y_1',
            completed: true,
            stars: 2,
            bestTimeSeconds: 70,
          ),
          'y_2': PuzzleSaveState(
            puzzleId: 'y_2',
            completed: false,
            letters: {'0,0': 'A', '0,1': 'B', '0,2': 'C'},
          ),
        },
      );

      const cloud = PlayerProfile(
        coins: 180,
        score: 920,
        bestCombo: 6,
        bestSprintScore: 480,
        bestSprintPuzzles: 5,
        dailyStreak: 5,
        lastDailyDate: '2026-11-25',
        completedDailyDates: {'2026-11-25'},
        soundEnabled: true,
        selectedBackgroundId: 'osmanli_cini',
        unlockedBackgroundIds: {'klasik_kagit', 'osmanli_cini'},
        unlockedMegaIds: {'mega_2'},
        claimedMissionIds: {'m_2'},
        learnedEnglishWords: {
          'APPLE': LearnedWord(
            word: 'APPLE',
            meaning: 'Elma',
            cefrLevel: 'A1',
            timesSolved: 5,
            isFavorite: false,
            firstLearnedIso: '2026-11-18T09:00:00',
          ),
          'CLOUD': LearnedWord(
            word: 'CLOUD',
            meaning: 'Bulut',
            cefrLevel: 'A1',
            timesSolved: 2,
            firstLearnedIso: '2026-11-19T09:00:00',
          ),
        },
        puzzleStates: {
          'y_1': PuzzleSaveState(
            puzzleId: 'y_1',
            completed: true,
            stars: 3,
            bestTimeSeconds: 54,
          ),
          'y_2': PuzzleSaveState(
            puzzleId: 'y_2',
            completed: false,
            letters: {'0,0': 'A'},
          ),
          'y_3': PuzzleSaveState(
            puzzleId: 'y_3',
            completed: true,
            stars: 3,
            bestTimeSeconds: 61,
          ),
        },
      );

      final merged = ProfileMerger.merge(local: local, cloud: cloud);
      expect(merged.coins, 240);
      expect(merged.score, 920);
      expect(merged.bestCombo, 6);
      expect(merged.bestSprintScore, 480);
      expect(merged.bestSprintPuzzles, 5);
      expect(merged.dailyStreak, 5);
      expect(merged.lastDailyDate, '2026-11-25');
      expect(merged.completedDailyDates, {'2026-11-23', '2026-11-24', '2026-11-25'});
      expect(merged.soundEnabled, isFalse);
      expect(merged.selectedBackgroundId, 'gece_yarisi');
      expect(merged.unlockedBackgroundIds, containsAll(['klasik_kagit', 'gece_yarisi', 'osmanli_cini']));
      expect(merged.unlockedMegaIds, {'mega_1', 'mega_2'});
      expect(merged.claimedMissionIds, {'m_1', 'm_2'});

      // Word Notebook union
      expect(merged.learnedEnglishWords.keys, containsAll(['APPLE', 'LOCAL', 'CLOUD']));
      expect(merged.learnedEnglishWords['APPLE']!.timesSolved, 5);
      expect(merged.learnedEnglishWords['APPLE']!.isFavorite, isTrue);

      // Puzzle states merge
      expect(merged.puzzleStates['y_1']!.stars, 3);
      expect(merged.puzzleStates['y_1']!.bestTimeSeconds, 54);
      expect(merged.puzzleStates['y_2']!.letters.length, 3);
      expect(merged.puzzleStates['y_3']!.completed, isTrue);
    });

    test('supports guest-first play, optional Google sign-in merge, sign-out, and account deletion',
        () async {
      final fakeAuth = _FakeAuthService();
      final fakeCloud = _FakeCloudSyncService(
        initial: {
          'uid_test_1': const PlayerProfile(
            coins: 300,
            score: 750,
            bestSprintScore: 510,
            unlockedBackgroundIds: {'klasik_kagit', 'osmanli_cini'},
            puzzleStates: {
              'yesilcam_05': PuzzleSaveState(
                puzzleId: 'yesilcam_05',
                completed: true,
                stars: 3,
                bestTimeSeconds: 48,
              ),
            },
          ),
        },
      );

      final appState = _createSilentAppState(
        authService: fakeAuth,
        cloudSyncService: fakeCloud,
      );
      await appState.initialize();

      // 1) Starts strictly in Guest Mode with NO forced login banner
      expect(appState.isSignedIn, isFalse);
      expect(appState.shouldShowCloudBackupBanner, isFalse);

      // 2) Solve 2 levels as guest -> gentle banner becomes eligible
      final yesilcam = appState.packs.firstWhere((p) => p.id == 'yesilcam');
      for (var i = 0; i < 2; i++) {
        await appState.completePuzzle(
          storageKey: yesilcam.levels[i].id,
          finalState: PuzzleSaveState(
            puzzleId: yesilcam.levels[i].id,
            elapsedSeconds: 60,
            completed: true,
          ),
          isDaily: false,
        );
      }
      expect(appState.totalSolvedPuzzles, 2);
      expect(appState.shouldShowCloudBackupBanner, isTrue);

      // 3) Connect Google -> merges guest levels + cloud progress cleanly
      final signInRes = await appState.signInWithGoogleAndSync();
      expect(signInRes.success, isTrue);
      expect(appState.isSignedIn, isTrue);
      expect(appState.signedInUser!.email, 'fatih@example.com');
      expect(appState.shouldShowCloudBackupBanner, isFalse);
      expect(appState.coins, 300);
      expect(appState.score, 750);
      expect(appState.bestSprintScore, 510);
      expect(appState.totalSolvedPuzzles, 3);
      expect(appState.lastCloudSync, isNotNull);
      expect(fakeCloud.store['uid_test_1']!.puzzleStates.length, 3);

      // 4) Manual sync works cleanly
      final syncRes = await appState.syncCloudNow();
      expect(syncRes.success, isTrue);

      // 5) Cancelled deletion preserves cloud backup
      fakeAuth.shouldFailDelete = true;
      final cancelDel = await appState.deleteAccountAndCloudData();
      expect(cancelDel.success, isFalse);
      expect(appState.isSignedIn, isTrue);
      expect(fakeCloud.store.containsKey('uid_test_1'), isTrue);

      // 6) Sign out keeps local guest progress intact
      final signOutRes = await appState.signOutGoogle();
      expect(signOutRes.success, isTrue);
      expect(appState.isSignedIn, isFalse);
      expect(appState.totalSolvedPuzzles, 3);

      // 7) Sign back in & confirm full account deletion wipes cloud + local
      fakeAuth.shouldFailDelete = false;
      await appState.signInWithGoogleAndSync();
      final delRes = await appState.deleteAccountAndCloudData();
      expect(delRes.success, isTrue);
      expect(appState.isSignedIn, isFalse);
      expect(appState.totalSolvedPuzzles, 0);
      expect(fakeCloud.store.containsKey('uid_test_1'), isFalse);

      appState.dispose();
    });
  });
}
