import 'package:flutter/material.dart';
import 'screens/home/home_screen.dart'; 
import 'widgets/custom_button.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const StartScreen(), 
    );
  }
}

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("pantalla 1"),
      ),
      body: Center(
        child: CustomButton(
          text: "Ir al Proyecto",
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          },
        ),
      ),
    );
  }
}
