class WordBlock {
  const WordBlock({required this.text, required this.role});

  final String text;
  final String role; // prefix | root | suffix

  factory WordBlock.fromJson(Map<String, dynamic> json) {
    return WordBlock(
      text: json['text'] as String,
      role: json['role'] as String,
    );
  }
}

class VocabWord {
  const VocabWord({
    required this.id,
    required this.en,
    required this.ipa,
    required this.zh,
    required this.type,
    required this.blocks,
    required this.syllables,
    this.syllableDisplay,
    required this.tts,
  });

  final int id;
  final String en;
  final String ipa;
  final String zh;
  final String type; // morph | compound | polysemy | twin | topic
  final List<WordBlock> blocks;
  final List<String> syllables;
  final String? syllableDisplay;
  final String tts;

  /// Chunks for study UI: morph/compound [blocks], else multi-syllable pieces.
  /// Empty when there is nothing useful to split (e.g. monosyllabic "which").
  List<WordBlock> get studyChunks {
    if (blocks.isNotEmpty) return blocks;
    if (syllables.length > 1) {
      return [
        for (final s in syllables) WordBlock(text: s, role: 'root'),
      ];
    }
    return const [];
  }

  factory VocabWord.fromJson(Map<String, dynamic> json) {
    return VocabWord(
      id: json['id'] as int,
      en: json['en'] as String,
      ipa: (json['ipa'] as String?) ?? '',
      zh: json['zh'] as String,
      type: json['type'] as String,
      blocks: (json['blocks'] as List? ?? [])
          .map((e) => WordBlock.fromJson(e as Map<String, dynamic>))
          .toList(),
      syllables: ((json['syllables'] as List?) ?? []).cast<String>(),
      syllableDisplay: json['syllableDisplay'] as String?,
      tts: (json['tts'] as String?) ?? (json['en'] as String),
    );
  }
}

class LevelQuestion {
  const LevelQuestion({
    required this.type,
    required this.prompt,
    required this.word,
    required this.options,
    required this.answer,
    this.zh,
    this.hint,
    this.explain,
  });

  final String type;
  final String prompt;
  final String word;
  final List<String> options;
  final String answer;
  final String? zh;
  final String? hint;
  final String? explain;

  factory LevelQuestion.fromJson(Map<String, dynamic> json) {
    return LevelQuestion(
      type: json['type'] as String,
      prompt: json['prompt'] as String,
      word: json['word'] as String,
      options: (json['options'] as List).cast<String>(),
      answer: json['answer'] as String,
      zh: json['zh'] as String?,
      hint: json['hint'] as String?,
      explain: json['explain'] as String?,
    );
  }
}

class LevelDef {
  const LevelDef({
    required this.id,
    required this.title,
    required this.principle,
    required this.goal,
    required this.passScore,
    required this.coach,
    required this.questions,
    required this.tip,
  });

  final int id;
  final String title;
  final String principle;
  final String goal;
  final int passScore;
  final String coach;
  final List<LevelQuestion> questions;
  final String tip;

  factory LevelDef.fromJson(Map<String, dynamic> json) {
    return LevelDef(
      id: json['id'] as int,
      title: json['title'] as String,
      principle: json['principle'] as String,
      goal: json['goal'] as String,
      passScore: json['passScore'] as int,
      coach: json['coach'] as String,
      questions: (json['questions'] as List)
          .map((e) => LevelQuestion.fromJson(e as Map<String, dynamic>))
          .toList(),
      tip: json['tip'] as String,
    );
  }
}
