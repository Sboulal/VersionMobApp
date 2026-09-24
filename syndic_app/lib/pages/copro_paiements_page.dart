import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syndic_app/pages/copro_charge_detail_page.dart';
import 'package:syndic_app/pages/copro_main_layout.dart'; 
// import 'package:syndic_app/pages/notifications_page.dart';
import 'package:syndic_app/pages/profile_page.dart'; 
import 'package:syndic_app/pages/forgot_password_page.dart'; 
import 'package:syndic_app/pages/login_page.dart'; 
import 'package:syndic_app/pages/NotificationsScreen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
          SizedBox(width: 12.w),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 14.sp,
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
              SizedBox(width: 8),
              
              // Nom de la résidence
              Expanded(
                child: Text(
                  residenceName.isNotEmpty ? "Sindy | $residenceName" : "Sindy",
                  style:  TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8),
              
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
              SizedBox(width: 12.w),
              
            // ======================================================
              // USER DROPDOWN (AVATAR)
              // ======================================================
              PopupMenuButton<String>(
                offset: const Offset(0, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                color: Colors.white,
                elevation: 4,
                // ... (khlli l'code dyal onSelected kima howa) ...
                itemBuilder: (BuildContext context) => [
                  _buildPopupMenuItem('profile', Icons.person_outline, 'Profil'),
                  _buildPopupMenuItem('password', Icons.lock_outline, 'Changer mot de passe'),
                  const PopupMenuDivider(),
                  _buildPopupMenuItem('logout', Icons.logout, 'Déconnexion', isDestructive: true),
                ],
                child: Container(
                  // 🟢 Nzidou padding sghir bach tban l'bordure mzyan
                  padding: const EdgeInsets.all(2), 
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2), // L'khat lbyed li dayr b tswira
                  ),
                  child: CircleAvatar(
                    radius: 22, // 🔥 HNA KBERNA TSWIRA (kanet 14, redinaha 22)
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
          SizedBox(height: 20),
          
          // Titre de la page
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 3),
          
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

class CoproPaiementsPage extends StatefulWidget {
  const CoproPaiementsPage({super.key});

  @override
  State<CoproPaiementsPage> createState() => _CoproPaiementsPageState();
}

class _CoproPaiementsPageState extends State<CoproPaiementsPage> {
  final Color mainBlue = const Color(0xFF1A5EAC);
  final Color bgLight = const Color(0xFFF4F6F9);

  bool _isLoading = true;
  List<dynamic> _paiementsList = [];
  
  // Variables dynamiques pour le header
  String _residenceName = "Chargement...";
  String _photoUrl = "";

  @override
  void initState() {
    super.initState();
    _fetchPaiements();
  }

  Future<void> _fetchPaiements() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    // Pré-chargement depuis le cache local pour un affichage instantané
    setState(() {
      _residenceName = prefs.getString('residence_name') ?? "Ma Résidence";
      _photoUrl = prefs.getString('photo_url') ?? "";
    });

    try {
      final response = await http.get(
        Uri.parse("https://api.syndify.nomade-cloud.com/api/mobile/copro/mes-paiements"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
      );
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _paiementsList = data['data'];

          // Mise à jour de la résidence et photo depuis l'API si dispo
          if (data['residence_name'] != null) {
            _residenceName = data['residence_name'];
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
      setState(() => _isLoading = false);
    }
  }

  Color _hexToColor(String hexString) {
    var hexColor = hexString.replaceAll("#", "");
    if (hexColor.length == 6) hexColor = "FF$hexColor";
    return Color(int.parse("0x$hexColor"));
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
              // ======================================================
              // UTILISATION DE CUSTOMHEADER (Dropdown activé)
              // ======================================================
              CustomHeader(
               title: "Mes Paiements",
               subtitle: "Historique de vos transactions",
               showBackButton: true,
               residenceName: _residenceName,
               photoUrl: _photoUrl,
               onBackTap: () {
                 if (Navigator.canPop(context)) {
                   Navigator.pop(context);
                 }
               }
                ),

              // ======================================================
              // RESTE DU CONTENU
              // ======================================================
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(color: mainBlue),
                      )
                    : _buildContent(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
          child: Text(
            "Historique",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey.shade800,
            ),
          ),
        ),
        Expanded(
          child: _paiementsList.isEmpty
              ? Center(
                  child: Text(
                    "Aucun paiement enregistré.",
                    style: TextStyle(color: Colors.blueGrey.shade400),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  itemCount: _paiementsList.length,
                  itemBuilder: (context, index) {
                    final p = _paiementsList[index];
                    final modeColor = _hexToColor(p['colorHex']);

                    String infoLine = "${p['date']} | ${p['amount']} | ${p['mode']}";
                    String refText = "";
                    if (p['reference'] != null &&
                        p['reference'].toString().trim().isNotEmpty) {
                      refText = "Réf. ${p['reference'].toString().trim()}";
                    }

                    return Container(
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
                          )
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: modeColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.credit_card,
                                color: modeColor, size: 24),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(infoLine,
                                    style:  TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14.sp,
                                        color: Colors.black87)),
                                if (refText.isNotEmpty) ...[
                                   SizedBox(height: 4.h),
                                  Text(refText,
                                      style:  TextStyle(
                                          color: Colors.black54,
                                          fontSize: 12.sp,
                                          fontStyle: FontStyle.italic)),
                                ]
                              ],
                            ),
                          ),
                          const Icon(Icons.check_circle,
                              color: Color(0xFF1B5E20), size: 22),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCitySkyline() {
    final color = mainBlue.withOpacity(0.03);
    return SizedBox(
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
    );
  }

  Widget _buildBuilding(double width, double height, Color color) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8), topRight: Radius.circular(8)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
            (height / 25).floor(),
            (index) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                        width: 8,
                        height: 10,
                        color: Colors.white.withOpacity(0.4)),
                    Container(
                        width: 8,
                        height: 10,
                        color: Colors.white.withOpacity(0.4)),
                    if (width > 55)
                      Container(
                          width: 8,
                          height: 10,
                          color: Colors.white.withOpacity(0.4)),
                  ],
                )),
      ),
    );
  }
}