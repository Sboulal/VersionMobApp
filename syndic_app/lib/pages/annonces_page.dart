import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syndic_app/widgets/custom_header.dart'; 
import 'package:syndic_app/pages/main_layout.dart'; 
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ==========================================
// 1. LISTE DES ANNONCES (Vue d'ensemble)
// ==========================================
class AnnoncesPage extends StatefulWidget {
  final bool isMainScreen;
  const AnnoncesPage({super.key, this.isMainScreen = true});

  @override
  State<AnnoncesPage> createState() => _AnnoncesPageState();
}

class _AnnoncesPageState extends State<AnnoncesPage> {
  final Color mainBlue = const Color(0xFF1A5EAC);
  final Color bgLight = const Color(0xFFF4F6F9);

  bool _isLoading = true;
  List<dynamic> annoncesList = [];

  @override
  void initState() {
    super.initState();
    _fetchAnnonces();
  }

  Future<void> _fetchAnnonces() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.get(
        Uri.parse("https://api.syndify.nomade-cloud.com/api/mobile/syndic/annonces"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          annoncesList = data['data'];
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

  IconData _getIcon(String iconStr) {
    switch (iconStr) {
      case 'build': return Icons.build_circle;
      case 'warning': return Icons.warning;
      case 'groups': return Icons.groups;
      case 'info': default: return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
              child: CustomHeader(
                title: "Sindy",
                subtitle: "Résidence Les Jardins\nAnnonces",
                showBackButton: true,
                onBackPressed: widget.isMainScreen 
                    ? () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const MainLayout()), (route) => false)
                    : null,
              ),
            ),
            
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0.w, vertical: 8.0.h),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    Image.network('https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80', height: 140, width: double.infinity, fit: BoxFit.cover),
                    Container(height: 140, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black.withOpacity(0.7), Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.topCenter))),
                    Positioned(
                      bottom: 16, left: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("Tableau d'affichage", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text("Restez informé des actualités de la résidence", style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 8),

            Expanded(
              child: _isLoading 
                ? Center(child: CircularProgressIndicator(color: mainBlue))
                : annoncesList.isEmpty
                  ? const Center(child: Text("Aucune annonce pour le moment.", style: TextStyle(color: Colors.grey)))
                  : ListView.separated(
                      padding: EdgeInsets.symmetric(horizontal: 16.0.w, vertical: 8.0.h),
                      itemCount: annoncesList.length,
                      separatorBuilder: (_, __) => SizedBox(height: 12.h),
                      itemBuilder: (context, index) {
                        final ann = annoncesList[index];
                        final aColor = _hexToColor(ann['colorHex']);
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))], border: Border.all(color: Colors.grey.shade200)),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(_getIcon(ann['iconString']), color: aColor, size: 28),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(child: Text(ann["title"], style:  TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp, color: Colors.black87))),
                                        Text(ann["date"], style:  TextStyle(color: Colors.black54, fontSize: 11.sp)),
                                      ],
                                    ),
                                     SizedBox(height: 4.h),
                                    Text(ann["category"], style: TextStyle(color: aColor, fontSize: 11.sp, fontWeight: FontWeight.bold)),
                                     SizedBox(height: 8.h),
                                    Text(ann["message"], style:  TextStyle(color: Colors.black54, fontSize: 13.sp)),
                                  ],
                                ),
                              ),
                            ],
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

