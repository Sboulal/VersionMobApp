import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SyndicValidationPage extends StatefulWidget {
  const SyndicValidationPage({super.key});

  @override
  State<SyndicValidationPage> createState() => _SyndicValidationPageState();
}

class _SyndicValidationPageState extends State<SyndicValidationPage> {
  final Color mainBlue = const Color(0xFF1A5EAC);
  List<dynamic> pendingUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPendingUsers();
  }

// 🟢 Fonction bach njbdou n-nass en attente
  Future<void> _fetchPendingUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.get(
        Uri.parse("https://api.syndify.nomade-cloud.com/api/mobile/syndic/copro-en-attente"),
        headers: {"Accept": "application/json", "Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          pendingUsers = data['data'];
          _isLoading = false;
        });
      } else {
        // 🔴 ZEDNA L-ELSE BACH Y-7BESS L-CHARGEMENT ILA KAN ERREUR
        print("Erreur Backend: ${response.body}");
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur serveur: ${response.statusCode}"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur de connexion")));
    }
  }

  // 🟢 Beddelna 'int userId' b 'dynamic userId' bach yqbel ay naw3 dyal les IDs
  Future<void> _validerUser(dynamic userId, String userName) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.post(
        Uri.parse("https://api.syndify.nomade-cloud.com/api/mobile/syndic/valider-copro/$userId"),
        headers: {"Accept": "application/json", "Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        // N-ms7ouh mn la liste w n-affichiwh msg
        setState(() {
          pendingUsers.removeWhere((user) => user['id'] == userId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$userName a été validé avec succès !"), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur lors de la validation"), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur de connexion au serveur"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: mainBlue),
        title: const Text("Validations en attente", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: mainBlue))
          : pendingUsers.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: pendingUsers.length,
                  itemBuilder: (context, index) {
                    final user = pendingUsers[index];
                    return _buildPendingUserCard(user);
                  },
                ),
    );
  }

  Widget _buildPendingUserCard(dynamic user) {
    bool hasPhoto = user['photo'] != null;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.blue.shade50,
              backgroundImage: hasPhoto ? NetworkImage(user['photo']) : null,
              child: !hasPhoto ? Icon(Icons.person, color: mainBlue) : null,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user['nom'], style:  TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 12, color: Colors.black54),
                      SizedBox(width: 4),
                      Text(user['tel'] ?? "Non renseigné", style: const TextStyle(color: Colors.black54, fontSize: 12)),
                    ],
                  ),
                  SizedBox(height: 2),
                  Text("Inscrit le: ${user['date_demande']}", style: TextStyle(color: Colors.orange.shade700, fontSize: 11)),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              // 🟢 Hna darna toString() bach ntfadaw l-machakil
              onPressed: () => _validerUser(user['id'], user['nom'].toString()),
              child: const Text("Valider", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 80, color: Colors.grey.shade400),
          SizedBox(height: 16.h),
          const Text("Aucune demande en attente", style: TextStyle(fontSize: 18, color: Colors.black54, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}