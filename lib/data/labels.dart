import '../models/models.dart';

/// Learner-facing labels. English words and the Chenning brand stay in English.
String studyTypeBody(String type) {
  switch (type) {
    case 'morph':
      return '词缀积木：看词头、词根、词尾';
    case 'compound':
      return '合成词：小词拼成大词，或记成短语';
    case 'polysemy':
      return '一词多义：先记住核心意思，再看句子';
    case 'twin':
      return '形近词：和长得像、容易混的词放在一起对比';
    default:
      return '主题词：按音节切块来记';
  }
}

String studyTypeBodyFor(VocabWord word) {
  switch (word.type) {
    case 'morph':
      return word.studyChunks.length > 1
          ? '词缀积木：看词头、词根、词尾；点积木听这一块'
          : studyTypeBody(word.type);
    case 'compound':
      return word.studyChunks.length > 1
          ? '合成词：小词拼成大词；点积木听这一块'
          : studyTypeBody(word.type);
    case 'topic':
      if (word.studyChunks.length > 1) {
        return '主题词：按音节切块来记；点积木听这一块，点「听」读整词';
      }
      return '主题词：单音节，整词记忆即可';
    default:
      return studyTypeBody(word.type);
  }
}

const vocabFilters = <(String, String)>[
  ('all', '全部'),
  ('morph', '词缀'),
  ('compound', '合成'),
  ('polysemy', '多义'),
  ('twin', '形近'),
  ('topic', '主题'),
];

String questionTypeLabel(String type) {
  switch (type) {
    case 'split':
      return '拆积木';
    case 'choice':
      return '选择';
    case 'fill_choice':
      return '填空';
    case 'zh_to_en':
      return '中译英';
    case 'ipa_to_en':
      return '看音标';
    default:
      return '题目';
  }
}
