import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:syndic_app/pages/copro_charge_detail_page.dart';
import 'package:syndic_app/pages/copro_main_layout.dart'; 
// import 'package:syndic_app/pages/notifications_page.dart';
import 'package:syndic_app/pages/profile_page.dart'; // 🟢 IMPORT AJOUTÉ
import 'package:syndic_app/pages/forgot_password_page.dart'; // 🟢 IMPORT AJOUTÉ
import 'package:syndic_app/pages/login_page.dart'; // 🟢 IMPORT AJOUTÉ
import 'package:syndic_app/pages/NotificationsScreen.dart';
// ==========================================
// WIDGET RÉUTILISABLE : CUSTOM HEADER
// ==========================================
class CustomHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String residenceName;
  final String photoUrl;
  final bool showBackButton;
  final String userRole;
  final VoidCallback? onBackTap;
  final VoidCallback? onNotificationTap;

  const CustomHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.residenceName,
    required this.photoUrl,
    this.showBackButton = false,
    this.userRole = 'copro',
    this.onBackTap,
    this.onNotificationTap,
  });

  // Fonction pour créer les items du menu déroulant
  PopupMenuItem<String> _buildPopupMenuItem(String value, IconData icon, String text, {bool isDestructive = false}) {
    final Color mainBlue = const Color(0xFF1A5EAC);
    final color = isDestructive ? Colors.redAccent : mainBlue;

    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color mainBlue = const Color(0xFF1A5EAC);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: mainBlue,
        image: DecorationImage(
          image: const NetworkImage(
            "https://images.unsplash.com/photo-1460317442991-0ec209397118?q=80&w=2070&auto=format&fit=crop",
          ),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            mainBlue.withOpacity(0.85),
            BlendMode.srcOver,
          ),
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 16,
        left: 16,
        right: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Bouton Retour
              if (showBackButton && onBackTap != null) 
                InkWell(
                  onTap: onBackTap,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 16.0),
                    child: Icon(Icons.arrow_back, color: Colors.white, size: 26),
                  ),
                ),
              
              const Icon(Icons.apartment, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              
              // Nom de la résidence
              Expanded(
                child: Text(
                  residenceName.isNotEmpty ? "Sindy | $residenceName" : "Sindy",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              
              // Bouton Notifications
              InkWell(
             onTap: onNotificationTap ?? () {
               // 🟢 S'il n'y a pas d'action définie, on ouvre la page par défaut
               Navigator.push(
                 context,
                 MaterialPageRoute(
                   builder: (context) => NotificationsScreen(role: userRole),
                 ),
               );
             },
             child: const Icon(Icons.notifications_none, color: Colors.white, size: 26),
           ),
              const SizedBox(width: 12),
              
              // ======================================================
              // USER DROPDOWN (AVATAR)
              // ======================================================
              PopupMenuButton<String>(
                offset: const Offset(0, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.white,
                elevation: 4,
                onSelected: (value) async {
                  if (value == 'profile') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const UnifiedProfilePage()),
                    );
                  } else if (value == 'password') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
                    );
                  } else if (value == 'logout') {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('auth_token');
                    
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                        (route) => false,
                      );
                    }
                  }
                },
                itemBuilder: (BuildContext context) => [
                  _buildPopupMenuItem('profile', Icons.person_outline, 'Profil'),
                  _buildPopupMenuItem('password', Icons.lock_outline, 'Changer mot de passe'),
                  const PopupMenuDivider(),
                  _buildPopupMenuItem('logout', Icons.logout, 'Déconnexion', isDestructive: true),
                ],
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.white,
                    backgroundImage: photoUrl.isNotEmpty
                        ? NetworkImage(photoUrl)
                        : const NetworkImage(
                            "https://ui-avatars.com/api/?name=Copro&background=ffffff&color=1A5EAC&size=128&bold=true",
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Titre de la page
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          
          // Sous-titre
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 1. LISTE DES CHARGES
// ==========================================
class CoproChargesPage extends StatefulWidget {
  final bool showBackButton; 
  
  const CoproChargesPage({super.key, this.showBackButton = false}); 

  @override
  State<CoproChargesPage> createState() => _CoproChargesPageState();
}

class _CoproChargesPageState extends State<CoproChargesPage> {
  final Color mainBlue = const Color(0xFF1A5EAC);
  final Color bgLight = const Color(0xFFF4F6F9);

  bool _isLoading = true;
  String _solde = "0,00 MAD";
  double _rawSolde = 0;
  List<dynamic> _chargesList = [];
  
  // 🟢 Données dynamiques initialisées vides (plus de fausses données)
  String _residenceName = "Chargement..."; 
  String _lotInfo = "";
  String _photoUrl = "";

  @override
  void initState() {
    super.initState();
    _fetchCharges();
  }

  Future<void> _fetchCharges() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    // Pré-remplissage avec le cache local pour éviter l'écran vide
    setState(() {
      _residenceName = prefs.getString('residence_name') ?? "Ma Résidence";
      _lotInfo = prefs.getString('lot_info') ?? "";
      _photoUrl = prefs.getString('photo_url') ?? "";
    });

    try {
      final response = await http.get(
        Uri.parse("https://api.syndify.nomade-cloud.com/api/mobile/copro/mes-charges"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
      );
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _solde = data['solde'] ?? "0,00 MAD";
          _rawSolde = (data['raw_solde'] ?? 0).toDouble();
          _chargesList = data['data'] ?? [];
          
          if (data['residence_name'] != null) {
            _residenceName = data['residence_name'];
          }
          if (data['lot_info'] != null) {
            _lotInfo = data['lot_info'];
          }
          if (data['user'] != null && data['user']['photo_url'] != null) {
            _photoUrl = data['user']['photo_url'];
          }
          
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Charges error: $e");
      setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    if (status == "Payé") return const Color(0xFF1B5E20); 
    if (status == "Impayé") return const Color(0xFFD32F2F); 
    return Colors.orange.shade800; // Pour "Partiel"
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildCitySkyline(), 
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🟢 Utilisation du composant CustomHeader
              CustomHeader(
                title: "Mes charges",
                subtitle: _lotInfo.isNotEmpty ? "$_residenceName • $_lotInfo" : _residenceName,
                 showBackButton: true,
                  residenceName: _residenceName,
                  photoUrl: _photoUrl,
                  onBackTap: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  }
                ),

              // 2. CONTENU DE LA PAGE CHARGES
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator(color: mainBlue))
                    : SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Carte de Solde globale
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade100),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.account_balance_wallet, color: Colors.blueGrey.shade400, size: 20),
                                      const SizedBox(width: 8),
                                      const Text("Solde de compte", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black54)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _rawSolde > 0
                                        ? _solde
                                        : (_rawSolde < 0
                                            ? "${_rawSolde.abs().toStringAsFixed(2)} MAD (Crédit)"
                                            : "À jour (0.00 MAD)"),
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: _rawSolde > 0
                                          ? const Color(0xFFD32F2F)
                                          : mainBlue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            const Text(
                              "Historique des charges",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black54),
                            ),
                            const SizedBox(height: 12),

                            // Liste des charges
                            _chargesList.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 40),
                                    child: Center(
                                      child: Text(
                                        "Aucune charge enregistrée.",
                                        style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 15),
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _chargesList.length,
                                    itemBuilder: (context, index) {
                                      final charge = _chargesList[index];
                                      final statusColor = _getStatusColor(charge['status'] ?? '');

                                      return InkWell(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => CoproChargeDetailPage(
                                                chargeData: charge,
                                                residenceName: _residenceName,
                                                photoUrl: _photoUrl,
                                              ),
                                            ),
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(16),
                                        child: Container(
                                          margin: const EdgeInsets.only(bottom: 12),
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: Colors.grey.shade100),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.03),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: mainBlue.withOpacity(0.08),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(Icons.receipt_long, color: mainBlue, size: 24),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      charge['title'] ?? 'Charge',
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      "Émise le : ${charge['date_emission'] ?? 'N/A'}",
                                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                                    ),
                                                    Text(
                                                      "Échéance : ${charge['date_echeance'] ?? 'N/A'}",
                                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    "${charge['amount'] ?? 0}",
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: statusColor.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      charge['status'] ?? '',
                                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // CITY SKYLINE
  // ==========================================================
  Widget _buildCitySkyline() {
    final color = mainBlue.withOpacity(0.03);

    return IgnorePointer(
      child: SizedBox(
        height: 220,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildBuilding(50, 120, color),
            _buildBuilding(65, 180, color),
            _buildBuilding(45, 140, color),
            _buildBuilding(75, 210, color),
            _buildBuilding(60, 160, color),
            _buildBuilding(50, 100, color),
          ],
        ),
      ),
    );
  }

  Widget _buildBuilding(double width, double height, Color color) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          (height / 25).floor(),
          (index) => Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(width: 8, height: 10, color: Colors.white.withOpacity(0.4)),
              Container(width: 8, height: 10, color: Colors.white.withOpacity(0.4)),
              if (width > 55)
                Container(width: 8, height: 10, color: Colors.white.withOpacity(0.4)),
            ],
          ),
        ),
      ),
    );
  }
}