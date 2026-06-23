import 'package:flutter/material.dart';
import '../pretest_repository.dart'; // Hubungkan ke repository biar singkron stuy
import 'modul_page.dart';
import 'bank_soal_page.dart';
import 'hasil_pretest_page.dart';

class DosenBerandaPage extends StatefulWidget {
  const DosenBerandaPage({super.key});

  @override
  State<DosenBerandaPage> createState() => _DosenBerandaPageState();
}

class _DosenBerandaPageState extends State<DosenBerandaPage> {
  final Color maroonPrimary = const Color(0xFF6B1D2F);

  @override
  void initState() {
    super.initState();
    // Mendengarkan perubahan sakelar ujian live dari Firestore secara real-time stuy
    PretestRepository.listenStatusUjian();
  }

  @override
  Widget build(BuildContext context) {
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
                      const Text(
                        'Tim Laboran CORAZON 👋',
                        style: TextStyle(
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
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
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
                  // 2. LIVE ACCESS CONTROL CARD (Sinkron Firestore secara otomatis stuy)
                  ValueListenableBuilder<bool>(
                    valueListenable: PretestRepository.statusUjianLive,
                    builder: (context, isUjianOpen, child) {
                      return Container(
                        width: double.infinity,
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
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isUjianOpen
                                        ? Colors.green.shade50
                                        : Colors.orange.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isUjianOpen
                                        ? Icons.lock_open_rounded
                                        : Icons.lock_rounded,
                                    color: isUjianOpen
                                        ? Colors.green
                                        : Colors.orange,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Status Gerbang Pre-Test',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isUjianOpen
                                            ? 'Akses Terbuka (Mahasiswa bisa ujian)'
                                            : 'Akses Terkunci (Mahasiswa standby)',
                                        style: TextStyle(
                                            color: isUjianOpen
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
                              height: 48,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isUjianOpen
                                      ? maroonPrimary
                                      : Colors.green,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                ),
                                onPressed: () async {
                                  await PretestRepository.ubahStatusUjian(
                                      !isUjianOpen);
                                },
                                child: Text(
                                  isUjianOpen
                                      ? 'TUTUP AKSES UJIAN'
                                      : 'BUKA AKSES UJIAN SEKARANG',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      letterSpacing: 0.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),
                  const Text(
                    'MENU UTAMA MANAJEMEN',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 16),

                  // 3. GRID MENU (Kelola Modul & Bank Soal)
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
                        // ✅ PERBAIKAN: Melemparkan isDosen: true agar ModulPage tahu yang masuk adalah Dosen
                        targetPage: const ModulPage(isDosen: true),
                      ),
                      _buildGridMenu(
                        context: context,
                        title: 'Manajemen\nBank Soal',
                        subtitle: 'Atur butir pretest',
                        icon: Icons.quiz_rounded,
                        iconColor: const Color(0xFFF5A623),
                        targetPage: const BankSoalPage(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 4. HASIL PRETEST (Full Width List)
                  _buildFullWidthMenu(
                    context: context,
                    title: 'Pantau Perkembangan & Hasil Pretest',
                    subtitle: 'Rekap skor & status kelulusan mahasiswa live',
                    icon: Icons.analytics_rounded,
                    iconColor: const Color(0xFF2ECC71),
                    targetPage: const HasilPretestPage(),
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
