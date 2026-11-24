import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/models/notebook_models.dart';
import '../../state/app_state.dart';
import '../../widgets/background_canvas.dart';

/// Çözülen tüm İngilizce kelimelerin otomatik kaydedildiği "Kelime Defteri"
/// ve etkileşimli Kart Tekrar (Flashcard) ekranı.
class WordNotebookScreen extends StatefulWidget {
  const WordNotebookScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<WordNotebookScreen> createState() => _WordNotebookScreenState();
}

class _WordNotebookScreenState extends State<WordNotebookScreen> {
  String _filter = 'ALL'; // ALL, A1, A2, B1, FAV
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        final activeBg = widget.appState.selectedBackground;
        final isDark = activeBg.isDark;
        final titleColor = isDark ? Colors.white : const Color(0xFF1C1917);
        final subColor = isDark ? Colors.white70 : const Color(0xFF57534E);

        final allWords = widget.appState.learnedEnglishWords;
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
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
                                  ),
                                ),
                                Text(
                                  '${allWords.length} İngilizce kelime öğrenildi',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: subColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (allWords.isNotEmpty)
                            FilledButton.icon(
                              onPressed: () =>
                                  _openFlashcards(context, filtered.isNotEmpty ? filtered : allWords),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF1D4ED8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: const Icon(Icons.style_rounded, size: 17),
                              label: const Text(
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
                      padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                      child: TextField(
                        onChanged: (v) => setState(() => _query = v.trim()),
                        decoration: InputDecoration(
                          hintText: 'İngilizce kelime veya Türkçe anlam ara...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.95),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFE7E5E4),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFE7E5E4),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Seviye Filtre Çipleri
                    SizedBox(
                      height: 38,
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
                            icon: Icons.star_rounded,
                            selected: _filter == 'FAV',
                            onTap: () => setState(() => _filter = 'FAV'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(28),
                                child: Container(
                                  padding: const EdgeInsets.all(22),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.94),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.menu_book_rounded,
                                        size: 46,
                                        color: Color(0xFF1D4ED8),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        allWords.isEmpty
                                            ? 'Kelime Defterin Henüz Boş'
                                            : 'Aramana Uygun Kelime Bulunamadı',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF1C1917),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        allWords.isEmpty
                                            ? 'İngilizce Kelime Avı, Dev Bulmaca veya Mini Sprint oynarken çözdüğün her İngilizce kelime otomatik buraya kaydedilir!'
                                            : 'Farklı bir filtre veya arama terimi deneyebilirsin.',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          color: Color(0xFF57534E),
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 26),
                              physics: const BouncingScrollPhysics(),
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 9),
                              itemBuilder: (context, index) {
                                final item = filtered[index];
                                final badgeColor = item.cefrLevel == 'A1'
                                    ? const Color(0xFF15803D)
                                    : item.cefrLevel == 'A2'
                                        ? const Color(0xFF1D4ED8)
                                        : const Color(0xFF6D28D9);

                                return Container(
                                  padding: const EdgeInsets.fromLTRB(
                                    14,
                                    11,
                                    8,
                                    11,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: const Color(0xFFE7E5E4),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: badgeColor
                                              .withValues(alpha: 0.14),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          item.cefrLevel,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w900,
                                            color: badgeColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 11),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.word,
                                              style: const TextStyle(
                                                fontSize: 15.5,
                                                fontWeight: FontWeight.w900,
                                                color: Color(0xFF1C1917),
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              item.meaning,
                                              style: const TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF57534E),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '${item.timesSolved}×',
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFFA8A29E),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () => widget.appState
                                            .toggleWordFavorite(item.word),
                                        icon: Icon(
                                          item.isFavorite
                                              ? Icons.star_rounded
                                              : Icons.star_outline_rounded,
                                          color: item.isFavorite
                                              ? const Color(0xFFF59E0B)
                                              : const Color(0xFFA8A29E),
                                        ),
                                        tooltip: 'Favori',
                                      ),
                                    ],
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
        );
      },
    );
  }

  void _openFlashcards(BuildContext context, List<LearnedWord> words) {
    showDialog<void>(
      context: context,
      builder: (_) => _FlashcardDialog(words: words),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1D4ED8) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? const Color(0xFF1D4ED8)
                : const Color(0xFFD6D3D1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: selected ? Colors.white : const Color(0xFFF59E0B),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : const Color(0xFF44403C),
              ),
            ),
          ],
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
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(22),
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
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 20),
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
                  vertical: 34,
                  horizontal: 18,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _revealed
                        ? [const Color(0xFF15803D), const Color(0xFF0F766E)]
                        : [const Color(0xFF1D4ED8), const Color(0xFF1E3A8A)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    Text(
                      _revealed ? 'İNGİLİZCE KARŞILIĞI' : 'TÜRKÇE ANLAMI (${current.cefrLevel})',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _revealed ? current.word : current.meaning,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _revealed
                          ? 'Anlamı görmek için dokun'
                          : 'Cevabı görmek için karta dokun',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
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
                      backgroundColor: const Color(0xFF1D4ED8),
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
