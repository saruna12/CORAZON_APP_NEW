import 'package:flutter/material.dart';

class HasilPretestPage extends StatelessWidget {
  final bool isDosen;

  const HasilPretestPage({super.key, this.isDosen = false});

  final Color maroonPrimary = const Color(0xFF6B1D2F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F6),
      appBar: AppBar(
        title: Text(
          isDosen ? 'Pantau Hasil & Perkembangan' : 'Grafik Skor Pretest Anda',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: maroonPrimary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: isDosen
          ? _buildTampilanDosen(context)
          : _buildTampilanMahasiswa(context),
    );
  }

  // ==========================================
  // 👥 1. TAMPILAN DOSEN: REKAP SEMUA MAHASISWA
  // ==========================================
  Widget _buildTampilanDosen(BuildContext context) {
    final List<Map<String, dynamic>> rekapMahasiswa = [
      {
        'nama': 'Ahmad Fauzi',
        'nim': 'G1A022001',
        'pre': 60,
        'post': 90,
        'status': 'Lulus'
      },
      {
        'nama': 'Siti Rahma',
        'nim': 'G1A022002',
        'pre': 45,
        'post': 85,
        'status': 'Lulus'
      },
      {
        'nama': 'Budi Santoso',
        'nim': 'G1A022003',
        'pre': 30,
        'post': 55,
        'status': 'Remedi'
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rekapMahasiswa.length,
      itemBuilder: (context, index) {
        final mhs = rekapMahasiswa[index];
        bool isLulus = mhs['status'] == 'Lulus';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
                color: Colors.grey
                    .shade200), // FIX: Sudah diganti ke 'side' yang benar stuy
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: maroonPrimary.withValues(alpha: 0.1),
                  child: Text(mhs['nama'][0],
                      style: TextStyle(
                          color: maroonPrimary, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(mhs['nama'],
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('NIM: ${mhs['nim']}',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(6)),
                            child: Text('Pre: ${mhs['pre']}',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(6)),
                            child: Text('Post: ${mhs['post']}',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isLulus ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    mhs['status'],
                    style: TextStyle(
                        color: isLulus ? Colors.green : Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // 🎓 2. TAMPILAN MAHASISWA: DIAGRAM PERSONAL
  // ==========================================
  Widget _buildTampilanMahasiswa(BuildContext context) {
    int nilaiPretest = 45;
    int nilaiPosttest = 90;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Grafik Perkembangan Belajar',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              // FIX: Parameter siluman 'maxFiniteArgs' sudah dihapus bersih stuy!
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  children: [
                    Text('$nilaiPretest',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.blue)),
                    const SizedBox(height: 8),
                    Container(
                      width: 45,
                      height: (nilaiPretest * 2).toDouble(),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade400,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Pre-Test',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 12)),
                  ],
                ),
                Column(
                  children: [
                    Text('$nilaiPosttest',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.green)),
                    const SizedBox(height: 8),
                    Container(
                      width: 45,
                      height: (nilaiPosttest * 2).toDouble(),
                      decoration: BoxDecoration(
                        color: Colors.green.shade400,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Post-Test',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt_rounded, color: Colors.green, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Luar biasa stuy! Nilai pemahaman anatomimu meningkat sebesar ${nilaiPosttest - nilaiPretest}% setelah melakukan post-test.',
                    style: TextStyle(
                        color: Colors.green.shade900,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.4),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
