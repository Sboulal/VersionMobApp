import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:syndic_app/pages/profile_page.dart';
import 'package:syndic_app/pages/dashboard_page.dart';
import 'package:syndic_app/pages/copropriete_page.dart';
import 'package:syndic_app/pages/documents_page.dart';
import 'package:syndic_app/pages/charges_page.dart'; 
import 'package:syndic_app/pages/assemblees_page.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  // 🟢 Variables dyal l'ajout (Formulaire Modal)
  final TextEditingController _titreController = TextEditingController();
  final TextEditingController _montantController = TextEditingController();
  DateTime? _dateEcheance;
  bool _isCreating = false;

  final List<Widget> _pages = [
    const DashboardPage(), // 1. Accueil
    const CoproprietePage(), // 2. Copropriété
    const ChargesPage(), // 3. Charges (Maghadich tban 7it ghatl3 modal)
    const AssembleesPage(), // 4. Assemblées
    const UnifiedProfilePage(), // 5. Profil
  ];

  // 🟢 L'API Bach t-généri l'Appel de Fonds
  Future<void> _ajouterAppelFonds(StateSetter setModalState, BuildContext modalContext) async {
    if (_titreController.text.isEmpty || _montantController.text.isEmpty || _dateEcheance == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez remplir tous les champs"), backgroundColor: Colors.red),
      );
      return;
    }

    setModalState(() => _isCreating = true);
    
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.post(
        Uri.parse("https://api.syndify.nomade-cloud.com/api/mobile/syndic/charges"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "title": _titreController.text,
          "amount": double.parse(_montantController.text),
          "due_date": "${_dateEcheance!.year}-${_dateEcheance!.month.toString().padLeft(2, '0')}-${_dateEcheance!.day.toString().padLeft(2, '0')}",
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        if (mounted) {
          Navigator.pop(modalContext); // Kaneseddo l'Bottom Sheet
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message']), backgroundColor: Colors.green),
          );
          // Kan-vidiw l'inputs l'merra jaya
          _titreController.clear();
          _montantController.clear();
          _dateEcheance = null;
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erreur: ${data['message']}"), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur de connexion"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setModalState(() => _isCreating = false);
    }
  }

  // 🟢 Fonction li katl3 l'Modal dyal l'appel de fonds w fiha l'formulaire
  void _showAddModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext modalContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalContext).viewInsets.bottom,
                left: 24, right: 24, top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50, height: 5,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text("Nouvel Appel de Fonds", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("Remplissez les détails pour générer l'appel.", style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 24),
                  
                  // 🟢 Input Titre
                  TextField(
                    controller: _titreController,
                    decoration: InputDecoration(
                      labelText: "Titre de l'appel",
                      hintText: "Ex: Appel de fonds T4 2026",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.title),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // 🟢 Input Montant Total
                  TextField(
                    controller: _montantController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: "Montant Global (MAD)",
                      hintText: "Ex: 12000.00",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.attach_money),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // 🟢 Input Date
                  InkWell(
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(primary: Color(0xFF003366)),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setModalState(() {
                          _dateEcheance = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month, color: Colors.grey),
                          const SizedBox(width: 12),
                          Text(
                            _dateEcheance == null 
                                ? "Date d'échéance" 
                                : "${_dateEcheance!.day.toString().padLeft(2, '0')}/${_dateEcheance!.month.toString().padLeft(2, '0')}/${_dateEcheance!.year}",
                            style: TextStyle(
                              color: _dateEcheance == null ? Colors.black54 : Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // 🟢 Bouton Valider
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isCreating ? null : () => _ajouterAppelFonds(setModalState, modalContext),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003366),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isCreating
                          ? const SizedBox(
                              width: 24, height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              "Générer l'appel de fonds",
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        );
      }
    );
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      // 🟢 Ila kllika 3la l'bouton f l'west, tl3 modal bla matbdel l'page
      _showAddModal();
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Darouri bach ibano b 5
        backgroundColor: Colors.white,
        elevation: 10,
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.apartment_outlined),
            activeIcon: Icon(Icons.apartment),
            label: 'Copropriété',
          ),
          
          // 🟢 Hada l'bouton + li f blast Charges (Index 2)
          BottomNavigationBarItem(
            icon: Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF003366), 
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: const Color(0xFF003366).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
                ]
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 24),
            ),
            label: '', // Khlitha khawya bach yban l'bouton n9i w mcenter
          ),
          
          const BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined), // Ou Icons.description_outlined
            activeIcon: Icon(Icons.folder),
            label: 'Assemblées',
          ),
          const BottomNavigationBarItem(
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