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
  final Color mainBlue = const Color(0xFF1E3A8A); // Bleu plus moderne/sombre
  final Color bgLight = const Color(0xFFF8FAFC); // Gris très clair façon iOS

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
    final String photoUrl = _dashboardData!['photo_url'] ?? "https://ui-avatars.com/api/?name=$firstName&background=ffffff&color=1E3A8A&size=128&bold=true";

    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. HEADER MODERNE (Inspiré du design clair)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Bonjour, $firstName",
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF1E293B), letterSpacing: -0.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.apartment, size: 14, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                "$_residenceName • $_lotInfo",
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFFE2E8F0),
                      backgroundImage: NetworkImage(photoUrl),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // 2. CARTES FINANCIÈRES (Design Soft)
              const Text("Vue d'ensemble", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildModernFinancialCard(
                      title: "Solde actuel",
                      value: solde > 0 ? "${solde.toStringAsFixed(0)} MAD" : (solde < 0 ? "Crédit" : "À jour"),
                      icon: Icons.account_balance_wallet,
                      isAlert: solde > 0,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildModernFinancialCard(
                      title: "Prochaine charge",
                      value: charge != null ? "${charge['amount']} MAD" : "Aucune",
                      icon: Icons.calendar_today_rounded,
                      isAlert: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // 3. SERVICES (Grille minimaliste)
              const Text("Vos services", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.05, 
                children: [
                  _buildModernGridCard(
                    icon: Icons.credit_score_rounded,
                    iconColor: const Color(0xFF10B981), // Vert pastel
                    title: "Paiements",
                    subtitle: paiement != null ? _formatDate(paiement['date']) : "Historique",
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CoproPaiementsPage())),
                  ),
                  _buildModernGridCard(
                    icon: Icons.campaign_rounded,
                    iconColor: const Color(0xFFF59E0B), // Orange pastel
                    title: "Annonces",
                    subtitle: "${annonces.length} nouveautés",
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CoproAnnoncesPage())),
                  ),
                  _buildModernGridCard(
                    icon: Icons.folder_copy_rounded,
                    iconColor: const Color(0xFF3B82F6), // Bleu ciel
                    title: "Documents",
                    subtitle: "Règlements & PV",
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CoproDocumentsPage())),
                  ),
                  _buildModernGridCard(
                    icon: Icons.receipt_long_rounded,
                    iconColor: const Color(0xFF8B5CF6), // Violet pastel
                    title: "Charges",
                    subtitle: "Détails & Appels",
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CoproChargesPage())),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // --- NOUVEAUX WIDGETS MODERNES ---

  Widget _buildModernFinancialCard({required String title, required String value, required IconData icon, required bool isAlert}) {
    // Couleurs douces inspirées de l'iOS moderne
    final Color bgColor = isAlert ? const Color(0xFFFEF2F2) : Colors.white;
    final Color borderColor = isAlert ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0);
    final Color iconBgColor = isAlert ? const Color(0xFFFEE2E2) : const Color(0xFFF1F5F9);
    final Color iconColor = isAlert ? const Color(0xFFEF4444) : mainBlue;
    final Color textColor = isAlert ? const Color(0xFF991B1B) : const Color(0xFF0F172A);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildModernGridCard({required IconData icon, required Color iconColor, required String title, required String subtitle, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 2),
          boxShadow: [
            BoxShadow(color: const Color(0xFF94A3B8).withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8))),
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