import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syndic_app/widgets/custom_header.dart';
import 'package:syndic_app/pages/main_layout.dart';
import 'package:syndic_app/pages/NotificationsScreen.dart';
import 'package:syndic_app/widgets/custom_header.dart'; // 🟢 ZID HADI
import 'package:flutter_screenutil/flutter_screenutil.dart'; // 🟢 ZIDNA HAD L'IMPORT DAROURI


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
      // 🟢 7yedna l'fond zre9 w tswira, khelina l'fond transparent bach yakhod loun dyal l'ecran
      color: Colors.transparent, 
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16.h,
        bottom: 16.h,
        left: 20.w,
        right: 20.w,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ==========================================
          // 🟢 PARTIE GAUCHE : Bouton retour, Icone, Textes
          // ==========================================
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bouton Retour rond (b7al f tswira dyalek)
                if (showBackButton && onBackTap != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: GestureDetector(
                      onTap: onBackTap,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                          ],
                        ),
                        child: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
                      ),
                    ),
                  ),
                
                // Icone de l'immeuble
                const Padding(
                  padding: EdgeInsets.only(top: 2.0),
                  child: Icon(Icons.apartment, color: Colors.black87, size: 28),
                ),
                SizedBox(width: 12.w),
                
                // Textes
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Sindy",
                        style: TextStyle(color: mainBlue, fontSize: 18.sp, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 2),
                      Text(
                        residenceName.isNotEmpty ? "$residenceName\n$title" : title,
                        style:  TextStyle(color: Colors.black54, fontSize: 13.sp, height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
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
// 1. ÉCRAN : LISTE DES ASSEMBLÉES GÉNÉRALES
// ==========================================
class AssembleesPage extends StatefulWidget {
  final bool isMainScreen;
  const AssembleesPage({super.key, this.isMainScreen = true});

  @override
  State<AssembleesPage> createState() => _AssembleesPageState();
}

class _AssembleesPageState extends State<AssembleesPage> {
  final Color mainBlue = const Color(0xFF1A5EAC);
  final Color bgLight = const Color(0xFFF4F6F9);

  bool _isLoading = true;
  List<dynamic> _assembleesList = [];

  @override
  void initState() {
    super.initState();
    _fetchAssemblees();
  }

  Future<void> _fetchAssemblees() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      // 🟢 SOLUTION 1 : Cache Buster (Nzidou l'wa9t f l'URL bach tjib dima l'jdid)
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final String url = "https://api.syndify.nomade-cloud.com/api/mobile/syndic/assemblees?t=$timestamp";

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json", 
          "Authorization": "Bearer $token",
          "Cache-Control": "no-cache", // Mne3 l'cache
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _assembleesList = data['data'] ?? [];
            _isLoading = false;
          });
          return;
        }
      }
      
      setState(() => _isLoading = false);
      
    } catch (e) {
      debugPrint("Erreur API Assemblees: $e");
      setState(() => _isLoading = false);
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
            CustomHeader(
              title: "Assemblées (AG)",
              subtitle: "Convocations et Procès-Verbaux",
              showBackButton: widget.isMainScreen,
              residenceName: "Résidence Les Jardins",
              photoUrl: "",
              onBackTap: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const MainLayout()), (route) => false);
                }
              },
            ),

            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: mainBlue))
                  : _assembleesList.isEmpty
                      ? const Center(child: Text("Aucune Assemblée Générale trouvée.", style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _assembleesList.length,
                          itemBuilder: (context, index) {
                            final ag = _assembleesList[index];
                            final isPasses = ag['statut'] == 'terminee';
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 16.0.w, vertical: 12.0.h),
                                    decoration: BoxDecoration(
                                      color: isPasses ? Colors.grey.shade100 : mainBlue.withOpacity(0.05),
                                      borderRadius:  BorderRadius.vertical(top: Radius.circular(16.r)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(isPasses ? Icons.history : Icons.event_available, color: isPasses ? Colors.grey : mainBlue, size: 20),
                                            SizedBox(width: 8),
                                            Text(
                                              isPasses ? "Terminée" : "À venir",
                                              style: TextStyle(fontWeight: FontWeight.bold, color: isPasses ? Colors.grey.shade700 : mainBlue),
                                            ),
                                          ],
                                        ),
                                        Text(ag['date'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                                      ],
                                    ),
                                  ),
                                  
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(ag['titre'], style:  TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
                                        SizedBox(height: 12),
                                        
                                        Row(
                                          children: [
                                            const Icon(Icons.access_time, size: 16, color: Colors.black54),
                                            SizedBox(width: 6),
                                            Text(ag['heure'], style: const TextStyle(color: Colors.black54, fontSize: 13)),
                                            SizedBox(width: 16),
                                            const Icon(Icons.location_on_outlined, size: 16, color: Colors.black54),
                                            SizedBox(width: 6),
                                            Expanded(child: Text(ag['lieu'], style: const TextStyle(color: Colors.black54, fontSize: 13), overflow: TextOverflow.ellipsis)),
                                          ],
                                        ),
                                        
                                        const Divider(height: 24),
                                        const Text("Ordre du jour :", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                                        SizedBox(height: 4),
                                        Text(ag['ordre_jour'], style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4)),

                                        SizedBox(height: 16.h),

                                        if (isPasses && ag['pv_url'] != null)
                                          SizedBox(
                                            width: double.infinity,
                                            child: OutlinedButton.icon(
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: mainBlue, side: BorderSide(color: mainBlue),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                              icon: const Icon(Icons.picture_as_pdf, size: 18),
                                              label: const Text("Télécharger le PV"),
                                              onPressed: () {
                                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ouverture du PV...")));
                                              },
                                            ),
                                          )
                                        else if (!isPasses)
                                          Row(
                                            children: [
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.green, foregroundColor: Colors.white,
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  ),
                                                  icon: const Icon(Icons.notifications_active, size: 18),
                                                  label: const Text("Rappeler"),
                                                  onPressed: () {
                                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Rappel envoyé aux résidents !"), backgroundColor: Colors.green));
                                                  },
                                                ),
                                              ),
                                            ],
                                          )
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

// ==========================================
// 2. ÉCRAN : CRÉER UNE ASSEMBLÉE (CONVOCATION)
// ==========================================
class CreateAssembleePage extends StatefulWidget {
  const CreateAssembleePage({super.key});

  @override
  State<CreateAssembleePage> createState() => _CreateAssembleePageState();
}

class _CreateAssembleePageState extends State<CreateAssembleePage> {
  final Color mainBlue = const Color(0xFF1A5EAC);
  
  final TextEditingController _titreController = TextEditingController(text: "Assemblée Générale Annuelle");
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _heureController = TextEditingController(text: "19:00");
  final TextEditingController _lieuController = TextEditingController();
  final TextEditingController _ordreJourController = TextEditingController();
  
  bool _sendNotification = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    DateTime futureDate = DateTime.now().add(const Duration(days: 15));
    _dateController.text = "${futureDate.year}-${futureDate.month.toString().padLeft(2, '0')}-${futureDate.day.toString().padLeft(2, '0')}";
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 15)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: mainBlue, onPrimary: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 19, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: mainBlue, onPrimary: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _heureController.text = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _submitAG() async {
    if (_titreController.text.isEmpty || _lieuController.text.isEmpty || _ordreJourController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez remplir tous les champs.")));
      return;
    }

    setState(() => _isSubmitting = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.post(
        Uri.parse("https://api.syndify.nomade-cloud.com/api/mobile/syndic/assemblees"),
        headers: {
          "Content-Type": "application/json", 
          "Accept": "application/json", // 🟢 HADI LI KANET NAKSSA BACH TFORCI LARAVEL YJAWB B JSON
          "Authorization": "Bearer $token"
        },
        body: jsonEncode({
          "titre": _titreController.text,
          "date": _dateController.text,
          "heure": _heureController.text,
          "lieu": _lieuController.text,
          "ordre_jour": _ordreJourController.text,
          "notifier_residents": _sendNotification
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        Navigator.pop(context, true); 
      } else {
        // 🟢 HNA GHANDIROU PROTECTION BACH ILA JA HTML MAYTPLANTACH L'APP
        try {
          final data = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Erreur serveur: ${data['message'] ?? 'Inconnue'}"), 
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
          ));
        } catch (formatException) {
          // Ila jawb b HTML, ghan-affichiou l'code d'erreur (Ex: 500)
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Erreur Système (Code ${response.statusCode}). Vérifiez le backend."), 
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
          ));
        }
      }
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur de connexion: $e"), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title:  Text("Planifier une AG", style: TextStyle(color: Colors.black87, fontSize: 16.sp, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black87), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12.r), border: Border.all(color: Colors.blue.shade100)),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: mainBlue),
                  SizedBox(width: 12.w),
                  const Expanded(child: Text("La Loi 18-00 exige l'envoi des convocations 15 jours avant la date de l'AG.", style: TextStyle(fontSize: 12, color: Colors.black87))),
                ],
              ),
            ),
            SizedBox(height: 24),

            _buildInput("Titre de l'assemblée", _titreController),
            SizedBox(height: 16.h),
            
            Row(
              children: [
                Expanded(
                  child: _buildInput("Date", _dateController, readOnly: true, onTap: () => _selectDate(context), suffixIcon: Icons.calendar_month),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildInput("Heure", _heureController, readOnly: true, onTap: () => _selectTime(context), suffixIcon: Icons.access_time),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            _buildInput("Lieu (Ex: Garage, Appt Syndic...)", _lieuController),
            SizedBox(height: 16.h),

            _buildInput("Ordre du jour (Points à débattre)", _ordreJourController, maxLines: 4, hint: "- Bilan financier\n- Choix du concierge\n- ..."),
            SizedBox(height: 24),

            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12.r), border: Border.all(color: Colors.grey.shade200)),
              child: SwitchListTile(
                activeColor: mainBlue,
                title:  Text("Envoyer une Convocation (Push)", style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
                subtitle:  Text("Les copropriétaires recevront une alerte sur leur téléphone.", style: TextStyle(fontSize: 12.sp)),
                value: _sendNotification,
                onChanged: (val) => setState(() => _sendNotification = val),
              ),
            ),
            
             SizedBox(height: 40.h),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: mainBlue, padding: EdgeInsets.symmetric(vertical: 16.h), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r))),
                onPressed: _isSubmitting ? null : _submitAG,
                child: _isSubmitting 
                  ?  SizedBox(height: 20.h, width: 20.w, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  :  Text("PLANIFIER ET CONVOQUER", style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller, {bool readOnly = false, VoidCallback? onTap, IconData? suffixIcon, int maxLines = 1, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style:  TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.black54)),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true, fillColor: Colors.white,
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black26),
            suffixIcon: suffixIcon != null ? Icon(suffixIcon, color: Colors.black45) : null,
            contentPadding: EdgeInsets.symmetric(horizontal: 16.0.w, vertical: 14.0.h),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: mainBlue)),
          ),
        ),
      ],
    );
  }
}