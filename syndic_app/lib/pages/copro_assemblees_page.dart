import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syndic_app/pages/NotificationsScreen.dart'; // 🟢 Hna t-7etti l-import dyal NotificationsScreen
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

class CoproAssembleesPage extends StatefulWidget {
  const CoproAssembleesPage({super.key});

  @override
  State<CoproAssembleesPage> createState() => _CoproAssembleesPageState();
}

class _CoproAssembleesPageState extends State<CoproAssembleesPage> {
  final Color mainBlue = const Color(0xFF1A5EAC);
  bool _isLoading = true;
  List<dynamic> _agList = [];
  String _errorMessage = "";
  String _residenceName = "Chargement...";
  String _photoUrl = "";

  @override
  void initState() {
    super.initState();
    _fetchAssemblees();
  }

  Future<void> _fetchAssemblees() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

   setState(() {
      _residenceName = prefs.getString('residence_name') ?? "Ma Résidence";
      _photoUrl = prefs.getString('photo_url') ?? "";
    });
    if (token == null) return;

    // 🟢 Hna t-7etti l-URL dyal l-API li ghadi t-jib l-liste f Laravel
    final String apiUrl = "https://api.syndify.nomade-cloud.com/api/mobile/copro/ag";

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      
      if (response.statusCode == 200) {
        final decodedBody = jsonDecode(response.body);
        
        if (mounted) {
          setState(() {
            _agList = decodedBody['data'] ?? [];
             if (decodedBody['residence_name'] != null) {
            _residenceName = decodedBody['residence_name'];
          }
          if (decodedBody['user'] != null && decodedBody['user']['photo_url'] != null) {
            _photoUrl = decodedBody['user']['photo_url'];
          }
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = "Erreur de chargement des assemblées.";
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Problème de connexion au réseau.";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      // ❌ 7iydi appBar mn hna
      body: Column(
        children: [
          // 🟢 1. 7etti l-Header howa l-wl f l-Body
          CustomHeader(
            title: "Assemblées Générales",
            subtitle: "Liste des assemblées planifiées",
            residenceName: _residenceName, // Nti tqadri tjibiha mn SharedPreferences
            photoUrl: _photoUrl, 
            showBackButton: false,
          ),
          
          // 🟢 2. Ghalfi l-contenu l-akhor b Expanded bach yakhod l-blassa li bqat
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: mainBlue))
                : _errorMessage.isNotEmpty
                    ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
                    : _agList.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 80), // Zdt l-bottom bach maytghatach b BottomNav
                            itemCount: _agList.length,
                            itemBuilder: (context, index) {
                              final ag = _agList[index];
                              return _buildAgCard(ag);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 80, color: Colors.grey.shade400),
          SizedBox(height: 16.h),
           Text("Aucune assemblée générale planifiée.", style: TextStyle(color: Colors.black54, fontSize: 16.sp)),
        ],
      ),
    );
  }

  Widget _buildAgCard(dynamic ag) {
    // 🟢 Kan-gaddou l-badge 3la hsab l-status
    String status = ag['status'] ?? 'planifiee';
    bool isCloturee = status.toLowerCase() == 'cloturee' || status.toLowerCase() == 'terminée';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    ag['title'] ?? "Assemblée Générale Ordinaire",
                    style:  TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCloturee ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    isCloturee ? "Clôturée" : "À venir",
                    style: TextStyle(
                      color: isCloturee ? Colors.green : Colors.orange.shade800,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.black54),
                 SizedBox(width: 8.w),
                Text(ag['date_time'] ?? "Date non fixée", style:  TextStyle(fontSize: 14.sp, color: Colors.black87)),
              ],
            ),
             SizedBox(height: 8.h),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: Colors.black54),
                 SizedBox(width: 8.w),
                Text(ag['location'] ?? "Lieu non précisé", style:  TextStyle(fontSize: 14.sp, color: Colors.black87)),
              ],
            ),
            SizedBox(height: 16.h),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isCloturee)
                  TextButton.icon(
                    onPressed: () {
                      // 🟢 Appel l la fonction dyal téléchargement PDF
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Téléchargement du PV en cours...")));
                    },
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                    label: const Text("Télécharger PV", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  )
                else
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      // 🟢 Hna t-zidi Navigation l-formulaire d l-procuration (Wakala)
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ouverture de la page de procuration...")));
                    },
                    icon: const Icon(Icons.handshake, size: 18),
                    label: const Text("Donner Procuration"),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}