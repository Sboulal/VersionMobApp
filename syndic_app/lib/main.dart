// Importing important packages require to connect
// Flutter and Dart
import 'package:flutter/material.dart';
import 'dart:io'; // 🟢 هاد السطر ضروري باش يخدم HttpOverrides

import 'package:syndic_app/pages/landing_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("🔥 Message reçu en background: ${message.messageId}");
}
// Main Function
void main() async {
  // 1. Darori t-zidi hadi 9bel Firebase
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Initialisation dyal Firebase
  await Firebase.initializeApp();
  // --- NOUVEAU CODE FCM ---
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  // Demander les permissions (Darori l'Android 13+ w iOS)
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  // Giving command to runApp() to run the app.
  HttpOverrides.global = MyHttpOverrides(); // 🟢 تخطي مشكل SSL
  // The purpose of the runApp() function is to attach
  // the given widget to the screen.

  // Gérer les messages f l'arrière-plan
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Récupérer le Token et l'afficher dans la console
  String? token = await messaging.getToken();
  print("====================================");
  print("🔑 FCM TOKEN: $token");
  print("====================================");
  // -------------------------
  runApp(const MyApp());
}




// MyApp extends StatelessWidget and overrides its
// build method.
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, 
      // title of the application
      title: 'Syndify App',
      
      // theme of the widget
      theme: ThemeData(
        primarySwatch: Colors.lightGreen,
      ),
      
      // Inner UI of the application
      home: const LandingPage(), // 🟢 من الأحسن تزيدي const هنا
    );
  }
}

// This class is similar to MyApp instead it
// returns Scaffold Widget 
class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      
      // Sets the content to the
      // center of the application page
      body: const Center(
          // Sets the content of the Application
          child: Text(
        'Welcome to SyndifyApp!',
      )),
    );
  }
}

// 🟢 Classe pour ignorer les erreurs de certificat SSL (En développement)
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}