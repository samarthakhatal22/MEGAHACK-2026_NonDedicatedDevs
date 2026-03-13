import 'package:flutter/material.dart';
import 'package:civicshield/pages/home_page.dart';

void main() {
  runApp(const CivicShieldApp());
}

class CivicShieldApp extends StatelessWidget {
  const CivicShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PolicyLens',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
        fontFamily: 'GoogleSans',
      ),
      home: const HomePage(),
    );
  }
}
