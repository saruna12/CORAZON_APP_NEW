import 'package:flutter/material.dart';
import '../pretest_repository.dart'; // Sesuaikan path repositorimu stuy
// ⚠️ SILAKAN GANTI IMPORT DI BAWAH INI DENGAN FILE HALAMAN SOAL/KUIS ASLIMU STUY!
// Contoh: import 'kuis_pretest_page.dart';

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
    // 🟢 KUNCI UTAMA: Nyalakan pendengar aliran data Firestore di sisi mahasiswa stuy!
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
              'Mohon tunggu ya stuy! Dosen atau laboran belum mengaktifkan sesi ujian ini. Harap standby di ruangan Lab.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  // 🏁 TAMPILAN SEBELUM MULAI (ABA-ABA)
  Widget _buildScreenSiapMulai(BuildContext context) {
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
                  Icons.timer_rounded, 'Durasi Pengerjaan', '15 Menit'),
              const SizedBox(height: 8),
              _buildInfoRow(
                  Icons.rule_rounded, 'Batas Kelulusan', 'Minimal Skor 70'),
              const SizedBox(height: 24),

              // TOMBOL ABA-ABA UNTUK MULAI MASUK KE SOAL
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: maroonPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    // 🟢 HUBUNGKAN KE HALAMAN KUIS ASLI KAMU STUY
                    // Ganti PlaceholderWidget() dengan KuisPretestPage() yang ada di struktur lib folder kamu
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PlaceholderWidget()),
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

class PlaceholderWidget extends StatelessWidget {
  const PlaceholderWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
        body: Center(child: Text('Halaman Kuis Belum Dihubungkan stuy!')));
  }
}
