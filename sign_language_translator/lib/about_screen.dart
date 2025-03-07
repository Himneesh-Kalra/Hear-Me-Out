import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("About This App"),
        centerTitle: true,
        backgroundColor: const Color.fromRGBO(77, 106, 109, 1), // Match theme
      ),
      backgroundColor: const Color.fromRGBO(234, 224, 204, 1),
      body: const Padding(
        padding: EdgeInsets.all(20.0),
        child: Center(
          child: Text(
            "This app translates sign language into text and speech in real-time.\n\n"
            "It uses camera input, processes frames using AI, and sends them to a server for interpretation.",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
