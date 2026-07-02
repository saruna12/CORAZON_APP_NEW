import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _npmController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Fungsi proses registrasi ke Firebase
  Future<void> _prosesRegistrasi() async {
    String name = _nameController.text.trim();
    String npm = _npmController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (name.isEmpty || npm.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnackbar('Semua kolom wajib diisi!');
      return;
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(npm)) {
      _showSnackbar('NPM harus berupa angka!');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Daftarkan akun di Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      String? uid = userCredential.user?.uid;

      if (uid != null) {
        // 2. Simpan data tambahan (Nama, NPM, Role) di Cloud Firestore
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'uid': uid,
          'nama': name,
          'npm': npm,
          'email': email,
          'role': 'mahasiswa',
          'status_pretest': 'BELUM DIAMBIL',
          'status_postest': 'BELUM DIAMBIL',
          'waktu_daftar': DateTime.now().toString(),
        });

        if (mounted) _showSuccessDialog(name, npm);
      }
    } on FirebaseAuthException catch (e) {
      String pesanError = 'Terjadi kesalahan.';
      if (e.code == 'weak-password') {
        pesanError = 'Password terlalu lemah (minimal 6 karakter).';
      } else if (e.code == 'email-already-in-use') {
        pesanError = 'Email ini sudah terdaftar.';
      } else if (e.code == 'invalid-email') {
        pesanError = 'Format email salah.';
      }
      _showSnackbar(pesanError);
    } catch (e) {
      _showSnackbar('Gagal menyimpan data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
  }

  void _showSuccessDialog(String name, String npm) {
    const maroonColor = Color(0xFF801A24);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('🎉 Registrasi Berhasil'),
          content: Text(
              'Akun Mahasiswa atas nama $name dengan NPM $npm telah tersimpan di Firebase.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Tutup dialog
                Navigator.pop(context); // Kembali ke halaman Login
              },
              child: const Text('OK',
                  style: TextStyle(
                      color: maroonColor, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
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
                          color: maroonColor),
                    ),
                  ),
                  const SizedBox(height: 20),
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
                      onPressed: _isLoading ? null : _prosesRegistrasi,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('REGISTER',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 16),
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
