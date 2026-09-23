import 'package:flutter/material.dart';
import 'dart:io'; 

// 🟢 HNA TBDLNA L'IMPORT BACH NJIBOU LOGIN PAGE
import 'package:syndic_app/pages/login_page.dart';

void main() async {
  HttpOverrides.global = MyHttpOverrides(); 
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, 
      title: 'Syndify App',
      theme: ThemeData(
        primarySwatch: Colors.lightGreen,
        // (Optionnel) Ila bghiti tbadal naw3 l'khat f l'app kamla
        // fontFamily: 'Montserrat', 
      ),
      
      // 🔥 HADI HIYA L'ASTUCE LI GHAT-FIXI MOCHKIL L'IPHONE 🔥
      builder: (context, child) {
        final MediaQueryData data = MediaQuery.of(context);
        return MediaQuery(
          data: data.copyWith(
            // Hna drna 1.15 ya3ni l'kht ghadi ykber b 15% f l'app kamla.
            // Ila ba9i kayban lik sghir, redha 1.20 wla 1.25.
            textScaler: const TextScaler.linear(1.15), 
            
            // ⚠️ NOTE: Ila knti kheddam b version 9dima chwiya dyal Flutter w 3tak erreur f textScaler, 
            // mss7 textScaler w dir f blassetha had ster lta7t:
            // textScaleFactor: 1.15,
          ),
          child: child!,
        );
      },
      
      home: const LoginPage(), 
    );
  }
}
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}