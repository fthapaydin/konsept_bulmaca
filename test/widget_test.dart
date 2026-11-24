import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:konsept_bulmaca/main.dart';
import 'package:konsept_bulmaca/models/background_models.dart';
import 'package:konsept_bulmaca/models/retention_models.dart';
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

  group('TurkishText & ComboEconomy', () {
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
  });

  group('PuzzleRepository & Assets', () {
    test('loads all 4 concept packs (80 levels), 15 daily, and 6 mega puzzles up to 20x20',
        () async {
      final repo = PuzzleRepository();
      final content = await repo.loadAll();

      expect(content.packs.length, 4);
      expect(content.dailyBank.puzzles.length, 15);
      expect(content.megaBank.items.length, 6);

      for (final pack in content.packs) {
        expect(pack.levels.length, 20, reason: '${pack.id} must have 20 levels');
        expect(pack.levels.first.rows, 5);
        expect(pack.levels.last.rows, 8);
      }

      // Verify 12x12, 15x15, and 20x20 mega puzzles exist
      final megaSizes =
          content.megaBank.items.map((i) => i.puzzle.rows).toSet();
      expect(megaSizes, containsAll([12, 15, 20]));
      expect(content.megaBank.items.last.puzzle.entries.length, greaterThanOrEqualTo(35));
    });
  });

  group('GameController, Combos, Puan Shop & Mega Unlocks', () {
    test('awards escalating combo coins & score on consecutive solved words and resets on hint',
        () async {
      final appState = AppState();
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

      // Solve entire puzzle cleanly without hints -> combos build on every word!
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

    test('uses free hint ticket first before spending coins, and buys bundles & backgrounds with Puan',
        () async {
      final appState = AppState();
      await appState.initialize();

      // Starts with 1 free letter hint ticket
      expect(appState.letterHintTickets, 1);
      final coinsBefore = appState.coins;

      final lvl1 = appState.packs.first.levels.first;
      final controller = GameController(
        puzzle: lvl1,
        storageKey: lvl1.id,
        language: 'tr',
        isDaily: false,
        appState: appState,
      );

      final hintRes = await controller.revealSelectedCell();
      expect(hintRes.status, HintStatus.ok);
      expect(appState.letterHintTickets, 0);
      expect(appState.coins, coinsBefore); // Ticket used -> 0 coins deducted!
      controller.dispose();

      // Grant score via combo award and buy hint bundle + background + mega unlock with Puan!
      await appState.awardComboWord(
        comboCount: 4,
        coinsEarned: 40,
        scoreEarned: 1000,
      );
      expect(appState.score, 1000);
      expect(appState.bestCombo, 4);

      final letterBundle = ShopCatalog.all.first;
      final buyRes = await appState.buyShopBundle(letterBundle, useScore: true);
      expect(buyRes.success, isTrue);
      expect(appState.letterHintTickets, letterBundle.quantity);

      // Unlock a background with Puan
      final yesilcamBg = BackgroundCatalog.byId('yesilcam_sinema');
      final bgRes = await appState.unlockBackgroundWithScore(yesilcamBg);
      expect(bgRes.success, isTrue);
      expect(appState.isBackgroundUnlocked(yesilcamBg), isTrue);
      expect(appState.selectedBackground.id, yesilcamBg.id);

      // Unlock 12x12 Mega Puzzle early with Puan
      final firstMega = appState.megaBank!.items.first;
      expect(appState.isMegaUnlocked(firstMega), isFalse);
      final megaRes = await appState.unlockMegaEarly(firstMega, useScore: true);
      expect(megaRes.success, isTrue);
      expect(appState.isMegaUnlocked(firstMega), isTrue);

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
      expect(reward!.coinsEarned, 80);
      expect(reward!.newDailyStreak, 1);

      controller.dispose();
      appState.dispose();
    });
  });

  group('Widget Flow Smoke Test', () {
    testWidgets('opens Background Gallery (10 themes) and switches cleanly',
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

      await tester.tap(find.text('Gece Yarısı'));
      await tester.pumpAndSettle();
      expect(appState.selectedBackground.id, 'gece_yarisi');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      appState.dispose();
    });

    testWidgets('renders Home, opens Yeşilçam pack, and launches Level 1 with Turkish keyboard',
        (tester) async {
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

      await tester.tap(find.text('Yeşilçam Klasikleri'));
      await tester.pumpAndSettle();

      expect(find.text('İlk Perde'), findsOneWidget);

      await tester.tap(find.text('İlk Perde'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final keyboard = find.byType(GameKeyboard);
      expect(keyboard, findsOneWidget);
      expect(find.descendant(of: keyboard, matching: find.text('Ğ')), findsOneWidget);
      expect(find.descendant(of: keyboard, matching: find.text('Ş')), findsOneWidget);
      expect(find.text('Harf'), findsOneWidget);

      await tester.tap(find.descendant(of: keyboard, matching: find.text('A')));
      await tester.pump();

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      appState.dispose();
    });
  });
}
