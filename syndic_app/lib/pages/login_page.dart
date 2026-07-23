import 'package:flutter/material.dart';
import 'main_layout.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Les controllers bash n9raw shno tktab f les inputs
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        centerTitle: true,
      ),
      // Padding bash nkhlliw l-espace f jnab
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // n-centriw kolchi f l-wst
          children: [
            // Champ dyal Email
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(), // Cadre 3la l-input
              ),
            ),
            const SizedBox(height: 20), // Espace bin l-email w l-mot de passe
            
            // Champ dyal Mot de passe
            TextField(
              controller: _passwordController,
              obscureText: true, // Bash y-tkhbba l-mot de passe
              decoration: const InputDecoration(
                labelText: 'Mot de passe',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            
            // Bouton de connexion
            SizedBox(
              width: double.infinity, // Bouton yakhod l-3ard kaml
              height: 50,
              child: ElevatedButton(
  onPressed: () {
    // Hna mn b3d ghadi n-zidou l-verification dyal l-API (Laravel)
    // Daba ghadi n-diro ghir redirection mobachara bash n-testew
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainLayout()),
    );
  },
  child: const Text(
    'Se Connecter',
    style: TextStyle(fontSize: 18),
  ),
),
            ),
          ],
        ),
      ),
    );
  }
}