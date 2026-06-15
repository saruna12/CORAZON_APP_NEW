import 'package:flutter/material.dart';
import 'beranda.dart';
import 'dosen/dosen_beranda_page.dart';
import 'package:corazon_clean/register_page.dart';

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
      backgroundColor: maroonColor,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24.0),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  const Text(
                    'Username / Nama',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Masukkan nama Anda',
                        hintStyle:
                            TextStyle(color: Colors.black38, fontSize: 13),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'NPM / Password',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
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
                        hintText: 'Masukkan NPM untuk Mahasiswa',
                        hintStyle:
                            TextStyle(color: Colors.black38, fontSize: 13),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Pindah ke halaman Register
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const RegisterPage()),
                          );
                        },
                        child: const Text(
                          "create account",
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: maroonColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
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
                        // Ambil string mentah tanpa trim/lowercase bawaan biar tidak merusak memori sensor password stuy
                        String username = _usernameController.text;
                        String password = _passwordController.text;

                        if (username.isEmpty || password.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Masukkan username dan password')),
                          );
                          return;
                        }

                        // ================= JALUR 1: DATA STAF / PENGELOLA LAB (DOSEN/LABORAN) =================
                        if ((username == 'dosen' && password == 'dosen123') ||
                            (username == 'laboran' &&
                                password == 'laboran123') ||
                            (username == 'asdos' && password == 'asdos123') ||
                            (username == 'admin' && password == 'admin123')) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const DosenBerandaPage()),
                          );

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Login Sukses sebagai ${username.toUpperCase()}')),
                          );
                        }
                        // ================= JALUR 2: DATA MAHASISWA BIASA =================
                        else {
                          // Jalur Mahasiswa: Cek apakah password berupa NPM (Angka)
                          final isNumber =
                              RegExp(r'^[0-9]+$').hasMatch(password);

                          if (!isNumber) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Login Gagal! Password Mahasiswa harus berupa NPM (Angka) / Gunakan Akun Staf'),
                              ),
                            );
                          } else {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    BerandaPage(namaMahasiswa: username),
                              ),
                            );
                          }
                        }
                      },
                      child: const Text(
                        'SIGN IN',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
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
