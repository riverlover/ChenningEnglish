import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/content_repository.dart';
import '../models/models.dart';
import '../services/srs_store.dart';
import '../services/tts_service.dart';
import '../theme/chenning_theme.dart';
import '../widgets/blocks.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  List<VocabWord> _queue = [];
  int _index = 0;
  bool _showAnswer = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = context.read<ContentRepository>();
    final srs = context.read<SrsStore>();
    final words = await repo.loadWords();
    await srs.ensureEnrolled(words.map((w) => w.id));
    final dueIds = srs.dueWordIds(limit: 15);
    final byId = {for (final w in words) w.id: w};
    setState(() {
      _queue = [
        for (final id in dueIds)
          if (byId[id] != null) byId[id]!,
      ];
      _loading = false;
      _index = 0;
      _showAnswer = false;
    });
  }

  VocabWord? get _current =>
      _queue.isEmpty || _index >= _queue.length ? null : _queue[_index];

  Future<void> _grade(bool correct) async {
    final w = _current;
    if (w == null) return;
    await context.read<SrsStore>().answer(w.id, correct: correct);
    if (_index + 1 >= _queue.length) {
      if (mounted) Navigator.pop(context);
      return;
    }
    setState(() {
      _index += 1;
      _showAnswer = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final w = _current;
    if (w == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('复习')),
        body: const Center(child: Text('现在没有要复习的，很好')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('复习 ${_index + 1}/${_queue.length}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '盖住再想',
              style: TextStyle(color: ChenningColors.muted),
            ),
            const SizedBox(height: 12),
            Text(
              w.zh,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),
            if (_showAnswer) ...[
              Text(
                w.en,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Rubik',
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (w.ipa.isNotEmpty)
                Text(
                  w.ipa,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: ChenningColors.muted),
                ),
              const SizedBox(height: 12),
              BlocksRow(
                blocks: w.studyChunks,
                large: true,
                onBlockTap: (b) =>
                    context.read<TtsService>().speak(b.text),
              ),
              const SizedBox(height: 12),
              SpeakButton(
                onPressed: () => context.read<TtsService>().speak(w.tts),
              ),
            ] else
              FilledButton(
                onPressed: () {
                  setState(() => _showAnswer = true);
                  context.read<TtsService>().speak(w.tts);
                },
                child: const Text('揭晓并听'),
              ),
            const Spacer(),
            if (_showAnswer)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _grade(false),
                      child: const Text('没记住'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _grade(true),
                      child: const Text('记住了'),
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
