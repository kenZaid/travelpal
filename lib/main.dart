import 'package:flutter/material.dart';

class TravelPalColors {
  static const blue = Color(0xFF0057B8);
  static const yellow = Color(0xFFFFD700);
  static const red = Color(0xFFCE1126);
}


void main() {
  runApp(const TravelPalApp());
}

class TravelPalApp extends StatelessWidget {
  const TravelPalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TravelPal',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TravelPal'),
      ),
      body: const Center(
        child: Text(
          'Welcome to TravelPal!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}