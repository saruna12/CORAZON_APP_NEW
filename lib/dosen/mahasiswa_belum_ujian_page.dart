import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MahasiswaBelumUjianPage extends StatelessWidget {
  final String jenisUjian;
  final String statusField;

  const MahasiswaBelumUjianPage({
    super.key,
    required this.jenisUjian,
    required this.statusField,
  });

  final Color maroonPrimary = const Color(0xFF6B1D2F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F6),
      appBar: AppBar(
        title: Text(
          'Belum Mengerjakan $jenisUjian',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: maroonPrimary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'mahasiswa')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(color: maroonPrimary));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Gagal memuat data: ${snapshot.error}'));
          }

          final belumMengerjakan = (snapshot.data?.docs ?? []).where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return (data[statusField] ?? 'BELUM DIAMBIL') == 'BELUM DIAMBIL';
          }).toList();

          if (belumMengerjakan.isEmpty) {
            return Center(
              child: Text('Semua mahasiswa sudah mengerjakan $jenisUjian.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: belumMengerjakan.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final data =
                  belumMengerjakan[index].data() as Map<String, dynamic>;
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: maroonPrimary.withValues(alpha: 0.1),
                      child: Icon(Icons.person_outline, color: maroonPrimary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['nama']?.toString() ?? '-',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('NPM: ${data['npm']?.toString() ?? '-'}'),
                          Text(data['email']?.toString() ?? '-',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
