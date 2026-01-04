import 'package:flutter/material.dart';

class PlayerBar extends StatelessWidget {
  const PlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          onPressed: () {},
          icon: Icon(Icons.repeat),
        ),
        IconButton(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          onPressed: () {},
          icon: Icon(Icons.skip_previous),
        ),
        IconButton(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          onPressed: () {},
          icon: Icon(Icons.play_circle),
        ),
        IconButton(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          onPressed: () {},
          icon: Icon(Icons.skip_next),
        ),
        IconButton(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          onPressed: () {},
          icon: Icon(Icons.shuffle),
        ),
      ],
    );
  }
}