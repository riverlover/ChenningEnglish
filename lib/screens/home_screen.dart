import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/content_repository.dart';
import '../models/models.dart';
import '../services/progress_store.dart';
import '../services/srs_store.dart';
import '../services/tts_service.dart';
import '../theme/chenning_theme.dart';
import '../widgets/blocks.dart';
import 'map_screen.dart';
import 'review_screen.dart';
import 'vocab_list_screen.dart';
import 'word_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressStore>();
    final srs = context.watch<SrsStore>();
    final repo = context.read<ContentRepository>();
    final dueCount = srs.dueWordIds().length;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Text(
              'Chenning',
              style: TextStyle(fontFamily: 'Rubik', 
                fontSize: 42,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: ChenningColors.ink,
              ),
            ),
            Text(
              '看见会读，听见会写',
              style: TextStyle(
                color: ChenningColors.muted,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFDEE9FF), Color(0xFFFFEBD9)],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: ChenningColors.line, width: 2),
              ),
              child: Column(
                children: [
                  const BlocksRow(
                    large: true,
                    blocks: [
                      WordBlock(text: 're', role: 'prefix'),
                      WordBlock(text: 'cycle', role: 'root'),
                      WordBlock(text: 'able', role: 'suffix'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '再 · 循环 · 能……',
                    style: TextStyle(color: ChenningColors.muted),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: ChenningColors.highlight,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'recyclable',
                      style: TextStyle(fontFamily: 'Rubik', fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SpeakButton(
                    onPressed: () =>
                        context.read<TtsService>().speak('recyclable'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: '已通关',
                    value: '${progress.clearedLevels.length}/9',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    label: '已掌握',
                    value: '${progress.masteredWordIds.length}/170',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _NavCard(
              title: '今日复习',
              subtitle: dueCount == 0
                  ? '现在没有要复习的'
                  : '$dueCount 个词待复习 · 盖住再想',
              color: ChenningColors.highlight.withValues(alpha: 0.55),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ReviewScreen()),
                );
              },
            ),
            _NavCard(
              title: '闯关地图',
              subtitle: '9 关 · 五年级积木',
              color: ChenningColors.rootTint,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MapScreen()),
                );
              },
            ),
            _NavCard(
              title: '单词本',
              subtitle: '170 词 · 点开就能听',
              color: ChenningColors.prefixTint,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const VocabListScreen()),
                );
              },
            ),
            _NavCard(
              title: '今日一词',
              subtitle: '随机打开一张词卡',
              color: ChenningColors.suffixTint,
              onTap: () async {
                final words = await repo.loadWords();
                if (!context.mounted || words.isEmpty) return;
                final w = (words.toList()..shuffle()).first;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => WordDetailScreen(word: w),
                  ),
                );
              },
            ),
            if (progress.wrongWords.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '错题本 · ${progress.wrongWords.length}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final w in progress.wrongWords.take(12))
                    Chip(label: Text(w)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ChenningColors.paper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ChenningColors.line, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: ChenningColors.muted)),
          Text(
            value,
            style: TextStyle(fontFamily: 'Rubik', 
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  const _NavCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(fontFamily: 'Rubik', 
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(color: ChenningColors.muted),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
