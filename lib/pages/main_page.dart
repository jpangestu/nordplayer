import 'package:flutter/material.dart';

import 'package:suara/widgets/player_bar.dart'; 
import 'package:suara/widgets/sidebar.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  // bool wideScreen = false;

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();

  //   final double width = MediaQuery.of(context).size.width;
  //   wideScreen = width > 840;
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Sidebar(),
                // VerticalDivider(thickness: 1,),
                // Main Content
                Expanded(
                  flex: 8, 
                  child: Center(child: Text("Main Library Area")),
                ),
              ],
            ),
          ),
          
          // Divider(thickness: 1,),
          const PlayerBar(),
        ],
      ),
    );
  }
}