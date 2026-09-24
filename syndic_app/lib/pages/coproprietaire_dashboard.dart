import 'package:flutter/material.dart';
import 'package:syndic_app/widgets/custom_header.dart'; 
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
        title: Text("ACCUEIL", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp, color: Colors.white)),
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
                  SizedBox(width: 12.w),
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
               SizedBox(height: 24.h),

              // 2. Situation : Votre solde
               Text("Situation", style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
               SizedBox(height: 12.h),
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
                         Text("Votre solde", style: TextStyle(fontSize: 14.sp, color: Colors.black54, fontWeight: FontWeight.w600)),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Text("À payer", style: TextStyle(color: Colors.red.shade700, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                     SizedBox(height: 8.h),
                    Text("2 500 MAD", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // 3. Prochaine charge
               Text("Prochaine charge", style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
              SizedBox(height: 12.h),
              _buildInfoCard(
                icon: Icons.receipt_long,
                iconColor: Colors.orange,
                title: "T3 2026",
                amount: "2 500 MAD",
                subtitle: "Échéance : 30/09/2026",
              ),
              SizedBox(height: 24),

              // 4. Dernier paiement
              Text("Dernier paiement", style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
              SizedBox(height: 12.h),
              _buildInfoCard(
                icon: Icons.check_circle,
                iconColor: Colors.green,
                title: "15/08/2026",
                amount: "2 500 MAD",
                subtitle: "Virement",
              ),
              SizedBox(height: 24.h),

              // 5. Dernières annonces
              Text("Dernières annonces", style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
              SizedBox(height: 12.h),
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
                      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(12.r)),
                      child: const Icon(Icons.campaign, color: Colors.blue, size: 24),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:  [
                          Text("Travaux ascenseur", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp, color: Colors.black87)),
                          SizedBox(height: 4.h),
                          Text(
                            "L'ascenseur sera indisponible mardi de 9h à 14h. Les copropriétaires reçoivent une notification.",
                            style: TextStyle(color: Colors.black54, fontSize: 12.sp, height: 1.4.h),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),

              // 6. Bouton : Voir toutes les charges
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainBlue,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    // Navigation vers la liste des charges
                  },
                  child:  Text("Voir toutes les charges", style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold)),
                ),
              ),
              SizedBox(height: 20),
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
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12.r)),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style:  TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp, color: Colors.black87)),
                SizedBox(height: 4),
                Text(subtitle, style:  TextStyle(color: Colors.black54, fontSize: 12.sp)),
              ],
            ),
          ),
          Text(amount, style:  TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp, color: Colors.black87)),
        ],
      ),
    );
  }
}