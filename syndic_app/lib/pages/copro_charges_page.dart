import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// ==========================================
// 1. LISTE DES CHARGES
// ==========================================
class CoproChargesPage extends StatefulWidget {
  const CoproChargesPage({super.key});

  @override
  State<CoproChargesPage> createState() => _CoproChargesPageState();
}

class _CoproChargesPageState extends State<CoproChargesPage> {
  final Color mainBlue = const Color(0xFF1A5EAC);
  final Color bgLight = const Color(0xFFF4F6F9);

  bool _isLoading = true;
  String _solde = "0,00 MAD";
  double _rawSolde = 0;
  List<dynamic> _chargesList = [];
  
  final String _residenceName = "Résidence Les Palmiers"; 
  final String _lotInfo = "Lot 12B";
  String _photoUrl = "";

  @override
  void initState() {
    super.initState();
    _fetchCharges();
  }

  Future<void> _fetchCharges() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.get(
        Uri.parse("https://api.syndify.nomade-cloud.com/api/mobile/copro/mes-charges"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _solde = data['solde'] ?? "0,00 MAD";
          _rawSolde = (data['raw_solde'] ?? 0).toDouble();
          _chargesList = data['data'] ?? [];
          
          if (data['user'] != null) {
            _photoUrl = data['user']['photo_url'] ?? "";
          }
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Charges error: $e");
      setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    if (status == "Payé") return const Color(0xFF1B5E20); 
    if (status == "Impayé") return const Color(0xFFD32F2F); 
    return Colors.orange.shade800; 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: Stack(
        children: [
          // --- BACKGROUND SKYLINE ---
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildCitySkyline(), 
          ),

          // --- CONTENU PRINCIPAL ---
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. BANNER
              _buildBanner(context),

              // 2. CONTENU DE LA PAGE CHARGES
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator(color: mainBlue))
                    : SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Carte de Solde globale
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade100),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.account_balance_wallet, color: Colors.blueGrey.shade400, size: 20),
                                      const SizedBox(width: 8),
                                      const Text("Solde de compte", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black54)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _rawSolde > 0
                                        ? _solde
                                        : (_rawSolde < 0
                                            ? "${_rawSolde.abs().toStringAsFixed(2)} MAD (Crédit)"
                                            : "À jour (0.00 MAD)"),
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: _rawSolde > 0
                                          ? const Color(0xFFD32F2F)
                                          : mainBlue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            const Text(
                              "Historique des charges",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black54),
                            ),
                            const SizedBox(height: 12),

                            // Liste des charges
                            _chargesList.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 40),
                                    child: Center(
                                      child: Text(
                                        "Aucune charge enregistrée.",
                                        style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 15),
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    padding: EdgeInsets.zero, // L'espace lkbir t7iyd b sbab hadi
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _chargesList.length,
                                    itemBuilder: (context, index) {
                                      final charge = _chargesList[index];
                                      final statusColor = _getStatusColor(charge['status'] ?? '');

                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: Colors.grey.shade100),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.03),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: mainBlue.withOpacity(0.08),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(Icons.receipt_long, color: mainBlue, size: 24),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    charge['title'] ?? 'Charge',
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    "Échéance : ${charge['date_echeance'] ?? 'N/A'}",
                                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  "${charge['amount'] ?? 0} MAD",
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                                                ),
                                                const SizedBox(height: 4),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: statusColor.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    charge['status'] ?? '',
                                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
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

  // ==========================================================
  // BANNER
  // ==========================================================
  Widget _buildBanner(BuildContext context) {
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
              const Icon(Icons.apartment, color: Colors.white, size: 24),
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
              const Icon(Icons.notifications_none, color: Colors.white, size: 26),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.white,
                  backgroundImage: _photoUrl.isNotEmpty
                      ? NetworkImage(_photoUrl)
                      : const NetworkImage(
                          "https://ui-avatars.com/api/?name=Copro&background=ffffff&color=1A5EAC&size=128&bold=true",
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            "Mes charges",
            style: TextStyle(
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
            _buildBuilding(50, 120, color),
            _buildBuilding(65, 180, color),
            _buildBuilding(45, 140, color),
            _buildBuilding(75, 210, color),
            _buildBuilding(60, 160, color),
            _buildBuilding(50, 100, color),
          ],
        ),
      ),
    );
  }

  Widget _buildBuilding(double width, double height, Color color) {
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
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(width: 8, height: 10, color: Colors.white.withOpacity(0.4)),
              Container(width: 8, height: 10, color: Colors.white.withOpacity(0.4)),
              if (width > 55)
                Container(width: 8, height: 10, color: Colors.white.withOpacity(0.4)),
            ],
          ),
        ),
      ),
    );
  }
}