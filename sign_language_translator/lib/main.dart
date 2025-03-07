import 'package:flutter/material.dart';
import 'home_screen.dart'; // Import the new Home Screen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sign Language Translator',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(), // Start with Home Screen
    );
  }
}
