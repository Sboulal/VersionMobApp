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
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:syndic_app/pages/add_lot_modal.dart';
import 'package:syndic_app/pages/add_assemblee_modal.dart';
import 'package:syndic_app/pages/add_paiement_modal.dart';
import 'package:syndic_app/pages/syndic_validation_page.dart';

// 🟢 ZIDNA LES IMPORTS DYAL LES FICHIERS JDAD LI KRÉYITI
import 'package:syndic_app/pages/add_depense_modal.dart';
import 'package:syndic_app/pages/add_annonce_modal.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  // Variables dyal l'ajout Appel Fonds (Formulaire Modal)
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

  // L'API Bach t-généri l'Appel de Fonds
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

void _showActionMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            // 🟢 Zidna padding l-te7t bash ma-dkhlsh l-modal f l-barre d-navigation dyal l-iphone
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min, // 🟢 Hna s-ser: kat-goul l-modal takhod ghir l-3bar li fih l-contenu
              children: [
                SizedBox(height: 12.h),
                Center(
                  child: Container(
                    width: 50.w, 
                    height: 5.h,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300, 
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
                SizedBox(height: 14.h),
                Text(
                  "Que souhaitez-vous ajouter ?", 
                  style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.bold, color: const Color(0xFF003366))
                ),
                SizedBox(height: 10.h),
                
                // 🟢 BDLLNA "Expanded" b "Flexible" bash l-khwa l-lta7t y-t7iyd
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(bottom: 16.h),
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // 🟢 Hta hadi darouriya l-SingleChildScrollView
                      children: [
                        _buildMenuItem(Icons.account_balance_wallet, "Nouvel appel de fonds", () {
                          Navigator.pop(context);
                          _showAppelFondsModal();
                        }),
                        
                        _buildMenuItem(Icons.apartment, "Ajouter un lot / copropriétaire", () {
                          Navigator.pop(context);
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => AddLotFormModal(
                              mainBlue: const Color(0xFF1A5EAC), 
                              onSuccess: () {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lot ajouté avec succès!"), backgroundColor: Colors.green));
                              }
                            ),
                          );
                        }),
                        
                        _buildMenuItem(Icons.payment, "Enregistrer une cotisation", () {
                          Navigator.pop(context);
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => AddPaiementModal(
                              mainBlue: const Color(0xFF1A5EAC), 
                              onSuccess: () {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Paiement enregistré avec succès !"), backgroundColor: Colors.green));
                              }
                            ),
                          );
                        }),
                        
                        _buildMenuItem(Icons.receipt_long, "Enregistrer une dépense", () {
                          Navigator.pop(context);
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => AddDepenseModal(
                              mainBlue: const Color(0xFF1A5EAC),
                              onSuccess: () {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Dépense enregistrée avec succès !"), backgroundColor: Colors.green));
                              }
                            ),
                          );
                        }),
                        
                        _buildMenuItem(Icons.event_note, "Nouvelle planification", () {
                          Navigator.pop(context);
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => AddAssembleeModal(
                              mainBlue: const Color(0xFF1A5EAC), 
                              onSuccess: () {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("AG planifiée avec succès !"), backgroundColor: Colors.green));
                              }
                            ),
                          );
                        }),
                        
                        _buildMenuItem(Icons.campaign, "Publier une annonce", () {
                          Navigator.pop(context);
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => AddAnnonceModal(
                              mainBlue: const Color(0xFF1A5EAC),
                              onSuccess: () {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Annonce publiée avec succès !"), backgroundColor: Colors.green));
                              }
                            ),
                          );
                        }),
                        
                        _buildMenuItem(Icons.person_add_alt_1, "Demandes d'inscription", () {
                          Navigator.pop(context);
                          Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (context) => const SyndicValidationPage())
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }
// 🟢 Sghrna l-padding dyal item chwiya bash y-jiw m-sttfin n9iyin
  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      dense: true, // 🟢 Kay-n9ess l-ertefa3 l-zayed
      visualDensity: const VisualDensity(vertical: -1),
      contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 2.h),
      leading: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: const Color(0xFF003366).withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF003366), size: 20.sp),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5.sp)),
      trailing: Icon(Icons.chevron_right, size: 18.sp, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }

  void _showAppelFondsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (BuildContext modalContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalContext).viewInsets.bottom,
                left: 24.w, right: 24.w, top: 24.h,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50.w, height: 5.h,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10.r)),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Text("Nouvel Appel de Fonds", style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8.h),
                  Text("Remplissez les détails pour générer l'appel.", style: TextStyle(color: Colors.grey.shade600, fontSize: 14.sp)),
                  SizedBox(height: 24.h),
                  
                  // Input Titre
                  TextField(
                    controller: _titreController,
                    decoration: InputDecoration(
                      labelText: "Titre de l'appel",
                      hintText: "Ex: Appel de fonds T4 2026",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                      prefixIcon: const Icon(Icons.title),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  
                  // Input Montant Total
                  TextField(
                    controller: _montantController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: "Montant Global (MAD)",
                      hintText: "Ex: 12000.00",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                      prefixIcon: const Icon(Icons.attach_money),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  
                  // Input Date
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
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month, color: Colors.grey),
                          SizedBox(width: 12.w),
                          Text(
                            _dateEcheance == null 
                                ? "Date d'échéance" 
                                : "${_dateEcheance!.day.toString().padLeft(2, '0')}/${_dateEcheance!.month.toString().padLeft(2, '0')}/${_dateEcheance!.year}",
                            style: TextStyle(
                              color: _dateEcheance == null ? Colors.black54 : Colors.black87,
                              fontSize: 16.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 32.h),
                  
                  // Bouton Valider
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isCreating ? null : () => _ajouterAppelFonds(setModalState, modalContext),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003366),
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      ),
                      child: _isCreating
                          ? SizedBox(
                              width: 24.w, height: 24.w,
                              child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              "Générer l'appel de fonds",
                              style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  SizedBox(height: 32.h),
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
      _showActionMenu();
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
        type: BottomNavigationBarType.fixed,
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
          
          BottomNavigationBarItem(
            icon: Container(
              margin: EdgeInsets.only(bottom: 4.h),
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: const Color(0xFF003366), 
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: const Color(0xFF003366).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
                ]
              ),
              child: Icon(Icons.add, color: Colors.white, size: 24.sp),
            ),
            label: '',
          ),
          
          const BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined),
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
        selectedItemColor: const Color(0xFF003366), 
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp),
        unselectedLabelStyle: TextStyle(fontSize: 11.sp),
        onTap: _onItemTapped,
      ),
    );
  }
}