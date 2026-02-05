import 'package:flutter/material.dart';
import 'package:nordplayer/pages/main_page.dart';

void main() {
  runApp(const NordplayerApp());
}

class NordplayerApp extends StatelessWidget {
  const NordplayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nordplayer',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.teal)),
      home: const MainPage(),
    );
  }
}
