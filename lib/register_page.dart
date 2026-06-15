import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _npmController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _npmController.dispose();
    _emailController.dispose();
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
                  const Center(
                    child: Text(
                      'CREATE ACCOUNT',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: maroonColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Input Nama
                  const Text('Nama Lengkap',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                        color: const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(8.0)),
                    child: TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Input NPM
                  const Text('NPM (Nomor Pokok Mahasiswa)',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                        color: const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(8.0)),
                    child: TextField(
                      controller: _npmController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Harus berupa angka',
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Input Email
                  const Text('Email',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                        color: const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(8.0)),
                    child: TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Input Password
                  const Text('Password',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                        color: const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(8.0)),
                    child: TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tombol Register
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: maroonColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0)),
                      ),
                      onPressed: () {
                        String name = _nameController.text.trim();
                        String npm = _npmController.text.trim();
                        String email = _emailController.text.trim();
                        String password = _passwordController.text.trim();

                        if (name.isEmpty ||
                            npm.isEmpty ||
                            email.isEmpty ||
                            password.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Semua kolom wajib diisi!')),
                          );
                          return;
                        }

                        // Validasi NPM harus angka
                        final isNumber = RegExp(r'^[0-9]+$').hasMatch(npm);
                        if (!isNumber) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('NPM harus berupa angka!')),
                          );
                          return;
                        }

                        // Alur simulasi sukses (Mock Flow)
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('🎉 Registrasi Berhasil'),
                              content: Text(
                                  'Akun Mahasiswa atas nama $name dengan NPM $npm telah terdaftar ke sistem.'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context); // Tutup dialog
                                    Navigator.pop(
                                        context); // Kembali ke halaman Sign In
                                  },
                                  child: const Text('OK',
                                      style: TextStyle(
                                          color: maroonColor,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: const Text('REGISTER',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tombol Kembali Ke Login
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        "Already have an account? Sign In",
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: maroonColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
