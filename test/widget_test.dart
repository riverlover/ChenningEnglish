import 'dart:convert';

import 'package:chenning_english/models/models.dart';
import 'package:chenning_english/screens/level_play_screen.dart';
import 'package:chenning_english/services/progress_store.dart';
import 'package:chenning_english/services/tts_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('vocab word parses blocks', () {
    final word = VocabWord.fromJson({
      'id': 77,
      'en': 'recyclable',
      'ipa': '/ˌriːˈsaɪkləbəl/',
      'zh': '可回收利用的',
      'type': 'morph',
      'blocks': [
        {'text': 're', 'role': 'prefix'},
        {'text': 'cycle', 'role': 'root'},
        {'text': 'able', 'role': 'suffix'},
      ],
      'syllables': ['re', 'cy', 'cla', 'ble'],
      'tts': 'recyclable',
    });
    expect(word.blocks.length, 3);
    expect(word.blocks.first.role, 'prefix');
  });

  test('suffix-hat questions are bilingual and explained', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final raw = await rootBundle.loadString('assets/levels/grade5_levels.json');
    final levels = (jsonDecode(raw) as Map<String, dynamic>)['levels'] as List;
    final level = LevelDef.fromJson(levels[1] as Map<String, dynamic>);

    expect(level.title, '词尾帽子');
    expect(level.questions, hasLength(10));
    for (final question in level.questions) {
      expect(question.prompt, isNot(contains('part of speech')));
      expect(question.explain, isNotNull);
      expect(question.options, contains(question.answer));
      for (final option in question.options) {
        expect(option, contains('｜'));
      }
    }
    expect(level.questions[1].answer, 'adjective｜形容词（什么样）');
    expect(level.questions[1].explain, contains('-ful'));
  });

  testWidgets('wrong suffix-hat answer shows the explanation', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final level = LevelDef(
      id: 2,
      title: '词尾帽子',
      principle: '词缀构词',
      goal: '看词尾，就知道这个词是干什么的',
      passScore: 1,
      coach: '词尾像一顶帽子。帽子告诉你这个词的工作。',
      questions: const [
        LevelQuestion(
          type: 'choice',
          prompt: 'helpful 这顶帽子是干什么的？',
          word: 'helpful',
          zh: '有帮助的',
          options: [
            'adjective｜形容词（什么样）',
            'verb｜动词（做什么）',
          ],
          answer: 'adjective｜形容词（什么样）',
          explain: '-ful 是形容词帽子，表示“什么样”。helpful 是“有帮助的”。',
        ),
      ],
      tip: '要说“什么样”？用形容词帽子。',
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider(create: (_) => TtsService()),
          ChangeNotifierProvider(create: (_) => ProgressStore()),
        ],
        child: MaterialApp(home: LevelPlayScreen(level: level)),
      ),
    );

    expect(find.text('形容词（什么样）'), findsOneWidget);
    expect(find.text('动词（做什么）'), findsOneWidget);
    expect(find.textContaining('解析'), findsNothing);

    await tester.tap(find.text('动词（做什么）'));
    await tester.pump();

    expect(find.text('答案：adjective 形容词（什么样）'), findsOneWidget);
    expect(
      find.text('解析：-ful 是形容词帽子，表示“什么样”。helpful 是“有帮助的”。'),
      findsOneWidget,
    );
  });
}
