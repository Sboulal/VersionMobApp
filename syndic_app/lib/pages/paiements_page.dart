import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syndic_app/widgets/custom_header.dart'; // تأكدي من مسار الـ import
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
class PaiementsPage extends StatefulWidget {
  final bool isMainScreen;
  const PaiementsPage({super.key, this.isMainScreen = true});

  @override
  State<PaiementsPage> createState() => _PaiementsPageState();
}

class _PaiementsPageState extends State<PaiementsPage> {
  final Color mainBlue = const Color(0xFF1A5EAC);
  final Color bgLight = const Color(0xFFF4F6F9);

  bool _isLoading = true;
  String _totalMois = "0,00"; 
  List<dynamic> paiementsList = [];

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
        Uri.parse("https://api.syndify.nomade-cloud.com/api/mobile/syndic/paiements"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _totalMois = data['total_mois']?.toString() ?? "15 000,00"; // Valeur l-test ila makantch f l-API
          paiementsList = data['data'];
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
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 16.0.w, right: 16.0.w, top: 16.0.h),
              child: CustomHeader(
                title: "Sindy",
                subtitle: "Gestion des Cotisations", 
                residenceName: "Résidence Les Jardins",
                photoUrl: "",
                showBackButton: true,
                onBackTap: widget.isMainScreen 
                    ? () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const MainLayout()), (route) => false)
                    : () => Navigator.pop(context),
              ),
            ),
            
            // 🟢 Bannière
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0.w, vertical: 8.0.h),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: Stack(
                  children: [
                    Image.network('https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80', height: 120.h, width: double.infinity, fit: BoxFit.cover),
                    Container(height: 120.h, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black.withOpacity(0.7), Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.topCenter))),
                    Positioned(
                      bottom: 16.h, left: 16.w,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Suivi des Cotisations", style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4.h),
                          Text("Consultez les règlements des copropriétaires", style: TextStyle(color: Colors.white70, fontSize: 12.sp)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 🟢 Bloc Total du mois
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.0.w),
              decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.grey.shade200), top: BorderSide(color: Colors.grey.shade200))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Cotisations", style: TextStyle(fontSize: 14.sp, color: Colors.black54, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8.h),
                  Text("Total encaissé ce mois :", style: TextStyle(fontSize: 14.sp, color: Colors.black87)),
                  SizedBox(height: 4.h),
                  Text("$_totalMois MAD", style: TextStyle(fontSize: 26.sp, fontWeight: FontWeight.bold, color: const Color(0xFF4CAF50))), 
                ],
              ),
            ),
            
            // 🟢 Liste des paiements/cotisations (Katakhoud ga3 l-espace li b9a l-te7t)
            Expanded(
              child: _isLoading
                ? Center(child: CircularProgressIndicator(color: mainBlue))
                : paiementsList.isEmpty
                  ? Center(child: Text("Aucune cotisation trouvée.", style: TextStyle(color: Colors.grey, fontSize: 14.sp)))
                  : ListView.separated(
                      padding: EdgeInsets.symmetric(horizontal: 16.0.w, vertical: 16.0.h), 
                      itemCount: paiementsList.length,
                      separatorBuilder: (_, __) => Divider(height: 24.h),
                      itemBuilder: (context, index) {
                        final p = paiementsList[index];
                        final modeColor = _hexToColor(p['modeColorHex']);
                        
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center, 
                          children: [
                            Container(
                              padding: EdgeInsets.all(10.w),
                              decoration: BoxDecoration(color: modeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12.r)),
                              child: Icon(Icons.arrow_downward, color: modeColor, size: 24.sp), 
                            ),
                            SizedBox(width: 16.w),
                            
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p["date"], style: TextStyle(color: Colors.black54, fontSize: 12.sp)),
                                  SizedBox(height: 4.h),
                                  Text("${p["owner"]} (${p["lot"]})", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp, color: Colors.black87)),
                                ],
                              ),
                            ),
                            
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text("+ ${p["amount"]}", style:TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp, color: const Color(0xFF4CAF50))), 
                                SizedBox(height: 4.h),
                                Row(
                                  children: [
                                    CircleAvatar(radius: 4.r, backgroundColor: modeColor),
                                    SizedBox(width: 4.w),
                                    Text(p["mode"], style: TextStyle(color: modeColor, fontWeight: FontWeight.bold, fontSize: 12.sp)),
                                  ],
                                )
                              ],
                            ),
                          ],
                        );
                      },
                    ),
            ),
            
            // 🟢 T7IYED L-BOUTON MN HNA B-SIFA NIHA2IYA
            
          ],
        ),
      ),
    );
  }
}