class ContrastWord {
  const ContrastWord({required this.en, required this.zh});

  final String en;
  final String zh;
}

class ContrastGroup {
  const ContrastGroup({
    required this.id,
    required this.words,
    required this.note,
  });

  final String id;
  final List<ContrastWord> words;
  final String note;

  bool contains(String en) =>
      words.any((w) => w.en.toLowerCase() == en.toLowerCase());
}

/// Pairs and near-misses from the Grade 5 levels. Partners that are not
/// in the 170-word bank are still listed, so a twin is never shown alone.
const contrastGroups = <ContrastGroup>[
  ContrastGroup(
    id: 'quiet',
    words: [
      ContrastWord(en: 'quiet', zh: '安静的'),
      ContrastWord(en: 'quite', zh: '很；相当'),
    ],
    note: 'quiet 末尾有 e，是“安静”；quite 没有 e，是“很、相当”。',
  ),
  ContrastGroup(
    id: 'their',
    words: [
      ContrastWord(en: 'their', zh: '他们的'),
      ContrastWord(en: 'there', zh: '在那里'),
      ContrastWord(en: 'here', zh: '这里'),
      ContrastWord(en: "they're", zh: '他们是（they are）'),
    ],
    note: 'their 是“他们的”；there 是“在那里”；here 是“这里”；they\'re = they are。',
  ),
  ContrastGroup(
    id: 'hour',
    words: [
      ContrastWord(en: 'hour', zh: '小时'),
      ContrastWord(en: 'our', zh: '我们的'),
    ],
    note: '读音一样。hour 是“小时”，our 是“我们的”。',
  ),
  ContrastGroup(
    id: 'help-harm',
    words: [
      ContrastWord(en: 'helpful', zh: '有帮助的'),
      ContrastWord(en: 'harmful', zh: '有害的'),
    ],
    note: '词尾都是 -ful。help 是帮助，harm 是伤害。',
  ),
  ContrastGroup(
    id: 'excite',
    words: [
      ContrastWord(en: 'exciting', zh: '令人兴奋的（多形容事物）'),
      ContrastWord(en: 'excited', zh: '感到兴奋的（多形容人）'),
    ],
    note: '-ing 常说事物“令人……”；-ed 常说人“感到……”。',
  ),
  ContrastGroup(
    id: 'difficult',
    words: [
      ContrastWord(en: 'difficult', zh: '困难的'),
      ContrastWord(en: 'different', zh: '不同的'),
    ],
    note: 'difficult 是“困难”，different 是“不同”，中间的字母不一样。',
  ),
];

List<ContrastGroup> groupsFor(String en) =>
    contrastGroups.where((g) => g.contains(en)).toList();
