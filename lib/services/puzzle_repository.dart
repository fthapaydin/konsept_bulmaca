import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/puzzle_models.dart';

typedef AssetStringLoader = Future<String> Function(String key);

class LoadedPuzzleContent {
  const LoadedPuzzleContent({
    required this.packs,
    required this.dailyBank,
    required this.megaBank,
    required this.sprintBank,
  });

  final List<ConceptPack> packs;
  final DailyBank dailyBank;
  final MegaBank megaBank;
  final SprintBank sprintBank;
}

class PuzzleRepository {
  PuzzleRepository({AssetStringLoader? loader})
      : _loader = loader ?? rootBundle.loadString;

  final AssetStringLoader _loader;

  Future<LoadedPuzzleContent> loadAll() async {
    final manifestRaw = await _loader('assets/puzzles/manifest.json');
    final manifest = jsonDecode(manifestRaw) as Map<String, dynamic>;

    final packPaths = (manifest['packs'] as List<dynamic>).cast<String>();
    final packs = <ConceptPack>[];
    for (final path in packPaths) {
      final raw = await _loader(path);
      packs.add(ConceptPack.fromJson(jsonDecode(raw) as Map<String, dynamic>));
    }

    final dailyPath = manifest['daily'] as String;
    final dailyRaw = await _loader(dailyPath);
    final dailyBank =
        DailyBank.fromJson(jsonDecode(dailyRaw) as Map<String, dynamic>);

    final megaPath = manifest['mega'] as String? ?? 'assets/puzzles/mega.json';
    final megaRaw = await _loader(megaPath);
    final megaBank =
        MegaBank.fromJson(jsonDecode(megaRaw) as Map<String, dynamic>);

    final sprintPath =
        manifest['sprint'] as String? ?? 'assets/puzzles/sprint.json';
    final sprintRaw = await _loader(sprintPath);
    final sprintBank =
        SprintBank.fromJson(jsonDecode(sprintRaw) as Map<String, dynamic>);

    return LoadedPuzzleContent(
      packs: packs,
      dailyBank: dailyBank,
      megaBank: megaBank,
      sprintBank: sprintBank,
    );
  }
}
