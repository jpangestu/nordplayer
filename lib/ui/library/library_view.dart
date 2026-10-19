import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/config/app_config.dart';

class LibraryView extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<LibraryView> createState() => LibraryViewState();
}

class LibraryViewState extends ConsumerState<LibraryView> {
  @override
  Widget build(BuildContext context) {
    final appConfig = ref.watch(appConfigProvider);
    final themeMode = ref.watch(appConfig.themeMode.provider);

    return Scaffold(
      body: Center(child: Column(children: [Text('Current Theme: ${themeMode.name}')])),
    );
  }
}
