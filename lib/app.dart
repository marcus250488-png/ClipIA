import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

class ClipIaApp extends StatelessWidget {
  const ClipIaApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'ClipIA',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8B5CF6), brightness: Brightness.dark),
      scaffoldBackgroundColor: const Color(0xFF0B0D12),
    ),
    home: const HomeScreen(),
  );
}
