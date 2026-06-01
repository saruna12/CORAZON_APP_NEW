import 'package:flutter/material.dart';

class DetailHalaman extends StatelessWidget {
  const DetailHalaman({super.key});

  @override
  Widget build(BuildContext context) {
    const maroonColor = Color(0xFF801A24); // Warna maroon khas Corazon

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: maroonColor,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'DETAIL CORAZON',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '❤️',
              style: TextStyle(fontSize: 80),
            ),
            const SizedBox(height: 10),
            const Text(
              'Halaman Detail Visualisasi Jantung',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: maroonColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                // Tombol fungsi untuk kembali ke halaman Beranda
                Navigator.pop(context);
              },
              child: const Text(
                'Kembali',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}