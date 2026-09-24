import 'package:flutter/material.dart';
import 'dart:io'; 
import 'package:flutter_screenutil/flutter_screenutil.dart'; // 🟢 ZIDNA HAD L'IMPORT DAROURI

// HNA TBDLNA L'IMPORT BACH NJIBOU LOGIN PAGE
import 'package:syndic_app/pages/login_page.dart';
import 'package:syndic_app/pages/landing_page.dart';

void main() async {
  // 🟢 Darouriya bach t2ked bli l-app t-initialisat 9bel ma t-lanci ScreenUtil
  WidgetsFlutterBinding.ensureInitialized(); 

  HttpOverrides.global = MyHttpOverrides(); 
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 🟢 GHLLFNA MATERIALLAPP B SCREENUTIL
    return ScreenUtilInit(
      designSize: const Size(360, 690), // L-3bar standard dyal l-écran
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false, 
          title: 'Syndify App',
          theme: ThemeData(
            primarySwatch: Colors.lightGreen,
          ),
          
          // 🟢 HNA N-BLOKIW L-ZOOM AUTOMATIQUE DYAL T-TILIFON 
          builder: (context, widget) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.0), // Radinaha 1.0 (ScreenUtil li ghaytkelaf)
              ),
              child: widget!,
            );
          },
          
          home: const LandingPage(), 
        );
      },
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