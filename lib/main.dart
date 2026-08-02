import 'package:flutter/material.dart';

import 'views/home_view.dart';

void main() {
  runApp(const LinguoReaderApp());
}

class LinguoReaderApp extends StatelessWidget {
  const LinguoReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI 语境阅读器',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF5C6BC0),
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF5C6BC0),
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: const HomeView(),
    );
  }
}
