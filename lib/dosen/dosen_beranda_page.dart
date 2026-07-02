import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../sign_in.dart';
import '../pretest_repository.dart'; // Jalur ke repository stuy
import 'modul_page.dart';
import 'bank_soal_page.dart';
import 'hasil_pretest_page.dart';
import 'user_management_page.dart';

class DosenBerandaPage extends StatefulWidget {
  const DosenBerandaPage({super.key});

  @override
  State<DosenBerandaPage> createState() => _DosenBerandaPageState();
}

class _DosenBerandaPageState extends State<DosenBerandaPage> {
  final Color maroonPrimary = const Color(0xFF6B1D2F);

  bool _checkingAuthorization = true;
  bool _isAuthorized = false;
  String _dosenNama = 'Dosen';
  String _dosenNIP = 'NIP Tidak Terbaca';

  @override
  void initState() {
    super.initState();
    _checkAuthorization();
    PretestRepository.listenStatusUjian();
  }

  Future<void> _checkAuthorization() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _redirectToSignIn();
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final role = snapshot.exists && snapshot.data() != null
          ? (snapshot.data() as Map<String, dynamic>)['role']?.toString() ?? ''
          : '';

      if (role.isEmpty || role == 'mahasiswa') {
        await FirebaseAuth.instance.signOut();
        _redirectToSignIn();
        return;
      }

      // Ambil nama dan NIP dosen
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data() as Map<String, dynamic>;
        _dosenNama = data['nama'] ?? 'Dosen';
        _dosenNIP = data['nip'] ?? 'NIP Tidak Terbaca';
      }

      if (mounted) {
        setState(() {
          _isAuthorized = true;
          _checkingAuthorization = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _checkingAuthorization = false;
          _isAuthorized = false;
        });
      }
      await FirebaseAuth.instance.signOut();
      _redirectToSignIn();
    }
  }

  void _redirectToSignIn() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SignInPage()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingAuthorization) {
      return const Scaffold(
        backgroundColor: Color(0xFFF9F6F6),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAuthorized) {
      return const Scaffold(
        backgroundColor: Color(0xFFF9F6F6),
        body: Center(
            child: Text('Akses tidak diizinkan. Mengarahkan ke login...')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F6),
      body: Column(
        children: [
          // 1. HEADER UTAMA + LOG OUT
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.only(top: 60, left: 24, right: 16, bottom: 32),
            decoration: BoxDecoration(
              color: maroonPrimary,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selamat Datang,',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_dosenNama ($_dosenNIP) 👋',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Sistem Kendali & Manajemen Anatomi',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded,
                      color: Colors.white70, size: 24),
                  tooltip: 'Keluar Aplikasi',
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    await FirebaseAuth.instance.signOut();
                    if (!mounted) return;
                    navigator.popUntil((route) => route.isFirst);
                  },
                ),
              ],
            ),
          ),

          // AREA KONTEN UTAMA
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. LIVE ACCESS CONTROL CARDS
                  const Text(
                    'KONTROL AKSES SESI UJIAN',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 12),

                  // KENDALI SESI PRETEST
                  ValueListenableBuilder<bool>(
                    valueListenable: PretestRepository.statusPretestLive,
                    builder: (context, isPreOpen, child) {
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isPreOpen
                                        ? Colors.green.shade50
                                        : Colors.orange.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isPreOpen
                                        ? Icons.lock_open_rounded
                                        : Icons.lock_rounded,
                                    color: isPreOpen
                                        ? Colors.green
                                        : Colors.orange,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Kendali Sesi Pretest',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14),
                                      ),
                                      Text(
                                        isPreOpen
                                            ? 'Pretest Sedang Aktif'
                                            : 'Pretest Ditutup',
                                        style: TextStyle(
                                            color: isPreOpen
                                                ? Colors.green
                                                : Colors.orange,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: isPreOpen,
                                  activeThumbColor: maroonPrimary,
                                  onChanged: (val) async {
                                    await PretestRepository.ubahStatusUjian(
                                        val);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // KENDALI SESI POSTTEST
                  ValueListenableBuilder<bool>(
                    valueListenable: PretestRepository.statusPosttestLive,
                    builder: (context, isPostOpen, child) {
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isPostOpen
                                        ? Colors.green.shade50
                                        : Colors.orange.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isPostOpen
                                        ? Icons.lock_open_rounded
                                        : Icons.lock_rounded,
                                    color: isPostOpen
                                        ? Colors.green
                                        : Colors.orange,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Kendali Sesi Post-test',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14),
                                      ),
                                      Text(
                                        isPostOpen
                                            ? 'Post-test Sedang Aktif'
                                            : 'Post-test Ditutup',
                                        style: TextStyle(
                                            color: isPostOpen
                                                ? Colors.green
                                                : Colors.orange,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: isPostOpen,
                                  activeThumbColor: maroonPrimary,
                                  onChanged: (val) async {
                                    await PretestRepository.ubahStatusPosttest(
                                        val);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const Text(
                    'MENU UTAMA MANAJEMEN',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 16),

                  // 3. GRID MENU
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.15,
                    children: [
                      _buildGridMenu(
                        context: context,
                        title: 'Kelola Modul\nPembelajaran',
                        subtitle: 'Upload materi PDF',
                        icon: Icons.menu_book_rounded,
                        iconColor: const Color(0xFF4A90E2),
                        targetPage: const ModulPage(isDosen: true),
                      ),
                      _buildGridMenu(
                        context: context,
                        title: 'Bank Soal\nTerpadu',
                        subtitle: 'Kelola pre/post test',
                        icon: Icons.quiz_rounded,
                        iconColor: const Color(0xFFF5A623),
                        targetPage: const BankSoalPage(),
                      ),
                      _buildGridMenu(
                        context: context,
                        title: 'Manajemen\nPengguna',
                        subtitle: 'Ubah role / hapus user',
                        icon: Icons.supervised_user_circle_rounded,
                        iconColor: const Color(0xFF16A085),
                        targetPage: const UserManagementPage(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 4. HASIL PRETEST (Full Width List)
                  _buildFullWidthMenu(
                    context: context,
                    title: 'Pantau Perkembangan & Hasil Ujian (Pre/Post)',
                    subtitle: 'Rekap skor & status kelulusan mahasiswa live',
                    icon: Icons.analytics_rounded,
                    iconColor: const Color(0xFF2ECC71),
                    targetPage: const HasilPretestPage(isDosen: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridMenu({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Widget targetPage,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => targetPage));
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13, height: 1.2),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullWidthMenu({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Widget targetPage,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => targetPage));
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.grey, size: 14),
          ],
        ),
      ),
    );
  }
}
