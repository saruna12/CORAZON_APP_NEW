import 'package:flutter/material.dart';

class PretestPage extends StatefulWidget {
  const PretestPage({super.key});

  @override
  State<PretestPage> createState() => _PretestPageState();
}

class _PretestPageState extends State<PretestPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Halaman Pretest'),
        backgroundColor: const Color(0xFF6B1D2F),
      ),
      body: const Center(
        child: Text('Kodingan soal-soal Pretest kamu di sini nanti'),
      ),
    );
  }
}
