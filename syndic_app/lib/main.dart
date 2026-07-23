// Importing important packages require to connect
// Flutter and Dart
import 'package:flutter/material.dart';
import 'package:syndic_app/pages/login_page.dart';

// Main Function
void main() {
// Giving command to runApp() to run the app.

// The purpose of the runApp() function is to attach
// the given widget to the screen.
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
        
      // title of the application
      title: 'Hello World Demo Application',
      
      // theme of the widget
      theme: ThemeData(
        primarySwatch: Colors.lightGreen,
      ),
      
      // Inner UI of the application
      home: const LoginPage(),
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