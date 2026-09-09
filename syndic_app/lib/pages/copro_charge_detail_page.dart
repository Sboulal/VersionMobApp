import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:syndic_app/pages/copro_main_layout.dart'; 
// import 'package:syndic_app/pages/notifications_page.dart';
import 'package:syndic_app/pages/profile_page.dart'; // 🟢 Ajouté pour le dropdown
import 'package:syndic_app/pages/forgot_password_page.dart'; // 🟢 Ajouté pour le dropdown
import 'package:syndic_app/pages/login_page.dart'; // 🟢 Ajouté pour le dropdown

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
// DÉTAIL DE LA CHARGE
// ==========================================
class CoproChargeDetailPage extends StatelessWidget {
  final Map<String, dynamic> chargeData;
  final String residenceName;
  final String photoUrl;

  const CoproChargeDetailPage({
    super.key,
    required this.chargeData,
    required this.residenceName,
    required this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final Color mainBlue = const Color(0xFF1A5EAC);
    final String status = chargeData['status'] ?? 'Inconnu';
    final bool isUnpaid = status == "Impayé";
    final Color statusColor = isUnpaid ? const Color(0xFFD32F2F) : const Color(0xFF1B5E20);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🟢 Utilisation dyal CustomHeader avec le nouveau dropdown inclus
            CustomHeader(
              title: chargeData['title'] ?? 'Détail de la charge',
              subtitle: "Informations et téléchargement",
               showBackButton: true,
                  residenceName:residenceName,
                  photoUrl: photoUrl,
                  onBackTap: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  }
                ),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Carte de Détail (Montant et Dates)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Montant", style: TextStyle(color: Colors.black54, fontSize: 14)),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isUnpaid ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                "${chargeData['amount'] ?? 0}",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Date d'émission :", style: TextStyle(fontWeight: FontWeight.w500)),
                              Text("${chargeData['date_emission'] ?? 'N/A'}", style: const TextStyle(color: Colors.black54)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Échéance :", style: TextStyle(fontWeight: FontWeight.w500)),
                              Text("${chargeData['date_echeance'] ?? 'N/A'}", style: const TextStyle(color: Colors.black54)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(Icons.circle, size: 12, color: statusColor),
                              const SizedBox(width: 8),
                              Text(
                                status,
                                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Bouton Télécharger
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: mainBlue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: mainBlue.withOpacity(0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.file_download_outlined),
                        label: const Text(
                          "Télécharger l'appel de charges",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Téléchargement du PDF en cours...")),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}