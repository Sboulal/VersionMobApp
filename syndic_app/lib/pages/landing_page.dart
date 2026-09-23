import 'package:flutter/material.dart';
import 'package:syndic_app/pages/login_page.dart';
import 'package:syndic_app/pages/syndic_register_page.dart'; // L-page dyal Syndic
import 'package:http/http.dart' as http;
import 'dart:convert';

class LandingPage extends StatelessWidget {
  final Color mainColor = const Color(0xFF1A5EAC);

  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mainColor,
      body: Stack(
        children: [
          // L-khalfiya dyal les immeubles
          BuildingsBackground(mainColor: mainColor, height: MediaQuery.of(context).size.height),
          
          SafeArea(
            bottom: false, // 🟢 Darouriya bach l-karta l-bida t-lse9 l-te7t ga3
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 1),
                
                // L-I9ona w l-ktaba f l-wst
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.apartment, size: 80, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 24),
                
                const Text(
                  "Syndify",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                ),
                const SizedBox(height: 12),
                
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40.0),
                  child: Text(
                    "Gérez votre copropriété en toute simplicité et transparence.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
                  ),
                ),
                
                const Spacer(flex: 1),
                
                // 🟢 HNA DRNA L-MENU MOBACHARA (DIRECT) F BLASET DIK L-KARTA SGHIRA
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 40), // Padding l-te7t bach yb3d 3la l-barre d tel
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Bienvenue, choisissez votre accès",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 24),
                      
                      // 1. Bouton Login (Ila kan deja 3ndo compte)
                      _buildDirectActionTile(
                        context,
                        icon: Icons.login,
                        iconColor: mainColor,
                        bgColor: mainColor.withOpacity(0.1),
                        title: "Se connecter",
                        subtitle: "J'ai déjà un compte",
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage())),
                      ),
                      
                      const Divider(height: 24),
                      
                      // 2. Bouton Syndic
                      _buildDirectActionTile(
                        context,
                        icon: Icons.domain,
                        iconColor: Colors.green.shade600,
                        bgColor: Colors.green.shade50,
                        title: "Je suis un Syndic",
                        subtitle: "Créer et gérer une résidence",
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SyndicRegisterPage())),
                      ),
                      
                      const Divider(height: 24),
                      
                      // 3. Bouton Saken (Copropriétaire)
                      _buildDirectActionTile(
                        context,
                        icon: Icons.person,
                        iconColor: mainColor,
                        bgColor: mainColor.withOpacity(0.1),
                        title: "Je suis un Résident",
                        subtitle: "Rejoindre avec un code",
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterInfoPage())),
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

  // 🟢 Widget m9add bach n-dessiniw les boutons dyal l-menu
  Widget _buildDirectActionTile(BuildContext context, {
    required IconData icon, 
    required Color iconColor, 
    required Color bgColor, 
    required String title, 
    required String subtitle, 
    required VoidCallback onTap
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: bgColor,
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
      onTap: onTap,
    );
  }
}

// ==========================================
// FORMULAIRE D'INSCRIPTION (RÉSIDENT)
// ==========================================
class RegisterInfoPage extends StatefulWidget {
  const RegisterInfoPage({super.key});

  @override
  State<RegisterInfoPage> createState() => _RegisterInfoPageState();
}

class _RegisterInfoPageState extends State<RegisterInfoPage> {
  final Color mainColor = const Color(0xFF1A5EAC);
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _codeResidenceController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSuccess = false;

  Future<void> _register() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty || _passwordController.text.isEmpty || _codeResidenceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez remplir tous les champs obligatoires."), backgroundColor: Colors.redAccent));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("https://api.syndify.nomade-cloud.com/api/mobile/copro/register"), 
        headers: {"Content-Type": "application/json", "Accept": "application/json"},
        body: jsonEncode({
          'name': _nameController.text.trim(),
          'tel': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'code_residence': _codeResidenceController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() => _isSuccess = true);
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
      return _buildSuccessScreen();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: mainColor),
        title: const Text("Demande d'inscription", style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Rejoignez votre copropriété",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: mainColor),
            ),
            const SizedBox(height: 8),
            const Text(
              "Remplissez ce formulaire. Votre accès sera activé une fois validé par le syndic.",
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 32),

            _buildInput("Code de la résidence *", _codeResidenceController, Icons.home_outlined),
            const SizedBox(height: 16),
            _buildInput("Nom Complet *", _nameController, Icons.person_outline),
            const SizedBox(height: 16),
            _buildInput("Numéro de téléphone *", _phoneController, Icons.phone_outlined, isPhone: true),
            const SizedBox(height: 16),
            _buildInput("Email (Optionnel)", _emailController, Icons.email_outlined),
            const SizedBox(height: 16),
            _buildInput("Mot de passe *", _passwordController, Icons.lock_outline, isPassword: true),
            
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _register,
                child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Créer mon compte", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle),
              child: Icon(Icons.hourglass_top, size: 80, color: Colors.orange.shade400),
            ),
            const SizedBox(height: 32),
            const Text("Demande Envoyée !", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 16),
            const Text(
              "Votre compte a été créé avec succès, mais il est en attente de validation.\n\nLe syndic doit valider votre identité avant que vous ne puissiez vous connecter.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.black54, height: 1.5),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: mainColor, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LandingPage()), (route) => false), // Retour à la page d'accueil
                child: const Text("Retour à l'accueil", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
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
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.black38),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: mainColor, width: 1.5)),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// L-Khalfiya (Background)
// ==========================================
class BuildingsBackground extends StatelessWidget {
  final Color mainColor;
  final double height;

  const BuildingsBackground({super.key, required this.mainColor, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [mainColor.withOpacity(0.8), mainColor],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 20,
            child: _buildBuilding(60, 150, Colors.white.withOpacity(0.1)),
          ),
          Positioned(
            bottom: 0,
            left: 90,
            child: _buildBuilding(80, 220, Colors.white.withOpacity(0.15)),
          ),
          Positioned(
            bottom: 0,
            right: 30,
            child: _buildBuilding(70, 180, Colors.white.withOpacity(0.08)),
          ),
          Positioned(
            bottom: 0,
            right: -10,
            child: _buildBuilding(50, 100, Colors.white.withOpacity(0.12)),
          ),
        ],
      ),
    );
  }

  Widget _buildBuilding(double width, double height, Color color) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          (height / 25).floor(), 
          (index) => Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(width: 8, height: 12, color: Colors.white.withOpacity(0.2)),
              Container(width: 8, height: 12, color: Colors.white.withOpacity(0.3)),
              if (width > 60) Container(width: 8, height: 12, color: Colors.white.withOpacity(0.2)),
            ],
          )
        ),
      ),
    );
  }
}