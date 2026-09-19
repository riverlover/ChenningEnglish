import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/models.dart';

class ContentRepository {
  Future<List<VocabWord>>? _wordsFuture;
  Future<List<LevelDef>>? _levelsFuture;

  Future<List<VocabWord>> loadWords() {
    return _wordsFuture ??= _readWords();
  }

  Future<List<VocabWord>> _readWords() async {
    final raw = await rootBundle.loadString('assets/vocab/grade5_beijing.json');
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return (map['words'] as List)
        .map((e) => VocabWord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<LevelDef>> loadLevels() {
    return _levelsFuture ??= _readLevels();
  }

  Future<List<LevelDef>> _readLevels() async {
    final raw = await rootBundle.loadString('assets/levels/grade5_levels.json');
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return (map['levels'] as List)
        .map((e) => LevelDef.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<VocabWord?> findByEn(String en) async {
    final words = await loadWords();
    try {
      return words.firstWhere(
        (w) => w.en.toLowerCase() == en.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}
