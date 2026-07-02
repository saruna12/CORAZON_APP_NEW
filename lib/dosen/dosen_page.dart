import 'package:flutter/material.dart';
import 'bank_soal_page.dart';
import 'modul_page.dart';
import 'hasil_pretest_page.dart';

class DosenPage extends StatelessWidget {
  const DosenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Dosen'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.menu_book),
            title: const Text('Kelola Modul Pembelajaran'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ModulPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.quiz),
            title: const Text('Manajemen Bank Soal'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BankSoalPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Memantau Hasil Pretest'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HasilPretestPage(isDosen: true),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
