import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syndic_app/widgets/custom_header.dart'; 
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
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: 14.sp)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color mainBlue = const Color(0xFF1A5EAC);

    return Container(
      width: double.infinity,
      color: Colors.transparent, 
      padding: EdgeInsets.only(bottom: 8.h), // 🟢 Padding m-qadd bach may-ji-ch zayed mn l-fo9
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // 🟢 L-Flèche w l-Icone w T-text m-centriyin f nfs s-ster
        children: [
          // 1. Bouton Retour (Flèche clean)
          if (showBackButton && onBackTap != null)
            GestureDetector(
              onTap: onBackTap,
              child: Padding(
                padding: EdgeInsets.only(right: 12.0.w),
                child: Icon(Icons.arrow_back_ios, color: Colors.black87, size: 22.sp),
              ),
            ),
          
          // 2. Icone de l'immeuble
          Padding(
            padding: EdgeInsets.only(right: 12.0.w),
            child: Icon(Icons.apartment, color: Colors.black87, size: 32.sp),
          ),
          
          // 3. Textes (Titre + Subtitle)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center, 
              children: [
                Text(
                  title,
                  style: TextStyle(color: mainBlue, fontSize: 18.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle, // 🟢 Hna 7iydna t-tikrar dyal Sindy w khllina ghir l-Subtitle
                  style: TextStyle(color: Colors.black54, fontSize: 13.sp, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
        // 🟢 HNA BEDDELNA L-LIEN L-SERVEUR LOCAL DYAL ANDROID
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
          padding: EdgeInsets.all(16.0.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomHeader(
                title: "Sindy",
                subtitle: "Résidence Les Jardins\nAppels de Charges",
                residenceName: "",
                photoUrl: "",
                showBackButton: true,
                onBackTap: widget.isMainScreen 
                    ? () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const MainLayout()), (route) => false)
                    : () => Navigator.pop(context),
              ),
              SizedBox(height: 16.h),

              ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: Stack(
                  children: [
                    Image.network('https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80', height: 140.h, width: double.infinity, fit: BoxFit.cover),
                    Container(height: 140.h, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black.withOpacity(0.7), Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.topCenter))),
                    Positioned(
                      bottom: 16.h, left: 16.w,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Appels de Fonds", style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4.h),
                          Text("Gérez les cotisations et budgets de la résidence", style: TextStyle(color: Colors.white70, fontSize: 12.sp)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              if (latestAppel != null) ...[
                Text("Dernier Appel : ${latestAppel!['title']}", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
                SizedBox(height: 12.h),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChargeDetailsPage(appelId: latestAppel!['id'].toString()))),
                  child: Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: Colors.white, 
                      borderRadius: BorderRadius.circular(16.r), 
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("${latestAppel!['amount']} MAD", style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10.0.w, vertical: 4.0.h),
                              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8.r)),
                              child: Text("${latestAppel!['lots_count']} Lots", style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.black54)),
                            ),
                          ],
                        ),
                        SizedBox(height: 20.h),
                        _buildStatusRow(const Color(0xFF4CAF50), "${latestAppel!['a_jour'] ?? 0} À jour"),
                        SizedBox(height: 8.h),
                        _buildStatusRow(const Color(0xFFD32F2F), "${latestAppel!['en_retard'] ?? 0} En retard"),
                      ],
                    ),
                  ),
                ),
                
                if (historique.isNotEmpty) ...[
                  SizedBox(height: 32.h),
                  Text("Historique des appels", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
                  SizedBox(height: 12.h),
                  ...historique.map((appel) => _buildHistoriqueCard(appel)).toList(),
                ],

              ] else ...[
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0.w),
                    child: Text("Aucun appel de fonds trouvé.", style: TextStyle(color: Colors.grey, fontSize: 14.sp)),
                  ),
                ),
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
        CircleAvatar(radius: 5.r, backgroundColor: color),
        SizedBox(width: 10.w),
        Text(label, style: TextStyle(fontSize: 14.sp, color: Colors.black87, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildHistoriqueCard(dynamic appel) {
    return GestureDetector(
      onTap: () {
        String appelId = (appel['id'] ?? appel['af_identifier']).toString();
        Navigator.push(context, MaterialPageRoute(builder: (context) => ChargeDetailsPage(appelId: appelId)));
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(color: mainBlue.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(Icons.receipt_long, color: mainBlue, size: 24.sp),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(appel['title'] ?? 'Appel de fond', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp, color: Colors.black87)),
                  SizedBox(height: 4.h),
                  Text(appel['due_date'] ?? '', style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
                ],
              ),
            ),
            Text("${appel['amount']} MAD", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp, color: Colors.black87)),
            SizedBox(width: 8.w),
            Icon(Icons.chevron_right, color: Colors.grey, size: 20.sp),
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
          "mode_calcul": _selectedMode 
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
              const CustomHeader(title: "Sindy", subtitle: "Nouvel appel de fonds", residenceName: "", photoUrl: "", showBackButton: true),
              SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildModeSelector(), 
                    SizedBox(height: 20),
                    
                    _buildInput("Titre / Description", _titleController),
                    SizedBox(height: 16.h),
                    
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
        // 🟢 HNA BEDDELNA L-LIEN L-SERVEUR LOCAL DYAL ANDROID
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

    int aJour = lignes.where((l) => l['status'] == 'À jour').length;
    int enRetard = lignes.where((l) => l['status'] == 'En retard').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomHeader(
                title: "Sindy", 
                subtitle: "Détail appel de fonds",
                residenceName: "",
                photoUrl: "",
                showBackButton: true,
                onBackTap: () => Navigator.pop(context),
              ),
              SizedBox(height: 8.h),

              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16.r)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: Image.network('https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80', height: 120.h, width: double.infinity, fit: BoxFit.cover),
                    ),
                    SizedBox(height: 16.h),
                    Text(appelDetails!['title'] ?? 'Appel', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8.h),
                    Text("Montant total :", style: TextStyle(fontSize: 12.sp, color: Colors.black54)),
                    Text("${appelDetails!['amount']} MAD", style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              Text("RÉSUMÉ FINANCIER", style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16.r)),
                child: Column(
                  children: [
                    _buildSummaryRow("Total appelé :", "${appelDetails!['amount']} MAD", Colors.black87),
                    Divider(height: 24.h),
                    _buildSummaryRow("Lots à jour :", "$aJour", const Color(0xFF4CAF50), isDot: true),
                    SizedBox(height: 8.h),
                    _buildSummaryRow("Lots en retard :", "$enRetard", const Color(0xFFD32F2F), isDot: true),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              Text("LISTE DES COPROPRIÉTAIRES", style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16.r)),
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
                          color: l['status'] == 'À jour' ? const Color(0xFF4CAF50) : const Color(0xFFD32F2F)
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
        Text(label, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500, color: Colors.black54)),
        Row(
          children: [
            if (isDot) CircleAvatar(radius: 4.r, backgroundColor: color),
            if (isDot) SizedBox(width: 6.w),
            Text(value, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ],
    );
  }

  Widget _buildLotDetailRow(String id, String owner, String amount, String status, {bool isHeader = false, Color color = Colors.black}) {
    TextStyle style = TextStyle(fontSize: 12.sp, fontWeight: isHeader ? FontWeight.bold : FontWeight.w500, color: isHeader ? Colors.black87 : Colors.black54);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.0.h),
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