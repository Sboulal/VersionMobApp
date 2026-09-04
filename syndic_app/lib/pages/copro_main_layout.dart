import 'package:flutter/material.dart';
import 'copro_dashboard_page.dart'; 
import 'copro_charges_page.dart'; 
import 'copro_documents_page.dart'; 
import 'copro_annonces_page.dart'; 
import 'profile_page.dart'; 

class CoproMainLayout extends StatefulWidget {
  const CoproMainLayout({super.key});

  @override
  State<CoproMainLayout> createState() => _CoproMainLayoutState();
}

class _CoproMainLayoutState extends State<CoproMainLayout> {
  int _currentIndex = 0;
  final Color mainBlue = const Color(0xFF1A5EAC);

  // 1. T7eydou les doublons hna bach yb9aw ghir 5 pages
  final List<Widget> _pages = [
    const CoproDashboardPage(), // Index 0: Accueil
    const CoproChargesPage(),   // Index 1: Charges
    const CoproDocumentsPage(), // Index 2: Documents
    const CoproAnnoncesPage(),  // Index 3: Annonces
    const UnifiedProfilePage(), // Index 4: Profil
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: mainBlue,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Accueil"),       // Index 0
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: "Charges"), // Index 1
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: "Documents"),   // Index 2
          BottomNavigationBarItem(icon: Icon(Icons.campaign), label: "Annonces"),  // Index 3
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),      // Index 4
        ],
      ),
    );
  }
}