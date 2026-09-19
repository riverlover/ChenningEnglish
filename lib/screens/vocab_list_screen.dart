import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/content_repository.dart';
import '../data/labels.dart';
import '../data/lookalikes.dart';
import '../models/models.dart';
import '../services/progress_store.dart';
import '../theme/chenning_theme.dart';
import 'word_detail_screen.dart';

class VocabListScreen extends StatefulWidget {
  const VocabListScreen({super.key});

  @override
  State<VocabListScreen> createState() => _VocabListScreenState();
}

class _VocabListScreenState extends State<VocabListScreen> {
  String _query = '';
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ContentRepository>();
    final progress = context.watch<ProgressStore>();

    return Scaffold(
      appBar: AppBar(title: const Text('单词本')),
      body: FutureBuilder<List<VocabWord>>(
        future: repo.loadWords(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final allWords = snap.data!;
          final q = _query.trim().toLowerCase();
          final showingTwins = _filter == 'twin';
          final groups = showingTwins
              ? contrastGroups.where((g) {
                  if (q.isEmpty) return true;
                  return g.words.any(
                    (w) =>
                        w.en.toLowerCase().contains(q) || w.zh.contains(q),
                  );
                }).toList()
              : const <ContrastGroup>[];
          var words = allWords;
          if (_filter != 'all' && !showingTwins) {
            words = words.where((w) => w.type == _filter).toList();
          }
          if (q.isNotEmpty && !showingTwins) {
            words = words
                .where(
                  (w) =>
                      w.en.toLowerCase().contains(q) ||
                      w.zh.contains(q) ||
                      '${w.id}'.contains(q),
                )
                .toList();
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: '搜英文、中文或序号',
                    filled: true,
                    fillColor: ChenningColors.paper,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: ChenningColors.line,
                        width: 2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: ChenningColors.line,
                        width: 2,
                      ),
                    ),
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    for (final f in vocabFilters)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(f.$2),
                          selected: _filter == f.$1,
                          onSelected: (_) => setState(() => _filter = f.$1),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: showingTwins
                    ? ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: groups.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final g = groups[i];
                          return _TwinGroupCard(
                            group: g,
                            words: allWords,
                          );
                        },
                      )
                    : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: words.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final w = words[i];
                    final known = progress.masteredWordIds.contains(w.id);
                    final mates = groupsFor(w.en)
                        .expand((g) => g.words)
                        .map((c) => c.en)
                        .where((en) => en.toLowerCase() != w.en.toLowerCase())
                        .toSet();
                    return Material(
                      color: ChenningColors.paper,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => WordDetailScreen(word: w),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: ChenningColors.line,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 36,
                                child: Text(
                                  '${w.id}',
                                  style: TextStyle(
                                    color: ChenningColors.muted,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      w.en,
                                      style: TextStyle(fontFamily: 'Rubik', 
                                        fontWeight: FontWeight.w800,
                                        fontSize: 17,
                                      ),
                                    ),
                                    Text(
                                      w.zh,
                                      style: TextStyle(
                                        color: ChenningColors.muted,
                                      ),
                                    ),
                                    if (mates.isNotEmpty)
                                      Text(
                                        '易混 ${mates.join(' · ')}',
                                        style: TextStyle(
                                          color: ChenningColors.prefix,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (known)
                                const Icon(
                                  Icons.check_circle,
                                  color: ChenningColors.suffix,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TwinGroupCard extends StatelessWidget {
  const _TwinGroupCard({required this.group, required this.words});

  final ContrastGroup group;
  final List<VocabWord> words;

  @override
  Widget build(BuildContext context) {
    VocabWord? match;
    for (final c in group.words) {
      for (final w in words) {
        if (w.en.toLowerCase() == c.en.toLowerCase()) {
          match = w;
          break;
        }
      }
      if (match != null) break;
    }

    return Material(
      color: ChenningColors.paper,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: match == null
            ? null
            : () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => WordDetailScreen(word: match!),
                  ),
                );
              },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ChenningColors.line, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                group.words.map((w) => w.en).join('  /  '),
                style: const TextStyle(
                  fontFamily: 'Rubik',
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                group.words.map((w) => '${w.en} ${w.zh}').join(' · '),
                style: TextStyle(color: ChenningColors.muted, height: 1.35),
              ),
              const SizedBox(height: 6),
              Text(group.note, style: const TextStyle(height: 1.35)),
            ],
          ),
        ),
      ),
    );
  }
}
