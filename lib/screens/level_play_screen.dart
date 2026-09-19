import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/labels.dart';
import '../models/models.dart';
import '../services/progress_store.dart';
import '../services/tts_service.dart';
import '../theme/chenning_theme.dart';
import '../widgets/blocks.dart';

class LevelPlayScreen extends StatefulWidget {
  const LevelPlayScreen({super.key, required this.level});

  final LevelDef level;

  @override
  State<LevelPlayScreen> createState() => _LevelPlayScreenState();
}

class _LevelPlayScreenState extends State<LevelPlayScreen> {
  int _index = 0;
  int _score = 0;
  String? _picked;
  bool _revealed = false;
  bool _done = false;
  late List<String> _shuffledOptions;
  final _rng = Random();

  LevelQuestion get _q => widget.level.questions[_index];

  @override
  void initState() {
    super.initState();
    _reshuffleOptions();
  }

  void _reshuffleOptions() {
    _shuffledOptions = List<String>.from(_q.options)..shuffle(_rng);
  }

  void _choose(String option) {
    if (_revealed) return;
    setState(() {
      _picked = option;
      _revealed = true;
      if (option == _q.answer) {
        _score += 1;
      } else {
        context.read<ProgressStore>().markWrong(_q.word);
      }
    });
    context.read<TtsService>().speak(_q.word);
  }

  Future<void> _next() async {
    if (_index + 1 >= widget.level.questions.length) {
      await context.read<ProgressStore>().recordLevelScore(
            widget.level.id,
            _score,
            widget.level.passScore,
          );
      setState(() => _done = true);
      return;
    }
    setState(() {
      _index += 1;
      _picked = null;
      _revealed = false;
      _reshuffleOptions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final level = widget.level;
    final total = level.questions.length;

    if (_done) {
      final passed = _score >= level.passScore;
      return Scaffold(
        appBar: AppBar(title: Text('第 ${level.id} 关')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: passed ? ChenningColors.good : ChenningColors.bad,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  children: [
                    Text(
                      passed ? '通关 ★' : '再练一练',
                      style: TextStyle(fontFamily: 'Rubik', 
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '得分 $_score / $total',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '及格线：${level.passScore}',
                      style: TextStyle(color: ChenningColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(level.tip, style: const TextStyle(height: 1.5)),
              const Spacer(),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('返回地图'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('第 ${level.id} 关 · ${level.title}'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Row(
            children: [
              _Badge(text: '第 ${_index + 1}/$total 题'),
              const SizedBox(width: 8),
              _Badge(text: '得分 $_score', color: ChenningColors.rootTint),
              const Spacer(),
              SpeakButton(
                label: '听',
                onPressed: () => context.read<TtsService>().speak(_q.word),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ChenningColors.rootTint,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(level.coach, style: const TextStyle(height: 1.45)),
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: _Badge(text: questionTypeLabel(_q.type)),
          ),
          const SizedBox(height: 8),
          Text(
            _q.prompt,
            style: TextStyle(fontFamily: 'Nunito', 
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
          if (_q.zh != null) ...[
            const SizedBox(height: 6),
            Text(_q.zh!, style: TextStyle(color: ChenningColors.muted)),
          ],
          const SizedBox(height: 18),
          ..._shuffledOptions.map((opt) {
            Color? bg;
            if (_revealed) {
              if (opt == _q.answer) {
                bg = ChenningColors.good;
              } else if (opt == _picked) {
                bg = ChenningColors.bad;
              }
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: bg ?? ChenningColors.paper,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _choose(opt),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: ChenningColors.line,
                        width: 2,
                      ),
                    ),
                    child: _OptionLabel(option: opt),
                  ),
                ),
              ),
            );
          }),
          if (_revealed) ...[
            const SizedBox(height: 8),
            Text(
              _picked == _q.answer
                  ? '答对了'
                  : '答案：${_plainOption(_q.answer)}',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: _picked == _q.answer
                    ? ChenningColors.suffix
                    : ChenningColors.prefix,
              ),
            ),
            if (_picked != _q.answer && _q.explain != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ChenningColors.prefixTint,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '解析：${_q.explain}',
                  style: const TextStyle(height: 1.45, fontWeight: FontWeight.w700),
                ),
              ),
            ],
            const SizedBox(height: 14),
            FilledButton(
              onPressed: _next,
              child: Text(
                _index + 1 >= total ? '看结果' : '下一题',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _plainOption(String option) => option.replaceAll('｜', ' ');

class _OptionLabel extends StatelessWidget {
  const _OptionLabel({required this.option});

  final String option;

  @override
  Widget build(BuildContext context) {
    final parts = option.split('｜');
    final en = parts.first;
    final zh = parts.length > 1 ? parts.sublist(1).join('｜') : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          en,
          style: const TextStyle(
            fontFamily: 'Rubik',
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (zh != null) ...[
          const SizedBox(height: 2),
          Text(
            zh,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
        ],
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, this.color = ChenningColors.highlight});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}
