import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// ==========================================
// 1. LISTE DES CHARGES (Écran 20)
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
          _solde = data['solde'];
          _rawSolde = (data['raw_solde'] ?? 0).toDouble();
          _chargesList = data['data'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
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
          // --- BACKGROUND WATERMARK ---
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
              // 1. Banner
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

              // 2. Titre de la page
              Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 20.0, bottom: 8.0),
                child: Text(
                  "Mes charges",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade800),
                ),
              ),

              // 3. Carte de Solde globale
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade100),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
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
                          ? "$_solde"
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
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Text("Historique des charges", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54)),
              ),

              // 4. Liste des charges 
              Expanded(
                child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: mainBlue))
                  : _chargesList.isEmpty
                    ? Center(child: Text("Aucune charge enregistrée.", style: TextStyle(color: Colors.blueGrey.shade400)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                        itemCount: _chargesList.length,
                        itemBuilder: (context, index) {
                          final charge = _chargesList[index];
                          final statusColor = _getStatusColor(charge['status']);

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => DetailChargeCoproPage(charge: charge)),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade100),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
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
                                          charge['title'],
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Échéance : ${charge['date_echeance'] ?? 'N/A'}",
                                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        charge['amount'],
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.circle, color: statusColor, size: 8),
                                            const SizedBox(width: 4),
                                            Text(charge['status'], style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ],
      )
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
}

// ==========================================
// 2. DÉTAIL D'UNE CHARGE (Écran 21)
// ==========================================
class DetailChargeCoproPage extends StatelessWidget {
  final Map<String, dynamic> charge;
  const DetailChargeCoproPage({super.key, required this.charge});

  @override
  Widget build(BuildContext context) {
    final Color mainBlue = const Color(0xFF1A5EAC);
    final Color bgLight = const Color(0xFFF4F6F9);
    const String residenceName = "Résidence Les Palmiers"; 

    Color statusColor = Colors.orange.shade800;
    if (charge['status'] == "Payé") {
      statusColor = const Color(0xFF1B5E20);
    } else if (charge['status'] == "Impayé") {
      statusColor = const Color(0xFFD32F2F);
    }

    return Scaffold(
      backgroundColor: bgLight,
      body: Stack(
        children: [
          // --- BACKGROUND WATERMARK ---
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _buildCitySkyline(mainBlue.withOpacity(0.03)),
          ),

          // --- CONTENU PRINCIPAL ---
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Bande bleue supérieure avec IMAGE DE FOND (Banner unifié)
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
                    // Flèche de retour (si existante)
                    if (Navigator.canPop(context))
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Padding(
                          padding: EdgeInsets.only(right: 12.0),
                          child: Icon(Icons.arrow_back, color: Colors.white, size: 24),
                        ),
                      ),
                      
                    const Icon(Icons.apartment, color: Colors.white, size: 24),
                    const SizedBox(width: 8),
                    
                    Expanded(
                      child: Text(
                        "Sindy | $residenceName",
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
                      // Titre
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          charge['title'],
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade800),
                        ),
                      ),

                      // Carte des détails
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade100),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.receipt_long, color: Colors.blueGrey.shade400, size: 20),
                                const SizedBox(width: 8),
                                const Text("Montant à régler", style: TextStyle(fontSize: 14, color: Colors.black54)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(charge['amount'], style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: statusColor)),
                            
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Divider(height: 1, color: Colors.black12),
                            ),

                            _buildDetailRow("Date d'émission", charge['date_emission'] ?? "N/A"),
                            const SizedBox(height: 16),
                            _buildDetailRow("Échéance", charge['date_echeance'] ?? "N/A"),
                            const SizedBox(height: 16),
                            
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Statut", style: TextStyle(color: Colors.black54, fontSize: 14)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.circle, color: statusColor, size: 10),
                                      const SizedBox(width: 6),
                                      Text(charge['status'], style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13)),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Bouton Télécharger
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mainBlue, 
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shadowColor: mainBlue.withOpacity(0.4),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.cloud_download),
                          label: const Text("TÉLÉCHARGER LE DOCUMENT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Téléchargement en cours..."), backgroundColor: Colors.green),
                            );
                          },
                        ),
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

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 14)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
      ],
    );
  }

  Widget _buildCitySkyline(Color color) {
    return SizedBox(
      height: 220,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Container(width: 50, height: 120, decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.vertical(top: Radius.circular(8)))),
          Container(width: 65, height: 180, decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.vertical(top: Radius.circular(8)))),
          Container(width: 45, height: 140, decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.vertical(top: Radius.circular(8)))),
          Container(width: 75, height: 210, decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.vertical(top: Radius.circular(8)))),
          Container(width: 60, height: 160, decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.vertical(top: Radius.circular(8)))),
          Container(width: 50, height: 100, decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.vertical(top: Radius.circular(8)))),
        ],
      ),
    );
  }
}