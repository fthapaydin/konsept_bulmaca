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

Future<void> _captureTabletSet(
  WidgetTester tester, {
  required Size logicalSize,
  required double outputScale,
  required String folderRelativeToTools,
  required String keyPrefix,
}) async {
  tester.view.physicalSize = Size(
    logicalSize.width * outputScale,
    logicalSize.height * outputScale,
  );
  tester.view.devicePixelRatio = 1.0;

  final appState = await _buildDemoAppState(tester);
  final yesilcam = appState.packs.firstWhere((p) => p.id == 'yesilcam');
  final boundaryKey = GlobalKey();
  Widget frame(Widget child) => RepaintBoundary(
        key: boundaryKey,
        child: FittedBox(
          fit: BoxFit.fill,
          child: SizedBox(
            width: logicalSize.width,
            height: logicalSize.height,
            child: child,
          ),
        ),
      );

  // 1) Ana Ekran
  await tester.pumpWidget(
    frame(KonseptBulmacaApp(key: ValueKey('${keyPrefix}_home'), appState: appState)),
  );
  await tester.pumpAndSettle();
  final ctx = tester.element(find.text(BrandConfig.appName));
  await tester.runAsync(
    () => precacheImage(const AssetImage(BrandConfig.iconAssetPath), ctx),
  );
  await tester.pumpAndSettle();
  await expectLater(
    find.byKey(boundaryKey),
    matchesGoldenFile('$folderRelativeToTools/01_ana_ekran.png'),
  );

  // 2) Bulmaca & Hatalı Kelime Kontrolü
  final lvlWrong = yesilcam.levels[1];
  await tester.pumpWidget(
    frame(
      MaterialApp(
        key: ValueKey('${keyPrefix}_game'),
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true, fontFamily: 'Roboto'),
        home: GameScreen(
          key: ValueKey('${keyPrefix}_wrong_${lvlWrong.id}'),
          puzzle: lvlWrong,
          storageKey: 'tablet_${keyPrefix}_${lvlWrong.id}',
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
  final goodWord = lvlWrong.orderedEntries[0];
  for (var i = 0; i < goodWord.cells.length; i++) {
    final cell = goodWord.cells[i];
    if (lvlWrong.isInitialRevealed(cell.row, cell.col)) continue;
    final ch = goodWord.answer.characters.elementAt(i);
    await tester.tap(find.descendant(of: kb, matching: find.text(ch)));
    await tester.pump(const Duration(milliseconds: 25));
  }
  final badWord = lvlWrong.orderedEntries[1];
  var wrongTyped = 0;
  for (var i = 0; i < badWord.cells.length; i++) {
    final cell = badWord.cells[i];
    if (lvlWrong.isInitialRevealed(cell.row, cell.col)) continue;
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
    matchesGoldenFile('$folderRelativeToTools/02_bulmaca_ve_kontrol.png'),
  );

  // 3) İki Sütunlu İngilizce – Türkçe Sözlük
  await tester.pumpWidget(
    frame(
      MaterialApp(
        key: ValueKey('${keyPrefix}_dict'),
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true, fontFamily: 'Roboto'),
        home: WordNotebookScreen(appState: appState),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await expectLater(
    find.byKey(boundaryKey),
    matchesGoldenFile('$folderRelativeToTools/03_ingilizce_turkce_sozluk.png'),
  );

  // 4) 90sn Mini Sprint
  await tester.pumpWidget(
    frame(
      MaterialApp(
        key: ValueKey('${keyPrefix}_sprint'),
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
    matchesGoldenFile('$folderRelativeToTools/04_90sn_mini_sprint.png'),
  );

  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  appState.dispose();
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

  testWidgets('Captures 7-inch (1200x1920) and 10-inch (1600x2560) tablet store screenshots',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // 7-inç Tablet (600x960 dp -> gerçek 1200x1920 px PNG — Google Play 1080p+ uyumlu)
    await _captureTabletSet(
      tester,
      logicalSize: const Size(600, 960),
      outputScale: 2.0,
      folderRelativeToTools: '../store_listing/tablet_7_inch',
      keyPrefix: 'tab7',
    );

    // 10-inç Tablet (800x1280 dp -> gerçek 1600x2560 px PNG — Google Play 1080p+ uyumlu)
    await _captureTabletSet(
      tester,
      logicalSize: const Size(800, 1280),
      outputScale: 2.0,
      folderRelativeToTools: '../store_listing/tablet_10_inch',
      keyPrefix: 'tab10',
    );
  });
}
