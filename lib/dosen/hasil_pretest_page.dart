import 'package:flutter/material.dart';
import '../pretest_repository.dart'; // Import repository biar datanya sinkron stuy

class HasilPretestPage extends StatelessWidget {
  const HasilPretestPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Setup warna khas tema CORAZON
    const Color maroonPrimary = Color(0xFF6B1D2F);
    const Color textDark = Color(0xFF2C2C2C);

    // Mengambil pretest yang sedang aktif saat ini dari repository stuy
    final activePretest = PretestRepository().getActivePretest();

    // Ambil list nilai dari pretest aktif tersebut, kalau kosong balikkan list kosong
    final listHasil = activePretest != null ? activePretest.results : [];

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F6),
      appBar: AppBar(
        title: const Text(
          'REKAP NILAI MAHASISWA',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
        ),
        backgroundColor: maroonPrimary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: listHasil.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics_outlined, size: 60, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'Belum ada mahasiswa yang mengumpulkan.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Nilai akan otomatis muncul di sini setelah ujian disubmit.',
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: listHasil.length,
              itemBuilder: (context, index) {
                final hasil = listHasil[index];

                // Format tanggal pengerjaan agar lebih enak dibaca stuy
                final waktuSelesai =
                    '${hasil.takenAt.hour.toString().padLeft(2, '0')}:${hasil.takenAt.minute.toString().padLeft(2, '0')} WIB';

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        // Avatar inisial mahasiswa stuy
                        CircleAvatar(
                          backgroundColor: maroonPrimary.withValues(alpha: 0.1),
                          foregroundColor: maroonPrimary,
                          child: Text(hasil.studentName.isNotEmpty
                              ? hasil.studentName[0].toUpperCase()
                              : 'M'),
                        ),
                        const SizedBox(width: 16),

                        // Detail Data Mahasiswa
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hasil.studentName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: textDark,
                                    fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'NPM: ${hasil.studentId}',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 12),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.access_time,
                                      size: 12, color: Colors.grey[400]),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Selesai pada: $waktuSelesai',
                                    style: TextStyle(
                                        color: Colors.grey[500], fontSize: 11),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Skor Nilai Bulat stuy
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: maroonPrimary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'SKOR',
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${hasil.score}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
