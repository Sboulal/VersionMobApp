import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syndic_app/widgets/custom_header.dart';
import 'package:syndic_app/pages/main_layout.dart';

// ==========================================
// 1. LISTE DES DÉPENSES (Écran 13)
// ==========================================
class DepensesPage extends StatefulWidget {
  final bool isMainScreen;
  const DepensesPage({super.key, this.isMainScreen = true});

  @override
  State<DepensesPage> createState() => _DepensesPageState();
}

class _DepensesPageState extends State<DepensesPage> {
  final Color mainBlue = const Color(0xFF1A5EAC);
  final Color bgLight = const Color(0xFFF4F6F9);

  bool _isLoading = true;
  String _totalMois = "0,00";
  List<dynamic> depensesList = [];

  @override
  void initState() {
    super.initState();
    _fetchDepenses();
  }

  Future<void> _fetchDepenses() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.get(
        Uri.parse("https://api.syndify.nomade-cloud.com/api/mobile/syndic/depenses"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _totalMois = data['total_mois'].toString();
          depensesList = data['data'];
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
      case 'cleaning_services': return Icons.cleaning_services;
      case 'description': return Icons.description;
      case 'build': default: return Icons.build;
    }
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
                subtitle: "Résidence Les Jardins\nGestion des Dépenses",
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
                    Image.network('https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80', height: 120, width: double.infinity, fit: BoxFit.cover),
                    Container(height: 120, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black.withOpacity(0.7), Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.topCenter))),
                    Positioned(
                      bottom: 16, left: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("Gestion des Dépenses", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text("Suivez les charges et factures de la résidence", style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.black12), top: BorderSide(color: Colors.black12))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Dépenses", style: TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text("Total du mois :", style: TextStyle(fontSize: 14, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text("$_totalMois MAD", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: mainBlue)),
                ],
              ),
            ),
            
            Expanded(
              child: _isLoading 
                ? Center(child: CircularProgressIndicator(color: mainBlue))
                : depensesList.isEmpty
                  ? const Center(child: Text("Aucune dépense enregistrée.", style: TextStyle(color: Colors.grey)))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                      itemCount: depensesList.length,
                      separatorBuilder: (_, __) => const Divider(height: 24),
                      itemBuilder: (context, index) {
                        final dep = depensesList[index];
                        final Color dColor = _hexToColor(dep['colorHex']);
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: dColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                              child: Icon(_getIcon(dep['iconString']), color: dColor, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(dep["date"], style: const TextStyle(color: Colors.black54, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text(dep["title"], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                                  Text(dep["category"], style: const TextStyle(color: Colors.black54, fontSize: 12)),
                                ],
                              ),
                            ),
                            Text(dep["amount"], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
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
                  label: const Text("Ajouter une dépense", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AjouterDepensePage())).then((_) => _fetchDepenses());
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
// 2. AJOUTER UNE DÉPENSE (Écran 14)
// ==========================================
class AjouterDepensePage extends StatefulWidget {
  const AjouterDepensePage({super.key});

  @override
  State<AjouterDepensePage> createState() => _AjouterDepensePageState();
}

class _AjouterDepensePageState extends State<AjouterDepensePage> {
  final Color mainBlue = const Color(0xFF1A5EAC);
  final Color bgLight = const Color(0xFFF4F6F9);
  
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _fournisseurController = TextEditingController();
  final TextEditingController _refController = TextEditingController();
  
  String _selectedCategory = "Maintenance";
  final List<String> _categories = ["Maintenance", "Entretien", "Frais administratifs", "Autre"];
  bool _isSubmitting = false;

  Future<void> _submitDepense() async {
    if (_titleController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("La description et le montant sont obligatoires.")));
      return;
    }

    setState(() => _isSubmitting = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.post(
        Uri.parse("https://api.syndify.nomade-cloud.com/api/mobile/syndic/depenses"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
        body: jsonEncode({
          "title": _titleController.text,
          "amount": num.tryParse(_amountController.text) ?? 0,
          "date": DateTime.now().toIso8601String().split('T')[0],
          "category": _selectedCategory,
          "fournisseur": _fournisseurController.text,
          "reference": _refController.text,
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red));
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
            Text("Confirmez-vous l'ajout de la dépense de ${_amountController.text} MAD (${_titleController.text}) ?", textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.info, color: Colors.green, size: 16),
                SizedBox(width: 8),
                Expanded(child: Text("Le solde des copropriétaires sera automatiquement recalculé selon les tantièmes.", style: TextStyle(fontSize: 12, color: Colors.black54))),
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
                _submitDepense(); 
              },
              child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text("CONFIRMER ET ENREGISTRER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              const CustomHeader(title: "Sindy", subtitle: "Ajouter une dépense"),
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("NOUVELLE DÉPENSE", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 16),
                    
                    _buildInputLabel("Description / Titre"),
                    _buildTextField("Ex: Réparation Ascenseur", _titleController, null),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _buildInputLabel("Catégorie"), 
                          _buildDropdown(_selectedCategory, (v) => setState(() => _selectedCategory = v!))
                        ])),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _buildInputLabel("Montant (MAD)"), 
                          _buildTextField("Ex: 3500", _amountController, null, isNum: true)
                        ])),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _buildInputLabel("Fournisseur (Opt)"), 
                          _buildTextField("Ex: Otis", _fournisseurController, null)
                        ])),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _buildInputLabel("Référence (Opt)"), 
                          _buildTextField("REF-9082", _refController, null)
                        ])),
                      ],
                    ),
                    const SizedBox(height: 24),

                    const Text("Pièce justificative (Facture)", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 12),
                    _buildUploadButton("+ Ajouter une facture", Icons.add, Colors.grey.shade200, Colors.black87),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _buildUploadButton("Prendre photo", Icons.camera_alt, Colors.grey.shade100, Colors.black54)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildUploadButton("Importer PDF", Icons.picture_as_pdf, Colors.grey.shade100, Colors.black54)),
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
                  child: const Text("ENREGISTRER DÉPENSE", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
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

  Widget _buildTextField(String hint, TextEditingController controller, IconData? icon, {bool isNum = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black54, fontSize: 13),
        suffixIcon: icon != null ? Icon(icon, color: Colors.black54, size: 20) : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      ),
    );
  }

  Widget _buildDropdown(String value, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13, overflow: TextOverflow.ellipsis)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildUploadButton(String label, IconData icon, Color bgColor, Color textColor) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        onPressed: () {},
      ),
    );
  }
}