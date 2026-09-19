import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/content_repository.dart';
import 'screens/home_screen.dart';
import 'services/progress_store.dart';
import 'services/srs_store.dart';
import 'services/tts_service.dart';
import 'theme/chenning_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final progress = ProgressStore();
  final srs = SrsStore();
  await Future.wait([progress.load(), srs.load()]);

  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => ContentRepository()),
        Provider(create: (_) => TtsService()),
        ChangeNotifierProvider.value(value: progress),
        ChangeNotifierProvider.value(value: srs),
      ],
      child: const ChenningApp(),
    ),
  );
}

class ChenningApp extends StatelessWidget {
  const ChenningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chenning',
      debugShowCheckedModeBanner: false,
      theme: ChenningTheme.light(),
      home: const HomeScreen(),
    );
  }
}
