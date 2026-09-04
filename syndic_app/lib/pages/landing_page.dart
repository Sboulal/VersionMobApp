import 'package:flutter/material.dart';
import 'package:syndic_app/pages/login_page.dart';

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 2),
                
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
                const SizedBox(height: 30),
                
                const Text(
                  "Bienvenue sur\nSyndify",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, height: 1.2),
                ),
                const SizedBox(height: 16),
                
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40.0),
                  child: Text(
                    "Gérez votre copropriété en toute simplicité et transparence.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                  ),
                ),
                
                const Spacer(flex: 3),
                
                // L-boutonat l-ta7t b7al f design
                Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
                          },
                          child: const Text("Login", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: double.infinity,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(30),
                              topRight: Radius.circular(30),
                            ),
                          ),
                          child: TextButton(
                            onPressed: () {
                              // Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage()));
                            },
                            child: Text("Register", style: TextStyle(color: mainColor, fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),
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
          // Immeuble 1
          Positioned(
            bottom: 0,
            left: 20,
            child: _buildBuilding(60, 150, Colors.white.withOpacity(0.1)),
          ),
          // Immeuble 2 (Twil)
          Positioned(
            bottom: 0,
            left: 90,
            child: _buildBuilding(80, 220, Colors.white.withOpacity(0.15)),
          ),
          // Immeuble 3
          Positioned(
            bottom: 0,
            right: 30,
            child: _buildBuilding(70, 180, Colors.white.withOpacity(0.08)),
          ),
          // Immeuble 4 (Sghir)
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