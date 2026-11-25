import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:konsept_bulmaca/core/brand/brand_config.dart';
import 'package:konsept_bulmaca/features/notebook/word_notebook_screen.dart';
import 'package:konsept_bulmaca/features/sprint/mini_sprint_screen.dart';
import 'package:konsept_bulmaca/main.dart';
import 'package:konsept_bulmaca/models/puzzle_models.dart';
import 'package:konsept_bulmaca/screens/game_screen.dart';
import 'package:konsept_bulmaca/services/feedback_service.dart';
import 'package:konsept_bulmaca/state/app_state.dart';
import 'package:konsept_bulmaca/widgets/game_keyboard.dart';

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

Future<AppState> _buildDemoAppState(WidgetTester tester) async {
  final appState = AppState(
    feedback: FeedbackService(enableAudioEngine: false),
  );
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
  return appState;
}

Widget _scaledFrame(GlobalKey key, Size logicalSize, Widget child) {
  return RepaintBoundary(
    key: key,
    child: FittedBox(
      fit: BoxFit.fill,
      child: SizedBox(
        width: logicalSize.width,
        height: logicalSize.height,
        child: child,
      ),
    ),
  );
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

  testWidgets(
      'Captures Foldable screenshots: 1:1 (1600x1600), 4:3 (1920x1440), and 10:16 (1200x1920)',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final appState = await _buildDemoAppState(tester);
    final yesilcam = appState.packs.firstWhere((p) => p.id == 'yesilcam');
    final boundaryKey = GlobalKey();

    // 1) Unfolded 1:1 — 1600x1600 px (Ana Ekran)
    tester.view.physicalSize = const Size(1600, 1600);
    tester.view.devicePixelRatio = 1.0;
    await tester.pumpWidget(
      _scaledFrame(
        boundaryKey,
        const Size(800, 800),
        KonseptBulmacaApp(key: const ValueKey('fold_1x1_home'), appState: appState),
      ),
    );
    await tester.pumpAndSettle();
    final ctx = tester.element(find.text(BrandConfig.appName));
    await tester.runAsync(
      () => precacheImage(const AssetImage(BrandConfig.iconAssetPath), ctx),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('../store_listing/foldable/01_unfolded_1x1_ana_ekran.png'),
    );

    // 2) Unfolded 4:3 — 1920x1440 px (Bulmaca & Kontrol Arayüzü)
    tester.view.physicalSize = const Size(1920, 1440);
    tester.view.devicePixelRatio = 1.0;
    final lvl = yesilcam.levels[1];
    await tester.pumpWidget(
      _scaledFrame(
        boundaryKey,
        const Size(960, 720),
        MaterialApp(
          key: const ValueKey('fold_4x3_game'),
          debugShowCheckedModeBanner: false,
          theme: ThemeData(useMaterial3: true, fontFamily: 'Roboto'),
          home: GameScreen(
            key: ValueKey('fold_game_${lvl.id}'),
            puzzle: lvl,
            storageKey: 'fold_${lvl.id}',
            language: yesilcam.language,
            packTitle: yesilcam.name,
            primaryColor: yesilcam.primaryColor,
            secondaryColor: yesilcam.secondaryColor,
            surfaceColor: yesilcam.surfaceColor,
            isDaily: false,
            appState: appState,
            pack: yesilcam,
            levelIndex: 1,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final kb = find.byType(GameKeyboard);
    final goodWord = lvl.orderedEntries[0];
    for (var i = 0; i < goodWord.cells.length; i++) {
      final cell = goodWord.cells[i];
      if (lvl.isInitialRevealed(cell.row, cell.col)) continue;
      final ch = goodWord.answer.characters.elementAt(i);
      await tester.tap(find.descendant(of: kb, matching: find.text(ch)));
      await tester.pump(const Duration(milliseconds: 25));
    }
    final badWord = lvl.orderedEntries[1];
    var wrongTyped = 0;
    for (var i = 0; i < badWord.cells.length; i++) {
      final cell = badWord.cells[i];
      if (lvl.isInitialRevealed(cell.row, cell.col)) continue;
      if (goodWord.containsCell(cell.row, cell.col)) continue;
      final realCh = badWord.answer.characters.elementAt(i);
      final tapCh = wrongTyped < 2 ? (realCh == 'Z' ? 'M' : 'Z') : realCh;
      wrongTyped++;
      await tester.tap(find.descendant(of: kb, matching: find.text(tapCh)));
      await tester.pump(const Duration(milliseconds: 25));
    }
    await tester.tap(find.text('Kontrol'));
    await tester.pump(const Duration(milliseconds: 260));
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('../store_listing/foldable/02_unfolded_4x3_bulmaca.png'),
    );

    // 3) Outer Folded Portrait 10:16 — 1200x1920 px (İki Sütunlu EN–TR Sözlük)
    tester.view.physicalSize = const Size(1200, 1920);
    tester.view.devicePixelRatio = 1.0;
    await tester.pumpWidget(
      _scaledFrame(
        boundaryKey,
        const Size(600, 960),
        MaterialApp(
          key: const ValueKey('fold_10x16_dict'),
          debugShowCheckedModeBanner: false,
          theme: ThemeData(useMaterial3: true, fontFamily: 'Roboto'),
          home: WordNotebookScreen(appState: appState),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('../store_listing/foldable/03_folded_10x16_sozluk.png'),
    );

    // 4) Ek Unfolded 1:1 — 1600x1600 px (90sn Mini Sprint)
    tester.view.physicalSize = const Size(1600, 1600);
    tester.view.devicePixelRatio = 1.0;
    await tester.pumpWidget(
      _scaledFrame(
        boundaryKey,
        const Size(800, 800),
        MaterialApp(
          key: const ValueKey('fold_1x1_sprint'),
          debugShowCheckedModeBanner: false,
          theme: ThemeData(useMaterial3: true, fontFamily: 'Roboto'),
          home: MiniSprintScreen(appState: appState),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('../store_listing/foldable/04_unfolded_1x1_mini_sprint.png'),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    appState.dispose();
  });
}
