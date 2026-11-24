import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:konsept_bulmaca/core/brand/brand_config.dart';
import 'package:konsept_bulmaca/features/notebook/word_notebook_screen.dart';
import 'package:konsept_bulmaca/features/sprint/mini_sprint_screen.dart';
import 'package:konsept_bulmaca/main.dart';
import 'package:konsept_bulmaca/models/background_models.dart';
import 'package:konsept_bulmaca/models/puzzle_models.dart';
import 'package:konsept_bulmaca/screens/background_gallery_screen.dart';
import 'package:konsept_bulmaca/screens/game_screen.dart';
import 'package:konsept_bulmaca/screens/mega_puzzles_screen.dart';
import 'package:konsept_bulmaca/services/feedback_service.dart';
import 'package:konsept_bulmaca/state/app_state.dart';
import 'package:konsept_bulmaca/widgets/completion_dialog.dart';
import 'package:konsept_bulmaca/widgets/confetti_overlay.dart';
import 'package:konsept_bulmaca/widgets/game_keyboard.dart';
import 'package:konsept_bulmaca/widgets/rewards_center_sheet.dart';

const String _fontDir = r'C:\src\flutter\bin\cache\artifacts\material_fonts';

Future<void> _loadRealAndroidFonts() async {
  final roboto = FontLoader('Roboto');
  for (final name in [
    'roboto-regular.ttf',
    'roboto-medium.ttf',
    'roboto-bold.ttf',
    'roboto-black.ttf',
  ]) {
    final bytes = File('$_fontDir\\$name').readAsBytesSync();
    roboto.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await roboto.load();

  final icons = FontLoader('MaterialIcons');
  final iconBytes =
      File('$_fontDir\\materialicons-regular.otf').readAsBytesSync();
  icons.addFont(Future.value(ByteData.sublistView(iconBytes)));
  await icons.load();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadRealAndroidFonts();
  });

  setUp(() {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Captures crisp Android preview screenshots of Karehane screens',
      (tester) async {
    tester.view.physicalSize = const Size(824, 1784);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final appState = AppState(
      feedback: FeedbackService(enableAudioEngine: false),
    );
    await tester.runAsync(() => appState.initialize());

    final yesilcam = appState.packs.firstWhere((p) => p.id == 'yesilcam');
    final ingilizce = appState.packs.firstWhere((p) => p.id == 'ingilizce');
    final megaItems = appState.megaBank!.items;

    await tester.runAsync(() async {
      for (var i = 0; i < 3; i++) {
        await appState.completePuzzle(
          storageKey: yesilcam.levels[i].id,
          finalState: PuzzleSaveState(
            puzzleId: yesilcam.levels[i].id,
            elapsedSeconds: 58 + i * 14,
            completed: true,
          ),
          isDaily: false,
          sessionComboCoins: 35,
          sessionComboScore: 140,
          maxComboInSession: 3,
        );
      }
      await appState.completePuzzle(
        storageKey: ingilizce.levels[0].id,
        finalState: PuzzleSaveState(
          puzzleId: ingilizce.levels[0].id,
          elapsedSeconds: 64,
          completed: true,
        ),
        isDaily: false,
        sessionComboCoins: 15,
        sessionComboScore: 60,
        maxComboInSession: 2,
      );
      await appState.awardComboWord(
        comboCount: 3,
        coinsEarned: 35,
        scoreEarned: 220,
      );
      await appState.recordSprintResult(
        sprintScore: 420,
        puzzlesSolved: 3,
        coinsBonus: 55,
        maxCombo: 4,
      );
      // Populate English Word Notebook with mixed A1, A2, and B1 levels!
      await appState.recordLearnedEnglishWords([
        ...ingilizce.levels[1].entries,
        ...ingilizce.levels[17].entries,
        ...ingilizce.levels[0].entries,
      ]);
      final words = appState.learnedEnglishWords;
      if (words.length >= 4) {
        await appState.toggleWordFavorite(words[1].word);
        await appState.toggleWordFavorite(words[2].word);
      }
    });

    final boundaryKey = GlobalKey();
    Widget frame(Widget child) => RepaintBoundary(key: boundaryKey, child: child);

    // 1) Karehane Ana Ekran (Özel İkon + Mini Sprint + Kelime Defteri + Konseptler)
    await tester.pumpWidget(frame(KonseptBulmacaApp(appState: appState)));
    await tester.pumpAndSettle();
    final homeCtx = tester.element(find.text(BrandConfig.appName));
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/branding/karehane_icon.png'),
        homeCtx,
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('screenshots/screen_01_home.png'),
    );

    // 2) 90sn Mini Sprint (Hız Modu — Canlı 5x5 Tahta, +5sn Bonus Flash ve Skor HUD)
    await tester.pumpWidget(
      frame(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(useMaterial3: true, fontFamily: 'Roboto'),
          home: MiniSprintScreen(appState: appState),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    // Solve the 1st across word live on Mini Sprint to showcase live combo +5sn flash!
    final sprintState = appState.sprintBank!.items;
    final firstSprint = sprintState.firstWhere(
      (item) => find.text(item.puzzle.orderedEntries.first.clue).evaluate().isNotEmpty,
      orElse: () => sprintState.first,
    );
    final sprintFirstEntry = firstSprint.puzzle.orderedEntries.first;
    final sprintKb = find.byType(GameKeyboard);
    for (var i = 0; i < sprintFirstEntry.cells.length; i++) {
      final cell = sprintFirstEntry.cells[i];
      if (firstSprint.puzzle.isInitialRevealed(cell.row, cell.col)) continue;
      final ch = sprintFirstEntry.answer.characters.elementAt(i);
      await tester.tap(find.descendant(of: sprintKb, matching: find.text(ch)));
      await tester.pump(const Duration(milliseconds: 35));
    }
    await tester.pump(const Duration(milliseconds: 180));
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('screenshots/screen_10_mini_sprint.png'),
    );

    // 3) İngilizce Kelime Defteri (A1-B1 Öğrendiklerim + Favoriler + Kartla Çalış)
    await tester.pumpWidget(
      frame(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(useMaterial3: true, fontFamily: 'Roboto'),
          home: WordNotebookScreen(appState: appState),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('screenshots/screen_11_word_notebook.png'),
    );

    // 4) Yeşilçam Bulmacası — Artan Dinamik İpucu Fiyatı (10 -> 15 -> 25)
    final lvl4 = yesilcam.levels[3];
    await tester.pumpWidget(
      frame(
        MaterialApp(
          key: const ValueKey<String>('yesilcam_hint_app'),
          debugShowCheckedModeBanner: false,
          theme: ThemeData(useMaterial3: true, fontFamily: 'Roboto'),
          home: GameScreen(
            key: ValueKey<String>(lvl4.id),
            puzzle: lvl4,
            storageKey: lvl4.id,
            language: yesilcam.language,
            packTitle: yesilcam.name,
            primaryColor: yesilcam.primaryColor,
            secondaryColor: yesilcam.secondaryColor,
            surfaceColor: yesilcam.surfaceColor,
            isDaily: false,
            appState: appState,
            pack: yesilcam,
            levelIndex: 3,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    // Tap 'Harf' twice (1st uses free ticket, 2nd pays 10 coins -> next badge shows 15!)
    await tester.tap(find.text('Harf'));
    await tester.pump(const Duration(milliseconds: 120));
    await tester.tap(find.text('Harf'));
    await tester.pump(const Duration(milliseconds: 300));
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('screenshots/screen_02_yesilcam_game.png'),
    );

    // 5) Dev Bulmacalar Ekranı (12x12 -> 15x15 -> 20x20)
    await tester.pumpWidget(
      frame(
        MaterialApp(
          key: const ValueKey<String>('mega_arena_app'),
          debugShowCheckedModeBanner: false,
          theme: ThemeData(useMaterial3: true, fontFamily: 'Roboto'),
          home: MegaPuzzlesScreen(appState: appState),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('screenshots/screen_07_mega_arena.png'),
    );

    // 6) 15x15 Dev Bulmaca + Canlı 2x KOMBO Şeridi + Zoom Kontrolü
    final mega15 = megaItems[3];
    await tester.pumpWidget(
      frame(
        MaterialApp(
          key: const ValueKey<String>('mega15_app'),
          debugShowCheckedModeBanner: false,
          theme: ThemeData(useMaterial3: true, fontFamily: 'Roboto'),
          home: GameScreen(
            key: ValueKey<String>(mega15.puzzle.id),
            puzzle: mega15.puzzle,
            storageKey: mega15.puzzle.id,
            language: mega15.language,
            packTitle: mega15.puzzle.title,
            primaryColor: mega15.primaryColor,
            secondaryColor: mega15.secondaryColor,
            surfaceColor: mega15.surfaceColor,
            isDaily: false,
            rewardMultiplier: mega15.rewardMultiplier,
            appState: appState,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    final firstEntry = mega15.puzzle.orderedEntries.first;
    final secondEntry = mega15.puzzle.orderedEntries[1];
    final kbFinder = find.byType(GameKeyboard);
    for (var i = 0; i < firstEntry.cells.length; i++) {
      final cell = firstEntry.cells[i];
      if (mega15.puzzle.isInitialRevealed(cell.row, cell.col)) continue;
      final ch = firstEntry.answer.characters.elementAt(i);
      await tester.tap(find.descendant(of: kbFinder, matching: find.text(ch)));
      await tester.pump(const Duration(milliseconds: 30));
    }
    for (var i = 0; i < secondEntry.cells.length; i++) {
      final cell = secondEntry.cells[i];
      if (mega15.puzzle.isInitialRevealed(cell.row, cell.col)) continue;
      if (firstEntry.containsCell(cell.row, cell.col)) continue;
      final ch = secondEntry.answer.characters.elementAt(i);
      await tester.tap(find.descendant(of: kbFinder, matching: find.text(ch)));
      await tester.pump(const Duration(milliseconds: 30));
    }
    await tester.pump(const Duration(milliseconds: 220));
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('screenshots/screen_08_mega_15x15_combo.png'),
    );

    // 7) Puan Mağazası (İpucu Paketleri & Puan-Altın Takası)
    await tester.pumpWidget(frame(KonseptBulmacaApp(appState: appState)));
    await tester.pumpAndSettle();
    final ctx = tester.element(find.text(BrandConfig.appName));
    showRewardsCenterSheet(ctx, appState, initialTab: 1);
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('screenshots/screen_09_puan_shop.png'),
    );

    // 8) Arka Plan Galerisi
    await tester.pumpWidget(
      frame(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(useMaterial3: true, fontFamily: 'Roboto'),
          home: BackgroundGalleryScreen(appState: appState),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('screenshots/screen_04_backgrounds.png'),
    );

    // 9) Kutlama Dialogu (Kombo Bonusu + Puan + Konfeti)
    await tester.pumpWidget(
      frame(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(useMaterial3: true, fontFamily: 'Roboto'),
          home: Scaffold(
            backgroundColor: const Color(0xFF1F1C1A),
            body: Stack(
              fit: StackFit.expand,
              children: [
                const ConfettiOverlay(active: true),
                Center(
                  child: CompletionDialog(
                    title: 'Yeşilçam Klasikleri • Seviye 5',
                    wordCount: 7,
                    reward: CompletionReward(
                      stars: 3,
                      coinsEarned: 40,
                      comboCoinsEarned: 75,
                      scoreEarned: 420,
                      maxCombo: 4,
                      elapsedSeconds: 94,
                      isFirstCompletion: true,
                      newDailyStreak: null,
                      newlyUnlockedBackgrounds: [
                        BackgroundCatalog.byId('osmanli_cini'),
                      ],
                    ),
                    primaryColor: yesilcam.primaryColor,
                    hasNextLevel: true,
                    onNextLevel: () {},
                    onBackToMap: () {},
                    onApplyBackground: (_) {},
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('screenshots/screen_06_victory_confetti.png'),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    appState.dispose();
  });
}
