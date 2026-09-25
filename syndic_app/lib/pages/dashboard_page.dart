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
import 'package:flutter_screenutil/flutter_screenutil.dart'; // 🟢 ZIDNA HAD L'IMPORT DAROURI


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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
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
                      child: Text(_errorMessage, style:  TextStyle(color: Colors.red, fontSize: 16.sp), textAlign: TextAlign.center),
                    )
                  )
                : SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        SizedBox(height: 24.h),
                        _buildWalletCard(), // 🟢 L-karta z-zr9a ghadi tbqa hna
                        SizedBox(height: 24.h),
                        _buildAnnonceBanner(),
                        SizedBox(height: 24.h),
                        _buildStatistiquesSection(),
                        SizedBox(height: 24.h),
                        _buildActivitesSection(),
                      ],
                    ),
                  ),
      ),
    );
  }

 // ==========================================================
  // 🟢 BANNIÈRE STYLE "PROMO / ALERTE" (DESIGN PREMIUM & CLEAN)
  // ==========================================================
  Widget _buildAnnonceBanner() {
    final derniereAnnonce = _dashboardData?['derniere_annonce'];
    
    final titre = derniereAnnonce?['titre'] ?? "Réunion de copropriété";
    final description = derniereAnnonce?['description'] ?? "N'oubliez pas l'assemblée générale extraordinaire ce weekend.";

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const AnnoncesPage()));
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          // 🟢 Gradient zwin b l-zre9 mftou7 bash tbiyen l-kettba dima
          gradient: const LinearGradient(
            colors: [Color(0xFFE8F0FE), Color(0xFFD2E3FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // 🟢 Zwaq d l-khalfia (Icone kbira mkhbiya chwiya)
            Positioned(
              right: -10.w,
              bottom: -15.h,
              child: Icon(
                Icons.campaign_rounded,
                size: 100.sp,
                color: Colors.blue.shade900.withOpacity(0.05),
              ),
            ),
            
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🟢 Badge Rouge "NOUVELLE ANNONCE"
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(6.r),
                            boxShadow: [
                              BoxShadow(color: Colors.redAccent.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))
                            ],
                          ),
                          child: Text(
                            "NOUVELLE ANNONCE", 
                            style: TextStyle(color: Colors.white, fontSize: 9.sp, fontWeight: FontWeight.bold, letterSpacing: 0.5)
                          ),
                        ),
                        SizedBox(height: 12.h),
                        
                        // 🟢 Titre (Beloun l-Gham9 bash yban)
                        Text(
                          titre,
                          style: TextStyle(color: mainBlueDark, fontSize: 17.sp, fontWeight: FontWeight.w900),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 6.h),
                        
                        // 🟢 Description
                        Text(
                          description,
                          style: TextStyle(color: Colors.black87, fontSize: 13.sp, height: 1.4, fontWeight: FontWeight.w500),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 14.h),
                        
                        // 🟢 Bouton "Lire la suite" b-chekel dyal Pilule
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            color: mainBlueDark,
                            borderRadius: BorderRadius.circular(20.r),
                            boxShadow: [
                              BoxShadow(color: mainBlueDark.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 3))
                            ]
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("Lire la suite", style: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.bold)),
                              SizedBox(width: 4.w),
                              Icon(Icons.arrow_forward_ios, color: Colors.white, size: 10.sp),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  
                  SizedBox(width: 16.w),
                  
                  // 🟢 Icone l-Limouniya f Jnb
                  Container(
                    width: 60.w,
                    height: 60.w, // kanderou .w l-height hta hwa bash ybqa carré/cercle m9ad
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                      ],
                    ),
                    child: Center(
                      child: Icon(Icons.campaign_rounded, color: const Color(0xFFFF9800), size: 30.sp),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
      crossAxisAlignment: CrossAxisAlignment.center, 
      children: [
        // ==============================================
        // 🟢 PARTIE GAUCHE: Textes (Nom & Résidence)
        // ==============================================
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center, 
            children: [
              if (widget.showBackButton)
                GestureDetector(
                  onTap: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                  child: Padding(
                    padding: EdgeInsets.only(right: 12.0.w), 
                    child: Icon(Icons.arrow_back_ios, color: Colors.black87, size: 22.sp),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center, 
                  children: [
                    Text(
                      "Bonjour $prenom!", 
                      style: TextStyle(color: Colors.black54, fontSize: 14.sp, fontWeight: FontWeight.w500)
                    ),
                    SizedBox(height: 4.h), 
                    Text(
                      coproNom, 
                      // 🟢 HNA BDLLNA L-LOUN: redinaha mainBlueDark bash t-ji m-nass9a m3a l-appli
                      style: TextStyle(color: mainBlueDark, fontWeight: FontWeight.w900, fontSize: 18.sp, height: 1.2), 
                      maxLines: 2, 
                      overflow: TextOverflow.ellipsis
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(width: 16.w), 

        // ==============================================
        // 🟢 PARTIE DROITE: Cloche + Photo
        // ==============================================
        Row(
          mainAxisSize: MainAxisSize.min, 
          crossAxisAlignment: CrossAxisAlignment.center, 
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
                    width: 42.w, 
                    height: 42.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))], 
                    ),
                    child: Icon(Icons.notifications_none, color: mainBlueDark, size: 22.sp), // 🟢 Hta l-icone d-jrass rdinaha zr9a
                  ),
                  if (_unreadCount > 0)
                    Positioned(
                      right: -2.w,
                      top: -2.h,
                      child: Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: bgLight, width: 2), 
                        ),
                        constraints: BoxConstraints(
                          minWidth: 18.w,
                          minHeight: 18.h,
                        ),
                        child: Center(
                          child: Text(
                            _unreadCount > 9 ? '9+' : '$_unreadCount',
                            style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            SizedBox(width: 12.w), 

            // 2. IMAGE DE PROFIL
            PopupMenuButton<String>(
              offset: const Offset(0, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
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
                _buildPopupMenuItem('espace_copro', Icons.swap_horiz, 'Mon Espace Copropriété'),
                _buildPopupMenuItem('password', Icons.lock_outline, 'Changer mot de passe'),
                const PopupMenuDivider(),
                _buildPopupMenuItem('logout', Icons.logout, 'Déconnexion', isDestructive: true),
              ],
              child: Container(
                width: 42.w, 
                height: 42.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2), 
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
          SizedBox(width: 12.w),
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
      padding: EdgeInsets.all(24.w), 
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [mainBlueDark, mainBlueLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24.r),
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
                  Icon(Icons.account_balance_wallet, color: Colors.white.withOpacity(0.8), size: 20.sp),
                  SizedBox(width: 8.w),
                  Text("Solde de la copropriété", style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14.sp)),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  children: [
                    Icon(Icons.domain, color: Colors.white, size: 14.sp),
                    SizedBox(width: 4.w),
                    Text("$nbLots Lots", style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 24.h),
          
          // 🟢 PRIX CENTERED
          Row(
            mainAxisAlignment: MainAxisAlignment.center, 
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                solde,
                style: TextStyle(
                  color: Colors.white, 
                  fontSize: 40.sp, 
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0, 
                ),
              ),
              SizedBox(width: 8.w),
              Padding(
                padding: EdgeInsets.only(bottom: 6.h), 
                child: Text(
                  "MAD",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8), 
                    fontSize: 16.sp, 
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          // 🟢 HNA NQESNA L-ESPACE LI KAN KBIR (Rddinah 12.h blast 32.h)
          SizedBox(height: 12.h), 
          
          // 🟢 Jouj stoura m9addin b Expanded
          Row(
            children: [
              _buildInnerActionBtn(Icons.add, "Appel fond", () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChargesPage()))),
              _buildInnerActionBtn(Icons.send, "Cotisation", () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PaiementsPage()))),
              _buildInnerActionBtn(Icons.receipt_long, "Dépense", () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DepensesPage()))),
            ],
          ),
          SizedBox(height: 16.h), 
          Row(
            children: [
              _buildInnerActionBtn(Icons.campaign, "Annonce", () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AnnoncesPage()))),
              _buildInnerActionBtn(Icons.groups, "Assemblées", () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AssembleesPage()))),
              _buildInnerActionBtn(Icons.folder_open, "Documents", () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DocumentsPage()))),
            ],
          )
        ],
      ),
    );
  }
  
Widget _buildInnerActionBtn(IconData icon, String label, VoidCallback onTap) {
    return Expanded( // 🟢 L-Expanded khelihom yt9assmou l-3erd d l-écran b-3dal (1/3 l-koul wa7d)
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque, // Bach l-zone kamla t-clicka machi ghir l-icone
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Icon(icon, color: Colors.white, size: 22.sp),
            ),
            SizedBox(height: 8.h),
            Text(
              label,
              style: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
              maxLines: 1, 
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
  
 Widget _buildStatistiquesSection() {
    final kpis = _dashboardData?['kpis'] ?? {};
    
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text("Synthèse Financière", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
          SizedBox(height: 20.h),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            crossAxisSpacing: 16.w,
            mainAxisSpacing: 16.h,
            physics: const NeverScrollableScrollPhysics(),
            // 🟢 HNA L-7EL 1: Bdalna l-aspect ratio mn 1.5 l 1.35 bash n-3tiwhom t-toul kber chwiya
            childAspectRatio: 1.35, 
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
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: bgColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: bgColor, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 20.sp),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, color: Colors.black54),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            // 🟢 HNA L-7EL 2: Zidna FittedBox bash l-montant y-sghar rassou ila kan kbir bzaf (bla ma ydir overflow)
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                "$amount MAD",
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: iconColor),
              ),
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
               Text("Dernières Activités", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const PaiementsPage()));
                },
                child: Text("Voir tout", style: TextStyle(fontSize: 12, color: mainBlueLight, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          SizedBox(height: 16.h),
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
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style:  TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(subtitle, style:  TextStyle(color: Colors.black54, fontSize: 12.sp)),
            ],
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 14.sp, 
            color: amount.startsWith('+') ? Colors.green : (amount.startsWith('-') ? Colors.black87 : Colors.redAccent)
          ),
        ),
      ],
    );
  }
}