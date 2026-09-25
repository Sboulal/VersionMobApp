import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syndic_app/widgets/custom_header.dart'; 
import 'package:syndic_app/pages/main_layout.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// ==========================================
// WIDGET RÉUTILISABLE : CUSTOM HEADER (DESIGN ÉPURÉ / BLANC)
// ==========================================
class CustomHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String residenceName;
  final String photoUrl;
  final bool showBackButton;
  
  final String userRole;
  final VoidCallback? onBackTap;
  final VoidCallback? onNotificationTap;

  const CustomHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.residenceName,
    required this.photoUrl,
    this.showBackButton = false,
    this.userRole = 'copro',
    this.onBackTap,
    this.onNotificationTap,
  });

  PopupMenuItem<String> _buildPopupMenuItem(String value, IconData icon, String text, {bool isDestructive = false}) {
    final Color mainBlue = const Color(0xFF1A5EAC);
    final color = isDestructive ? Colors.redAccent : mainBlue;

    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 12.w),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: 14)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color mainBlue = const Color(0xFF1A5EAC);

    return Container(
      width: double.infinity,
      // 🟢 7yedna l'fond zre9 w tswira, khelina l'fond transparent bach yakhod loun dyal l'ecran
      color: Colors.transparent, 
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 16,
        left: 20,
        right: 20,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ==========================================
          // 🟢 PARTIE GAUCHE : Bouton retour, Icone, Textes
          // ==========================================
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bouton Retour rond (b7al f tswira dyalek)
                if (showBackButton && onBackTap != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: GestureDetector(
                      onTap: onBackTap,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                          ],
                        ),
                        child: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
                      ),
                    ),
                  ),
                
                // Icone de l'immeuble
                const Padding(
                  padding: EdgeInsets.only(top: 2.0),
                  child: Icon(Icons.apartment, color: Colors.black87, size: 28),
                ),
                SizedBox(width: 12.w),
                
                // Textes
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Sindy",
                        style: TextStyle(color: mainBlue, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 2),
                      Text(
                        residenceName.isNotEmpty ? "$residenceName\n$title" : title,
                        style: const TextStyle(color: Colors.black54, fontSize: 13, height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
      
        ],
      ),
    );
  }
}
// ==========================================
// 1. VUE D'ENSEMBLE (Écran 08)
// ==========================================
class ChargesPage extends StatefulWidget {
  final bool isMainScreen; 
  const ChargesPage({super.key, this.isMainScreen = true}); 

  @override
  State<ChargesPage> createState() => _ChargesPageState();
}

class _ChargesPageState extends State<ChargesPage> {
  final Color mainBlue = const Color(0xFF1A5EAC);
  final Color bgLight = const Color(0xFFF4F6F9);

  bool _isLoading = true;
  Map<String, dynamic>? latestAppel;
  List<dynamic> appelsList = [];

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
        Uri.parse("https://api.syndify.nomade-cloud.com/api/mobile/syndic/charges"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          latestAppel = data['latest_appel'];
          appelsList = data['appels'] ?? [];
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
    // Filtrer l'historique pour ne pas réafficher le dernier appel deux fois
    List<dynamic> historique = appelsList.where((appel) {
      String appelId = (appel['id'] ?? appel['af_identifier']).toString();
      String latestId = latestAppel?['id'].toString() ?? "";
      return appelId != latestId;
    }).toList();

    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        child: _isLoading 
        ? Center(child: CircularProgressIndicator(color: mainBlue))
        : SingleChildScrollView(
          padding: EdgeInsets.all(16.0.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomHeader(
                title: "Sindy",
                subtitle: "Résidence Les Jardins\nAppels de Charges",
                residenceName: "",
                photoUrl: "",
                showBackButton: true,
                onBackTap: widget.isMainScreen 
                    ? () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const MainLayout()), (route) => false)
                    : () => Navigator.pop(context),
              ),
              SizedBox(height: 16.h),

              // 🟢 Banner Image
              ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: Stack(
                  children: [
                    Image.network('https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80', height: 140.h, width: double.infinity, fit: BoxFit.cover),
                    Container(height: 140.h, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black.withOpacity(0.7), Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.topCenter))),
                    Positioned(
                      bottom: 16.h, left: 16.w,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Appels de Fonds", style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4.h),
                          Text("Gérez les cotisations et budgets de la résidence", style: TextStyle(color: Colors.white70, fontSize: 12.sp)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              // 🟢 Le Dernier Appel (Mise en avant)
              if (latestAppel != null) ...[
                Text("Dernier Appel : ${latestAppel!['title']}", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
                SizedBox(height: 12.h),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChargeDetailsPage(appelId: latestAppel!['id'].toString()))),
                  child: Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: Colors.white, 
                      borderRadius: BorderRadius.circular(16.r), 
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("${latestAppel!['amount']} MAD", style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10.0.w, vertical: 4.0.h),
                              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8.r)),
                              child: Text("${latestAppel!['lots_count']} Lots", style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.black54)),
                            ),
                          ],
                        ),
                        SizedBox(height: 20.h),
                        _buildStatusRow(Colors.green, "${latestAppel!['payes']} Payés"),
                        SizedBox(height: 8.h),
                        _buildStatusRow(Colors.orange, "${latestAppel!['partiels']} Partiellement Payés"),
                        SizedBox(height: 8.h),
                        _buildStatusRow(Colors.red, "${latestAppel!['impayes']} Impayés"),
                        // 🟢 T7IYED L-BOUTON MN HNA B-SIFA NIHA2IYA
                      ],
                    ),
                  ),
                ),
                
                // 🟢 Affichage de l'historique des appels
                if (historique.isNotEmpty) ...[
                  SizedBox(height: 32.h),
                  Text("Historique des appels", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
                  SizedBox(height: 12.h),
                  ...historique.map((appel) => _buildHistoriqueCard(appel)).toList(),
                ],

              ] else ...[
                // Cas où il n'y a aucun appel du tout
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0.w),
                    child: Text("Aucun appel de fonds trouvé.", style: TextStyle(color: Colors.grey, fontSize: 14.sp)),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusRow(Color color, String label) {
    return Row(
      children: [
        CircleAvatar(radius: 5.r, backgroundColor: color),
        SizedBox(width: 10.w),
        Text(label, style: TextStyle(fontSize: 14.sp, color: Colors.black87, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildHistoriqueCard(dynamic appel) {
    return GestureDetector(
      onTap: () {
        String appelId = (appel['id'] ?? appel['af_identifier']).toString();
        Navigator.push(context, MaterialPageRoute(builder: (context) => ChargeDetailsPage(appelId: appelId)));
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(color: mainBlue.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(Icons.receipt_long, color: mainBlue, size: 24.sp),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(appel['title'] ?? 'Appel de fond', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp, color: Colors.black87)),
                  SizedBox(height: 4.h),
                  Text(appel['due_date'] ?? '', style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
                ],
              ),
            ),
            Text("${appel['amount']} MAD", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp, color: Colors.black87)),
            SizedBox(width: 8.w),
            Icon(Icons.chevron_right, color: Colors.grey, size: 20.sp),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 3. DÉTAILS D'UN APPEL (Écran 10)
// ==========================================
class ChargeDetailsPage extends StatefulWidget {
  final String appelId;
  const ChargeDetailsPage({super.key, required this.appelId});

  @override
  State<ChargeDetailsPage> createState() => _ChargeDetailsPageState();
}

class _ChargeDetailsPageState extends State<ChargeDetailsPage> {
  final Color mainBlue = const Color(0xFF1A5EAC);
  bool _isLoading = true;
  Map<String, dynamic>? appelDetails;
  List<dynamic> lignes = [];

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.get(
        Uri.parse("https://api.syndify.nomade-cloud.com/api/mobile/syndic/charges/${widget.appelId}"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          appelDetails = data['appel'];
          lignes = data['lignes'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(backgroundColor: const Color(0xFFF4F6F9), body: Center(child: CircularProgressIndicator(color: mainBlue)));
    }

    if (appelDetails == null) {
      return const Scaffold(body: Center(child: Text("Détails introuvables.")));
    }

    int payes = lignes.where((l) => l['status'] == 'Payé').length;
    int impayes = lignes.where((l) => l['status'] == 'Impayé').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomHeader(
                title: "Sindy", 
                subtitle: "Détail appel de fonds",
                residenceName: "",
                photoUrl: "",
                showBackButton: true,
                onBackTap: () => Navigator.pop(context),
              ),
              SizedBox(height: 8.h),

              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16.r)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: Image.network('https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80', height: 120.h, width: double.infinity, fit: BoxFit.cover),
                    ),
                    SizedBox(height: 16.h),
                    Text(appelDetails!['title'] ?? 'Appel', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8.h),
                    Text("Montant total :", style: TextStyle(fontSize: 12.sp, color: Colors.black54)),
                    Text("${appelDetails!['amount']} MAD", style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              Text("RÉSUMÉ FINANCIER", style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16.r)),
                child: Column(
                  children: [
                    _buildSummaryRow("Total appelé :", "${appelDetails!['amount']} MAD", Colors.black87),
                    Divider(height: 24.h),
                    _buildSummaryRow("Lots payés :", "$payes", Colors.green, isDot: true),
                    SizedBox(height: 8.h),
                    _buildSummaryRow("Lots impayés :", "$impayes", Colors.red, isDot: true),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              Text("LISTE DES COPROPRIÉTAIRES", style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16.r)),
                child: Column(
                  children: [
                    _buildLotDetailRow("Lot", "Propriétaire", "Montant", "Statut", isHeader: true),
                    const Divider(),
                    ...lignes.map((l) => Column(
                      children: [
                        _buildLotDetailRow(
                          l['id'].toString(), 
                          l['owner'].toString(), 
                          "${l['amount']} MAD", 
                          l['status'], 
                          color: l['status'] == 'Payé' ? Colors.green : (l['status'] == 'Impayé' ? Colors.red : Colors.orange)
                        ),
                        const Divider(),
                      ],
                    )).toList()
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color, {bool isDot = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500, color: Colors.black54)),
        Row(
          children: [
            if (isDot) CircleAvatar(radius: 4.r, backgroundColor: color),
            if (isDot) SizedBox(width: 6.w),
            Text(value, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ],
    );
  }

  Widget _buildLotDetailRow(String id, String owner, String amount, String status, {bool isHeader = false, Color color = Colors.black}) {
    TextStyle style = TextStyle(fontSize: 12.sp, fontWeight: isHeader ? FontWeight.bold : FontWeight.w500, color: isHeader ? Colors.black87 : Colors.black54);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.0.h),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text(id, style: style)),
          Expanded(flex: 2, child: Text(owner, style: style, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 2, child: Center(child: Text(amount, style: style))),
          Expanded(flex: 1, child: Align(alignment: Alignment.centerRight, child: Text(status, style: style.copyWith(color: color, fontWeight: FontWeight.bold)))),
        ],
      ),
    );
  }
}