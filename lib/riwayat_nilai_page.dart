import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Halaman ini menampilkan RIWAYAT lengkap semua percobaan pretest & postest
// mahasiswa dalam bentuk tabel: No, Jenis, Tanggal, Waktu Pengerjaan, Nilai, Status.
// Datanya diambil dari sub-collection:
//   users/{uid}/riwayat_pretest
//   users/{uid}/riwayat_posttest
class RiwayatNilaiPage extends StatelessWidget {
  const RiwayatNilaiPage({super.key});

  final Color maroonPrimary = const Color(0xFF6B1D2F);

  String _formatTanggal(Timestamp? ts) {
    if (ts == null) return '-';
    final d = ts.toDate();
    return '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String _formatDurasi(int? detik) {
    if (detik == null || detik == 0) return '-';
    final menit = detik ~/ 60;
    final sisaDetik = detik % 60;
    if (menit > 0) return '$menit menit $sisaDetik detik';
    return '$sisaDetik detik';
  }

  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F6),
      appBar: AppBar(
        title: const Text('Riwayat Nilai Saya',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        backgroundColor: maroonPrimary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: userId.isEmpty
          ? const Center(child: Text('Kamu belum login.'))
          : StreamBuilder<QuerySnapshot>(
              // Gabungkan dua sumber data tidak bisa langsung via satu query Firestore,
              // jadi kita listen dua-duanya lalu digabung di client.
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('riwayat_pretest')
                  .orderBy('tanggal', descending: true)
                  .snapshots(),
              builder: (context, pretestSnap) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .collection('riwayat_posttest')
                      .orderBy('tanggal', descending: true)
                      .snapshots(),
                  builder: (context, posttestSnap) {
                    if (pretestSnap.connectionState ==
                            ConnectionState.waiting ||
                        posttestSnap.connectionState ==
                            ConnectionState.waiting) {
                      return Center(
                          child:
                              CircularProgressIndicator(color: maroonPrimary));
                    }

                    // Gabungkan semua riwayat jadi satu list dengan label jenis
                    List<Map<String, dynamic>> gabungan = [];

                    if (pretestSnap.hasData) {
                      for (var doc in pretestSnap.data!.docs) {
                        final d = doc.data() as Map<String, dynamic>;
                        gabungan.add({
                          'jenis': 'Pretest',
                          'tanggal': d['tanggal'] as Timestamp?,
                          'nilai': d['nilai'] ?? 0,
                          'status': d['status'] ?? '-',
                          'durasi_detik': d['durasi_detik'] ?? 0,
                        });
                      }
                    }
                    if (posttestSnap.hasData) {
                      for (var doc in posttestSnap.data!.docs) {
                        final d = doc.data() as Map<String, dynamic>;
                        gabungan.add({
                          'jenis': 'Postest',
                          'tanggal': d['tanggal'] as Timestamp?,
                          'nilai': d['nilai'] ?? 0,
                          'status': d['status'] ?? '-',
                          'durasi_detik': d['durasi_detik'] ?? 0,
                        });
                      }
                    }

                    // Urutkan gabungan berdasarkan tanggal terbaru
                    gabungan.sort((a, b) {
                      final ta = a['tanggal'] as Timestamp?;
                      final tb = b['tanggal'] as Timestamp?;
                      if (ta == null || tb == null) return 0;
                      return tb.compareTo(ta);
                    });

                    if (gabungan.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history_rounded,
                                  size: 60, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              const Text(
                                'Belum ada riwayat pretest maupun postest.',
                                style:
                                    TextStyle(color: Colors.grey, fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor:
                              WidgetStateProperty.all(maroonPrimary),
                          headingTextStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                          dataTextStyle: const TextStyle(fontSize: 12),
                          columns: const [
                            DataColumn(label: Text('No')),
                            DataColumn(label: Text('Jenis')),
                            DataColumn(label: Text('Tanggal Mulai')),
                            DataColumn(label: Text('Waktu Pengerjaan')),
                            DataColumn(label: Text('Nilai')),
                            DataColumn(label: Text('Status')),
                          ],
                          rows:
                              List<DataRow>.generate(gabungan.length, (index) {
                            final item = gabungan[index];
                            final bool lulus = item['status'] == 'LULUS';
                            return DataRow(cells: [
                              DataCell(Text('${index + 1}')),
                              DataCell(Text(item['jenis'])),
                              DataCell(Text(_formatTanggal(item['tanggal']))),
                              DataCell(
                                  Text(_formatDurasi(item['durasi_detik']))),
                              DataCell(Text('${item['nilai']}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold))),
                              DataCell(Text(
                                item['status'],
                                style: TextStyle(
                                  color: lulus ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              )),
                            ]);
                          }),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
