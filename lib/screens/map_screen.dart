import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/content_repository.dart';
import '../models/models.dart';
import '../services/progress_store.dart';
import '../theme/chenning_theme.dart';
import 'level_play_screen.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  static const _colors = [
    ChenningColors.root,
    ChenningColors.prefix,
    ChenningColors.suffix,
  ];

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ContentRepository>();
    final progress = context.watch<ProgressStore>();

    return Scaffold(
      appBar: AppBar(title: const Text('闯关地图')),
      body: FutureBuilder<List<LevelDef>>(
        future: repo.loadLevels(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final levels = snap.data!;
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            itemCount: levels.length,
            itemBuilder: (context, i) {
              final lv = levels[i];
              final unlocked = progress.isUnlocked(lv.id);
              final cleared = progress.clearedLevels.contains(lv.id);
              final best = progress.levelBest[lv.id];
              final color = _colors[i % _colors.length];

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Opacity(
                  opacity: unlocked ? 1 : 0.45,
                  child: Material(
                    color: ChenningColors.paper,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: unlocked
                          ? () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => LevelPlayScreen(level: lv),
                                ),
                              );
                            }
                          : null,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: ChenningColors.line,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 64,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Text(
                                'L${lv.id}',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontFamily: 'Rubik', 
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lv.title,
                                    style: TextStyle(fontFamily: 'Rubik', 
                                      fontWeight: FontWeight.w800,
                                      fontSize: 17,
                                    ),
                                  ),
                                  Text(
                                    lv.principle,
                                    style: TextStyle(
                                      color: ChenningColors.muted,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    '${lv.questions.length} 题 · 及格 ${lv.passScore}'
                                    '${best != null ? ' · 最高 $best' : ''}',
                                    style: TextStyle(
                                      color: ChenningColors.muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              !unlocked
                                  ? Icons.lock_outline
                                  : cleared
                                      ? Icons.star_rounded
                                      : Icons.play_arrow_rounded,
                              color: cleared
                                  ? ChenningColors.prefix
                                  : ChenningColors.root,
                              size: 28,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
