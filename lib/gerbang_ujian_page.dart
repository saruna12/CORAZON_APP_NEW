import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pretest_repository.dart';
import 'kuis_pretest_page.dart'; // ✅ FIX: Import halaman kuis yang asli

class GerbangUjianPage extends StatefulWidget {
  final bool isPretest; // true untuk Pretest, false untuk Posttest

  const GerbangUjianPage({super.key, required this.isPretest});

  @override
  State<GerbangUjianPage> createState() => _GerbangUjianPageState();
}

class _GerbangUjianPageState extends State<GerbangUjianPage> {
  final Color maroonPrimary = const Color(0xFF6B1D2F);

  @override
  void initState() {
    super.initState();
    PretestRepository.listenStatusUjian();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F6),
      appBar: AppBar(
        title: Text(
          widget.isPretest
              ? 'Pretest Syarat Masuk Lab'
              : 'Posttest Pembelajaran',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: maroonPrimary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: PretestRepository.statusUjianLive,
        builder: (context, isOpen, child) {
          if (!isOpen) {
            return _buildScreenTerkunci();
          } else {
            return _buildScreenSiapMulai(context);
          }
        },
      ),
    );
  }

  // 🔒 TAMPILAN AKSES BELUM DIBUKA
  Widget _buildScreenTerkunci() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_clock_rounded,
                size: 80, color: maroonPrimary.withValues(alpha: 0.4)),
            const SizedBox(height: 24),
            const Text(
              'Akses Ujian Belum Dibuka',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Mohon tunggu! Dosen atau laboran belum mengaktifkan sesi ujian ini. Harap standby di ruangan Lab.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  // 🏁 TAMPILAN SEBELUM MULAI
  Widget _buildScreenSiapMulai(BuildContext context) {
    // ✅ FIX: Ambil userId dari Firebase Auth
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.assignment_turned_in_rounded,
                    color: Colors.green, size: 40),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sesi Ujian Telah Dibuka!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              _buildInfoRow(
                  Icons.timer_rounded, 'Durasi Pengerjaan', '10 Menit'),
              const SizedBox(height: 8),
              _buildInfoRow(
                  Icons.rule_rounded, 'Batas Kelulusan', 'Minimal Skor 70'),
              const SizedBox(height: 24),

              // ✅ FIX: Warning jika belum login
              if (userId.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_rounded, color: Colors.red.shade700),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Kamu belum login. Silakan login terlebih dahulu.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // TOMBOL MULAI
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        userId.isEmpty ? Colors.grey : maroonPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  // ✅ FIX: Hubungkan ke KuisPretestPage yang asli
                  onPressed: userId.isEmpty
                      ? null
                      : () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  KuisPretestPage(userId: userId),
                            ),
                          );
                        },
                  child: const Text(
                    'MULAI UJIAN SEKARANG',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const Spacer(),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}
