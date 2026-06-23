import 'package:flutter/material.dart';
import 'pretest_repository.dart';
import 'kuis_pretest_page.dart';

class PretestPage extends StatefulWidget {
  const PretestPage({super.key});

  @override
  State<PretestPage> createState() => _PretestPageState();
}

class _PretestPageState extends State<PretestPage> {
  final Color maroonPrimary = const Color(0xFF6B1D2F);

  @override
  void initState() {
    super.initState();
    // Jalankan listener agar status 'is_live' dari Firestore terpantau real-time stuy
    PretestRepository.listenStatusUjian();
  }

  @override
  Widget build(BuildContext context) {
    // SEMENTARA: Ganti dengan ID mahasiswa asli hasil dari proses login autentikasi kamu stuy
    const String dummyUserId = "mhs_corazon_001";

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F6),
      appBar: AppBar(
        title: const Text('Halaman Pretest',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: maroonPrimary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.assignment_rounded,
                      size: 80, color: maroonPrimary),
                  const SizedBox(height: 16),
                  const Text(
                    "Pretest Anatomi CORAZON",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Kuis ini terdiri dari 5 soal acak yang dipilih langsung oleh sistem. Waktu pengerjaan adalah 10 menit stuy.",
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // 📡 Memantau status LIVE ujian secara real-time dari repository
                  ValueListenableBuilder<bool>(
                    valueListenable: PretestRepository.statusUjianLive,
                    builder: (context, isLive, child) {
                      if (!isLive) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.lock_clock_rounded,
                                  color: Colors.amber.shade800),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Ujian belum dibuka oleh Dosen. Silakan tunggu info selanjutnya stuy.",
                                  style: TextStyle(
                                      color: Colors.amber.shade900,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: maroonPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.play_arrow_rounded,
                              color: Colors.white),
                          label: const Text(
                            "Mulai Kerjakan Kuis",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                          onPressed: () {
                            // Pindah ke halaman pengerjaan kuis stuy!
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const KuisPretestPage(userId: dummyUserId),
                              ),
                            );
                          },
                        ),
                      );
                    },
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
