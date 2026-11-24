import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:konsept_bulmaca/main.dart';
import 'package:konsept_bulmaca/models/background_models.dart';
import 'package:konsept_bulmaca/models/puzzle_models.dart';
import 'package:konsept_bulmaca/screens/background_gallery_screen.dart';
import 'package:konsept_bulmaca/screens/game_screen.dart';
import 'package:konsept_bulmaca/screens/mega_puzzles_screen.dart';
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

  testWidgets('Captures crisp Android preview screenshots of all key screens',
      (tester) async {
    tester.view.physicalSize = const Size(824, 1784);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final appState = AppState();
    await tester.runAsync(() => appState.initialize());

    final yesilcam = appState.packs.firstWhere((p) => p.id == 'yesilcam');
    final ingilizce = appState.packs.firstWhere((p) => p.id == 'ingilizce');
    final megaItems = appState.megaBank!.items;

    await tester.runAsync(() async {
      // Solve 4 puzzles & earn realistic combo score so Mega Arena + Puan Shop shine!
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
    });

    final boundaryKey = GlobalKey();
    Widget frame(Widget child) => RepaintBoundary(key: boundaryKey, child: child);

    // 1) Dev Bulmacalar Ekranı (12x12 -> 15x15 -> 20x20)
    await tester.pumpWidget(
      frame(
        MaterialApp(
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

    // 2) 15x15 Dev Bulmaca + Canlı 3x KOMBO Şeridi + Zoom Kontrolü!
    final mega15 = megaItems[3]; // Bilim & Kültür Maratonu (15x15)
    await tester.pumpWidget(
      frame(
        MaterialApp(
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

    // Solve 2 full words cleanly via GameKeyboard to showcase real live 2x KOMBO strip!
    final firstEntry = mega15.puzzle.orderedEntries.first;
    final secondEntry = mega15.puzzle.orderedEntries[1];
    final kbFinder = find.byType(GameKeyboard);
    // First word is already selected by default
    for (var i = 0; i < firstEntry.cells.length; i++) {
      final cell = firstEntry.cells[i];
      if (mega15.puzzle.isInitialRevealed(cell.row, cell.col)) continue;
      final ch = firstEntry.answer.characters.elementAt(i);
      await tester.tap(find.descendant(of: kbFinder, matching: find.text(ch)));
      await tester.pump(const Duration(milliseconds: 30));
    }
    // Now second word is automatically focused -> solve it to trigger 2x KOMBO!
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

    // 3) Puan Mağazası (İpucu Paketleri & Puan->Altın Takası)
    await tester.pumpWidget(frame(KonseptBulmacaApp(appState: appState)));
    await tester.pumpAndSettle();
    final ctx = tester.element(find.text('Konsept Bulmaca'));
    showRewardsCenterSheet(ctx, appState, initialTab: 1);
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('screenshots/screen_09_puan_shop.png'),
    );

    // 4) Güncel Arka Plan Galerisi (10 Tema — Puan ve Altın fiyatları!)
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

    // 5) Güncel Kutlama Dialogu (Kombo Bonusu + Puan + Konfeti)
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
