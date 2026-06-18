import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'beranda.dart';
import 'dosen/dosen_beranda_page.dart';
import 'package:corazon_clean/register_page.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController _emailOrUsernameController =
      TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailOrUsernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _prosesLogin() async {
    String inputUser = _emailOrUsernameController.text.trim();
    String password = _passwordController.text.trim();

    if (inputUser.isEmpty || password.isEmpty) {
      _showSnackbar('Masukkan email/username dan password!');
      return;
    }

    setState(() => _isLoading = true);

    // ================= JALUR 1: DATA STAF / ADMIN LAB (Tanpa Firebase) =================
    if ((inputUser == 'dosen' && password == 'dosen123') ||
        (inputUser == 'laboran' && password == 'laboran123') ||
        (inputUser == 'asdos' && password == 'asdos123') ||
        (inputUser == 'admin' && password == 'admin123')) {
      setState(() => _isLoading = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DosenBerandaPage()),
      );
      _showSnackbar('Login Sukses sebagai ${inputUser.toUpperCase()}');
      return;
    }

    // ================= JALUR 2: LOGIN MAHASISWA (Lewat Firebase) =================
    try {
      // Login menggunakan Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: inputUser, password: password);

      String? uid = userCredential.user?.uid;

      if (uid != null) {
        // Ambil data nama asli mahasiswa dari Cloud Firestore berdasarkan UID
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();

        String namaMhs = userDoc.exists
            ? (userDoc.data() as Map<String, dynamic>)['nama'] ?? 'Mahasiswa'
            : 'Mahasiswa';

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => BerandaPage(namaMahasiswa: namaMhs)),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String pesanError = 'Login gagal. Periksa kembali email & password Anda.';
      if (e.code == 'user-not-found') {
        pesanError =
            'Akun tidak ditemukan. Silakan registrasi terlebih dahulu.';
      } else if (e.code == 'wrong-password') {
        pesanError = 'Password salah.';
      } else if (e.code == 'invalid-email') {
        pesanError = 'Format email salah (Gunakan email saat daftar).';
      }
      _showSnackbar(pesanError);
    } catch (e) {
      _showSnackbar('Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
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
                    'Email / Username Staf',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                        color: const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(8.0)),
                    child: TextField(
                      controller: _emailOrUsernameController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Masukkan email Anda / username staf',
                        hintStyle:
                            TextStyle(color: Colors.black38, fontSize: 13),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Password',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                        color: const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(8.0)),
                    child: TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Masukkan password Anda',
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
                      const Text("Don't have an account? ",
                          style:
                              TextStyle(fontSize: 12, color: Colors.black87)),
                      GestureDetector(
                        onTap: () {
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
                            borderRadius: BorderRadius.circular(8.0)),
                      ),
                      onPressed: _isLoading ? null : _prosesLogin,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('SIGN IN',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
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
