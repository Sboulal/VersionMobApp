import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syndic_app/widgets/custom_header.dart'; 
import 'package:syndic_app/pages/main_layout.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';


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
              SizedBox(height: 16.h),

              // 🟢 Banner Image
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
                          Text("Appels de Fonds", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text("Gérez les cotisations et budgets de la résidence", style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // 🟢 Le Dernier Appel (Mise en avant)
              if (latestAppel != null) ...[
                Text("Dernier Appel : ${latestAppel!['title']}", style:  TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
                SizedBox(height: 12),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChargeDetailsPage(appelId: latestAppel!['id']))),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white, 
                      borderRadius: BorderRadius.circular(16), 
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("${latestAppel!['amount']} MAD", style:  TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10.0.w, vertical: 4.0.h),
                              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                              child: Text("${latestAppel!['lots_count']} Lots", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54)),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        _buildStatusRow(Colors.green, "${latestAppel!['payes']} Payés"),
                        SizedBox(height: 8),
                        _buildStatusRow(Colors.orange, "${latestAppel!['partiels']} Partiellement Payés"),
                        SizedBox(height: 8),
                        _buildStatusRow(Colors.red, "${latestAppel!['impayes']} Impayés"),
                        SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: mainBlue, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r))),
                            icon: const Icon(Icons.add, color: Colors.white, size: 20),
                            label: const Text("Nouvel appel de fond", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateChargePage())).then((_) => _fetchCharges()),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                
                // 🟢 NOUVEAU : Affichage de l'historique des appels
                if (historique.isNotEmpty) ...[
                  SizedBox(height: 32),
                   Text("Historique des appels", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
                  SizedBox(height: 12),
                  ...historique.map((appel) => _buildHistoriqueCard(appel)).toList(),
                ],

              ] else ...[
                // Cas où il n'y a aucun appel du tout
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text("Aucun appel de fonds trouvé.", style: TextStyle(color: Colors.grey)),
                  ),
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: mainBlue, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r))),
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
        SizedBox(width: 10),
        Text(label, style:  TextStyle(fontSize: 14.sp, color: Colors.black87, fontWeight: FontWeight.w500)),
      ],
    );
  }

  // 🟢 NOUVEAU WIDGET : Design des cartes de l'historique
  Widget _buildHistoriqueCard(dynamic appel) {
    return GestureDetector(
      onTap: () {
        String appelId = (appel['id'] ?? appel['af_identifier']).toString();
        Navigator.push(context, MaterialPageRoute(builder: (context) => ChargeDetailsPage(appelId: appelId)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: mainBlue.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(Icons.receipt_long, color: mainBlue, size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(appel['title'] ?? 'appel de fond', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                  SizedBox(height: 4),
                  Text(appel['due_date'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Text("${appel['amount']} MAD", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
            SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}
// ==========================================
// 2. CRÉER UN APPEL (Écran 09) - ADAPTÉ MAROC
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
  String _selectedMode = 'forfait'; // 'forfait' ou 'tantiemes' par défaut

  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime.now();
    try {
      if (_dateController.text.isNotEmpty) {
        initialDate = DateTime.parse(_dateController.text);
      }
    } catch (_) {}

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: mainBlue, 
              onPrimary: Colors.white, 
              onSurface: Colors.black87, 
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        String formattedDate = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
        _dateController.text = formattedDate;
      });
    }
  }

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
          "due_date": _dateController.text,
          "mode_calcul": _selectedMode // 🟢 ENVOI DU NOUVEAU PARAMÈTRE
        }),
      );

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
      if (!mounted) return;
      if (response.statusCode == 200 && data['success']) {
        setState(() {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Appel créé et réparti avec succès.", style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
          Navigator.pop(context); 
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? "Erreur"), backgroundColor: Colors.redAccent));
      }
    } catch (e) {
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
        title:  Center(child: Text("CONFIRMATION", style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             Text("Confirmez-vous la création de l'appel de fonds ?", textAlign: TextAlign.center, style: TextStyle(fontSize: 14.sp)),
            SizedBox(height: 16.h),
            Row(
              children: [
                const Icon(Icons.info, color: Colors.green, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedMode == 'forfait' 
                      ? "Chaque lot se verra facturer exactement ce montant fixe." 
                      : "Le montant sera réparti automatiquement selon les tantièmes.", 
                    style: const TextStyle(fontSize: 12, color: Colors.black54)
                  )
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
                _submitCharge();
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
              const CustomHeader(title: "Sindy", subtitle: "Nouvel appel de fonds"),
              SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildModeSelector(), // 🟢 NOUVEAU SÉLECTEUR DE MODE
                    SizedBox(height: 20),
                    
                    _buildInput("Titre / Description", _titleController),
                    SizedBox(height: 16.h),
                    
                    // 🟢 TEXTE DYNAMIQUE SELON LE MODE
                    _buildInput(
                      _selectedMode == 'forfait' ? "Montant par appartement (MAD)" : "Montant global à répartir (MAD)", 
                      _amountController, 
                      isNumber: true
                    ),
                    SizedBox(height: 16.h),
                    
                    _buildInput(
                      "Date d'échéance", 
                      _dateController, 
                      readOnly: true, 
                      onTap: () => _selectDate(context),
                      suffixIcon: Icon(Icons.calendar_month, color: mainBlue, size: 20),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: mainBlue, padding: EdgeInsets.symmetric(vertical: 16.h), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r))),
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

  // 🟢 WIDGET SÉLECTEUR FORFAIT / TANTIÈMES
  Widget _buildModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Méthode de calcul", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedMode = 'forfait'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _selectedMode == 'forfait' ? mainBlue : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _selectedMode == 'forfait' ? mainBlue : Colors.grey.shade300)
                  ),
                  child: Center(child: Text("Forfait Fixe", style: TextStyle(color: _selectedMode == 'forfait' ? Colors.white : Colors.black87, fontWeight: FontWeight.bold))),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedMode = 'tantiemes'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _selectedMode == 'tantiemes' ? mainBlue : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _selectedMode == 'tantiemes' ? mainBlue : Colors.grey.shade300)
                  ),
                  child: Center(child: Text("Tantièmes", style: TextStyle(color: _selectedMode == 'tantiemes' ? Colors.white : Colors.black87, fontWeight: FontWeight.bold))),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          _selectedMode == 'forfait' 
            ? "💡 Idéal Maroc: Chaque résident paiera exactement le montant saisi." 
            : "⚖️ Loi 18-00: Le montant sera divisé selon la quote-part de chaque lot.",
          style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
        )
      ],
    );
  }

  Widget _buildInput(String label, TextEditingController controller, {bool isNumber = false, bool readOnly = false, VoidCallback? onTap, Widget? suffixIcon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
        SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            filled: true, 
            fillColor: Colors.grey.shade50,
            suffixIcon: suffixIcon,
            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: mainBlue, width: 1.5)),
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
              const CustomHeader(title: "Sindy", subtitle: "Détail appel de fonds"),
              SizedBox(height: 8),

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
                    SizedBox(height: 16.h),
                    Text(appelDetails!['title'] ?? 'Appel', style:  TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    const Text("Montant total :", style: TextStyle(fontSize: 12, color: Colors.black54)),
                    Text("${appelDetails!['amount']} MAD", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              SizedBox(height: 24),

               Text("RÉSUMÉ FINANCIER", style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
               SizedBox(height: 12.h),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    _buildSummaryRow("Total appelé :", "${appelDetails!['amount']} MAD", Colors.black87),
                    const Divider(height: 24),
                    _buildSummaryRow("Lots payés :", "$payes", Colors.green, isDot: true),
                    SizedBox(height: 8),
                    _buildSummaryRow("Lots impayés :", "$impayes", Colors.red, isDot: true),
                  ],
                ),
              ),
              SizedBox(height: 24),

               Text("LISTE DES COPROPRIÉTAIRES", style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
               SizedBox(height: 12.h),
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
            if (isDot) SizedBox(width: 6),
            Text(value, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: color)),
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