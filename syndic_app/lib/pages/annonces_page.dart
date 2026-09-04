import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syndic_app/widgets/custom_header.dart'; 
import 'package:syndic_app/pages/main_layout.dart'; 

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
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
            const SizedBox(height: 8),

            Expanded(
              child: _isLoading 
                ? Center(child: CircularProgressIndicator(color: mainBlue))
                : annoncesList.isEmpty
                  ? const Center(child: Text("Aucune annonce pour le moment.", style: TextStyle(color: Colors.grey)))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      itemCount: annoncesList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
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
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(child: Text(ann["title"], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87))),
                                        Text(ann["date"], style: const TextStyle(color: Colors.black54, fontSize: 11)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(ann["category"], style: TextStyle(color: aColor, fontSize: 11, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    Text(ann["message"], style: const TextStyle(color: Colors.black54, fontSize: 13)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            
            Container(
              padding: const EdgeInsets.all(16.0),
              color: bgLight,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: mainBlue, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  icon: const Icon(Icons.campaign, color: Colors.white),
                  label: const Text("Créer une annonce", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const CreerAnnoncePage())).then((_) => _fetchAnnonces());
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 2. CRÉER UNE ANNONCE (Écran 18)
// ==========================================
class CreerAnnoncePage extends StatefulWidget {
  const CreerAnnoncePage({super.key});

  @override
  State<CreerAnnoncePage> createState() => _CreerAnnoncePageState();
}

class _CreerAnnoncePageState extends State<CreerAnnoncePage> {
  final Color mainBlue = const Color(0xFF1A5EAC);
  final Color bgLight = const Color(0xFFF4F6F9);

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _expDateController = TextEditingController();

  String _selectedCategory = "Information";
  final List<String> _categories = ["Travaux", "Entretien", "Information", "Urgent", "Assemblée Générale"];
  bool _sendNotification = true;
  bool _isSubmitting = false;

  Future<void> _submitAnnonce() async {
    if (_titleController.text.trim().isEmpty || _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Le titre et le message sont obligatoires.")));
      return;
    }

    setState(() => _isSubmitting = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.post(
        Uri.parse("https://api.syndify.nomade-cloud.com/api/mobile/syndic/annonces"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
        body: jsonEncode({
          "title": _titleController.text.trim(),
          "category": _selectedCategory,
          "message": _messageController.text.trim(),
          "expiration_date": _expDateController.text.isNotEmpty ? _expDateController.text : null,
          "send_notification": _sendNotification
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message']), backgroundColor: Colors.green));
          Navigator.pop(context);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? "Erreur Serveur"), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur réseau: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Center(child: Text("CONFIRMATION", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Confirmez-vous la création et la publication de l'annonce ?", textAlign: TextAlign.center, style: TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _sendNotification ? "L'annonce sera visible. Une notification Push sera envoyée." : "L'annonce sera visible sans notification.", 
                    style: const TextStyle(fontSize: 12, color: Colors.black54)
                  ),
                ),
              ],
            )
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: mainBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              onPressed: () {
                Navigator.pop(context); 
                _submitAnnonce(); 
              },
              child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text("CONFIRMER ET PUBLIER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("ANNULER", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CustomHeader(title: "Sindy", subtitle: "Créer une annonce", showBackButton: true),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("NOUVELLE ANNONCE", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 16),
                    
                    _buildInputLabel("Titre *"),
                    TextField(controller: _titleController, decoration: _inputDecoration("Ex: Travaux ascenseur")),
                    const SizedBox(height: 16),

                    _buildInputLabel("Catégorie"),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: bgLight, borderRadius: BorderRadius.circular(8)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          isExpanded: true,
                          items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat, style: const TextStyle(fontSize: 13)))).toList(),
                          onChanged: (val) => setState(() => _selectedCategory = val!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildInputLabel("Message *"),
                    TextField(
                      controller: _messageController,
                      maxLines: 4,
                      decoration: _inputDecoration("Saisissez votre message ici..."),
                    ),
                    const SizedBox(height: 16),

                    _buildInputLabel("Date d'expiration (YYYY-MM-DD)"),
                    TextField(controller: _expDateController, decoration: _inputDecoration("Optionnel", icon: Icons.calendar_today)),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Checkbox(
                          value: _sendNotification,
                          activeColor: mainBlue,
                          onChanged: (val) => setState(() => _sendNotification = val ?? true),
                        ),
                        const Text("Envoyer une notification Push", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: mainBlue, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  onPressed: _showConfirmation,
                  child: const Text("PUBLIER", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
    );
  }

  InputDecoration _inputDecoration(String hint, {IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
      suffixIcon: icon != null ? Icon(icon, color: Colors.black54, size: 18) : null,
      filled: true, fillColor: bgLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
    );
  }
}