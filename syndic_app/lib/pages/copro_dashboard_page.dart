import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// 🟢 N'oublie pas de modifier ces chemins vers l'emplacement réel de tes fichiers
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
  final Color secondaryBlue = const Color(0xFF3070C6); 
  final Color bgLight = const Color(0xFFF4F6F9);

  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;
  final String _residenceName = "Résidence Les Palmiers"; 
  final String _lotInfo = "Lot 12B"; 

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.get(
        Uri.parse("https://api.syndify.nomade-cloud.com/api/mobile/copro/dashboard"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _dashboardData = data['data'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(backgroundColor: bgLight, body: Center(child: CircularProgressIndicator(color: mainBlue)));
    }

    if (_dashboardData == null) {
      return Scaffold(backgroundColor: bgLight, body: const Center(child: Text("Erreur de chargement")));
    }

    final double solde = (_dashboardData!['solde'] ?? 0).toDouble();
    final charge = _dashboardData!['prochaine_charge'];
    final paiement = _dashboardData!['dernier_paiement'];
    final List annonces = _dashboardData!['annonces'] ?? [];
    
    final String firstName = _dashboardData!['first_name'] ?? 'Copropriétaire';
    final String photoUrl = _dashboardData!['photo_url'] ?? "https://ui-avatars.com/api/?name=$firstName&background=ffffff&color=1A5EAC&size=128&bold=true";

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
              // 1. BANNER CORRIGÉ
            Container(
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
                  bottom: 16, 
                  left: 16, 
                  right: 16
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.apartment, color: Colors.white, size: 24),
                    const SizedBox(width: 8),
                    
                    // 🟢 Correction : Expanded + Ellipsis pour éviter que ça se compresse
                    Expanded(
                      child: Text(
                        "Sindy | $_residenceName", 
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    const Icon(Icons.notifications_none, color: Colors.white, size: 26),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.white,
                        backgroundImage: NetworkImage("https://ui-avatars.com/api/?name=Copro&background=ffffff&color=1A5EAC&size=128&bold=true"),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Bienvenue,",
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade800),
                          ),
                          Text(
                            "$firstName | $_lotInfo",
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.blueGrey.shade500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: _buildTopCard(
                              title: "Solde actuel",
                              value: solde > 0 ? "${solde.toStringAsFixed(0)} MAD" : (solde < 0 ? "Crédit" : "À jour"),
                              badgeText: solde > 0 ? "!" : "✓",
                              color: solde > 0 ? const Color(0xFFD32F2F) : mainBlue, 
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTopCard(
                              title: "Prochaine charge",
                              value: charge != null ? "${charge['amount']} MAD" : "Aucune",
                              badgeText: charge != null ? "1" : "0",
                              color: secondaryBlue, 
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.0, 
                        children: [
                          _buildGridCard(
                            icon: Icons.credit_card,
                            title: "Dernier Paiement",
                            value: paiement != null ? "${paiement['amount']} MAD" : "-",
                            subtitle: paiement != null ? _formatDate(paiement['date']) : "Aucun",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const CoproPaiementsPage()),
                              );
                            },
                          ),
                          _buildGridCard(
                            icon: Icons.campaign,
                            title: "Annonces",
                            value: "${annonces.length}",
                            subtitle: "Dernières infos",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const CoproAnnoncesPage()),
                              );
                            },
                          ),
                          _buildGridCard(
                            icon: Icons.folder_open,
                            title: "Documents",
                            value: "Voir",
                            subtitle: "Règlements & PV",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const CoproDocumentsPage()),
                              );
                            },
                          ),
                          _buildGridCard(
                            icon: Icons.receipt_long,
                            title: "Mes Charges",
                            value: "Historique",
                            subtitle: "Consulter tout",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const CoproChargesPage()),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
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

  // --- WIDGETS REUTILISABLES ---

  Widget _buildCitySkyline() {
    final color = mainBlue.withOpacity(0.04); 
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
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
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
              if (width > 55) Container(width: 8, height: 10, color: Colors.white.withOpacity(0.4)),
            ],
          )
        ),
      ),
    );
  }

  Widget _buildTopCard({required String title, required String value, required String badgeText, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                child: Text(badgeText, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildGridCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: mainBlue.withOpacity(0.08), shape: BoxShape.circle),
              child: Icon(icon, color: mainBlue, size: 28), 
            ),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.blueGrey.shade700)),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: mainBlue)), 
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
    } catch (e) {
      return dateStr;
    }
  }
}