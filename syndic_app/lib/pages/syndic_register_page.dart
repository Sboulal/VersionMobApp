import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 🟢 Mohima bash n-copiw l-code (Clipboard)
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syndic_app/pages/main_layout.dart'; // 🟢 Dashboard dyal Syndic
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SyndicRegisterPage extends StatefulWidget {
  const SyndicRegisterPage({super.key});

  @override
  State<SyndicRegisterPage> createState() => _SyndicRegisterPageState();
}

class _SyndicRegisterPageState extends State<SyndicRegisterPage> {
  final Color mainColor = const Color(0xFF1A5EAC);
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _residenceNameController = TextEditingController(); // 🟢 Input jdid l-Syndic
  
  bool _isLoading = false;
  bool _isSuccess = false;
  String _generatedCode = ""; // 🟢 Bash n-khbiw l-code li ghadi y-rje3 mn Laravel

  Future<void> _registerSyndic() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty || _passwordController.text.isEmpty || _residenceNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez remplir tous les champs obligatoires."), backgroundColor: Colors.redAccent));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("https://api.syndify.nomade-cloud.com/api/mobile/syndic/register"), // 🟢 Route jdida dyal Syndic
        headers: {"Content-Type": "application/json", "Accept": "application/json"},
        body: jsonEncode({
          'name': _nameController.text.trim(),
          'tel': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'nom_residence': _residenceNameController.text.trim(), // 🟢 Smit l-i9ama
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // 🟢 N-sauvegardiw l-Token 7it l-Syndic kay-dkhol direct m-validé (status = 1)
        final prefs = await SharedPreferences.getInstance();
        if (data['data'] != null && data['data']['token'] != null) {
          await prefs.setString('auth_token', data['data']['token']);
          await prefs.setString('user_role', 'syndic');
          await prefs.setString('residence_name', _residenceNameController.text.trim());
        }

        setState(() {
          _generatedCode = data['code_residence'] ?? "ERREUR-CODE"; // 🟢 Kanjbdou l-code mn l-API
          _isSuccess = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? "Erreur lors de l'inscription"), backgroundColor: Colors.redAccent));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur de connexion au serveur."), backgroundColor: Colors.redAccent));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSuccess) {
      return _buildSuccessScreen(); // 🟢 L'Ecran li fih l-Code bach y-partagih
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: mainColor),
        title:  Text("Créer une Résidence", style: TextStyle(color: Colors.black87, fontSize: 16.sp, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.0.w, vertical: 20.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Devenir Syndic", style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: mainColor)),
            SizedBox(height: 8),
             Text("Créez votre résidence en quelques clics pour commencer à la gérer.", style: TextStyle(fontSize: 14.sp, color: Colors.black54)),
            SizedBox(height: 32),

            // 🟢 L'Input d l-i9ama darouri l-Syndic
            _buildInput("Nom de la Résidence *", _residenceNameController, Icons.domain),
            SizedBox(height: 16.h),

            _buildInput("Votre Nom Complet *", _nameController, Icons.person_outline),
            SizedBox(height: 16.h),
            _buildInput("Numéro de téléphone *", _phoneController, Icons.phone_outlined, isPhone: true),
            SizedBox(height: 16.h),
            _buildInput("Email (Optionnel)", _emailController, Icons.email_outlined),
            SizedBox(height: 16.h),
            _buildInput("Mot de passe *", _passwordController, Icons.lock_outline, isPassword: true),
            
            SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainColor,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                onPressed: _isLoading ? null : _registerSyndic,
                child: _isLoading 
                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    :  Text("Créer ma résidence", style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // ÉCRAN DE SUCCÈS M3A L-CODE RÉSIDENCE
  // ==========================================
  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                child: Icon(Icons.check_circle, size: 80, color: Colors.green.shade500),
              ),
            ),
            SizedBox(height: 32),
            const Text("Résidence Créée !", textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
            SizedBox(height: 16.h),
            const Text(
              "Félicitations, votre espace syndic est prêt. Partagez le code ci-dessous avec les résidents pour qu'ils puissent rejoindre l'application.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.black54, height: 1.5),
            ),
            SizedBox(height: 32),

            // 🟢 La zone li fiha L-Code m3a bouton dyal Copy
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: mainColor.withOpacity(0.3), width: 2),
              ),
              child: Column(
                children: [
                  const Text("VOTRE CODE RÉSIDENCE :", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _generatedCode,
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: mainColor, letterSpacing: 2),
                      ),
                      SizedBox(width: 16),
                      IconButton(
                        onPressed: () {
                          // 🟢 Hadi katsauvegardi l-code f l-press-papier (Copier)
                          Clipboard.setData(ClipboardData(text: _generatedCode));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Code copié dans le presse-papiers !"), backgroundColor: Colors.green));
                        },
                        icon: const Icon(Icons.copy),
                        color: mainColor,
                      )
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: mainColor, padding: EdgeInsets.symmetric(vertical: 16.h), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r))),
              onPressed: () {
                // 🟢 L-Syndic kaydkhol direct l-Dashboard dyalo 7it deja 3tih l-token
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const MainLayout()), (route) => false);
              },
              child:  Text("Accéder à mon tableau de bord", style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller, IconData icon, {bool isPassword = false, bool isPhone = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.black38),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: mainColor, width: 1.5)),
          ),
        ),
      ],
    );
  }
}