import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple Leitner-style boxes for word IDs.
/// Box 0 = new/wrong, 1 = next day, 2 = 3 days, 3 = 7 days, 4 = mastered month.
class SrsStore extends ChangeNotifier {
  SrsStore();

  static const _key = 'chenning_srs_v1';
  final Map<int, _Card> _cards = {};

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    _cards
      ..clear()
      ..addAll(
        map.map(
          (k, v) => MapEntry(
            int.parse(k),
            _Card.fromJson(v as Map<String, dynamic>),
          ),
        ),
      );
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(_cards.map((k, v) => MapEntry('$k', v.toJson()))),
    );
  }

  Future<void> ensureEnrolled(Iterable<int> wordIds) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    var changed = false;
    for (final id in wordIds) {
      if (_cards.containsKey(id)) continue;
      _cards[id] = _Card(box: 0, dueAt: now);
      changed = true;
    }
    if (changed) {
      await _save();
      notifyListeners();
    }
  }

  List<int> dueWordIds({int limit = 20}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final due = _cards.entries
        .where((e) => e.value.dueAt <= now && e.value.box < 4)
        .map((e) => e.key)
        .toList()
      ..sort((a, b) => _cards[a]!.box.compareTo(_cards[b]!.box));
    return due.take(limit).toList();
  }

  Future<void> answer(int wordId, {required bool correct}) async {
    final now = DateTime.now();
    final card = _cards[wordId] ?? _Card(box: 0, dueAt: now.millisecondsSinceEpoch);
    if (correct) {
      final nextBox = (card.box + 1).clamp(0, 4);
      card.box = nextBox;
      card.dueAt = now.add(_interval(nextBox)).millisecondsSinceEpoch;
    } else {
      card.box = 0;
      card.dueAt = now.millisecondsSinceEpoch;
    }
    _cards[wordId] = card;
    await _save();
    notifyListeners();
  }

  Duration _interval(int box) {
    switch (box) {
      case 1:
        return const Duration(days: 1);
      case 2:
        return const Duration(days: 3);
      case 3:
        return const Duration(days: 7);
      case 4:
        return const Duration(days: 30);
      default:
        return Duration.zero;
    }
  }
}

class _Card {
  _Card({required this.box, required this.dueAt});

  int box;
  int dueAt;

  factory _Card.fromJson(Map<String, dynamic> json) => _Card(
        box: json['box'] as int,
        dueAt: json['dueAt'] as int,
      );

  Map<String, dynamic> toJson() => {'box': box, 'dueAt': dueAt};
}
