import 'package:flutter/material.dart';

class Playback extends StatelessWidget {
  const Playback({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: .center,
      children: [
        IconButton(
          // isSelected: true,
          icon: Icon(Icons.shuffle),
          iconSize: 24,
          onPressed: () {},
        ),
        IconButton(
          // isSelected: true,
          icon: Icon(Icons.skip_previous),
          iconSize: 24,
          onPressed: () {},
        ),
        IconButton(
          isSelected: true,
          icon: Icon(Icons.play_circle),
          iconSize: 36,
          onPressed: () {},
        ),
        IconButton(
          // isSelected: true,
          icon: Icon(Icons.skip_next),
          iconSize: 24,
          onPressed: () {},
        ),
        IconButton(
          // isSelected: true,
          icon: Icon(Icons.repeat),
          iconSize: 24,
          onPressed: () {},
        ),
      ],
    );
  }
}
