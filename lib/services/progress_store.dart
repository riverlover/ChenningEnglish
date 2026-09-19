import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProgressStore extends ChangeNotifier {
  ProgressStore();

  static const _key = 'chenning_progress_v1';

  final Map<int, int> levelBest = {};
  final Set<int> clearedLevels = {};
  final Set<int> masteredWordIds = {};
  final List<String> wrongWords = [];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    levelBest
      ..clear()
      ..addAll(
        (map['levelBest'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(int.parse(k), v as int),
        ),
      );
    clearedLevels
      ..clear()
      ..addAll(((map['cleared'] as List?) ?? []).cast<int>());
    masteredWordIds
      ..clear()
      ..addAll(((map['mastered'] as List?) ?? []).cast<int>());
    wrongWords
      ..clear()
      ..addAll(((map['wrong'] as List?) ?? []).cast<String>());
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({
        'levelBest': levelBest.map((k, v) => MapEntry('$k', v)),
        'cleared': clearedLevels.toList(),
        'mastered': masteredWordIds.toList(),
        'wrong': wrongWords,
      }),
    );
  }

  Future<void> recordLevelScore(int levelId, int score, int passScore) async {
    final prev = levelBest[levelId] ?? 0;
    if (score > prev) levelBest[levelId] = score;
    if (score >= passScore) clearedLevels.add(levelId);
    await _save();
    notifyListeners();
  }

  Future<void> markMastered(int wordId) async {
    masteredWordIds.add(wordId);
    await _save();
    notifyListeners();
  }

  Future<void> unmarkMastered(int wordId) async {
    if (!masteredWordIds.remove(wordId)) return;
    await _save();
    notifyListeners();
  }

  /// Returns whether the word is mastered after the toggle.
  Future<bool> toggleMastered(int wordId) async {
    if (masteredWordIds.contains(wordId)) {
      await unmarkMastered(wordId);
      return false;
    }
    await markMastered(wordId);
    return true;
  }

  Future<void> markWrong(String word) async {
    if (!wrongWords.contains(word)) {
      wrongWords.add(word);
      await _save();
      notifyListeners();
    }
  }

  Future<void> clearWrong(String word) async {
    wrongWords.remove(word);
    await _save();
    notifyListeners();
  }

  bool isUnlocked(int levelId) {
    if (levelId <= 1) return true;
    return clearedLevels.contains(levelId - 1);
  }
}
