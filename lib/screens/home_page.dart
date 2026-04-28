import 'package:flutter/material.dart';
import '../tab/search_tab.dart';
import '../tab/champions_tab.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          title: const Text('LOL ENCYCLOPEDIA', 
            style: TextStyle(color: Color(0xFF732571), fontWeight: FontWeight.bold, letterSpacing: 2)),
          centerTitle: true,
        ),
        body: const TabBarView(
          children: [
            SearchTab(),
            ChampionsTab(),
          ],
        ),
        bottomNavigationBar: Container(
          color: Colors.black,
          child: const TabBar(
            labelColor: Color(0xFF732571),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF610463),
            tabs: [
              Tab(icon: Icon(Icons.search), text: "Buscador"),
              Tab(icon: Icon(Icons.grid_view_rounded), text: "Campeones"),
            ],
          ),
        ),
      ),
    );
  }
}