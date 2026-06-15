import 'dart:async'; // WAJIB DIIMPORT untuk fungsi Timer durasi
import 'package:flutter/material.dart';
import 'sign_in.dart'; // Menghubungkan ke halaman Sign In agar bisa pindah halaman

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Fungsi Timer: Menunggu selama 3 detik, lalu pindah ke SignInPage
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SignInPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    const maroonColor = Color(0xFF801A24);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            Image.asset(
              'assets/images/logo.png',
              width: 180,
              height: 180,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.favorite,
                    size: 150, color: maroonColor);
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'CORAZON APP',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1B2A52),
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(flex: 1),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: const LinearProgressIndicator(
                  value: 0.6,
                  minHeight: 12,
                  backgroundColor: Color(0xFFE0E0E0),
                  valueColor: AlwaysStoppedAnimation<Color>(maroonColor),
                ),
              ),
            ),
            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }
}
