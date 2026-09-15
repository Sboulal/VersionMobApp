import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:syndic_app/pages/pdf_viewer_page.dart';
import 'package:syndic_app/pages/NotificationsScreen.dart';
import 'package:syndic_app/pages/profile_page.dart';
import 'package:syndic_app/pages/forgot_password_page.dart';
import 'package:syndic_app/pages/login_page.dart';

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
// PAGE DES DOCUMENTS (COPRO)
// ==========================================
class CoproDocumentsPage extends StatefulWidget {
  final bool showBackButton;

  const CoproDocumentsPage({super.key, this.showBackButton = false});

  @override
  State<CoproDocumentsPage> createState() => _CoproDocumentsPageState();
}

class _CoproDocumentsPageState extends State<CoproDocumentsPage> {
  final Color mainBlue = const Color(0xFF1A5EAC);
  final Color bgLight = const Color(0xFFF4F6F9);

  bool _isLoading = true;
  List<dynamic> _groupedDocuments = [];
  
  // 🟢 1. 7aydi "final" bash n9dro nbdlohom
  String _residenceName = "Chargement...";
  String _photoUrl = "";
  final Map<String, dynamic>? _dashboardData = null;

  @override
  void initState() {
    super.initState();
    _fetchDocuments();
  }

  Future<void> _fetchDocuments() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    // 🟢 2. Récupérer tswira w smit résidence men l'cache b7al page Charges
    setState(() {
      _residenceName = prefs.getString('residence_name') ?? "Ma Résidence";
      _photoUrl = prefs.getString('photo_url') ?? "";
    });

    try {
      final response = await http.get(
        Uri.parse("https://api.syndify.nomade-cloud.com/api/mobile/copro/mes-documents"),
        headers: {"Authorization": "Bearer $token"},
      );
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        setState(() {
          _groupedDocuments = data['data'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // 🟢 LA FONCTION POUR OUVRIR LE PDF
  void _openFile(String url, String fileName) {
    if (url.toLowerCase().endsWith('.pdf')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfViewerPage(pdfUrl: url, documentName: fileName),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Format de fichier non pris en charge pour la lecture interne.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: Stack(
        children: [
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _buildCitySkyline(),
          ),
          
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🟢 Appel propre au CustomHeader (sans les paramètres qui causent l'erreur)
                CustomHeader(
                  title: "Vos Documents",
                  subtitle: "Règlements, PV et factures",
                  
                  residenceName: _residenceName,
                  photoUrl: _photoUrl,
                  showBackButton: widget.showBackButton,
              onBackTap: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              
    
                  
                ),
                Expanded(
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator(color: mainBlue))
                      : _buildContent(),
                ),
              ],
            ),
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
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
          child: Text(
            "Dossiers et Fichiers",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade800),
          ),
        ),
        Expanded(
          child: _groupedDocuments.isEmpty
              ? Center(child: Text("Aucun document disponible.", style: TextStyle(color: Colors.blueGrey.shade400)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: _groupedDocuments.length,
                  itemBuilder: (context, index) {
                    final group = _groupedDocuments[index];
                    final files = group['files'] as List;

                    return Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        initiallyExpanded: true,
                        iconColor: mainBlue,
                        collapsedIconColor: Colors.blueGrey,
                        leading: Icon(Icons.folder_open_rounded, color: Colors.amber.shade600, size: 28),
                        title: Text(
                          group['category'],
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        children: files.isEmpty
                            ? [
                                Padding(
                                  padding: const EdgeInsets.only(left: 56.0, bottom: 12.0),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text("Dossier vide", style: TextStyle(color: Colors.grey.shade400, fontSize: 13, fontStyle: FontStyle.italic)),
                                  ),
                                )
                              ]
                            : files.map((file) {
                                return GestureDetector(
                                  // 🟢 CLIC SUR TOUTE LA LIGNE
                                  onTap: () => _openFile(file['url'], file['name']),
                                  child: Container(
                                    margin: const EdgeInsets.only(left: 24.0, right: 8.0, bottom: 12.0),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade100),
                                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                                          child: Icon(Icons.picture_as_pdf, color: Colors.red.shade400, size: 24),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(file['name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87)),
                                              const SizedBox(height: 4),
                                              Text("${file['date']} • ${file['size']}", style: const TextStyle(color: Colors.black54, fontSize: 11)),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.visibility, color: Colors.black54, size: 20),
                                              // 🟢 CLIC SUR LE BOUTON VOIR
                                              onPressed: () => _openFile(file['url'], file['name']),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.file_download, color: Colors.black54, size: 20),
                                              // 🟢 CLIC SUR LE BOUTON TÉLÉCHARGER
                                              onPressed: () => _openFile(file['url'], file['name']),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
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
      width: width, height: height,
      decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8))),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate((height / 25).floor(), (index) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(width: 8, height: 10, color: Colors.white.withOpacity(0.4)),
                    Container(width: 8, height: 10, color: Colors.white.withOpacity(0.4)),
                    if (width > 55) Container(width: 8, height: 10, color: Colors.white.withOpacity(0.4)),
                  ],
                )),
      ),
    );
  }
}