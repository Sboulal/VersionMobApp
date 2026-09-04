import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:syndic_app/pages/copro_charges_page.dart';
import 'package:syndic_app/pages/copro_documents_page.dart';
import 'package:syndic_app/pages/copro_annonces_page.dart';
import 'package:syndic_app/pages/copro_paiements_page.dart';

class CoproDashboardPage extends StatefulWidget {
  const CoproDashboardPage({super.key});

  @override
  State<CoproDashboardPage> createState() => _CoproDashboardPageState();
}

class _CoproDashboardPageState extends State<CoproDashboardPage> {
  final Color mainBlue = const Color(0xFF1A5EAC);
  final Color bgLight = const Color(0xFFF4F6F9);

  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;

  final String _residenceName = "Résidence Les Palmiers";
  final String _lotInfo = "Lot 12B";

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  // ==========================================================
  // API
  // ==========================================================

  Future<void> _fetchDashboardData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.get(
        Uri.parse(
          "https://api.syndify.nomade-cloud.com/api/mobile/copro/dashboard",
        ),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _dashboardData = data['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Dashboard error : $e");

      setState(() {
        _isLoading = false;
      });
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
          // ======================================================
          // BACKGROUND SKYLINE
          // ======================================================

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildCitySkyline(),
          ),

          // ======================================================
          // CONTENT
          // ======================================================

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ====================================================
              // BANNER
              // ====================================================

              _buildBanner(context),

              // ====================================================
              // BODY
              // ====================================================

              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: mainBlue,
                        ),
                      )
                    : _dashboardData == null
                        ? const Center(
                            child: Text(
                              "Erreur de chargement",
                              style: TextStyle(
                                color: Colors.blueGrey,
                                fontSize: 15,
                              ),
                            ),
                          )
                        : _buildDashboardContent(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // BANNER - EXACT STYLE CHARGES
  // ==========================================================

  Widget _buildBanner(BuildContext context) {
    final firstName =
        (_dashboardData?['first_name'] ?? 'Copropriétaire').toString();

    final String photoUrl =
        (_dashboardData?['photo_url'] ?? '').toString();

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
          // ------------------------------------------------------
          // TOP ROW
          // ------------------------------------------------------

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.apartment,
                color: Colors.white,
                size: 24,
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  "Sindy | $_residenceName",
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

              const Icon(
                Icons.notifications_none,
                color: Colors.white,
                size: 26,
              ),

              const SizedBox(width: 12),

              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
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
            ],
          ),

          const SizedBox(height: 20),

          // ------------------------------------------------------
          // GREETING
          // ------------------------------------------------------

          Text(
            "Bonjour, $firstName",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            "$_residenceName • $_lotInfo",
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

  // ==========================================================
  // DASHBOARD CONTENT
  // ==========================================================

  Widget _buildDashboardContent() {
    final double solde =
        (_dashboardData!['solde'] ?? 0).toDouble();

    final charge =
        _dashboardData!['prochaine_charge'];

    final paiement =
        _dashboardData!['dernier_paiement'];

    final List annonces =
        _dashboardData!['annonces'] is List
            ? _dashboardData!['annonces']
            : [];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),

      padding: const EdgeInsets.fromLTRB(
        16,
        18,
        16,
        110,
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ======================================================
          // TITLE
          // ======================================================

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 2,
            ),
            child: Text(
              "Vue d'ensemble",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey.shade800,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ======================================================
          // FINANCIAL CARDS
          // ======================================================

          Row(
            children: [
              Expanded(
                child: _buildFinancialCard(
                  title: "Solde actuel",
                  value: solde > 0
                      ? "${solde.toStringAsFixed(0)} MAD"
                      : solde < 0
                          ? "Crédit"
                          : "À jour",
                  icon: Icons.account_balance_wallet,
                  isAlert: solde > 0,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _buildFinancialCard(
                  title: "Prochaine charge",
                  value: charge != null
                      ? "${charge['amount'] ?? 0} MAD"
                      : "Aucune",
                  icon: Icons.calendar_today,
                  isAlert: false,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20), // Espace avant "Vos services"

          // ======================================================
          // SERVICES
          // ======================================================

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 2,
            ),
            child: Text(
              "Vos services",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.blueGrey.shade800,
              ),
            ),
          ),

          const SizedBox(height: 10), // Petit espace après le titre

          // ======================================================
          // SERVICES GRID
          // ======================================================

          GridView.count(
            padding: EdgeInsets.zero, // <-- ENLEVE L'ESPACE CACHÉ QUI POSE PROBLÈME
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),

            crossAxisCount: 2,

            crossAxisSpacing: 12,
            mainAxisSpacing: 12,

            childAspectRatio: 1.12, 

            children: [
              // --------------------------------------------------
              // PAIEMENTS
              // --------------------------------------------------

              _buildServiceCard(
                icon: Icons.credit_score_rounded,
                iconColor: const Color(0xFF10B981),
                title: "Paiements",
                subtitle: paiement != null
                    ? _formatDate(
                        paiement['date']?.toString() ?? '',
                      )
                    : "Historique",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const CoproPaiementsPage(),
                    ),
                  );
                },
              ),

              // --------------------------------------------------
              // ANNONCES
              // --------------------------------------------------

              _buildServiceCard(
                icon: Icons.campaign_rounded,
                iconColor: const Color(0xFFF59E0B),
                title: "Annonces",
                subtitle: "${annonces.length} nouveautés",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const CoproAnnoncesPage(),
                    ),
                  );
                },
              ),

              // --------------------------------------------------
              // DOCUMENTS
              // --------------------------------------------------

              _buildServiceCard(
                icon: Icons.folder_copy_rounded,
                iconColor: const Color(0xFF3B82F6),
                title: "Documents",
                subtitle: "Règlements & PV",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const CoproDocumentsPage(),
                    ),
                  );
                },
              ),

              // --------------------------------------------------
              // CHARGES
              // --------------------------------------------------

              _buildServiceCard(
                icon: Icons.receipt_long_rounded,
                iconColor: const Color(0xFF8B5CF6),
                title: "Charges",
                subtitle: "Détails & Appels",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const CoproChargesPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // FINANCIAL CARD (CORRIGÉ POUR ÉVITER LE OVERFLOW)
  // ==========================================================

  Widget _buildFinancialCard({
    required String title,
    required String value,
    required IconData icon,
    required bool isAlert,
  }) {
    final Color cardColor = isAlert
        ? const Color(0xFFFFF3F3)
        : Colors.white;

    final Color borderColor = isAlert
        ? const Color(0xFFFF8A8A)
        : Colors.grey.shade200;

    final Color iconBg = isAlert
        ? const Color(0xFFFFE1E1)
        : const Color(0xFFF1F5F9);

    final Color iconColor = isAlert
        ? const Color(0xFFD32F2F)
        : mainBlue;

    final Color valueColor = isAlert
        ? const Color(0xFFD32F2F)
        : const Color(0xFF172033);

    return Container(
      // <-- Hauteur (height) supprimée totalement pour s'adapter au contenu dynamiquement
      padding: const EdgeInsets.all(14), 

      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),

        border: Border.all(
          color: borderColor,
          width: isAlert ? 1.2 : 1,
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // <-- Permet à la colonne de prendre juste l'espace nécessaire
        children: [
          Container(
            width: 38,
            height: 38,

            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(11),
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
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
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
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.96),

          borderRadius: BorderRadius.circular(18),

          border: Border.all(
            color: Colors.grey.shade100,
          ),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50, 
              height: 50, 

              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.10),
                shape: BoxShape.circle,
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
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),

            const SizedBox(height: 5),

            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
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
    final color = mainBlue.withOpacity(0.03);

    return IgnorePointer(
      child: SizedBox(
        height: 220,

        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,

          children: [
            _buildBuilding(
              50,
              120,
              color,
            ),

            _buildBuilding(
              65,
              180,
              color,
            ),

            _buildBuilding(
              45,
              140,
              color,
            ),

            _buildBuilding(
              75,
              210,
              color,
            ),

            _buildBuilding(
              60,
              160,
              color,
            ),

            _buildBuilding(
              50,
              100,
              color,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // BUILDING
  // ==========================================================

  Widget _buildBuilding(
    double width,
    double height,
    Color color,
  ) {
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
            mainAxisAlignment:
                MainAxisAlignment.spaceEvenly,

            children: [
              Container(
                width: 8,
                height: 10,
                color: Colors.white.withOpacity(0.4),
              ),

              Container(
                width: 8,
                height: 10,
                color: Colors.white.withOpacity(0.4),
              ),

              if (width > 55)
                Container(
                  width: 8,
                  height: 10,
                  color: Colors.white.withOpacity(0.4),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // DATE
  // ==========================================================

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) {
      return "Historique";
    }

    try {
      final date = DateTime.parse(dateStr);

      return "${date.day.toString().padLeft(2, '0')}/"
          "${date.month.toString().padLeft(2, '0')}/"
          "${date.year}";
    } catch (e) {
      return dateStr;
    }
  }
}