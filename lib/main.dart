import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'splash_screen.dart';
import 'pretest_repository.dart'; // 🔴 WAJIB IMPORT REPOSITORY KAMU DI SINI STUY!

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyAHBEjOlLQGwcaa6kiQP86pFe3bvuWAfvs',
      appId: '1:413923570150:android:db1be88c3ca475e9d06627',
      messagingSenderId: '413923570150',
      projectId: 'corazon-9a8c7',
    ),
  );

  // 🟢 KUNCI UTAMA: Aktifkan pendengar status ujian sejak aplikasi dibuka stuy!
  PretestRepository.listenStatusUjian();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<void> jalankanTesFirebase() async {
    try {
      await FirebaseFirestore.instance.collection('users').add({
        'status_koneksi': 'Berhasil Terhubung!',
        'nama_aplikasi': 'Corazon Clean App',
        'waktu_tes': DateTime.now().toString(),
      });
      debugPrint("===== KONEKSI FIRESTORE BERHASIL =====");
    } catch (e) {
      debugPrint("===== KONEKSI FIRESTORE GAGAL: $e =====");
    }
  }

  @override
  Widget build(BuildContext context) {
    jalankanTesFirebase();

    return MaterialApp(
      title: 'Corazon App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF801A24),
      ),
      home: const SplashScreen(),
    );
  }
}
