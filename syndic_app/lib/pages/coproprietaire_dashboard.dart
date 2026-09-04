import 'package:flutter/material.dart';
import 'package:syndic_app/widgets/custom_header.dart'; 

class CoproprietaireDashboard extends StatelessWidget {
  const CoproprietaireDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final Color mainBlue = const Color(0xFF1A5EAC);
    final Color bgLight = const Color(0xFFF4F6F9);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: mainBlue,
        elevation: 0,
        title: const Text("ACCUEIL", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. En haut : Bonjour Jean (🟢 CORRECTION ICI avec Expanded)
              Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage('https://cdn-icons-png.flaticon.com/512/3135/3135715.png'),
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Expanded( // 🟢 Ajout de Expanded
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Bonjour Jean", 
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis, // 🟢 Coupe proprement si c'est trop long
                        ),
                        Text(
                          "Lot A12 | Résidence Les Jardins", 
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis, // 🟢 Coupe proprement si c'est trop long
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 2. Situation : Votre solde
              const Text("Situation", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.shade200, width: 1.5),
                  boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Votre solde", style: TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w600)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Text("À payer", style: TextStyle(color: Colors.red.shade700, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text("2 500 MAD", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3. Prochaine charge
              const Text("Prochaine charge", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 12),
              _buildInfoCard(
                icon: Icons.receipt_long,
                iconColor: Colors.orange,
                title: "T3 2026",
                amount: "2 500 MAD",
                subtitle: "Échéance : 30/09/2026",
              ),
              const SizedBox(height: 24),

              // 4. Dernier paiement
              const Text("Dernier paiement", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 12),
              _buildInfoCard(
                icon: Icons.check_circle,
                iconColor: Colors.green,
                title: "15/08/2026",
                amount: "2 500 MAD",
                subtitle: "Virement",
              ),
              const SizedBox(height: 24),

              // 5. Dernières annonces
              const Text("Dernières annonces", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.campaign, color: Colors.blue, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("Travaux ascenseur", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                          SizedBox(height: 4),
                          Text(
                            "L'ascenseur sera indisponible mardi de 9h à 14h. Les copropriétaires reçoivent une notification.",
                            style: TextStyle(color: Colors.black54, fontSize: 12, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 6. Bouton : Voir toutes les charges
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    // Navigation vers la liste des charges
                  },
                  child: const Text("Voir toutes les charges", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper pour générer les cartes (Charges / Paiements) ---
  Widget _buildInfoCard({required IconData icon, required Color iconColor, required String title, required String amount, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          ),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
        ],
      ),
    );
  }
}