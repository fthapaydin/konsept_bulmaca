import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/models/notebook_models.dart';
import '../../core/theme/app_theme.dart';
import '../../state/app_state.dart';
import '../../widgets/background_canvas.dart';
import '../../widgets/editorial_emblems.dart';

/// Çözülen tüm İngilizce kelimelerin otomatik kaydedildiği karşılıklı
/// (İngilizce | Türkçe) iki sütunlu editoryal "Kelime Defteri & Sözlük" ekranı.
class WordNotebookScreen extends StatefulWidget {
  const WordNotebookScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<WordNotebookScreen> createState() => _WordNotebookScreenState();
}

class _WordNotebookScreenState extends State<WordNotebookScreen> {
  String _filter = 'ALL'; // ALL, A1, A2, B1, FAV
  String _query = '';
  bool _sortAlphabetical = true;
  bool _hideMeanings = false;
  final Set<String> _temporarilyRevealed = {};

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        final activeBg = widget.appState.selectedBackground;
        final isDark = activeBg.isDark;
        final titleColor = isDark ? Colors.white : AppPalette.ink;
        final subColor = isDark ? Colors.white70 : AppPalette.inkMuted;

        final allWords = widget.appState.learnedEnglishWords;
        final a1Count = allWords.where((w) => w.cefrLevel == 'A1').length;
        final a2Count = allWords.where((w) => w.cefrLevel == 'A2').length;
        final b1Count = allWords.where((w) => w.cefrLevel == 'B1').length;

        final filtered = allWords.where((w) {
          if (_filter == 'FAV' && !w.isFavorite) return false;
          if (_filter != 'ALL' && _filter != 'FAV' && w.cefrLevel != _filter) {
            return false;
          }
          if (_query.isNotEmpty) {
            final q = _query.toLowerCase();
            return w.word.toLowerCase().contains(q) ||
                w.meaning.toLowerCase().contains(q);
          }
          return true;
        }).toList();

        if (_sortAlphabetical) {
          filtered.sort((a, b) => a.word.compareTo(b.word));
        }

        // Alfabetik sıralamada baş harf grupları oluştur
        final rows = <_DictEntryRow>[];
        String? lastLetter;
        for (final word in filtered) {
          if (_sortAlphabetical && word.word.isNotEmpty) {
            final initial = word.word[0].toUpperCase();
            if (initial != lastLetter) {
              rows.add(_DictEntryRow.header(initial));
              lastLetter = initial;
            }
          }
          rows.add(_DictEntryRow.word(word));
        }

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: isDark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: BackgroundCanvas(
              background: activeBg,
              child: SafeArea(
                child: Column(
                  children: [
                    // Üst Editoryal Başlık
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 20,
                            ),
                            color: titleColor,
                            tooltip: 'Geri',
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kelime Defterim',
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                    color: titleColor,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                Text(
                                  '${allWords.length} kelime • A1:$a1Count  A2:$a2Count  B1:$b1Count',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: subColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (allWords.isNotEmpty)
                            FilledButton(
                              onPressed: () => _openFlashcards(
                                context,
                                filtered.isNotEmpty ? filtered : allWords,
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppPalette.ink,
                                foregroundColor: AppPalette.brassBright,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 13,
                                  vertical: 9,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Tekrar Et',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Arama Kutusu
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: TextField(
                        onChanged: (v) => setState(() => _query = v.trim()),
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppPalette.ink,
                        ),
                        decoration: InputDecoration(
                          hintText: 'İngilizce veya Türkçe kelime ara...',
                          hintStyle: const TextStyle(
                            color: AppPalette.inkMuted,
                            fontSize: 13,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 19,
                            color: AppPalette.inkMuted,
                          ),
                          filled: true,
                          fillColor: AppPalette.card,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppPalette.hairline,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppPalette.hairline,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppPalette.brass,
                              width: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Filtre & Çalışma Modu Çubuğu
                    SizedBox(
                      height: 34,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          _FilterChip(
                            label: 'Tümü (${allWords.length})',
                            selected: _filter == 'ALL',
                            onTap: () => setState(() => _filter = 'ALL'),
                          ),
                          const SizedBox(width: 6),
                          _FilterChip(
                            label: 'A1',
                            selected: _filter == 'A1',
                            onTap: () => setState(() => _filter = 'A1'),
                          ),
                          const SizedBox(width: 6),
                          _FilterChip(
                            label: 'A2',
                            selected: _filter == 'A2',
                            onTap: () => setState(() => _filter = 'A2'),
                          ),
                          const SizedBox(width: 6),
                          _FilterChip(
                            label: 'B1',
                            selected: _filter == 'B1',
                            onTap: () => setState(() => _filter = 'B1'),
                          ),
                          const SizedBox(width: 6),
                          _FilterChip(
                            label: 'Favoriler',
                            selected: _filter == 'FAV',
                            onTap: () => setState(() => _filter = 'FAV'),
                          ),
                        ],
                      ),
                    ),
                    // Sözlük Araç Çubuğu (A–Z / Son & Anlamları Gizle Çalışma Modu)
                    if (allWords.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                        child: Row(
                          children: [
                            _MiniTogglePill(
                              label: _sortAlphabetical ? 'Sıra: A–Z' : 'Sıra: Yeni',
                              active: _sortAlphabetical,
                              onTap: () => setState(
                                () => _sortAlphabetical = !_sortAlphabetical,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _MiniTogglePill(
                              label: _hideMeanings
                                  ? 'Anlamlar Gizli (Test)'
                                  : 'Anlamları Gizle',
                              active: _hideMeanings,
                              onTap: () => setState(() {
                                _hideMeanings = !_hideMeanings;
                                _temporarilyRevealed.clear();
                              }),
                            ),
                            const Spacer(),
                            Text(
                              '${filtered.length} kayıt',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: subColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    // İki Sütunlu Karşılıklı Sözlük Sayfası
                    Expanded(
                      child: allWords.isEmpty
                          ? _buildEmptyState(isDark: isDark)
                          : filtered.isEmpty
                              ? Center(
                                  child: Text(
                                    'Bu filtreye uyan kelime bulunamadı.',
                                    style: TextStyle(
                                      color: subColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                )
                              : Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 4, 16, 16),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppPalette.card,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: AppPalette.hairline,
                                      ),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Column(
                                      children: [
                                        // Sabit Karşılıklı Sözlük Sütun Başlığı
                                        Container(
                                          color: AppPalette.ink,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 9,
                                          ),
                                          child: Row(
                                            children: [
                                              const Expanded(
                                                flex: 46,
                                                child: Text(
                                                  'İNGİLİZCE',
                                                  style: TextStyle(
                                                    color:
                                                        AppPalette.brassBright,
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.w900,
                                                    letterSpacing: 1.0,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                width: 1,
                                                height: 14,
                                                color: Colors.white24,
                                              ),
                                              const SizedBox(width: 12),
                                              const Expanded(
                                                flex: 54,
                                                child: Text(
                                                  'TÜRKÇE KARŞILIĞI',
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: 0.9,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Karşılıklı Sözlük Satırları
                                        Expanded(
                                          child: ListView.builder(
                                            physics:
                                                const BouncingScrollPhysics(),
                                            itemCount: rows.length,
                                            itemBuilder: (context, index) {
                                              final item = rows[index];
                                              if (item.letterHeader != null) {
                                                return Container(
                                                  color: AppPalette.cardMuted
                                                      .withValues(alpha: 0.65),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 14,
                                                    vertical: 4,
                                                  ),
                                                  child: Text(
                                                    item.letterHeader!,
                                                    style: const TextStyle(
                                                      fontSize: 11.5,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      color: AppPalette.brass,
                                                      letterSpacing: 0.8,
                                                    ),
                                                  ),
                                                );
                                              }
                                              final word = item.word!;
                                              final masked = _hideMeanings &&
                                                  !_temporarilyRevealed
                                                      .contains(word.word);
                                              return _DictionaryTableRow(
                                                word: word,
                                                masked: masked,
                                                onRevealToggle: () {
                                                  if (!_hideMeanings) return;
                                                  setState(() {
                                                    if (_temporarilyRevealed
                                                        .contains(word.word)) {
                                                      _temporarilyRevealed
                                                          .remove(word.word);
                                                    } else {
                                                      _temporarilyRevealed
                                                          .add(word.word);
                                                    }
                                                  });
                                                },
                                                onToggleFavorite: () => widget
                                                    .appState
                                                    .toggleWordFavorite(
                                                      word.word,
                                                    ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({required bool isDark}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppPalette.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppPalette.hairline),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              EditorialEmblem(
                kind: EmblemKind.dictionary,
                size: 56,
                accentColor: AppPalette.brass,
              ),
              SizedBox(height: 14),
              Text(
                'Sözlüğün Henüz Boş',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: AppPalette.ink,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'İngilizce Kelime Avı veya Mini Sprint oynadıkça bildiğin kelimeler İngilizce – Türkçe karşılıklarıyla buraya otomatik eklenecek.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  color: AppPalette.inkSoft,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openFlashcards(
    BuildContext context,
    List<LearnedWord> words,
  ) async {
    if (words.isEmpty) return;
    await showDialog<void>(
      context: context,
      builder: (_) => _FlashcardDialog(words: words),
    );
  }
}

class _DictEntryRow {
  const _DictEntryRow._({this.letterHeader, this.word});
  const _DictEntryRow.header(String letter) : this._(letterHeader: letter);
  const _DictEntryRow.word(LearnedWord w) : this._(word: w);

  final String? letterHeader;
  final LearnedWord? word;
}

class _DictionaryTableRow extends StatelessWidget {
  const _DictionaryTableRow({
    required this.word,
    required this.masked,
    required this.onRevealToggle,
    required this.onToggleFavorite,
  });

  final LearnedWord word;
  final bool masked;
  final VoidCallback onRevealToggle;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onRevealToggle,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppPalette.hairline, width: 0.8),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Sol Sütun: İngilizce Baş Kelime + CEFR Seviyesi
              Expanded(
                flex: 46,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      word.word,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: AppPalette.ink,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: word.cefrLevel == 'B1'
                                ? AppPalette.brassSoft
                                : AppPalette.cardMuted,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            word.cefrLevel,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: word.cefrLevel == 'B1'
                                  ? AppPalette.brass
                                  : AppPalette.inkSoft,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${word.timesSolved}×',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppPalette.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Orta İnce Sözlük Sütun Çizgisi
              Container(
                width: 1,
                margin: const EdgeInsets.symmetric(vertical: 2),
                color: AppPalette.hairline,
              ),
              const SizedBox(width: 12),
              // Sağ Sütun: Türkçe Karşılığı + Favori Yıldızı
              Expanded(
                flex: 54,
                child: Row(
                  children: [
                    Expanded(
                      child: masked
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppPalette.cardMuted,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Görmek için dokun',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w600,
                                  color: AppPalette.inkMuted,
                                ),
                              ),
                            )
                          : Text(
                              word.meaning,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: AppPalette.inkSoft,
                                height: 1.25,
                              ),
                            ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: onToggleFavorite,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          word.isFavorite
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 20,
                          color: word.isFavorite
                              ? AppPalette.brassBright
                              : AppPalette.hairlineStrong,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppPalette.ink : AppPalette.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppPalette.ink : AppPalette.hairline,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: selected ? AppPalette.brassBright : AppPalette.inkSoft,
          ),
        ),
      ),
    );
  }
}

class _MiniTogglePill extends StatelessWidget {
  const _MiniTogglePill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: active ? AppPalette.brassSoft : AppPalette.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? AppPalette.brassBorder : AppPalette.hairline,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: active ? AppPalette.brass : AppPalette.inkSoft,
          ),
        ),
      ),
    );
  }
}

class _FlashcardDialog extends StatefulWidget {
  const _FlashcardDialog({required this.words});

  final List<LearnedWord> words;

  @override
  State<_FlashcardDialog> createState() => _FlashcardDialogState();
}

class _FlashcardDialogState extends State<_FlashcardDialog> {
  int _index = 0;
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final current = widget.words[_index % widget.words.length];
    return Dialog(
      backgroundColor: AppPalette.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppPalette.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Kart Tekrarı (${_index + 1}/${widget.words.length})',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: AppPalette.ink,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: AppPalette.inkSoft,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => setState(() => _revealed = !_revealed),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 18,
                ),
                decoration: BoxDecoration(
                  color: _revealed ? AppPalette.brassSoft : AppPalette.ink,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _revealed
                        ? AppPalette.brassBorder
                        : AppPalette.brassBright.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _revealed
                          ? 'İNGİLİZCE KARŞILIĞI • ${current.cefrLevel}'
                          : 'TÜRKÇE ANLAMI • ${current.cefrLevel}',
                      style: TextStyle(
                        color: _revealed
                            ? AppPalette.brass
                            : AppPalette.brassBright,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.9,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _revealed ? current.word : current.meaning,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _revealed ? AppPalette.ink : Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _revealed
                          ? 'Türkçesini görmek için karta dokun'
                          : 'İngilizcesini görmek için karta dokun',
                      style: TextStyle(
                        color:
                            _revealed ? AppPalette.inkMuted : Colors.white60,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppPalette.ink,
                      side: const BorderSide(color: AppPalette.hairlineStrong),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                    ),
                    onPressed: () => setState(() {
                      _index = (_index - 1 + widget.words.length) %
                          widget.words.length;
                      _revealed = false;
                    }),
                    child: const Text(
                      'Önceki',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppPalette.ink,
                      foregroundColor: AppPalette.brassBright,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                    ),
                    onPressed: () => setState(() {
                      _index = (_index + 1) % widget.words.length;
                      _revealed = false;
                    }),
                    child: const Text(
                      'Sonraki',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
