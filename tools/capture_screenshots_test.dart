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
import 'package:konsept_bulmaca/state/app_state.dart';
import 'package:konsept_bulmaca/widgets/completion_dialog.dart';
import 'package:konsept_bulmaca/widgets/confetti_overlay.dart';
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
    // Crisp Android portrait screen: 412x892 logical @ 2.0x DPR = 824x1784 PNG
    tester.view.physicalSize = const Size(824, 1784);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final appState = AppState();
    await tester.runAsync(() => appState.initialize());

    final yesilcam = appState.packs.firstWhere((p) => p.id == 'yesilcam');
    final ingilizce = appState.packs.firstWhere((p) => p.id == 'ingilizce');

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
      );

      final y5 = yesilcam.levels[4];
      final y5Letters = <String, String>{};
      for (var eIdx = 0; eIdx < 2 && eIdx < y5.entries.length; eIdx++) {
        final entry = y5.entries[eIdx];
        final chars = entry.answer.characters.toList();
        for (var k = 0; k < entry.cells.length; k++) {
          y5Letters[entry.cells[k].key] = chars[k];
        }
      }
      await appState.savePuzzleProgress(
        y5.id,
        PuzzleSaveState(
          puzzleId: y5.id,
          letters: y5Letters,
          elapsedSeconds: 74,
        ),
      );

      final e2 = ingilizce.levels[1];
      final e2Letters = <String, String>{};
      final firstEntry = e2.entries.first;
      final firstChars = firstEntry.answer.characters.toList();
      for (var k = 0; k < firstEntry.cells.length; k++) {
        e2Letters[firstEntry.cells[k].key] = firstChars[k];
      }
      await appState.savePuzzleProgress(
        e2.id,
        PuzzleSaveState(
          puzzleId: e2.id,
          letters: e2Letters,
          elapsedSeconds: 41,
        ),
      );
    });

    final boundaryKey = GlobalKey();
    Widget frame(Widget child) => RepaintBoundary(key: boundaryKey, child: child);

    // 1) Ana Ekran
    await tester.pumpWidget(frame(KonseptBulmacaApp(appState: appState)));
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('screenshots/screen_01_home.png'),
    );

    // 2) Yeşilçam Oynanış (6x6, belirgin kare çizgileri, Türkçe klavye)
    final y5 = yesilcam.levels[4];
    await tester.pumpWidget(
      frame(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(useMaterial3: true, fontFamily: 'Roboto'),
          home: GameScreen(
            key: ValueKey<String>(y5.id),
            puzzle: y5,
            storageKey: y5.id,
            language: 'tr',
            packTitle: yesilcam.name,
            primaryColor: yesilcam.primaryColor,
            secondaryColor: yesilcam.secondaryColor,
            surfaceColor: yesilcam.surfaceColor,
            isDaily: false,
            appState: appState,
            pack: yesilcam,
            levelIndex: 4,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('screenshots/screen_02_yesilcam_game.png'),
    );

    // 3) İngilizce Kelime Avı — Gece Yarısı Koyu Mod & EN Klavye
    await tester.runAsync(() => appState.selectBackground('gece_yarisi'));
    final e2 = ingilizce.levels[1];
    await tester.pumpWidget(
      frame(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(useMaterial3: true, fontFamily: 'Roboto'),
          home: GameScreen(
            key: ValueKey<String>(e2.id),
            puzzle: e2,
            storageKey: e2.id,
            language: 'en',
            packTitle: ingilizce.name,
            primaryColor: ingilizce.primaryColor,
            secondaryColor: ingilizce.secondaryColor,
            surfaceColor: ingilizce.surfaceColor,
            isDaily: false,
            appState: appState,
            pack: ingilizce,
            levelIndex: 1,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('screenshots/screen_03_ingilizce_dark.png'),
    );

    // 4) Arka Plan Galerisi (Ege Kıyısı aktif)
    await tester.runAsync(() => appState.selectBackground('ege_kiyisi'));
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

    // 5) Görevler & Jeton Merkezi Sheet
    await tester.runAsync(() => appState.selectBackground('concept_auto'));
    await tester.pumpWidget(frame(KonseptBulmacaApp(appState: appState)));
    await tester.pumpAndSettle();
    final ctx = tester.element(find.text('Konsept Bulmaca'));
    showRewardsCenterSheet(ctx, appState);
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('screenshots/screen_05_rewards_missions.png'),
    );

    // 6) Konfeti & 3 Yıldız Kutlama Dialogu
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
                    title: 'Yeşilçam Klasikleri • Seviye 3',
                    wordCount: 6,
                    reward: CompletionReward(
                      stars: 3,
                      coinsEarned: 40,
                      elapsedSeconds: 86,
                      isFirstCompletion: true,
                      newDailyStreak: null,
                      newlyUnlockedBackgrounds: [
                        BackgroundCatalog.byId('yesilcam_sinema'),
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
