import 'package:flutter/material.dart';

import 'package:suara/widgets/player_bar.dart'; 
import 'package:suara/widgets/sidebar.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 2, 
                  child: Sidebar(), 
                ),
                
                // Main Content
                Expanded(
                  flex: 8, 
                  child: Center(child: Text("Main Library Area")),
                ),
              ],
            ),
          ),

          SizedBox(
            height: 90,
            width: double.infinity,
            child: const PlayerBar(),
          ),
        ],
      ),
    );
  }
}