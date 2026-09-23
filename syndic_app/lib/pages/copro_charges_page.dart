import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syndic_app/pages/profile_page.dart'; 
import 'package:syndic_app/pages/forgot_password_page.dart'; 
import 'package:syndic_app/pages/login_page.dart'; 
import 'package:syndic_app/pages/NotificationsScreen.dart';

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      elevation: 4,
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
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  residenceName.isNotEmpty ? "Sindy | $residenceName" : "Sindy",
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
              const SizedBox(width: 12),
              _buildPopupMenu(context),
            ],
          ),
          const SizedBox(height: 20),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ==========================================
// 1. LISTE DES APPELS DE FONDS SYNDIC
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
  bool _isCreating = false; // Bach n-geriw chrgement dyal l'ajout
  Map<String, dynamic>? _latestAppel;
  List<dynamic> _historiqueAppels = [];
  String _residenceName = "Résidence Les Jardins";

  // Controllers l'formulaire dyal l'ajout
  final TextEditingController _titreController = TextEditingController();
  final TextEditingController _montantController = TextEditingController();
  DateTime? _dateEcheance;

  @override
  void initState() {
    super.initState();
    _fetchChargesData();
  }

  Future<void> _fetchChargesData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    setState(() {
      _residenceName = prefs.getString('residence_name') ?? "Résidence Les Jardins";
      _isLoading = true; // Bach mni ndirou refresh tb9a tban loading
    });

    try {
      final response = await http.get(
        Uri.parse("https://api.syndify.nomade-cloud.com/api/mobile/syndic/charges"), 
        headers: {"Authorization": "Bearer $token"},
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        setState(() {
          _latestAppel = data['latest_appel'];
          _historiqueAppels = data['appels'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // ==========================================
  // FONCTION BACH TSIFET NOVEAU APPEL L'API
  // ==========================================
  Future<void> _ajouterAppelFonds() async {
    if (_titreController.text.isEmpty || _montantController.text.isEmpty || _dateEcheance == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez remplir tous les champs"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isCreating = true);
    
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.post(
        Uri.parse("https://api.syndify.nomade-cloud.com/api/mobile/syndic/charges"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "title": _titreController.text,
          "amount": double.parse(_montantController.text),
          "due_date": "${_dateEcheance!.year}-${_dateEcheance!.month.toString().padLeft(2, '0')}-${_dateEcheance!.day.toString().padLeft(2, '0')}",
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        if (mounted) {
          Navigator.pop(context); // Katssed l'bottom sheet
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message']), backgroundColor: Colors.green),
          );
          // Kat-vidi l'inputs w katdir refresh l'données
          _titreController.clear();
          _montantController.clear();
          _dateEcheance = null;
          _fetchChargesData();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erreur: ${data['message']}"), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur de connexion"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  // ==========================================
  // L'MODAL BOTTOM SHEET L'AJOUT APPEL FONDS
  // ==========================================
  void _showAddAppelFondsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Bach ytla3 fou9 l'clavier
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder( // StatefulBuilder bach n9der nbedel date dl'echeance
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Nouvel Appel de Fonds",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Saisissez les informations pour générer un nouvel appel.",
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  
                  // Input Titre
                  TextField(
                    controller: _titreController,
                    decoration: InputDecoration(
                      labelText: "Titre de l'appel",
                      hintText: "Ex: Appel de charges T4 2026",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.title),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Input Montant Total
                  TextField(
                    controller: _montantController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: "Montant Global (MAD)",
                      hintText: "Ex: 12000.00",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.attach_money),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Input Date
                  InkWell(
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: mainBlue, 
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setModalState(() {
                          _dateEcheance = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month, color: Colors.grey),
                          const SizedBox(width: 12),
                          Text(
                            _dateEcheance == null 
                                ? "Date d'échéance" 
                                : "${_dateEcheance!.day.toString().padLeft(2, '0')}/${_dateEcheance!.month.toString().padLeft(2, '0')}/${_dateEcheance!.year}",
                            style: TextStyle(
                              color: _dateEcheance == null ? Colors.black54 : Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Bouton Valider
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isCreating ? null : _ajouterAppelFonds,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainBlue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isCreating
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              "Générer l'appel de fonds",
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      // 🟢 LE NOUVEAU BOUTON FLOATING ACTION BUTTON EN BAS A DROITE
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAppelFondsModal,
        backgroundColor: mainBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Nouvel appel", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            CustomHeader(
              title: "Appels de Fonds",
              subtitle: "Gérez les cotisations et budgets",
              residenceName: _residenceName,
              photoUrl: "", // Remplace par ta variable si tu l'as
              showBackButton: widget.showBackButton,
              onBackTap: () => Navigator.pop(context),
            ),
            Expanded(
              child: _isLoading 
                  ? Center(child: CircularProgressIndicator(color: mainBlue))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16).copyWith(bottom: 80), // bottom: 80 bach matghtach bl'FAB
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_latestAppel != null) ...[
                            Text(
                              "Dernier Appel : ${_latestAppel!['title'] ?? 'Appel de fonds'}",
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
                            ),
                            const SizedBox(height: 12),
                            _buildLatestChargeCard(),
                            const SizedBox(height: 24),
                          ],

                          const Text(
                            "Historique des appels de fonds",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
                          ),
                          const SizedBox(height: 12),
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

  Widget _buildLatestChargeCard() {
    final amount = _latestAppel!['amount'] ?? 0;
    final lotsCount = _latestAppel!['lots_count'] ?? 0;
    final payes = _latestAppel!['payes'] ?? 0;
    final partiels = _latestAppel!['partiels'] ?? 0;
    final impayes = _latestAppel!['impayes'] ?? 0;

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${double.parse(amount.toString()).toStringAsFixed(2)} MAD",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                child: Text("$lotsCount Lots", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildStatRow(Colors.green, "$payes Payés"),
          const SizedBox(height: 8),
          _buildStatRow(Colors.orange, "$partiels Partiellement Payés"),
          const SizedBox(height: 8),
          _buildStatRow(Colors.red, "$impayes Impayés"),
          // 🛑 7yedt l'Bouton "Nouvel appel de fonds" mn Hna, w rdito Flotant (lfou9)
        ],
      ),
    );
  }

  Widget _buildStatRow(Color color, String text) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
      ],
    );
  }

  Widget _buildHistoriqueList() {
    if (_historiqueAppels.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text("Aucun appel enregistré.")));

    return Column(
      children: _historiqueAppels.map((appel) {
        String dateFormatted = appel['created_at'] != null ? appel['created_at'].toString().split(' ')[0] : "N/A";
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: mainBlue.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.receipt_long, color: mainBlue, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(appel['title'] ?? 'Appel', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                    const SizedBox(height: 4),
                    Text(dateFormatted, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  ],
                ),
              ),
              Text("${double.parse((appel['amount'] ?? 0).toString()).toStringAsFixed(2)} MAD", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ],
          ),
        );
      }).toList(),
    );
  }
}