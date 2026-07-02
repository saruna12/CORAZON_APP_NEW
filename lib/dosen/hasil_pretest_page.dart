import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
          isDosen ? 'Pantau Perkembangan Mahasiswa' : 'Grafik Skor Kamu',
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

  // ============================================================
  // 👥 TAMPILAN DOSEN: TABEL REKAP SEMUA MAHASISWA (REAL-TIME)
  // ============================================================
  Widget _buildTampilanDosen(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'mahasiswa')
          .snapshots(),
      builder: (context, snapshot) {
        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: maroonPrimary),
          );
        }

        // Error
        if (snapshot.hasError) {
          return Center(
            child: Text('Gagal memuat data: ${snapshot.error}'),
          );
        }

        // Kosong
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline,
                    size: 60, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text('Belum ada data mahasiswa.',
                    style: TextStyle(color: Colors.grey, fontSize: 14)),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs;

        return Column(
          children: [
            // Header Tabel
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: maroonPrimary,
              child: const Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text('No',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text('Nama, NPM & Email',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                  SizedBox(
                    width: 45,
                    child: Text('Pre',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                  SizedBox(
                    width: 45,
                    child: Text('Post',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                  SizedBox(
                    width: 65,
                    child: Text('Status',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                ],
              ),
            ),

            // List Mahasiswa
            Expanded(
              child: ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  String nama = data['nama'] ?? '-';
                  String npm = data['npm'] ?? '-';
                  String email = data['email'] ?? '-';
                  int nilaiPre = data['nilai_pretest'] ?? 0;
                  int nilaiPost = data['nilai_posttest'] ?? 0;
                  String statusPre = data['status_pretest'] ?? 'BELUM DIAMBIL';
                  String statusPost =
                      data['status_posttest'] ?? 'BELUM DIAMBIL';

                  // Status akhir: lulus kalau keduanya lulus
                  bool sudahKeduanya = statusPre != 'BELUM DIAMBIL' &&
                      statusPost != 'BELUM DIAMBIL';
                  bool lulusKeduanya =
                      statusPre == 'LULUS' && statusPost == 'LULUS';

                  String statusAkhir = !sudahKeduanya
                      ? 'BELUM LENGKAP'
                      : lulusKeduanya
                          ? 'LULUS'
                          : 'TIDAK LULUS';

                  Color statusColor = !sudahKeduanya
                      ? Colors.orange
                      : lulusKeduanya
                          ? Colors.green
                          : Colors.red;

                  bool isGanjil = index % 2 == 0;

                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isGanjil ? Colors.white : const Color(0xFFFAF7F7),
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade100),
                      ),
                    ),
                    child: Row(
                      children: [
                        // No
                        SizedBox(
                          width: 28,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ),

                        // Nama, NPM & Email
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nama,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                npm,
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade500),
                              ),
                              Text(
                                email,
                                style: TextStyle(
                                    fontSize: 10, color: Colors.grey.shade400),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Nilai Pretest
                        SizedBox(
                          width: 45,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusPre == 'BELUM DIAMBIL'
                                  ? Colors.grey.shade100
                                  : Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              statusPre == 'BELUM DIAMBIL' ? '-' : '$nilaiPre',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: statusPre == 'BELUM DIAMBIL'
                                      ? Colors.grey
                                      : Colors.blue.shade700),
                            ),
                          ),
                        ),

                        const SizedBox(width: 45 - 45), // spacer
                        // Nilai Posttest
                        SizedBox(
                          width: 45,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusPost == 'BELUM DIAMBIL'
                                  ? Colors.grey.shade100
                                  : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              statusPost == 'BELUM DIAMBIL'
                                  ? '-'
                                  : '$nilaiPost',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: statusPost == 'BELUM DIAMBIL'
                                      ? Colors.grey
                                      : Colors.green.shade700),
                            ),
                          ),
                        ),

                        // Status Akhir
                        SizedBox(
                          width: 65,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              statusAkhir == 'BELUM LENGKAP'
                                  ? 'PROSES'
                                  : statusAkhir,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // 🎓 TAMPILAN MAHASISWA: GRAFIK PERSONAL (REAL-TIME)
  // ============================================================
  Widget _buildTampilanMahasiswa(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? "";

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        int nilaiPretest = 0;
        int nilaiPosttest = 0;
        String statusPre = 'BELUM DIAMBIL';
        String statusPost = 'BELUM DIAMBIL';

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          nilaiPretest = data['nilai_pretest'] ?? 0;
          nilaiPosttest = data['nilai_posttest'] ?? 0;
          statusPre = data['status_pretest'] ?? 'BELUM DIAMBIL';
          statusPost = data['status_posttest'] ?? 'BELUM DIAMBIL';
        }

        bool sudahKeduanya =
            statusPre != 'BELUM DIAMBIL' && statusPost != 'BELUM DIAMBIL';
        int selisih = nilaiPosttest - nilaiPretest;

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

              // Grafik Bar
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      children: [
                        Text(
                            '${statusPre == 'BELUM DIAMBIL' ? '-' : nilaiPretest}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue)),
                        const SizedBox(height: 8),
                        Container(
                          width: 45,
                          height: statusPre == 'BELUM DIAMBIL'
                              ? 10
                              : (nilaiPretest * 2).toDouble(),
                          decoration: BoxDecoration(
                            color: statusPre == 'BELUM DIAMBIL'
                                ? Colors.grey.shade300
                                : Colors.blue.shade400,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(8)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text('Pre-Test',
                            style: TextStyle(
                                fontWeight: FontWeight.w500, fontSize: 12)),
                        Text(statusPre,
                            style: TextStyle(
                                fontSize: 10,
                                color: statusPre == 'LULUS'
                                    ? Colors.green
                                    : statusPre == 'TIDAK LULUS'
                                        ? Colors.red
                                        : Colors.grey)),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                            '${statusPost == 'BELUM DIAMBIL' ? '-' : nilaiPosttest}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green)),
                        const SizedBox(height: 8),
                        Container(
                          width: 45,
                          height: statusPost == 'BELUM DIAMBIL'
                              ? 10
                              : (nilaiPosttest * 2).toDouble(),
                          decoration: BoxDecoration(
                            color: statusPost == 'BELUM DIAMBIL'
                                ? Colors.grey.shade300
                                : Colors.green.shade400,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(8)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text('Post-Test',
                            style: TextStyle(
                                fontWeight: FontWeight.w500, fontSize: 12)),
                        Text(statusPost,
                            style: TextStyle(
                                fontSize: 10,
                                color: statusPost == 'LULUS'
                                    ? Colors.green
                                    : statusPost == 'TIDAK LULUS'
                                        ? Colors.red
                                        : Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Info perkembangan
              if (sudahKeduanya)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: selisih >= 0
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selisih >= 0
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        color: selisih >= 0 ? Colors.green : Colors.red,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          selisih >= 0
                              ? 'Nilai kamu meningkat sebesar $selisih poin setelah posttest!'
                              : 'Nilai kamu turun ${selisih.abs()} poin. Tetap semangat belajar!',
                          style: TextStyle(
                              color: selisih >= 0
                                  ? Colors.green.shade900
                                  : Colors.red.shade900,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              height: 1.4),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: Colors.amber.shade800, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          statusPre == 'BELUM DIAMBIL'
                              ? 'Kamu belum mengambil pretest maupun posttest.'
                              : 'Kamu sudah mengambil pretest. Segera kerjakan posttest!',
                          style: TextStyle(
                              color: Colors.amber.shade900,
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
