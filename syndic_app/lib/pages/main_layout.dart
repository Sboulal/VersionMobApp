import 'package:flutter/material.dart';
import 'package:syndic_app/pages/profile_page.dart';

import 'package:syndic_app/pages/dashboard_page.dart';
import 'package:syndic_app/pages/copropriete_page.dart';
import 'package:syndic_app/pages/documents_page.dart';
import 'package:syndic_app/pages/charges_page.dart';
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(), // 1. Accueil
    const CoproprietePage(), // 2. Copropriété
    const ChargesPage(), // 3. Charges
    const DocumentsPage(), // 4. Documents
    const UnifiedProfilePage(), // 5. Profil
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Darouri bach ibano b 5
        backgroundColor: Colors.white,
        elevation: 10,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.apartment_outlined),
            activeIcon: Icon(Icons.apartment),
            label: 'Copropriété',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'Charges',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined), // Ou Icons.description_outlined
            activeIcon: Icon(Icons.folder),
            label: 'Documents',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        currentIndex: _selectedIndex,
        // Loun zre9 li ghadi m3a l-maquette jdida (Dark Blue)
        selectedItemColor: const Color(0xFF003366), 
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        onTap: _onItemTapped,
      ),
    );
  }
}