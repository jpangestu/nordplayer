import 'package:flutter/material.dart';

import 'package:suara/widgets/progress_bar.dart';

class PlayerBar extends StatelessWidget {
  const PlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(flex: 3, child: Placeholder()),
        Expanded(
          flex: 7,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
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
                      iconSize: 40,
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
                ),
              ),
              ProgressBar(
                position: const Duration(minutes: 1, seconds: 15), // Mock data
                duration: const Duration(minutes: 3, seconds: 45), // Mock data
                onSeek: (newPosition) {
                  print("User seeked to: $newPosition");
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
