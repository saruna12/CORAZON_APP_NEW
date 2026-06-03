import 'package:flutter/material.dart';
import 'package:corazon_clean/beranda.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Corazon App',
      theme: ThemeData(
        primaryColor: const Color(0xFF801A24),
      ),
      home: const BerandaPage(),
    );
  }
}