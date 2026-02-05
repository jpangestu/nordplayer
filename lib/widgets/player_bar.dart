import 'package:flutter/material.dart';

class PlayerBar extends StatelessWidget {
  const PlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(height: 90, color: Theme.of(context).colorScheme.surfaceContainer,);
  }
}