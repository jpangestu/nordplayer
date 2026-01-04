import 'package:flutter/material.dart';

import 'package:suara/pages/main_page.dart'; 

void main() {
  runApp(const SuaraApp());
}

class SuaraApp extends StatelessWidget {
  const SuaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Suara',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
      ),
      home: const MainPage(),
    );
  }
}