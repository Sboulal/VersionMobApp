import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syndic_app/pages/profile_page.dart'; 
import 'package:syndic_app/pages/forgot_password_page.dart'; 
import 'package:syndic_app/pages/login_page.dart'; 
import 'package:syndic_app/pages/NotificationsScreen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ==========================================
// WIDGET RÉUTILISABLE : CUSTOM HEADER
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

  PopupMenuButton<String> _buildPopupMenu(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      color: Colors.white,
      elevation: 4,
      // 🟢 ZIDNA Hadi bach l-menu ywlli khdam w y-dir l-action !
      onSelected: (String value) async {
        if (value == 'profile') {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const UnifiedProfilePage()));
        } else if (value == 'logout') {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('auth_token');
          if (context.mounted) {
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginPage()), (route) => false);
          }
        }
      },
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem(value: 'profile', child: Text('Profil')),
        const PopupMenuItem(value: 'logout', child: Text('Déconnexion', style: TextStyle(color: Colors.red))),
      ],
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: CircleAvatar(
          radius: 22,
          backgroundColor: Colors.white,
          backgroundImage: photoUrl.isNotEmpty
              ? NetworkImage(photoUrl)
              : const NetworkImage("https://ui-avatars.com/api/?name=Copro&background=ffffff&color=1A5EAC&bold=true"),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color mainBlue = const Color(0xFF1A5EAC);

    return Container(
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
        right: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (showBackButton && onBackTap != null)
                InkWell(
                  onTap: onBackTap,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 16.0),
                    child: Icon(Icons.arrow_back, color: Colors.white, size: 26),
                  ),
                ),
              const Icon(Icons.apartment, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  residenceName.isNotEmpty ? "Sindy | $residenceName" : "Sindy",
                  style:  TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: onNotificationTap ?? () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationsScreen(role: userRole)));
                },
                child: const Icon(Icons.notifications_none, color: Colors.white, size: 26),
              ),
              SizedBox(width: 12.w),
              _buildPopupMenu(context),
            ],
          ),
          SizedBox(height: 20),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w800)),
          SizedBox(height: 3),
          Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ==========================================
// 1. LISTE DES CHARGES COPROPRIÉTAIRE (Corrigée)
// ==========================================
class CoproChargesPage extends StatefulWidget {
  final bool showBackButton;
  const CoproChargesPage({super.key, required this.showBackButton});

  @override
  State<CoproChargesPage> createState() => _CoproChargesPageState();
}

class _CoproChargesPageState extends State<CoproChargesPage> {
  final Color mainBlue = const Color(0xFF1A5EAC);
  final Color bgLight = const Color(0xFFF4F6F9);

  bool _isLoading = true;
  String _solde = "0,00 MAD";
  List<dynamic> _historiqueAppels = [];
  
  String _residenceName = "Ma Résidence";
  String _photoUrl = "";

  @override
  void initState() {
    super.initState();
    _fetchMesCharges();
  }

  Future<void> _fetchMesCharges() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    setState(() {
      _residenceName = prefs.getString('residence_name') ?? "Ma Résidence";
      _photoUrl = prefs.getString('photo_url') ?? "";
      _isLoading = true; 
    });

    if (token == null) return;

    try {
      // 🟢 API S7i7a dyal l-copropriétaire 
      final response = await http.get(
        Uri.parse("https://api.syndify.nomade-cloud.com/api/mobile/copro/mes-charges"), 
        headers: {"Authorization": "Bearer $token", "Accept": "application/json"},
      );
      
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        if (mounted) {
          setState(() {
            _solde = data['solde'] ?? "0,00 MAD";
            _historiqueAppels = data['data'] ?? [];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      // ❌ 7iydna FloatingActionButton li kan kiy-zid l'appel de fonds
      body: SafeArea(
        child: Column(
          children: [
            CustomHeader(
              title: "Mes Charges",
              subtitle: "Consultez l'état de vos cotisations",
              residenceName: _residenceName,
              photoUrl: _photoUrl, 
              showBackButton: widget.showBackButton,
              onBackTap: () => Navigator.pop(context),
            ),
            Expanded(
              child: _isLoading 
                  ? Center(child: CircularProgressIndicator(color: mainBlue))
                  : SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16).copyWith(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSoldeCard(),
                          SizedBox(height: 24),
                           Text(
                            "Historique de mes charges",
                            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: Colors.black87),
                          ),
                          SizedBox(height: 12),
                          _buildHistoriqueList(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoldeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet, color: mainBlue, size: 20),
               SizedBox(width: 8.w),
               Text("Mon Solde Actuel", style: TextStyle(fontSize: 14.sp, color: Colors.black54, fontWeight: FontWeight.w600)),
            ],
          ),
           SizedBox(height: 12.h),
          Text(
            _solde,
            style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold, color: mainBlue),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoriqueList() {
    if (_historiqueAppels.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text("Aucune charge enregistrée.")));
    }

    return Column(
      children: _historiqueAppels.map((appel) {
        // Loun d'status 3la hsab wach khless wla la
        Color statusColor = (appel['status'] == 'Impayé') ? Colors.red.shade600 : Colors.green.shade600;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: mainBlue.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.receipt_long, color: mainBlue, size: 24),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(appel['title'] ?? 'Appel de charge', style:  TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp, color: Colors.black87)),
                     SizedBox(height: 4.h),
                    Text("Échéance: ${appel['date_echeance'] ?? 'N/A'}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12.sp)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(appel['amount'] ?? "0.00 MAD", style:  TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
                   SizedBox(height: 4.h),
                  Text(appel['status'] ?? "Impayé", style: TextStyle(color: statusColor, fontSize: 12.sp, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}