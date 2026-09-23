import 'dart:async'; // 🟢 Pour le Timer
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:syndic_app/pages/login_page.dart';
import 'package:syndic_app/pages/paiements_page.dart'; 
import 'package:syndic_app/pages/depenses_page.dart'; 
import 'package:syndic_app/pages/annonces_page.dart';
import 'package:syndic_app/pages/charges_page.dart'; 
import 'package:syndic_app/pages/profile_page.dart';
import 'package:syndic_app/pages/forgot_password_page.dart';
import 'package:syndic_app/pages/NotificationsScreen.dart';
import 'package:syndic_app/pages/copro_main_layout.dart';
import 'package:syndic_app/pages/documents_page.dart'; // 🟢 Page dyal les documents
import 'package:syndic_app/pages/assemblees_page.dart'; // 🟢 Page dyal l-AG


class DashboardPage extends StatefulWidget {
  final bool showBackButton; 
  const DashboardPage({super.key, this.showBackButton = false});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}
class _DashboardPageState extends State<DashboardPage> {
  final Color bgLight = const Color(0xFFF7F9FC); 
  final Color mainBlueDark = const Color(0xFF003366);
  final Color mainBlueLight = const Color(0xFF005BB5);

  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;
  String _errorMessage = "";
  
  String _cachedPhotoUrl = ""; 
  
  // 🟢 Variables pour les notifications
  Timer? _notifTimer;
  int _unreadCount = 0; 
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    _startNotificationListener(); // 🟢 On lance l'écouteur au démarrage
  }

  @override
  void dispose() {
    _notifTimer?.cancel(); // 🟢 On arrête l'écouteur quand on quitte la page
    _horizontalScrollController.dispose();
    super.dispose();
  }

  // ==========================================================
  // 🟢 ÉCOUTEUR DE NOTIFICATIONS (POLLING)
  // ==========================================================
  void _startNotificationListener() {
    _notifTimer = Timer.periodic(const Duration(seconds: 15), (timer) async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      try {
        final response = await http.get(
          Uri.parse("https://api.syndify.nomade-cloud.com/api/mobile/syndic/dashboard"),
          headers: {"Authorization": "Bearer $token", "Accept": "application/json"},
        );
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          int newUnread = data['data']['unread_notifications'] ?? 0;

          // Si le nombre de notifications non lues a augmenté
          if (newUnread > _unreadCount) {
            if (mounted) {
             // 1. Afficher le Pop-up
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  // 🟢 غلفنا المحتوى بـ GestureDetector باش يولي كليكابل
                  content: GestureDetector(
                    onTap: () {
                      // كنحيدو الـ SnackBar باش ميبقاش معلق
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      
                      // كندوزو لصفحة الإشعارات
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(
                            role: 'syndic', // صيفطنا الرول
                            showBackButton: true, // بينا السهم
                          ),
                        ),
                      ).then((_) => _fetchDashboardData()); // فاش كنرجعو، كنديرو تحديث للداشبورد
                    },
                    child: const Row(
                      children: [
                        Icon(Icons.notifications_active, color: Colors.white),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Vous avez une nouvelle notification !",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: mainBlueLight,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
                  elevation: 8,
                  duration: const Duration(seconds: 5), // طولت الميساج شوية باش يلحق يكليكي
                ),
              );
              // 2. Mettre à jour l'UI (le badge rouge)
              setState(() {
                _dashboardData?['unread_notifications'] = newUnread;
              });
            }
          }
          _unreadCount = newUnread; // On synchronise le compteur
        }
      } catch (e) {
        // On ignore les erreurs en arrière-plan pour ne pas spammer l'écran
      }
    });
  }

  Future<void> _fetchDashboardData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
      return;
    }

    setState(() {
      _cachedPhotoUrl = prefs.getString('photo_url') ?? "";
    });

    final String apiUrl = "https://api.syndify.nomade-cloud.com/api/mobile/syndic/dashboard";

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      final decodedBody = jsonDecode(response.body);

      if (response.statusCode == 200 && decodedBody['success'] == true) {
        if (!mounted) return; 
        setState(() {
          _dashboardData = decodedBody['data'];
          _unreadCount = _dashboardData?['unread_notifications'] ?? 0; // 🟢 On initialise le compteur
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        await prefs.remove('auth_token');
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
      } else {
        if (!mounted) return; 
        setState(() {
          _errorMessage = decodedBody['message'] ?? "Erreur serveur : ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return; 
      setState(() {
        _errorMessage = "Problème de connexion au réseau.";
        _isLoading = false;
      });
    }
  }

  String _formatMontant(dynamic montant) {
    if (montant == null) return "0";
    return montant.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ');
  }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: mainBlueDark))
            : _errorMessage.isNotEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 16), textAlign: TextAlign.center),
                    )
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 24),
                        _buildWalletCard(), // 🟢 L-karta z-zr9a ghadi tbqa hna
                        const SizedBox(height: 24),
                        _buildStatistiquesSection(),
                        const SizedBox(height: 24),
                        _buildActivitesSection(),
                      ],
                    ),
                  ),
      ),
    );
  }
// ==========================================================
  // HEADER AVEC TEXTE À GAUCHE ET ICÔNES À DROITE (DESIGN FIXÉ)
  // ==========================================================
  Widget _buildHeader() {
    final prenom = _dashboardData?['utilisateur']?['prenom'] ?? "Syndic";
    final coproNom = _dashboardData?['copropriete']?['nom'] ?? "Ma Résidence";
    
    String apiPhotoUrl = _dashboardData?['utilisateur']?['photo_url'] ?? "";
    String apiPhoto = _dashboardData?['utilisateur']?['photo'] ?? "";
    
    String rawPhoto = apiPhotoUrl.isNotEmpty 
        ? apiPhotoUrl 
        : (apiPhoto.isNotEmpty ? apiPhoto : _cachedPhotoUrl);
    
    final photoUrl = rawPhoto.isNotEmpty 
        ? rawPhoto 
        : "https://ui-avatars.com/api/?name=${prenom[0]}&background=ffffff&color=1A5EAC&size=128&bold=true";

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
      crossAxisAlignment: CrossAxisAlignment.start, // 🟢 Darouriya bach les icones yb9aw lfoq ila kan text fih 2 stoura
      children: [
        // ==============================================
        // 🟢 PARTIE GAUCHE: Textes (Nom & Résidence)
        // ==============================================
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.showBackButton)
                GestureDetector(
                  onTap: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                  child: const Padding(
                    padding: EdgeInsets.only(right: 12.0, top: 4.0), // Ajusté m3a l'ktaba
                    child: Icon(Icons.arrow_back_ios, color: Colors.black87, size: 22),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Bonjour $prenom!", 
                      style: const TextStyle(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.w500)
                    ),
                    const SizedBox(height: 4),
                    Text(
                      coproNom, 
                      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 20, height: 1.2), 
                      maxLines: 3, 
                      overflow: TextOverflow.ellipsis
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(width: 16),

        // ==============================================
        // 🟢 PARTIE DROITE: Cloche + Photo (Mêmes dimensions)
        // ==============================================
        Row(
          mainAxisSize: MainAxisSize.min, 
          children: [
            // 1. ICONE DE NOTIFICATION
            GestureDetector(
              onTap: () {
                 Navigator.push(
                   context, 
                   MaterialPageRoute(
                     builder: (context) => const NotificationsScreen(
                       role: 'syndic', 
                       showBackButton: true
                     )
                   )
                 ).then((_) => _fetchDashboardData());
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 44, // 🟢 3bar fixe bach yji cercle parfait
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))], // Ombre khfifa b7al tswira
                    ),
                    child: const Icon(Icons.notifications_none, color: Colors.black87, size: 24),
                  ),
                  if (_unreadCount > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: bgLight, width: 2), // 🟢 Bordure plus nette
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Center(
                          child: Text(
                            _unreadCount > 9 ? '9+' : '$_unreadCount',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(width: 12), 

            // 2. IMAGE DE PROFIL
            PopupMenuButton<String>(
              offset: const Offset(0, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Colors.white,
              elevation: 4,
              onSelected: (value) async {
                if (value == 'profile') {
                  await Navigator.push(context, MaterialPageRoute(builder: (context) => const UnifiedProfilePage()));
                  _fetchDashboardData(); 
                } 
                else if (value == 'espace_copro') {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const CoproMainLayout()));
                } else if (value == 'password') {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordPage()));
                } else if (value == 'logout') {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('auth_token');
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginPage()), (route) => false);
                  }
                }
              },
              itemBuilder: (BuildContext context) => [
                _buildPopupMenuItem('profile', Icons.person_outline, 'Profil'),
                _buildPopupMenuItem('espace_copro', Icons.swap_horiz, 'Espace Résident'),
                _buildPopupMenuItem('password', Icons.lock_outline, 'Changer mot de passe'),
                const PopupMenuDivider(),
                _buildPopupMenuItem('logout', Icons.logout, 'Déconnexion', isDestructive: true),
              ],
              child: Container(
                width: 44, // 🟢 Nafs l'3bar dyal l'cloche (44x44)
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2), // Bordure bayda r9i9a
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: NetworkImage(photoUrl),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
  PopupMenuItem<String> _buildPopupMenuItem(String value, IconData icon, String text, {bool isDestructive = false}) {
    final color = isDestructive ? Colors.redAccent : mainBlueDark;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildWalletCard() {
    final solde = _formatMontant(_dashboardData?['kpis']['solde']);
    final nbLots = _dashboardData?['kpis']['lots'] ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [mainBlueDark, mainBlueLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: mainBlueDark.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.account_balance_wallet, color: Colors.white.withOpacity(0.8), size: 20),
                  const SizedBox(width: 8),
                  Text("Solde de la copropriété", style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.domain, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text("$nbLots Lots", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "$solde MAD",
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          
          // 🟢 Hna ghadi nzidou l-Scroll Horizontal l-les boutons
       // 🟢 Zidna Scrollbar hna bach yban l-khet dyal scroll
          Scrollbar(
            controller: _horizontalScrollController, // 🟢 Darouri ndiroh hna
            thumbVisibility: true, // 🟢 Katkhli l-khet dima bayn (wla kayban ghir tqissih)
            thickness: 3.0, // 🟢 Ghold dyal l-khet
            radius: const Radius.circular(10),
            trackVisibility: true, // 🟢 Kaybiyen l-khlfiya d l-khet
            child: SingleChildScrollView(
              controller: _horizontalScrollController, // 🟢 W darouri hta hna
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12.0), // 🟢 Espace sghir bach l-khet mayghattich l-ktaba d l-boutons
                child: Row(
                  children: [
                    _buildInnerActionBtn(Icons.add, "Appel de fond", () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChargesPage()))),
                    const SizedBox(width: 20),
                    _buildInnerActionBtn(Icons.send, "Paiement", () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PaiementsPage()))),
                    const SizedBox(width: 20),
                    _buildInnerActionBtn(Icons.receipt_long, "Dépense", () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DepensesPage()))),
                    const SizedBox(width: 20),
                    _buildInnerActionBtn(Icons.campaign, "Annonce", () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AnnoncesPage()))),
                    const SizedBox(width: 20),
                    _buildInnerActionBtn(Icons.groups, "Assemblées", () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AssembleesPage()))),
                    const SizedBox(width: 20),
                    _buildInnerActionBtn(Icons.folder_open, "Documents", () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DocumentsPage()))),
                    
                    // 🟢 (Astuce) Tqadri tzidi had l-icône sghira f l-kher katchir l-limn
                    const SizedBox(width: 10),
                    Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.5), size: 16),
                    const SizedBox(width: 10),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInnerActionBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistiquesSection() {
    final kpis = _dashboardData?['kpis'] ?? {};
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Synthèse Financière", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.5,
            children: [
              _buildLargeStatCard(
                Icons.request_quote, const Color(0xFFE8EAF6), const Color(0xFF3F51B5), "Appel de fonds", _formatMontant(kpis['charges_appelees']),
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChargesPage())),
              ),
              _buildLargeStatCard(
                Icons.savings, const Color(0xFFE8F5E9), const Color(0xFF4CAF50), "Encaissé", _formatMontant(kpis['encaisse']),
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PaiementsPage())),
              ),
              _buildLargeStatCard(
                Icons.warning_amber_rounded, const Color(0xFFFFEBEE), const Color(0xFFF44336), "Impayés", _formatMontant(kpis['impayes']),
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChargesPage())),
              ),
              _buildLargeStatCard(
                Icons.credit_card, const Color(0xFFFFF3E0), const Color(0xFFFF9800), "Dépenses", _formatMontant(kpis['depenses']),
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DepensesPage())),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLargeStatCard(IconData icon, Color bgColor, Color iconColor, String title, String amount, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: bgColor, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black54),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "$amount MAD",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: iconColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitesSection() {
    List<dynamic> activites = _dashboardData?['dernieres_activites'] ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Dernières Activités", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const PaiementsPage()));
                },
                child: Text("Voir tout", style: TextStyle(fontSize: 12, color: mainBlueLight, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (activites.isEmpty)
            const Text("Aucune activité récente.", style: TextStyle(color: Colors.black54)),
          ...activites.map((act) {
            Color actColor = Color(int.parse(act['couleur'].replaceAll('#', '0xFF')));
            IconData actIcon = act['type'] == 'paiement' ? Icons.check_circle : Icons.build;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: _buildActivityRow(actIcon, actColor, act['titre'], act['date'], act['montant']),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildActivityRow(IconData icon, Color color, String title, String subtitle, String amount) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 12)),
            ],
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 14, 
            color: amount.startsWith('+') ? Colors.green : (amount.startsWith('-') ? Colors.black87 : Colors.redAccent)
          ),
        ),
      ],
    );
  }
}