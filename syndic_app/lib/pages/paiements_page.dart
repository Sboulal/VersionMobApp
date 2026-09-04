import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syndic_app/widgets/custom_header.dart'; 
import 'package:syndic_app/pages/main_layout.dart'; 

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
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
              child: CustomHeader(
                title: "Sindy",
                subtitle: "Résidence Les Jardins\nSuivi des Paiements",
                showBackButton: true,
                onBackPressed: widget.isMainScreen 
                    ? () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const MainLayout()), (route) => false)
                    : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    Image.network('https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80', height: 120, width: double.infinity, fit: BoxFit.cover),
                    Container(height: 120, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black.withOpacity(0.7), Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.topCenter))),
                    Positioned(
                      bottom: 16, left: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("Suivi des Paiements", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text("Consultez les règlements des copropriétaires", style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            Expanded(
              child: _isLoading
                ? Center(child: CircularProgressIndicator(color: mainBlue))
                : paiementsList.isEmpty
                  ? const Center(child: Text("Aucun paiement trouvé.", style: TextStyle(color: Colors.grey)))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: paiementsList.length,
                      separatorBuilder: (_, __) => const Divider(height: 24),
                      itemBuilder: (context, index) {
                        final p = paiementsList[index];
                        final modeColor = _hexToColor(p['modeColorHex']);
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p["date"], style: const TextStyle(color: Colors.black54, fontSize: 12)),
                                const SizedBox(height: 4),
                                Text("${p["owner"]} (${p["lot"]})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(p["amount"], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    CircleAvatar(radius: 4, backgroundColor: modeColor),
                                    const SizedBox(width: 4),
                                    Text(p["mode"], style: TextStyle(color: modeColor, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ],
                                )
                              ],
                            ),
                          ],
                        );
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.white,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: mainBlue, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text("Enregistrer un paiement", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const EnregistrerPaiementPage())).then((_) => _fetchPaiements());
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

class EnregistrerPaiementPage extends StatefulWidget {
  const EnregistrerPaiementPage({super.key});

  @override
  State<EnregistrerPaiementPage> createState() => _EnregistrerPaiementPageState();
}

class _EnregistrerPaiementPageState extends State<EnregistrerPaiementPage> {
  final Color mainBlue = const Color(0xFF1A5EAC);
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _refController = TextEditingController();
  String _selectedMode = "Virement";
  final List<String> _modes = ["Virement", "Espèces", "Chèque", "Autre"];
  
  String? _selectedUserId;
  List<dynamic> _owners = [];
  bool _isLoadingOwners = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchOwners();
  }

  Future<void> _fetchOwners() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    try {
      final response = await http.get(
        Uri.parse("https://api.syndify.nomade-cloud.com/api/mobile/syndic/paiements/coproprietaires"),
        headers: {"Authorization": "Bearer $token"},
      );
      final data = jsonDecode(response.body);
      if (data['success']) {
        setState(() {
          _owners = data['data'];
          if (_owners.isNotEmpty) _selectedUserId = _owners[0]['user_id'].toString();
          _isLoadingOwners = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingOwners = false);
    }
  }

  Future<void> _submitPaiement() async {
    if (_amountController.text.isEmpty || _selectedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Le montant et le copropriétaire sont obligatoires.")));
      return;
    }

    setState(() => _isSubmitting = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.post(
        Uri.parse("https://api.syndify.nomade-cloud.com/api/mobile/syndic/paiements"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
        body: jsonEncode({
          "user_id": _selectedUserId,
          "amount": num.tryParse(_amountController.text) ?? 0,
          "date": DateTime.now().toIso8601String().split('T')[0],
          "payment_method": _selectedMode,
          "reference": _refController.text.isNotEmpty ? _refController.text : null,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message']), backgroundColor: Colors.green));
          Navigator.pop(context);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? "Erreur"), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur réseau"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CustomHeader(title: "Sindy", subtitle: "Enregistrer un paiement"),
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Copropriétaire / Lot", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                    const SizedBox(height: 6),
                    _isLoadingOwners 
                      ? const LinearProgressIndicator() 
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(8)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedUserId,
                              isExpanded: true,
                              items: _owners.map<DropdownMenuItem<String>>((o) {
                                return DropdownMenuItem<String>(
                                  value: o['user_id'].toString(),
                                  child: Text("${o['owner_name']} (Lot: ${o['lot_id']})"),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedUserId = val),
                            ),
                          ),
                        ),
                    const SizedBox(height: 16),

                    const Text("Montant (MAD)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                    const SizedBox(height: 6),
                    TextField(controller: _amountController, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: "Ex: 2500", border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12))),
                    const SizedBox(height: 16),

                    const Text("Mode de paiement", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(8)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedMode,
                          isExpanded: true,
                          items: _modes.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                          onChanged: (val) => setState(() => _selectedMode = val!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text("Référence (Optionnel)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                    const SizedBox(height: 6),
                    TextField(controller: _refController, decoration: InputDecoration(hintText: "Ex: Chèque N°12345", border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12))),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: mainBlue, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  onPressed: _isSubmitting ? null : _submitPaiement,
                  child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text("ENREGISTRER LE PAIEMENT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}