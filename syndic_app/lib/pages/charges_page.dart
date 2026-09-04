import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syndic_app/widgets/custom_header.dart'; 
import 'package:syndic_app/pages/main_layout.dart'; 

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
          appelsList = data['appels'];
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
    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        child: _isLoading 
        ? Center(child: CircularProgressIndicator(color: mainBlue))
        : SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomHeader(
                title: "Sindy",
                subtitle: "Résidence Les Jardins\nAppels de Charges",
                showBackButton: true,
                onBackPressed: widget.isMainScreen 
                    ? () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const MainLayout()), (route) => false)
                    : null,
              ),
              const SizedBox(height: 8),

              // Banner Image
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    Image.network('https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80', height: 140, width: double.infinity, fit: BoxFit.cover),
                    Container(height: 140, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black.withOpacity(0.7), Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.topCenter))),
                    Positioned(
                      bottom: 16, left: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("Appels de Charges", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text("Gérez les cotisations et budgets de la résidence", style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (latestAppel != null) ...[
                Text("Dernier Appel : ${latestAppel!['title']}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChargeDetailsPage(appelId: latestAppel!['id']))),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("${latestAppel!['amount']} MAD", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                            Text("${latestAppel!['lots_count']} Lots", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildStatusRow(Colors.green, "${latestAppel!['payes']} Payés"),
                        const SizedBox(height: 6),
                        _buildStatusRow(Colors.orange, "${latestAppel!['partiels']} Partiellement Payés"),
                        const SizedBox(height: 6),
                        _buildStatusRow(Colors.red, "${latestAppel!['impayes']} Impayés"),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: mainBlue, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            icon: const Icon(Icons.add, color: Colors.white, size: 20),
                            label: const Text("Nouvel appel de charge", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateChargePage())).then((_) => _fetchCharges()),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ] else ...[
                const Center(child: Text("Aucun appel de fonds trouvé.", style: TextStyle(color: Colors.grey))),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: mainBlue, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    icon: const Icon(Icons.add, color: Colors.white, size: 20),
                    label: const Text("Créer le premier appel", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateChargePage())).then((_) => _fetchCharges()),
                  ),
                )
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
        CircleAvatar(radius: 5, backgroundColor: color),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ==========================================
// 2. CRÉER UN APPEL (Écran 09)
// ==========================================
class CreateChargePage extends StatefulWidget {
  const CreateChargePage({super.key});

  @override
  State<CreateChargePage> createState() => _CreateChargePageState();
}

class _CreateChargePageState extends State<CreateChargePage> {
  final Color mainBlue = const Color(0xFF1A5EAC);
  final TextEditingController _titleController = TextEditingController(text: "Charges T4 2026");
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dateController = TextEditingController(text: "2026-10-31");
  bool _isSubmitting = false;

Future<void> _submitCharge() async {
    if (_amountController.text.isEmpty || _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez remplir le montant et le titre.")));
      return;
    }

    setState(() => _isSubmitting = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.post(
        Uri.parse("https://api.syndify.nomade-cloud.com/api/mobile/syndic/charges"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
        body: jsonEncode({
          "title": _titleController.text,
          "amount": num.tryParse(_amountController.text) ?? 0,
          "due_date": _dateController.text
        }),
      );

      // 🟢 قبل ما نقراو JSON، كنتأكدو أن السيرفر مارجعش HTML Error
      if (response.statusCode == 404) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur 404: Route introuvable. Vérifiez api.php"), backgroundColor: Colors.redAccent));
        setState(() => _isSubmitting = false);
        return;
      }
      if (response.statusCode == 500) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur 500: Erreur interne du serveur (Database)."), backgroundColor: Colors.redAccent));
        setState(() => _isSubmitting = false);
        return;
      }

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Appel créé et réparti avec succès.", style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
          Navigator.pop(context); 
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? "Erreur"), backgroundColor: Colors.redAccent));
      }
    } catch (e) {
      // 🟢 هنا غادي يبين ليك الخطأ بالضبط عوض "Erreur réseau"
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Détail de l'erreur: $e"), backgroundColor: Colors.redAccent));
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
            const Text("Confirmez-vous la création de l'appel de charges ?", textAlign: TextAlign.center, style: TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            Row(
              children: const [
                Icon(Icons.info, color: Colors.green, size: 18),
                SizedBox(width: 8),
                Expanded(child: Text("Les montants seront répartis automatiquement sur les lots selon les tantièmes.", style: TextStyle(fontSize: 12, color: Colors.black54))),
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
                Navigator.pop(context); // Close Modal
                _submitCharge(); // Trigger API
              },
              child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text("CONFIRMER ET CRÉER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      backgroundColor: const Color(0xFFF4F6F9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CustomHeader(title: "Sindy", subtitle: "Nouvel appel de charges"),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInput("Titre / Description", _titleController),
                    const SizedBox(height: 16),
                    _buildInput("Montant total à répartir (MAD)", _amountController, isNumber: true),
                    const SizedBox(height: 16),
                    _buildInput("Date d'échéance (YYYY-MM-DD)", _dateController),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: mainBlue, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: _showConfirmation,
                  child: const Text("CRÉER L'APPEL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            filled: true, fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
          ),
        ),
      ],
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CustomHeader(title: "Sindy", subtitle: "Détail Appel de Charges"),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network('https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80', height: 120, width: double.infinity, fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 16),
                    Text(appelDetails!['title'] ?? 'Appel', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text("Montant total :", style: TextStyle(fontSize: 12, color: Colors.black54)),
                    Text("${appelDetails!['amount']} MAD", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text("RÉSUMÉ FINANCIER", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    _buildSummaryRow("Total appelé :", "${appelDetails!['amount']} MAD", Colors.black87),
                    const Divider(height: 24),
                    _buildSummaryRow("Lots payés :", "$payes", Colors.green, isDot: true),
                    const SizedBox(height: 8),
                    _buildSummaryRow("Lots impayés :", "$impayes", Colors.red, isDot: true),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text("LISTE DES COPROPRIÉTAIRES", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
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
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black54)),
        Row(
          children: [
            if (isDot) CircleAvatar(radius: 4, backgroundColor: color),
            if (isDot) const SizedBox(width: 6),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ],
    );
  }

  Widget _buildLotDetailRow(String id, String owner, String amount, String status, {bool isHeader = false, Color color = Colors.black}) {
    TextStyle style = TextStyle(fontSize: 12, fontWeight: isHeader ? FontWeight.bold : FontWeight.w500, color: isHeader ? Colors.black87 : Colors.black54);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
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