import 'package:flutter/material.dart';
import 'beranda.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    const maroonColor = Color(0xFF801A24);

    return Scaffold(
      backgroundColor: maroonColor, // Background merah marun
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white, // Menggunakan 'C' besar
                borderRadius: BorderRadius.circular(24.0), // Kotak putih melengkung
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  
                  // Label Username
                  const Text(
                    'Username',
                    style: TextStyle(
                      fontSize: 14, 
                      fontWeight: FontWeight.w500, 
                      color: Colors.black87, // FIX: Menggunakan warna resmi Flutter
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Input Username Abu-abu
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0), 
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Label Password
                  const Text(
                    'Password',
                    style: TextStyle(
                      fontSize: 14, 
                      fontWeight: FontWeight.w500, 
                      color: Colors.black87, // FIX: Menggunakan warna resmi Flutter
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Input Password Abu-abu
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Teks Create Account bawah
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Text(
                        "Don't have an account? ", 
                        style: TextStyle(fontSize: 12, color: Colors.black87), // FIX
                      ),
                      GestureDetector(
                        onTap: () {
                          // Aksi daftar akun baru
                        },
                        child: const Text(
                          "create account",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: maroonColor),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),

                  // Tombol Sign In Utama
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: maroonColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      onPressed: () {
                        if (_usernameController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Masukkan username dan password')),
                          );
                          return;
                        }

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const BerandaPage()),
                        );
                      },
                      child: const Text(
                        'SIGN IN',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}