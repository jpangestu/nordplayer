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
            flex: 88, 
            child: Row(
              children: [
                Expanded(
                  flex: 2, 
                  child: Sidebar(), 
                ),
                
                // Main Content
                Expanded(
                  flex: 8, 
                  child: Container(
                    color: Colors.white,
                    child: Center(child: Text("Main Library Area")),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            flex: 12,
            child: Container(
              color: Colors.grey[100],
              child: const PlayerBar(),
            ),
          ),
        ],
      ),
    );
  }
}