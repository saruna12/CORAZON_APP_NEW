import 'package:flutter/material.dart';
import 'modul_page.dart';
import 'bank_soal_page.dart';
import 'hasil_pretest_page.dart';

class DosenBerandaPage extends StatefulWidget {
  const DosenBerandaPage({super.key});

  @override
  State<DosenBerandaPage> createState() => _DosenBerandaPageState();
}

class _DosenBerandaPageState extends State<DosenBerandaPage> {
  bool _isUjianOpen = false;
  final Color maroonPrimary = const Color(0xFF6B1D2F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F6),
      body: Column(
        children: [
          // 1. HEADER MEWAH (Mirip Dashboard Mahasiswa)
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 30),
            decoration: BoxDecoration(
              color: maroonPrimary,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat Datang,',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                SizedBox(height: 4),
                Text(
                  'Tim Laboran CORAZON 👋',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 6),
                Text(
                  'Sistem Kendali & Manajemen Praktikum Anatomi',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. LIVE ACCESS CONTROL CARD (Sinyal Utama Ujian)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          // SUDAH DIPERBAIKI: Menggunakan .withValues sesuai standar baru Flutter
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _isUjianOpen
                                    ? Colors.green.shade50
                                    : Colors.orange.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isUjianOpen ? Icons.lock_open : Icons.lock,
                                color:
                                    _isUjianOpen ? Colors.green : Colors.orange,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Status Gerbang Pre-Test',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _isUjianOpen
                                        ? 'Akses Terbuka (Mahasiswa bisa ujian)'
                                        : 'Akses Terkunci (Mahasiswa standby)',
                                    style: TextStyle(
                                        color: _isUjianOpen
                                            ? Colors.green
                                            : Colors.orange,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  _isUjianOpen ? Colors.green : maroonPrimary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              setState(() {
                                _isUjianOpen = !_isUjianOpen;
                              });
                            },
                            child: Text(
                              _isUjianOpen
                                  ? 'TUTUP AKSES UJIAN'
                                  : 'BUKA AKSES UJIAN SEKARANG',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),
                  const Text(
                    'MENU MANAJEMEN LABORATORIUM',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 16),

                  // 3. GRID MENU MODERN
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                    children: [
                      // Menu 1: Kelola Modul
                      _buildGridMenu(
                        context: context,
                        title: 'Kelola Modul\nPembelajaran',
                        subtitle: 'Upload materi PDF',
                        icon: Icons.menu_book_rounded,
                        iconColor: const Color(0xFF4A90E2),
                        targetPage: const ModulPage(),
                      ),
                      // Menu 2: Bank Soal
                      _buildGridMenu(
                        context: context,
                        title: 'Manajemen\nBank Soal',
                        subtitle: 'Atur butir pretest',
                        icon: Icons.quiz_rounded,
                        iconColor: const Color(0xFFF5A623),
                        targetPage: const BankSoalPage(),
                      ),
                      // Menu 3: Pantau Nilai
                      _buildGridMenu(
                        context: context,
                        title: 'Memantau\nHasil Pretest',
                        subtitle: 'Rekap skor mhs live',
                        icon: Icons.analytics_rounded,
                        iconColor: const Color(0xFF2ECC71),
                        targetPage: const HasilPretestPage(),
                      ),
                      // Menu 4: Log Out / Keluar Sistem
                      _buildGridMenu(
                        context: context,
                        title: 'Keluar\nAplikasi',
                        subtitle: 'Kembali ke Sign In',
                        icon: Icons.logout_rounded,
                        iconColor: const Color(0xFFE74C3C),
                        targetPage: null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper Widget untuk Bikin Kotak Menu Grid
  Widget _buildGridMenu({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Widget? targetPage,
  }) {
    return InkWell(
      onTap: () {
        if (targetPage != null) {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => targetPage));
        } else {
          // Logika Log Out kembali ke Sign In stuy
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
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
              // SUDAH DIPERBAIKI: Menggunakan .withValues standar baru
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
                // SUDAH DIPERBAIKI: Menggunakan .withValues standar baru
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
}
