import 'package:flutter/material.dart';
// 1. Ini baris untuk mengenalkan file beranda yang kamu buat tadi ke main.dart
import 'beranda_page.dart'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      // 2. Di sini kita panggil BerandaPage() supaya saat aplikasi pertama kali dibuka, 
      //    tampilan Beranda langsung muncul.
      home: BerandaPage(), 
    );
  }
}