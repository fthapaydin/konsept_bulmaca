import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:konsept_bulmaca/main.dart';
import 'package:konsept_bulmaca/models/background_models.dart';
import 'package:konsept_bulmaca/models/puzzle_models.dart';
import 'package:konsept_bulmaca/services/puzzle_repository.dart';
import 'package:konsept_bulmaca/state/app_state.dart';
import 'package:konsept_bulmaca/state/game_controller.dart';
import 'package:konsept_bulmaca/utils/turkish_text.dart';
import 'package:konsept_bulmaca/widgets/game_keyboard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TurkishText', () {
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

    test('formats duration cleanly', () {
      expect(TurkishText.formatDuration(0), '00:00');
      expect(TurkishText.formatDuration(65), '01:05');
      expect(TurkishText.formatDuration(600), '10:00');
    });
  });

  group('PuzzleRepository & Assets', () {
    test('loads all 4 concept packs (40 levels) and 15 daily puzzles', () async {
      final repo = PuzzleRepository();
      final content = await repo.loadAll();

      expect(content.packs.length, 4);
      expect(content.dailyBank.puzzles.length, 15);

      for (final pack in content.packs) {
        expect(pack.levels.length, 10, reason: '${pack.id} must have 10 levels');
        // Optimum mobile progression: starts 5x5 and ends 8x8
        expect(pack.levels.first.rows, 5);
        expect(pack.levels.first.cols, 5);
        expect(pack.levels.last.rows, 8);
        expect(pack.levels.last.cols, 8);

        for (final lvl in pack.levels) {
          expect(lvl.entries.length, greaterThanOrEqualTo(4));
          expect(lvl.acrossEntries.length, greaterThanOrEqualTo(2));
          expect(lvl.downEntries.length, greaterThanOrEqualTo(2));
        }
      }
    });
  });

  group('GameController & AppState', () {
    test('handles typing, hints, mistake checking, completion, and level unlock', () async {
      final appState = AppState();
      await appState.initialize();

      final yesilcam = appState.packs.firstWhere((p) => p.id == 'yesilcam');
      expect(appState.isLevelUnlocked(yesilcam, 0), isTrue);
      expect(appState.isLevelUnlocked(yesilcam, 1), isFalse);

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

      // Test checkMistakes on empty editable cells (does not charge coins)
      final initialCoins = appState.coins;
      final emptyCheck = await controller.checkMistakes();
      expect(emptyCheck.status, HintStatus.nothingToDo);
      expect(appState.coins, initialCoins);

      // Type a deliberately wrong letter into selected cell
      final startCell = controller.selectedCell;
      final correctChar = lvl1.solutionAt(startCell.row, startCell.col)!;
      final wrongChar = correctChar == 'A' ? 'Z' : 'A';
      await controller.inputLetter(wrongChar);

      // Check mistakes should detect the wrong letter and deduct 10 coins
      final checkRes = await controller.checkMistakes();
      expect(checkRes.status, HintStatus.ok);
      expect(controller.isWrong(startCell.row, startCell.col), isTrue);
      expect(appState.coins, initialCoins - AppState.checkMistakesCost);

      // Select that wrong cell and use letter hint
      controller.selectCell(startCell.row, startCell.col);
      final hintRes = await controller.revealSelectedCell();
      expect(hintRes.status, HintStatus.ok);
      expect(controller.letterAt(startCell.row, startCell.col), correctChar);
      expect(controller.isLocked(startCell.row, startCell.col), isTrue);

      // Fill all remaining active cells with correct solution letters
      for (var r = 0; r < lvl1.rows; r++) {
        for (var c = 0; c < lvl1.cols; c++) {
          if (controller.isCompleted) break;
          final sol = lvl1.solutionAt(r, c);
          if (sol != null && controller.letterAt(r, c) != sol) {
            controller.selectCell(r, c);
            await controller.inputLetter(sol);
          }
        }
      }

      expect(controller.isCompleted, isTrue);
      expect(receivedReward, isNotNull);
      expect(receivedReward!.stars, inInclusiveRange(1, 3));
      expect(receivedReward!.coinsEarned, greaterThan(0));
      expect(appState.isLevelCompleted(lvl1), isTrue);
      expect(appState.isLevelUnlocked(yesilcam, 1), isTrue);

      controller.dispose();
      appState.dispose();
    });

    test('daily puzzle completion increments streak and doubles coins', () async {
      final appState = AppState();
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
      expect(reward!.coinsEarned, 80); // 2x (3*10 + 10)
      expect(reward!.newDailyStreak, 1);

      controller.dispose();
      appState.dispose();
    });

    test('backgrounds support free selection, coin unlock, and progression auto-unlock', () async {
      final appState = AppState();
      await appState.initialize();

      // 3 starter themes unlocked initially
      expect(appState.unlockedBackgroundCount, 3);
      expect(appState.selectedBackground.id, BackgroundCatalog.defaultId);

      // Select free dark theme
      final selectedDark = await appState.selectBackground('gece_yarisi');
      expect(selectedDark, isTrue);
      expect(appState.selectedBackground.id, 'gece_yarisi');
      expect(appState.selectedBackground.isDark, isTrue);

      // Locked theme cannot be selected directly before unlock
      final yesilcamBg = BackgroundCatalog.byId('yesilcam_sinema');
      expect(appState.isBackgroundUnlocked(yesilcamBg), isFalse);
      expect(await appState.selectBackground(yesilcamBg.id), isFalse);

      // Solve 3 puzzles -> Yeşilçam Perdesi (target: 3 solved) & Ege Kıyısı (9 stars) auto-unlock!
      final pack = appState.packs.first;
      CompletionReward? thirdReward;
      for (var i = 0; i < 3; i++) {
        final lvl = pack.levels[i];
        thirdReward = await appState.completePuzzle(
          storageKey: lvl.id,
          finalState: PuzzleSaveState(
            puzzleId: lvl.id,
            elapsedSeconds: 45,
            completed: true,
          ),
          isDaily: false,
        );
      }

      expect(appState.isBackgroundUnlocked(yesilcamBg), isTrue);
      expect(
        thirdReward!.newlyUnlockedBackgrounds.any((b) => b.id == 'yesilcam_sinema'),
        isTrue,
      );
      expect(
        thirdReward.newlyUnlockedBackgrounds.any((b) => b.id == 'ege_kiyisi'),
        isTrue,
      );

      // Coin early unlock on Kapadokya Şafağı (costs 200; player has 150 + 3*40 = 270 coins)
      final cappadocia = BackgroundCatalog.byId('kapadokya_safak');
      expect(appState.isBackgroundUnlocked(cappadocia), isFalse);
      final coinsBefore = appState.coins;
      final buyRes = await appState.unlockBackgroundWithCoins(cappadocia);
      expect(buyRes.success, isTrue);
      expect(appState.isBackgroundUnlocked(cappadocia), isTrue);
      expect(appState.selectedBackground.id, cappadocia.id);
      expect(appState.coins, coinsBefore - cappadocia.coinCost);

      appState.dispose();
    });
  });

  group('Widget Flow Smoke Test', () {
    testWidgets('opens Background Gallery and switches to Gece Yarısı cleanly',
        (tester) async {
      tester.view.physicalSize = const Size(412, 892);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final appState = AppState();
      await tester.runAsync(() => appState.initialize());

      await tester.pumpWidget(KonseptBulmacaApp(appState: appState));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Arka Planlar'));
      await tester.pumpAndSettle();

      expect(find.text('Arka Plan Galerisi'), findsOneWidget);
      expect(find.text('Gece Yarısı'), findsOneWidget);
      expect(find.text('Yeşilçam Perdesi'), findsOneWidget);

      await tester.tap(find.text('Gece Yarısı'));
      await tester.pumpAndSettle();
      expect(appState.selectedBackground.id, 'gece_yarisi');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      appState.dispose();
    });
    testWidgets('renders Home, opens Yeşilçam pack, and launches Level 1 with Turkish keyboard',
        (tester) async {
      // Simulate typical Android phone portrait viewport (412 x 892)
      tester.view.physicalSize = const Size(412, 892);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final appState = AppState();
      await tester.runAsync(() => appState.initialize());

      await tester.pumpWidget(KonseptBulmacaApp(appState: appState));
      await tester.pumpAndSettle();

      expect(find.text('Konsept Bulmaca'), findsOneWidget);
      expect(find.text('Günün Bulmacası'), findsOneWidget);
      expect(find.text('Yeşilçam Klasikleri'), findsOneWidget);
      expect(find.text('İngilizce Kelime Avı'), findsOneWidget);

      // Navigate into Yeşilçam pack
      await tester.tap(find.text('Yeşilçam Klasikleri'));
      await tester.pumpAndSettle();

      expect(find.text('İlk Perde'), findsOneWidget);
      expect(find.text('5×5'), findsAtLeastNWidgets(1));

      // Launch Level 1 (use timed pump because GameScreen runs a 1s periodic timer)
      await tester.tap(find.text('İlk Perde'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Custom Turkish keyboard keys must be visible inside GameKeyboard
      final keyboard = find.byType(GameKeyboard);
      expect(keyboard, findsOneWidget);
      expect(find.descendant(of: keyboard, matching: find.text('Ğ')), findsOneWidget);
      expect(find.descendant(of: keyboard, matching: find.text('Ş')), findsOneWidget);
      expect(find.descendant(of: keyboard, matching: find.text('İ')), findsOneWidget);
      expect(find.text('Harf Aç'), findsOneWidget);

      // Tap a Turkish key on the keyboard and verify no exceptions
      await tester.tap(find.descendant(of: keyboard, matching: find.text('A')));
      await tester.pump();

      // Unmount tree so GameController timer is disposed cleanly before test ends
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      appState.dispose();
    });
  });
}
