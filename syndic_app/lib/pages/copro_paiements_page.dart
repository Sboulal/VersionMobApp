import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CoproPaiementsPage extends StatefulWidget {
  const CoproPaiementsPage({super.key});

  @override
  State<CoproPaiementsPage> createState() => _CoproPaiementsPageState();
}

class _CoproPaiementsPageState extends State<CoproPaiementsPage> {
  final Color mainBlue = const Color(0xFF1A5EAC);
  final Color bgLight = const Color(0xFFF4F6F9);

  bool _isLoading = true;
  List<dynamic> _paiementsList = [];
  final String _residenceName = "Résidence Les Palmiers"; 

  @override
  void initState() {
    super.initState();
    _fetchPaiements();
  }

  Future<void> _fetchPaiements() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.get(
        Uri.parse("https://api.syndify.nomade-cloud.com/api/mobile/copro/mes-paiements"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _paiementsList = data['data'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Color _hexToColor(String hexString) {
    var hexColor = hexString.replaceAll("#", "");
    if (hexColor.length == 6) hexColor = "FF$hexColor";
    return Color(int.parse("0x$hexColor"));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: Stack(
        children: [
          // --- BACKGROUND WATERMARK ---
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _buildCitySkyline(),
          ),

          // --- CONTENU PRINCIPAL ---
          // ❌ SafeArea retiré ici
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 20.0, bottom: 12.0),
                child: Text(
                  "Mes paiements",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade800),
                ),
              ),

              // 3. Liste des paiements
              Expanded(
                child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: mainBlue))
                  : _paiementsList.isEmpty
                    ? Center(child: Text("Aucun paiement enregistré.", style: TextStyle(color: Colors.blueGrey.shade400)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                        itemCount: _paiementsList.length,
                        itemBuilder: (context, index) {
                          final p = _paiementsList[index];
                          final modeColor = _hexToColor(p['colorHex']);
                          
                          String infoLine = "${p['date']} | ${p['amount']} | ${p['mode']}";
                          String refText = "";
                          if (p['reference'] != null && p['reference'].toString().trim().isNotEmpty) {
                            refText = "Réf. ${p['reference'].toString().trim()}";
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade100),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Icône circulaire
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: modeColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.credit_card, color: modeColor, size: 24),
                                ),
                                const SizedBox(width: 16),
                                
                                // Détails
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(infoLine, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                                      if (refText.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(refText, style: const TextStyle(color: Colors.black54, fontSize: 12, fontStyle: FontStyle.italic)),
                                      ]
                                    ],
                                  ),
                                ),
                                
                                // Badge de succès (Vert forêt unifié)
                                const Icon(Icons.check_circle, color: Color(0xFF1B5E20), size: 22),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🟢 ويدجيت الخلفية ديال العمارات
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