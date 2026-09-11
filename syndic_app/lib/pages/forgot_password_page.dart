import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;


class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final Color mainColor = const Color(0xFF1A5EAC);
  final Color bgGrey = const Color(0xFFF4F7FC);
  final Color successGreen = const Color(0xFFE8F5E9);
  final Color successTextGreen = const Color(0xFF2E7D32);

  // حط رابط الـ API ديالك هنا
  final String apiUrl = "https://api.syndify.nomade-cloud.com/api"; 

  int _currentStep = 1; // 1: Email, 2: Code & Nouveau MP, 3: Succès
  bool _isLoading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController(); // 🟢 زدت هادا
  final TextEditingController _newPwdController = TextEditingController();
  final TextEditingController _confirmPwdController = TextEditingController();

  // 🟢 دالة لعرض رسائل الخطأ أو النجاح
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  // 🟢 1. Appel API باش نصيفطو الكود
  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnackBar("Veuillez entrer votre email.", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$apiUrl/forgot-password/send-code'),
        headers: {'Accept': 'application/json'},
        body: {'email': email},
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _showSnackBar(data['message']);
        setState(() {
          _currentStep = 2; // دوز للمرحلة الثانية
        });
      } else {
        _showSnackBar(data['message'] ?? "Erreur lors de l'envoi du code", isError: true);
      }
    } catch (e) {
      _showSnackBar("Erreur de connexion au serveur.", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 🟢 2. Appel API باش نبدلو المودباس
  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();
    final newPwd = _newPwdController.text.trim();
    final confirmPwd = _confirmPwdController.text.trim();

    if (code.length != 5) {
      _showSnackBar("Le code doit contenir 5 chiffres.", isError: true);
      return;
    }
    if (newPwd.length < 6) {
      _showSnackBar("Le mot de passe doit contenir au moins 6 caractères.", isError: true);
      return;
    }
    if (newPwd != confirmPwd) {
      _showSnackBar("Les mots de passe ne correspondent pas.", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$apiUrl/forgot-password/reset'),
        headers: {'Accept': 'application/json'},
        body: {
          'email': email,
          'code': code,
          'nouveau_password': newPwd,
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _currentStep = 3; // دوز لمرحلة النجاح
        });
      } else {
        _showSnackBar(data['message'] ?? "Code invalide ou erreur.", isError: true);
      }
    } catch (e) {
      _showSnackBar("Erreur de connexion au serveur.", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isSuccess = _currentStep == 3;

    return Scaffold(
      backgroundColor: bgGrey,
      body: Stack(
        children: [
          // Background (assurez-vous que BuildingsBackground existe)
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.45,
              color: isSuccess ? successTextGreen : mainColor,
              // child: BuildingsBackground(...), 
            ),
          ),
          
          Positioned(
            top: 50, left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Formulaire
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: MediaQuery.of(context).size.height * (_currentStep == 2 ? 0.75 : 0.65),
              decoration: BoxDecoration(
                color: isSuccess ? successGreen : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.apartment, color: isSuccess ? successTextGreen : mainColor, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      'Sindy',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isSuccess ? successTextGreen : mainColor),
                    ),
                    const SizedBox(height: 30),

                    // --- STEP 1 ---
                    if (_currentStep == 1) ...[
                      const Text(
                        "Pour réinitialiser votre mot de passe, entrez votre email.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(label: "Email", hint: "Saisissez votre email", controller: _emailController),
                      const SizedBox(height: 30),
                      _buildButton(label: "RECEVOIR LE CODE", onPressed: _sendCode, color: mainColor),
                    ],

                    // --- STEP 2 ---
                    if (_currentStep == 2) ...[
                      const Text("Code de vérification", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _codeController, // 🟢 ضفنا الكنترولر هنا باش نقراو الكود
                        textAlign: TextAlign.center,
                        maxLength: 5,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 24),
                        decoration: InputDecoration(
                          counterText: "",
                          hintText: "•••••",
                          filled: true,
                          fillColor: bgGrey,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _sendCode, // 🟢 يعاود يصيفط الكود
                          child: Text("Renvoyer le code", style: TextStyle(fontSize: 12, color: mainColor, fontWeight: FontWeight.bold)),
                        )
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(label: "Nouveau mot de passe", hint: "Votre nouveau mot de passe", controller: _newPwdController, isPwd: true),
                      const SizedBox(height: 16),
                      _buildTextField(label: "Confirmation du mot de passe", hint: "Confirmez le mot de passe", controller: _confirmPwdController, isPwd: true),
                      const SizedBox(height: 30),
                      _buildButton(label: "RÉINITIALISER MON MOT DE PASSE", onPressed: _resetPassword, color: mainColor),
                    ],

                    // --- STEP 3 ---
                    if (_currentStep == 3) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(color: successTextGreen, borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.check_circle, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text("Mot de passe réinitialisé !", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        "Félicitations,\nvotre mot de passe a\nété mis à jour.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 40),
                      _buildButton(
                        label: "SE CONNECTER À VOTRE ESPACE", 
                        onPressed: () => Navigator.pop(context), 
                        color: mainColor
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({required String label, required String hint, required TextEditingController controller, bool isPwd = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPwd,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black26),
            suffixIcon: isPwd ? const Icon(Icons.visibility_off, color: Colors.black26) : null,
            filled: true,
            fillColor: _currentStep == 3 ? Colors.white.withOpacity(0.5) : bgGrey,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildButton({required String label, required VoidCallback onPressed, required Color color}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      onPressed: _isLoading ? null : onPressed,
      child: _isLoading 
        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
        : Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }
}