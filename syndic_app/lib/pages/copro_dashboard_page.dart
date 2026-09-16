import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:syndic_app/pages/copro_charges_page.dart';
import 'package:syndic_app/pages/copro_documents_page.dart';
import 'package:syndic_app/pages/copro_annonces_page.dart';
import 'package:syndic_app/pages/copro_paiements_page.dart';
import 'package:syndic_app/pages/notifications_page.dart';
import 'package:syndic_app/pages/login_page.dart';
import 'package:syndic_app/pages/profile_page.dart';
import 'package:syndic_app/pages/forgot_password_page.dart';
import 'package:syndic_app/pages/NotificationsScreen.dart';
import 'package:syndic_app/pages/copro_main_layout.dart';
import 'package:syndic_app/pages/main_layout.dart';

// ==========================================
// WIDGET RÉUTILISABLE : CUSTOM HEADER (CORRIGÉ)
// ==========================================
class CustomHeader extends StatefulWidget {
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

  @override
  State<CustomHeader> createState() => _CustomHeaderState();
}

class _CustomHeaderState extends State<CustomHeader> {
  bool _isSyndic = false;

  @override
  void initState() {
    super.initState();
    _checkIfSyndic();
  }

  // 🟢 Kanchoufou wach l'user 3ndo l'rôle 'syndic' f l'cache
  Future<void> _checkIfSyndic() async {
    final prefs = await SharedPreferences.getInstance();
    final roles = prefs.getStringList('user_roles') ?? [];
    if (roles.contains('syndic')) {
      if (mounted) {
        setState(() {
          _isSyndic = true;
        });
      }
    }
  }

  PopupMenuItem<String> _buildPopupMenuItem(String value, IconData icon, String text, {bool isDestructive = false}) {
    final Color mainBlue = const Color(0xFF1A5EAC);
    final color = isDestructive ? Colors.redAccent : mainBlue;

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

  @override
  Widget build(BuildContext context) {
    final Color mainBlue = const Color(0xFF1A5EAC);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: mainBlue,
        image: DecorationImage(
          image: const NetworkImage("https://images.unsplash.com/photo-1460317442991-0ec209397118?q=80&w=2070&auto=format&fit=crop"),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(mainBlue.withOpacity(0.85), BlendMode.srcOver),
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 16, left: 16, right: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.showBackButton && widget.onBackTap != null) 
                InkWell(
                  onTap: widget.onBackTap,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 16.0),
                    child: Icon(Icons.arrow_back, color: Colors.white, size: 26),
                  ),
                ),
              const Icon(Icons.apartment, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.residenceName.isNotEmpty ? "Sindy | ${widget.residenceName}" : "Sindy",
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: widget.onNotificationTap ?? () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationsScreen(role: widget.userRole)));
                },
                child: const Icon(Icons.notifications_none, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              
              // ======================================================
              // USER DROPDOWN (AVATAR)
              // ======================================================
              PopupMenuButton<String>(
                offset: const Offset(0, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: Colors.white,
                elevation: 4,
                
                // 🟢 HNA KAN LMOCHKIL: ONSLECTED KANTA KHAWYA !
                onSelected: (value) async {
                  if (value == 'profile') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const UnifiedProfilePage()),
                    );
                  } else if (value == 'espace_syndic') {
                    // 🟢 YRJE3 L'ESPACE SYNDIC
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const MainLayout()),
                      (route) => false,
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
                  
                  // 🟢 KAYBAN GHIR ILA KAN _isSyndic = true (Bhal Nabil)
                  if (_isSyndic)
                    _buildPopupMenuItem('espace_syndic', Icons.admin_panel_settings, 'Espace Syndic'),
                    
                  _buildPopupMenuItem('password', Icons.lock_outline, 'Changer mot de passe'),
                  const PopupMenuDivider(),
                  _buildPopupMenuItem('logout', Icons.logout, 'Déconnexion', isDestructive: true),
                ],
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                  ),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white,
                    backgroundImage: widget.photoUrl.isNotEmpty
                        ? NetworkImage(widget.photoUrl)
                        : const NetworkImage("https://ui-avatars.com/api/?name=Copro&background=ffffff&color=1A5EAC&size=128&bold=true"),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(widget.subtitle, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class CoproDashboardPage extends StatefulWidget {
  const CoproDashboardPage({super.key});

  @override
  State<CoproDashboardPage> createState() =>
      _CoproDashboardPageState();
}

class _CoproDashboardPageState
    extends State<CoproDashboardPage> {

  final Color mainBlue = const Color(0xFF1A5EAC);
  final Color bgLight = const Color(0xFFF4F6F9);

  static const String dashboardUrl =
      'https://api.syndify.nomade-cloud.com/api/mobile/copro/dashboard';

  bool _isLoading = true;

  Map<String, dynamic>? _dashboardData;
  String _photoUrl = '';

  String _residenceName = 'Ma Résidence';
  
  String _lotInfo = '';

  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  // ==========================================================
  // API
  // ==========================================================

  Future<void> _fetchDashboardData() async {

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }

    final prefs =
        await SharedPreferences.getInstance();

   final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Session expirée. Veuillez vous reconnecter.';
        });
      }
      return;
    }

   

   // 🟢 1. Récupération des données du cache (Y COMPRIS PHOTO_URL)
    final cachedResidence = prefs.getString('residence_name');
    final cachedLot = prefs.getString('lot_info');
    final cachedPhoto = prefs.getString('photo_url'); // <-- NOUVEAU

    if (mounted) {
      setState(() {
        if (cachedResidence != null && cachedResidence.isNotEmpty) {
          _residenceName = cachedResidence;
        }
        if (cachedLot != null) {
          _lotInfo = cachedLot;
        }
        if (cachedPhoto != null) {
          _photoUrl = cachedPhoto; // <-- MISE À JOUR DE L'AVATAR
        }
      });
    }

    try {

      final headers = <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      // إذا كان عندك residence_id مخزنة في SharedPreferences
      final residenceId =
          prefs.getString('residence_id');

      if (residenceId != null &&
          residenceId.isNotEmpty) {
        headers['residence_id'] =
            residenceId;
      }

      debugPrint(
        'DASHBOARD REQUEST: $dashboardUrl',
      );

      final response = await http
          .get(
            Uri.parse(dashboardUrl),
            headers: headers,
          )
          .timeout(
            const Duration(seconds: 20),
          );

      debugPrint(
        'DASHBOARD STATUS: ${response.statusCode}',
      );

      debugPrint(
        'DASHBOARD BODY: ${response.body}',
      );

      dynamic decoded;

      try {
        decoded =
            jsonDecode(response.body);
      } catch (_) {

        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage =
                'Réponse serveur invalide.';
          });
        }

        return;
      }

      if (response.statusCode == 401) {

        await prefs.remove('auth_token');

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const LoginPage(),
          ),
          (_) => false,
        );

        return;
      }

      if (response.statusCode == 200 &&
          decoded is Map &&
          decoded['success'] == true) {

        final root =
            Map<String, dynamic>.from(
          decoded as Map,
        );

        final dynamic rawData =
            root['data'];

        final Map<String, dynamic> data =
            rawData is Map
                ? Map<String, dynamic>.from(
                    rawData,
                  )
                : <String, dynamic>{};

        // ------------------------------------------------------
        // Residence
        // ------------------------------------------------------

        final residenceFromApi =
            root['residence_name'] ??
            data['residence_name'];

        if (residenceFromApi != null &&
            residenceFromApi
                .toString()
                .trim()
                .isNotEmpty) {

          _residenceName =
              residenceFromApi
                  .toString()
                  .trim();

          await prefs.setString(
            'residence_name',
            _residenceName,
          );
        }

        // ------------------------------------------------------
        // Lot
        // ------------------------------------------------------

        final lotFromApi =
            root['lot_info'] ??
            data['lot_info'];

        if (lotFromApi != null) {

          _lotInfo =
              lotFromApi
                  .toString()
                  .trim();

          await prefs.setString(
            'lot_info',
            _lotInfo,
          );
        }

        if (!mounted) return;

        setState(() {

          _dashboardData = data;

          _isLoading = false;

          _errorMessage = '';
        });

      } else {

        String message =
            'Erreur de chargement';

        if (decoded is Map &&
            decoded['message'] != null) {
          message =
              decoded['message'].toString();
        }

        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = message;
          });
        }
      }

    } catch (e) {

      debugPrint(
        'DASHBOARD EXCEPTION: $e',
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
          
              'Impossible de charger le dashboard.';
        });
      }
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

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
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

             CustomHeader(
                title: "Dashboard",
                subtitle: _lotInfo.isNotEmpty ? "$_residenceName • $_lotInfo" : _residenceName,
                 
                  residenceName: _residenceName,
                  photoUrl: _photoUrl,
                 
                ),

              Expanded(
                child: _buildBody(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // BODY
  // ==========================================================

  Widget _buildBody() {

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: mainBlue,
        ),
      );
    }

    if (_dashboardData == null) {

      return RefreshIndicator(
        color: mainBlue,

        onRefresh:
            _fetchDashboardData,

        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),

          padding:
              const EdgeInsets.only(
            top: 150,
            left: 25,
            right: 25,
          ),

          children: [

            Icon(
              Icons.cloud_off_rounded,
              size: 52,
              color: Colors.blueGrey.shade200,
            ),

            const SizedBox(height: 18),

            Text(
              _errorMessage.isNotEmpty
                  ? _errorMessage
                  : 'Erreur de chargement',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color: Colors.blueGrey.shade600,
                fontSize: 15,
                fontWeight:
                    FontWeight.w500,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'Tirez vers le bas pour réessayer.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color: Colors.blueGrey.shade400,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return _buildDashboardContent();
  }

  // ==========================================================
  // BANNER
  // ==========================================================

  Widget _buildBanner(
      BuildContext context) {

    final firstName =
        (_dashboardData?['first_name'] ??
                'Copropriétaire')
            .toString();

    final photoUrl =
        (_dashboardData?['photo_url'] ??
                '')
            .toString();

    return Container(

      width: double.infinity,

      decoration: BoxDecoration(
        color: mainBlue,

        image: DecorationImage(

          image: const NetworkImage(
            'https://images.unsplash.com/photo-1460317442991-0ec209397118?q=80&w=2070&auto=format&fit=crop',
          ),

          fit: BoxFit.cover,

          colorFilter:
              ColorFilter.mode(
            mainBlue.withOpacity(0.84),
            BlendMode.srcOver,
          ),
        ),
      ),

      padding: EdgeInsets.only(
        top:
            MediaQuery.of(context)
                    .padding
                    .top +
                16,

        bottom: 16,

        left: 16,

        right: 16,
      ),

      child: Column(

        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Row(

            children: [

              const Icon(
                Icons.apartment,
                color: Colors.white,
                size: 24,
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(

                  _residenceName
                          .trim()
                          .isNotEmpty
                      ? 'Sindy | $_residenceName'
                      : 'Sindy',

                  maxLines: 1,

                  overflow:
                      TextOverflow.ellipsis,

                  style:
                      const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Notification
              InkWell(

                borderRadius:
                    BorderRadius.circular(
                  30,
                ),

                onTap: () {

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const NotificationsPage(),
                    ),
                  );
                },

                child: const Icon(
                  Icons.notifications_none,
                  color: Colors.white,
                  size: 26,
                ),
              ),

              const SizedBox(width: 10),

              // Profile dropdown
              PopupMenuButton<String>(

                offset:
                    const Offset(0, 50),

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),

                color: Colors.white,

                elevation: 5,

                onSelected:
                    _handleProfileAction,

                itemBuilder:
                    (context) => [

                  _buildPopupMenuItem(
                    'profile',
                    Icons.person_outline,
                    'Profil',
                  ),

                  _buildPopupMenuItem(
                    'password',
                    Icons.lock_outline,
                    'Changer mot de passe',
                  ),

                  const PopupMenuDivider(),

                  _buildPopupMenuItem(
                    'logout',
                    Icons.logout,
                    'Déconnexion',
                    isDestructive: true,
                  ),
                ],

                child: Container(

                  width: 34,
                  height: 34,

                  decoration:
                      BoxDecoration(
                    shape:
                        BoxShape.circle,
                    border:
                        Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),

                  child: CircleAvatar(

                    radius: 22,

                    backgroundColor:
                        Colors.white,

                    backgroundImage:
                        photoUrl.isNotEmpty
                            ? NetworkImage(
                                photoUrl,
                              )
                            : const NetworkImage(
                                'https://ui-avatars.com/api/?name=Copro&background=ffffff&color=1A5EAC&size=128&bold=true',
                              ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Text(
            'Bonjour, $firstName',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight:
                  FontWeight.w800,
            ),
          ),

          const SizedBox(height: 4),

          Text(

            _lotInfo.isNotEmpty
                ? '$_residenceName • $_lotInfo'
                : _residenceName,

            maxLines: 1,

            overflow:
                TextOverflow.ellipsis,

            style: TextStyle(
              color:
                  Colors.white.withOpacity(
                0.86,
              ),
              fontSize: 12,
              fontWeight:
                  FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // PROFILE MENU
  // ==========================================================

 Future<void> _handleProfileAction(String value) async {
    if (value == 'profile') {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const UnifiedProfilePage()),
      );
      if (mounted) {
        _fetchDashboardData();
      }
    } else if (value == 'espace_copro') {
      // 🟢 HNA FIN KAYTSOWWITCHI L'ESPACE RESIDENT (COPRO)
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CoproMainLayout()),
      );
    } else if (value == 'password') {

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const ForgotPasswordPage(),
        ),
      );

    } else if (value == 'logout') {

      final prefs =
          await SharedPreferences
              .getInstance();

      await prefs.remove(
        'auth_token',
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,

        MaterialPageRoute(
          builder: (_) =>
              const LoginPage(),
        ),

        (_) => false,
      );
    }
  }

  PopupMenuItem<String>
      _buildPopupMenuItem(
    String value,
    IconData icon,
    String text, {
    bool isDestructive = false,
  }) {

    final color =
        isDestructive
            ? Colors.redAccent
            : mainBlue;

    return PopupMenuItem<String>(

      value: value,

      child: Row(

        children: [

          Icon(
            icon,
            color: color,
            size: 20,
          ),

          const SizedBox(width: 12),

          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight:
                  FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // DASHBOARD CONTENT
  // ==========================================================

  Widget _buildDashboardContent() {

    final data =
        _dashboardData ??
            <String, dynamic>{};

    final solde =
        _toDouble(
      data['solde'],
    );

    final charge =
        data['prochaine_charge'];

    final paiement =
        data['dernier_paiement'];

    final List<dynamic> annonces =
        data['annonces'] is List
            ? data['annonces']
                as List<dynamic>
            : <dynamic>[];

    return RefreshIndicator(

      color: mainBlue,

      onRefresh:
          _fetchDashboardData,

      child: SingleChildScrollView(

        physics:
            const AlwaysScrollableScrollPhysics(),

        padding:
            const EdgeInsets.fromLTRB(
          16,
          18,
          16,
          110,
        ),

        child: Column(

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            Text(
              "Vue d'ensemble",
              style: TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.bold,
                color:
                    Colors.blueGrey.shade800,
              ),
            ),

            const SizedBox(height: 16),

            Row(

              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Expanded(
                  child:
                      _buildFinancialCard(
                    title:
                        'Solde actuel',

                    value:
                        _formatSolde(
                      solde,
                    ),

                    icon:
                        Icons.account_balance_wallet_rounded,

                    isAlert:
                        solde > 0,
                  ),
                ),

                const SizedBox(
                    width: 12),

                Expanded(
                  child:
                      _buildFinancialCard(
                    title:
                        'Prochaine charge',

                    value:
                        charge is Map
                            ? _formatAmount(
                                charge['amount'],
                              )
                            : 'Aucune',

                    icon:
                        Icons.calendar_today_rounded,

                    isAlert: false,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            Text(
              'Vos services',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.w700,
                color:
                    Colors.blueGrey.shade800,
              ),
            ),

            const SizedBox(height: 10),

            GridView.count(

              padding: EdgeInsets.zero,

              shrinkWrap: true,

              physics:
                  const NeverScrollableScrollPhysics(),

              crossAxisCount: 2,

              crossAxisSpacing: 12,

              mainAxisSpacing: 12,

              childAspectRatio: 1.12,

              children: [

                _buildServiceCard(
                  icon:
                      Icons.credit_score_rounded,

                  iconColor:
                      const Color(0xFF10B981),

                  title:
                      'Paiements',

                  subtitle:
                      paiement is Map
                          ? _formatDate(
                              paiement[
                                      'date']
                                  ?.toString() ??
                                  '',
                            )
                          : 'Historique',

                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const CoproPaiementsPage(),
                      ),
                    );
                  },
                ),

                _buildServiceCard(
                  icon:
                      Icons.campaign_rounded,

                  iconColor:
                      const Color(0xFFF59E0B),

                  title:
                      'Annonces',

                  subtitle:
                      annonces.isEmpty
                          ? 'Aucune nouveauté'
                          : '${annonces.length} nouveautés',

                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const CoproAnnoncesPage(showBackButton: true),
                      ),
                    );
                  },
                ),

                _buildServiceCard(
                  icon:
                      Icons.folder_copy_rounded,

                  iconColor:
                      const Color(0xFF3B82F6),

                  title:
                      'Documents',

                  subtitle:
                      'Règlements & PV',

                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const CoproDocumentsPage(showBackButton: true),
                      ),
                    );
                  },
                ),

                _buildServiceCard(
                  icon:
                      Icons.receipt_long_rounded,

                  iconColor:
                      const Color(0xFF8B5CF6),

                  title:
                      'Charges',

                  subtitle:
                      'Détails & Appels',

                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const CoproChargesPage(showBackButton: true),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // FINANCIAL CARD
  // ==========================================================

  Widget _buildFinancialCard({

    required String title,

    required String value,

    required IconData icon,

    required bool isAlert,
  }) {

    final cardColor =
        isAlert
            ? const Color(0xFFFFF3F3)
            : Colors.white;

    final borderColor =
        isAlert
            ? const Color(0xFFFF8A8A)
            : Colors.grey.shade200;

    final iconBg =
        isAlert
            ? const Color(0xFFFFE1E1)
            : const Color(0xFFF1F5F9);

    final iconColor =
        isAlert
            ? const Color(0xFFD32F2F)
            : mainBlue;

    final valueColor =
        isAlert
            ? const Color(0xFFD32F2F)
            : const Color(0xFF172033);

    return Container(

      padding:
          const EdgeInsets.all(14),

      decoration:
          BoxDecoration(

        color: cardColor,

        borderRadius:
            BorderRadius.circular(18),

        border:
            Border.all(
          color: borderColor,
          width:
              isAlert ? 1.2 : 1,
        ),

        boxShadow: [

          BoxShadow(
            color:
                Colors.black
                    .withOpacity(0.035),

            blurRadius: 10,

            offset:
                const Offset(0, 4),
          ),
        ],
      ),

      child: Column(

        crossAxisAlignment:
            CrossAxisAlignment.start,

        mainAxisSize:
            MainAxisSize.min,

        children: [

          Container(

            width: 38,
            height: 38,

            decoration:
                BoxDecoration(
              color: iconBg,
              borderRadius:
                  BorderRadius.circular(
                11,
              ),
            ),

            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            title,
            style:
                const TextStyle(
              fontSize: 12,
              fontWeight:
                  FontWeight.w600,
              color:
                  Colors.blueGrey,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            value,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 17,
              fontWeight:
                  FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SERVICE CARD
  // ==========================================================

  Widget _buildServiceCard({

    required IconData icon,

    required Color iconColor,

    required String title,

    required String subtitle,

    required VoidCallback onTap,
  }) {

    return GestureDetector(

      onTap: onTap,

      child: Container(

        decoration:
            BoxDecoration(

          color:
              Colors.white.withOpacity(
            0.96,
          ),

          borderRadius:
              BorderRadius.circular(
            18,
          ),

          border:
              Border.all(
            color:
                Colors.grey.shade100,
          ),

          boxShadow: [

            BoxShadow(
              color:
                  Colors.black
                      .withOpacity(0.035),

              blurRadius: 10,

              offset:
                  const Offset(0, 4),
            ),
          ],
        ),

        child: Column(

          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [

            Container(

              width: 50,
              height: 50,

              decoration:
                  BoxDecoration(

                color:
                    iconColor.withOpacity(
                  0.10,
                ),

                shape:
                    BoxShape.circle,
              ),

              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              title,
              style:
                  const TextStyle(
                fontSize: 14,
                fontWeight:
                    FontWeight.bold,
                color:
                    Color(0xFF1E293B),
              ),
            ),

            const SizedBox(height: 5),

            Text(
              subtitle,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                fontSize: 11,
                color:
                    Color(0xFF94A3B8),
                fontWeight:
                    FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // CITY SKYLINE
  // ==========================================================

  Widget _buildCitySkyline() {

    final color =
        mainBlue.withOpacity(0.03);

    return IgnorePointer(

      child: SizedBox(

        height: 220,

        child: Row(

          crossAxisAlignment:
              CrossAxisAlignment.end,

          mainAxisAlignment:
              MainAxisAlignment.spaceEvenly,

          children: [

            _buildBuilding(
                50, 120, color),

            _buildBuilding(
                65, 180, color),

            _buildBuilding(
                45, 140, color),

            _buildBuilding(
                75, 210, color),

            _buildBuilding(
                60, 160, color),

            _buildBuilding(
                50, 100, color),
          ],
        ),
      ),
    );
  }

  Widget _buildBuilding(
    double width,
    double height,
    Color color,
  ) {

    return Container(

      width: width,

      height: height,

      decoration:
          BoxDecoration(

        color: color,

        borderRadius:
            const BorderRadius.only(
          topLeft:
              Radius.circular(8),
          topRight:
              Radius.circular(8),
        ),
      ),

      child: Column(

        mainAxisAlignment:
            MainAxisAlignment.spaceEvenly,

        children: List.generate(

          (height / 25)
              .floor(),

          (index) => Row(

            mainAxisAlignment:
                MainAxisAlignment
                    .spaceEvenly,

            children: [

              Container(
                width: 8,
                height: 10,
                color:
                    Colors.white
                        .withOpacity(
                  0.4,
                ),
              ),

              Container(
                width: 8,
                height: 10,
                color:
                    Colors.white
                        .withOpacity(
                  0.4,
                ),
              ),

              if (width > 55)

                Container(
                  width: 8,
                  height: 10,
                  color:
                      Colors.white
                          .withOpacity(
                    0.4,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // HELPERS
  // ==========================================================

  double _toDouble(dynamic value) {

    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value
              .toString()
              .replaceAll(',', '.')
              .replaceAll('MAD', '')
              .trim(),
        ) ??
        0;
  }

  String _formatSolde(
      double solde) {

    if (solde > 0) {
      return '${solde.toStringAsFixed(0)} MAD';
    }

    if (solde < 0) {
      return 'Crédit';
    }

    return 'À jour';
  }

  String _formatAmount(
      dynamic amount) {

    final value =
        _toDouble(amount);

    if (value == 0) {
      return 'Aucune';
    }

    return '${value.toStringAsFixed(0)} MAD';
  }

  String _formatDate(
      String dateStr) {

    if (dateStr.isEmpty) {
      return 'Historique';
    }

    try {

      final date =
          DateTime.parse(dateStr);

      return
          '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';

    } catch (_) {

      return dateStr;
    }
  }
}