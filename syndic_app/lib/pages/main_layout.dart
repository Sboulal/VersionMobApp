import 'package:flutter/material.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  // Had l-variable kay-3ql 3la ayna page 7na fiha daba (kaybda b 0 li hiya Accueil)
  int _selectedIndex = 0;

  // Hna kan-7tto les pages li ghadi yt-bdlo f l-wst
  // (Daba dert ghir Text bash n-testew, mn b3d t-3wdiha b les pages dyalk bhal HomePage(), ProfilPage()...)
  final List<Widget> _pages = [
    const Center(child: Text('Page Dashboard', style: TextStyle(fontSize: 24))),
    const Center(child: Text('Page Coproprietaire', style: TextStyle(fontSize: 24))),
    const Center(child: Text('Page Profil', style: TextStyle(fontSize: 24))),
  ];

  // Had l-fonction kat-tbdel l-index mlli kan-dghto 3la chi icône l-ta7t
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Syndic App'),
        centerTitle: true,
      ),
      // l-body kay-tbdel 3la 7sab l-index
      body: _pages[_selectedIndex], 
      
      // Hada howa l-menu li kay-bqa tabet l-ta7t
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report_problem),
            label: 'Réclamations',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}