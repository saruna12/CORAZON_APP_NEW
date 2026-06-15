import 'package:flutter/material.dart';
import 'splash_screen.dart'; // Hanya mengimport yang benar-benar dipakai

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Corazon App',
      debugShowCheckedModeBanner:
          false, // Biar banner debug merah di kanan atas hilang
      theme: ThemeData(
        primaryColor: const Color(0xFF801A24),
      ),
      // Membuka Splash Screen sebagai halaman pertama secara normal
      home: const SplashScreen(),
    );
  }
}
