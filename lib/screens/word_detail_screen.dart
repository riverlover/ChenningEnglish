import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/content_repository.dart';
import '../data/labels.dart';
import '../data/lookalikes.dart';
import '../models/models.dart';
import '../services/progress_store.dart';
import '../services/tts_service.dart';
import '../theme/chenning_theme.dart';
import '../widgets/blocks.dart';

class WordDetailScreen extends StatefulWidget {
  const WordDetailScreen({super.key, required this.word});

  final VocabWord word;

  @override
  State<WordDetailScreen> createState() => _WordDetailScreenState();
}

class _WordDetailScreenState extends State<WordDetailScreen> {
  /// Practice: multi-chunk words start hidden until tapped.
  late bool _chunksVisible;

  @override
  void initState() {
    super.initState();
    // Morph/compound: show like homepage. Syllable topic words: reveal on tap.
    final w = widget.word;
    _chunksVisible = w.blocks.isNotEmpty || w.studyChunks.length <= 1;
  }

  @override
  Widget build(BuildContext context) {
    final word = widget.word;
    final tts = context.read<TtsService>();
    final progress = context.watch<ProgressStore>();
    final mastered = progress.masteredWordIds.contains(word.id);
    final chunks = word.studyChunks;
    final canSplit = chunks.length > 1;

    return Scaffold(
      appBar: AppBar(title: const Text('Chenning')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ChenningColors.paper,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: ChenningColors.line, width: 2),
            ),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '#${word.id}',
                    style: TextStyle(color: ChenningColors.muted, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  word.en,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Rubik',
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: ChenningColors.ink,
                  ),
                ),
                if (word.ipa.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    word.ipa,
                    style: TextStyle(
                      color: ChenningColors.muted,
                      fontSize: 16,
                    ),
                  ),
                ],
                if (canSplit) ...[
                  const SizedBox(height: 16),
                  if (_chunksVisible) ...[
                    BlocksRow(
                      blocks: chunks,
                      large: true,
                      onBlockTap: (b) => tts.speak(b.text),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '点积木听这一块',
                      style: TextStyle(
                        color: ChenningColors.muted,
                        fontSize: 13,
                      ),
                    ),
                  ] else
                    OutlinedButton(
                      onPressed: () => setState(() => _chunksVisible = true),
                      child: const Text('点我看切块'),
                    ),
                ],
                const SizedBox(height: 18),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: ChenningColors.highlight,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    word.zh,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SpeakButton(onPressed: () => tts.speak(word.tts)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (word.syllableDisplay != null)
            _InfoTile(
              title: '音节',
              body: word.syllableDisplay!,
            ),
          _InfoTile(
            title: '学习类型',
            body: studyTypeBodyFor(word),
          ),
          ...groupsFor(word.en).map(
            (g) => _LookalikeTile(group: g, current: word.en),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () async {
              final nowMastered = await progress.toggleMastered(word.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(nowMastered ? '已记下：我会了' : '已取消掌握'),
                  ),
                );
              }
            },
            child: Text(mastered ? '已掌握 ✓（点取消）' : '我会了'),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ChenningColors.rootTint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(body),
        ],
      ),
    );
  }
}

class _LookalikeTile extends StatelessWidget {
  const _LookalikeTile({required this.group, required this.current});

  final ContrastGroup group;
  final String current;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ContentRepository>();
    return FutureBuilder<List<VocabWord>>(
      future: repo.loadWords(),
      builder: (context, snap) {
        final known = {
          for (final w in snap.data ?? const <VocabWord>[])
            w.en.toLowerCase(): w,
        };
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ChenningColors.highlight.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('易混词', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              for (final item in group.words)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _LookalikeRow(
                    item: item,
                    current: item.en.toLowerCase() == current.toLowerCase(),
                    onOpen: () {
                      final hit = known[item.en.toLowerCase()];
                      if (hit == null) return;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => WordDetailScreen(word: hit),
                        ),
                      );
                    },
                    tappable: known.containsKey(item.en.toLowerCase()) &&
                        item.en.toLowerCase() != current.toLowerCase(),
                  ),
                ),
              Text(group.note, style: const TextStyle(height: 1.4)),
            ],
          ),
        );
      },
    );
  }
}

class _LookalikeRow extends StatelessWidget {
  const _LookalikeRow({
    required this.item,
    required this.current,
    required this.onOpen,
    required this.tappable,
  });

  final ContrastWord item;
  final bool current;
  final VoidCallback onOpen;
  final bool tappable;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: current ? ChenningColors.paper : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: tappable ? onOpen : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              Text(
                item.en,
                style: const TextStyle(
                  fontFamily: 'Rubik',
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(item.zh)),
              if (current)
                Text(
                  '当前',
                  style: TextStyle(
                    color: ChenningColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
