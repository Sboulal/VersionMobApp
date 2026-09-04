import 'package:flutter/material.dart';
// import 'package:syndic_app/pages/detail_charge_page.dart'; // Décommente si tu as créé la page de détail

class MesChargesPage extends StatelessWidget {
  const MesChargesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Color mainBlue = const Color(0xFF1A5EAC);
    final Color bgLight = const Color(0xFFF4F6F9);

    // Données chronologiques des charges
    final List<Map<String, dynamic>> chargesList = [
      {
        "periode": "T3 2026",
        "montant": "2 500 MAD",
        "statut": "Impayé",
        "couleur": Colors.red.shade700,
      },
      {
        "periode": "T2 2026",
        "montant": "2 500 MAD",
        "statut": "Payé",
        "couleur": Colors.green,
      },
      {
        "periode": "T1 2026",
        "montant": "2 500 MAD",
        "statut": "Payé",
        "couleur": Colors.green,
      },
    ];

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: mainBlue,
        elevation: 0,
        title: const Text("MES CHARGES", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. En-tête : Bonjour Jean & Solde à payer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text("Bonjour Jean", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 20),
                  
                  // Carte Solde
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      children: [
                        const Text("Situation : Solde à payer", style: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text("2 500 MAD", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. Titre de la liste
            const Padding(
              padding: EdgeInsets.only(left: 16.0, right: 16.0, top: 24.0, bottom: 12.0),
              child: Text("Liste des charges chronologiques", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
            ),

            // 3. Liste Chronologique
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                itemCount: chargesList.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final charge = chargesList[index];
                  
                  return GestureDetector(
                    onTap: () {
                      // 🟢 Navigation vers les détails de la charge (Écran 21)
                      // Navigator.push(context, MaterialPageRoute(builder: (context) => DetailChargePage(charge: charge)));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Période
                          Expanded(
                            flex: 2,
                            child: Text(charge["periode"], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                          ),
                          // Séparateur
                          Container(height: 16, width: 1, color: Colors.grey.shade300),
                          // Montant
                          Expanded(
                            flex: 3,
                            child: Center(
                              child: Text(charge["montant"], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                            ),
                          ),
                          // Séparateur
                          Container(height: 16, width: 1, color: Colors.grey.shade300),
                          // Statut avec pastille
                          Expanded(
                            flex: 2,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                CircleAvatar(radius: 5, backgroundColor: charge["couleur"]),
                                const SizedBox(width: 6),
                                Text(charge["statut"], style: TextStyle(color: charge["couleur"], fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
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
      ),
    );
  }
}