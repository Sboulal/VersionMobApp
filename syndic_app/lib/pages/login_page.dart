import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syndic_app/pages/main_layout.dart';
import 'package:syndic_app/pages/copro_main_layout.dart';
import 'package:syndic_app/pages/forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false; 
  bool _isSuccess = false; // 🟢 Kat-géri l'état dyal naja7 l-connexion
  bool _rememberMe = true; 
  bool _obscurePassword = true; 
  
  String? _emailError;
  String? _passwordError;
  String? _globalError;
  
  final Color mainColor = const Color(0xFF1A5EAC); 
  final Color bgGrey = const Color(0xFFF4F7FC); 

  bool _isValidEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email);
  }

Future<void> _login() async {
    final String apiUrl = "https://api.syndify.nomade-cloud.com/api/mobile/syndic/login"; 

    setState(() {
      _emailError = null;
      _passwordError = null;
      _globalError = null;
      _isSuccess = false;
    });

    String emailText = _emailController.text.trim();
    String passwordText = _passwordController.text.trim();
    bool hasError = false;

    if (emailText.isEmpty) {
      _emailError = "L'email est obligatoire";
      hasError = true;
    }

    if (passwordText.isEmpty) {
      _passwordError = "Le mot de passe est obligatoire";
      hasError = true;
    }

    if (hasError) {
      setState(() {});
      return; 
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({'email': emailText, 'password': passwordText}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        
        await prefs.setString('auth_token', data['data']['token']); 

        // 🟢 حفظ الدور (Role)
        final String role = (data['data']['role'] ?? 'syndic').toString().toLowerCase();
        await prefs.setString('user_role', role);
        
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isSuccess = true;
          });
        }

        await Future.delayed(const Duration(milliseconds: 1500));
        
        if (mounted) {
          // 🟢 التوجيه حسب الدور
          if (role == 'coproprietaire') {
            Navigator.pushReplacement(
              context, 
              MaterialPageRoute(builder: (context) => const CoproMainLayout())
            );
          } else {
            Navigator.pushReplacement(
              context, 
              MaterialPageRoute(builder: (context) => const MainLayout())
            );
          }
        }
      } else {
        setState(() {
          _globalError = data['message'] ?? 'Identifiants invalides.';
          _passwordError = 'Mauvais mot de passe'; 
          _isLoading = false;
        });
      }
    } catch (e) {
      print("❌ ERREUR API FLUTTER: $e");
      setState(() {
        _globalError = 'Problème de connexion au serveur.';
        _isLoading = false;
      });
    }
}
  @override
  Widget build(BuildContext context) {
    // 🟢 Ila nja7 l-login, kan-affichiw l-page dyal Succès li fih l-khder l-fo9
    if (_isSuccess) {
      return _buildSuccessScreen();
    }

    // Sinon, kan-affichiw l-formulaire normal dyal login
    return Scaffold(
      backgroundColor: bgGrey, 
      body: Stack(
        children: [
          Positioned(
            top: 0, left: 0, right: 0,
            child: BuildingsBackground(mainColor: mainColor, height: MediaQuery.of(context).size.height * 0.45),
          ),
          
          Positioned(
            top: 50, left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: MediaQuery.of(context).size.height * 0.65,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Bienvenue de nouveau !',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1A5EAC)),
                    ),
                    const SizedBox(height: 30),

                    if (_globalError != null) ...[
                      Text(_globalError!, style: const TextStyle(color: Colors.redAccent, fontSize: 14), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                    ],

                    _buildTextField(
                      label: 'Email',
                      controller: _emailController,
                      hintText: 'name@example.com',
                      obscureText: false,
                      errorText: _emailError,
                    ),
                    const SizedBox(height: 20),

                    _buildTextField(
                      label: 'Password',
                      controller: _passwordController,
                      hintText: '••••••••',
                      obscureText: _obscurePassword,
                      errorText: _passwordError,
                      isPassword: true,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              height: 20, width: 20,
                              child: Checkbox(
                                value: _rememberMe,
                                activeColor: mainColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                onChanged: (value) => setState(() => _rememberMe = value ?? false),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('Remember me', style: TextStyle(color: Colors.black54, fontSize: 13)),
                          ],
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordPage())),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                          child: Text('Mot de passe oublié?', style: TextStyle(color: mainColor, fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainColor,
                        foregroundColor: Colors.white, 
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🟢 L-Page j-jdida li katban mli kaynj7 l-login (Félicitations)
  Widget _buildSuccessScreen() {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            flex: 6,
            child: Container(
              width: double.infinity,
              color: const Color(0xFFE8F5E9), // L-Khder l-mftou7
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Félicitations,\nvous êtes connecté !",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87, height: 1.3),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Redirection...",
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainColor, // L-Bouton Zre9
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.check_circle, size: 20),
                    label: const Text("Connexion réussie !", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    onPressed: () {}, // Desactivé 7it a-rediriger auto
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                BuildingsBackground(mainColor: mainColor, height: double.infinity),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.apartment, color: Colors.white, size: 30),
                          SizedBox(width: 8),
                          Text("Sindy", style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text("Résidence Les Palmiers", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    String? errorText,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          style: const TextStyle(color: Colors.black, fontSize: 15),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.black26, fontSize: 15),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.black26, size: 20),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  )
                : (errorText != null ? const Icon(Icons.error, color: Colors.redAccent, size: 20) : null),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: errorText != null ? Colors.redAccent : Colors.grey.shade300, width: 1), 
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: errorText != null ? Colors.redAccent : mainColor, width: 1.5),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6.0, left: 4.0),
            child: Text(errorText, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
          ),
      ],
    );
  }
}

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