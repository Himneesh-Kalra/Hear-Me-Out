import 'package:flutter/material.dart';
import 'camera_stream.dart';
import 'about_screen.dart'; // Import the new About page

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(77, 106, 109, 1), // AppBar color
        elevation: 0, // No shadow under AppBar
      ),
      backgroundColor: const Color.fromRGBO(234, 224, 204, 1),
      body: Column(
        children: [
          // About Button (Centered below AppBar, same Y-axis as Translation Button)
          Padding(
            padding: const EdgeInsets.only(top: 20), // Keep Y-axis consistent
            child: Align(
              alignment: Alignment.center, // Center align horizontally
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color.fromRGBO(77, 106, 109, 1), // Button color
                  foregroundColor: Colors.white, // Text color
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // Rounded corners
                  ),
                  shadowColor: Colors.black.withOpacity(0.4), // Shadow effect
                  elevation: 5, // Shadow depth
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const AboutScreen()), // Navigate to AboutScreen
                  );
                },
                child: const Text(
                  "Why this app?",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),

          const Spacer(), // Pushes the main button to center

          // Main Button
          Center(
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const CameraStreamPage()),
                  );
                },
                splashColor: Colors.white.withOpacity(0.2),
                highlightColor: Colors.white.withOpacity(0.1),
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(77, 106, 109, 1),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        spreadRadius: 5,
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      "Hear Me Out!",
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Color.fromRGBO(234, 224, 204, 1),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const Spacer(), // Adds space at the bottom
        ],
      ),
    );
  }
}
