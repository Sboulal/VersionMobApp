import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syndic_app/pages/login_page.dart';
import 'package:syndic_app/pages/paiements_page.dart'; 
import 'package:syndic_app/pages/depenses_page.dart'; 
import 'package:syndic_app/pages/annonces_page.dart';
import 'package:syndic_app/pages/charges_page.dart'; 

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

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

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
      return;
    }

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
        setState(() {
          _dashboardData = decodedBody['data'];
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        await prefs.remove('auth_token');
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
      } else {
        setState(() {
          // 🟢 هكا غيبان الخطأ الحقيقي لي صيفط Laravel
          _errorMessage = decodedBody['message'] ?? "Erreur serveur : ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
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
                        _buildWalletCard(),
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

  Widget _buildHeader() {
    final prenom = _dashboardData?['utilisateur']['prenom'] ?? "Syndic";
    final coproNom = _dashboardData?['copropriete']['nom'] ?? "Ma Résidence";

    return Row(
      children: [
        const CircleAvatar(
          radius: 24,
          backgroundColor: Colors.white,
          backgroundImage: NetworkImage('https://cdn-icons-png.flaticon.com/512/3135/3135715.png'), 
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Bonjour $prenom!", style: const TextStyle(color: Colors.black54, fontSize: 12)),
              Text(coproNom, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          ),
          child: const Icon(Icons.notifications_none, color: Colors.black87, size: 22),
        )
      ],
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInnerActionBtn(Icons.add, "Appel de charge", () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChargesPage()))),
              _buildInnerActionBtn(Icons.send, "Paiement", () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PaiementsPage()))),
              _buildInnerActionBtn(Icons.receipt_long, "Dépense", () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DepensesPage()))),
              _buildInnerActionBtn(Icons.campaign, "Annonce", () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AnnoncesPage()))),
            ],
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
                Icons.request_quote, const Color(0xFFE8EAF6), const Color(0xFF3F51B5), "Total des charges", _formatMontant(kpis['charges_appelees']),
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChargesPage())),
              ),
              _buildLargeStatCard(
                Icons.savings, const Color(0xFFE8F5E9), const Color(0xFF4CAF50), "Total encaissé", _formatMontant(kpis['encaisse']),
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PaiementsPage())),
              ),
              _buildLargeStatCard(
                Icons.warning_amber_rounded, const Color(0xFFFFEBEE), const Color(0xFFF44336), "Total des impayés", _formatMontant(kpis['impayes']),
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChargesPage())), // Redirige vers ChargesPage par défaut
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
              Text("Voir tout", style: TextStyle(fontSize: 12, color: mainBlueLight, fontWeight: FontWeight.w600)),
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