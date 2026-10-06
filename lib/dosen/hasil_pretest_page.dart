import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pretest_repository.dart';

class HasilPretestPage extends StatefulWidget {
  final bool isDosen;
  const HasilPretestPage({super.key, this.isDosen = false});

  @override
  State<HasilPretestPage> createState() => _HasilPretestPageState();
}

class _HasilPretestPageState extends State<HasilPretestPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final Color maroonPrimary = const Color(0xFF6B1D2F);
  final Stream<DocumentSnapshot> _classSettingsStream = FirebaseFirestore
      .instance
      .collection('class_settings')
      .doc('app')
      .snapshots();
  final Stream<QuerySnapshot> _usersStream = FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: 'mahasiswa')
      .snapshots();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _tampilkanJawabanPosttest(
      String userId, Map<String, dynamic> data) async {
    final jawabanRaw = data['jawaban_posttest'];
    final jawaban = jawabanRaw is List
        ? jawabanRaw.whereType<Map>().map((item) {
            return Map<String, dynamic>.from(item);
          }).toList()
        : <Map<String, dynamic>>[];
    final nilaiLama = (data['nilai_posttest'] as num?)?.toInt();
    final nilaiController = TextEditingController(
      text: nilaiLama?.toString() ?? '',
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(nilaiLama == null
            ? 'Nilai Posttest - ${data['nama'] ?? '-'}'
            : 'Edit Nilai Posttest - ${data['nama'] ?? '-'}'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (jawaban.isEmpty)
                  const Text('Belum ada jawaban posttest yang tersimpan.')
                else
                  for (var index = 0; index < jawaban.length; index++) ...[
                    Text(
                      'Soal ${index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(jawaban[index]['pertanyaan']?.toString() ?? '-'),
                    const SizedBox(height: 6),
                    Text(
                      jawaban[index]['jawaban_mahasiswa']?.toString() ??
                          '(Tidak dijawab)',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    if (index < jawaban.length - 1)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(),
                      ),
                  ],
                const SizedBox(height: 16),
                TextField(
                  controller: nilaiController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Nilai akhir',
                    hintText: 'Contoh: 85',
                    suffixText: 'poin',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: maroonPrimary),
            onPressed: () async {
              final nilai = num.tryParse(nilaiController.text.trim());
              if (nilai == null || nilai < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Nilai harus berupa angka valid.')),
                );
                return;
              }
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .set({
                'nilai_posttest': nilai,
                'status_posttest': 'SELESAI',
                'nilai_akhir': nilai,
                'waktu_penilaian_posttest': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Nilai posttest berhasil disimpan.')),
                );
              }
            },
            child: const Text('Simpan Nilai',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    nilaiController.dispose();
  }

  void _tampilkanEvaluasiMahasiswa(Map<String, dynamic> data) {
    final jawabanRaw = data['jawaban_posttest'];
    final jawaban = jawabanRaw is List
        ? jawabanRaw.whereType<Map>().map(Map<String, dynamic>.from).toList()
        : <Map<String, dynamic>>[];

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Evaluasi Posttest'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nilai: ${data['nilai_posttest'] ?? 0} poin',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(height: 16),
                for (var index = 0; index < jawaban.length; index++) ...[
                  Text('Soal ${index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(jawaban[index]['pertanyaan']?.toString() ?? '-'),
                  const SizedBox(height: 6),
                  Text(
                    'Jawaban kamu: ${jawaban[index]['jawaban_mahasiswa'] ?? '(Tidak dijawab)'}',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  if (index < jawaban.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(),
                    ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F6),
      appBar: AppBar(
        title: Text(
          widget.isDosen ? 'Pantau Perkembangan Mahasiswa' : 'Grafik Skor Kamu',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: maroonPrimary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: widget.isDosen
          ? _buildTampilanDosen(context)
          : _buildTampilanMahasiswa(context),
    );
  }

  // ============================================================
  // 👥 TAMPILAN DOSEN: TABEL REKAP SEMUA MAHASISWA (REAL-TIME)
  // ============================================================
  Widget _buildTampilanDosen(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _classSettingsStream,
      builder: (context, classSettingsSnapshot) {
        final activeClassCode = classSettingsSnapshot.data?.data() is Map
            ? ((classSettingsSnapshot.data!.data()
                        as Map<String, dynamic>)['active_code']
                    ?.toString()
                    .trim()
                    .toLowerCase() ??
                '')
            : '';

        return StreamBuilder<QuerySnapshot>(
          stream: _usersStream,
          builder: (context, snapshot) {
            // Loading
            if (classSettingsSnapshot.connectionState ==
                    ConnectionState.waiting ||
                snapshot.connectionState == ConnectionState.waiting) {
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

            final docs = (snapshot.data?.docs ?? []).where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final classCode =
                  data['class_code']?.toString().trim().toLowerCase();
              return activeClassCode.isNotEmpty && classCode == activeClassCode;
            }).toList();
            final query = _searchQuery.trim().toLowerCase();
            final filteredDocs = docs.where((doc) {
              if (query.isEmpty) return true;
              final data = doc.data() as Map<String, dynamic>;
              final searchableText = [
                data['nama'],
                data['npm'],
                data['email'],
              ]
                  .where((value) => value != null)
                  .map((value) => value.toString())
                  .join(' ')
                  .toLowerCase();
              return searchableText.contains(query);
            }).toList();

            if (docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline,
                        size: 60, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text('Belum ada data mahasiswa di kelas aktif.',
                        style: TextStyle(color: Colors.grey, fontSize: 14)),
                  ],
                ),
              );
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Cari nama, NPM, atau email mahasiswa',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchQuery.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Hapus pencarian',
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                  ),
                ),
                if (filteredDocs.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text(
                          'Tidak ada mahasiswa yang cocok dengan pencarian.'),
                    ),
                  )
                else ...[
                  // Header Tabel
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
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
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) {
                        final data =
                            filteredDocs[index].data() as Map<String, dynamic>;
                        String nama = data['nama'] ?? '-';
                        String npm = data['npm'] ?? '-';
                        String email = data['email'] ?? '-';
                        int nilaiPre =
                            (data['nilai_pretest'] as num?)?.toInt() ?? 0;
                        int nilaiPost =
                            (data['nilai_posttest'] as num?)?.toInt() ?? 0;
                        String statusPre =
                            data['status_pretest'] ?? 'BELUM DIAMBIL';
                        String statusPost =
                            data['status_posttest'] ?? 'BELUM DIAMBIL';
                        final punyaJawabanPosttest =
                            data['jawaban_posttest'] is List &&
                                (data['jawaban_posttest'] as List).isNotEmpty;

                        // Status selesai hanya jika kedua ujian sudah dinilai.
                        final sudahNilaiPretest = statusPre == 'SELESAI' &&
                            data['nilai_pretest'] is num;
                        final sudahNilaiPosttest = statusPost == 'SELESAI' &&
                            data['nilai_posttest'] is num;
                        bool sudahKeduanya =
                            sudahNilaiPretest && sudahNilaiPosttest;
                        String statusAkhir =
                            sudahKeduanya ? 'SELESAI' : 'PROSES';
                        Color statusColor =
                            sudahKeduanya ? Colors.green : Colors.orange;

                        bool isGanjil = index % 2 == 0;

                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isGanjil
                                ? Colors.white
                                : const Color(0xFFFAF7F7),
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
                                      fontSize: 12,
                                      color: Colors.grey.shade600),
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
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      npm,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade500),
                                    ),
                                    Text(
                                      email,
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey.shade400),
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
                                    color: statusPre != 'SELESAI'
                                        ? Colors.grey.shade100
                                        : Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    statusPre != 'SELESAI' ? '-' : '$nilaiPre',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: statusPre != 'SELESAI'
                                            ? Colors.grey
                                            : Colors.blue.shade700),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 45 - 45), // spacer
                              // Nilai Posttest sekaligus tombol lihat/edit nilai.
                              SizedBox(
                                width: 45,
                                child: GestureDetector(
                                  onTap: punyaJawabanPosttest
                                      ? () => _tampilkanJawabanPosttest(
                                          filteredDocs[index].id, data)
                                      : null,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusPost != 'SELESAI'
                                          ? Colors.grey.shade100
                                          : Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      statusPost != 'SELESAI'
                                          ? '-'
                                          : '$nilaiPost',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: statusPost != 'SELESAI'
                                              ? Colors.grey
                                              : Colors.green.shade700),
                                    ),
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
                                    statusAkhir,
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
              ],
            );
          },
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
        num nilaiPretest = 0;
        num nilaiPosttest = 0;
        String statusPre = 'BELUM DIAMBIL';
        String statusPost = 'BELUM DIAMBIL';

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          nilaiPretest = (data['nilai_pretest'] as num?) ?? 0;
          nilaiPosttest = (data['nilai_posttest'] as num?) ?? 0;
          statusPre = data['status_pretest'] ?? 'BELUM DIAMBIL';
          statusPost = data['status_posttest'] ?? 'BELUM DIAMBIL';
        }

        bool sudahKeduanya = statusPre == 'SELESAI' && statusPost == 'SELESAI';
        num selisih = nilaiPosttest - nilaiPretest;

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
                        Text('${statusPre == 'SELESAI' ? nilaiPretest : '-'}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue)),
                        const SizedBox(height: 8),
                        Container(
                          width: 45,
                          height: statusPre != 'SELESAI'
                              ? 10
                              : (nilaiPretest * 2).toDouble(),
                          decoration: BoxDecoration(
                            color: statusPre != 'SELESAI'
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
                                color: statusPre == 'SELESAI'
                                    ? Colors.green
                                    : Colors.grey)),
                      ],
                    ),
                    Column(
                      children: [
                        Text('${statusPost == 'SELESAI' ? nilaiPosttest : '-'}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green)),
                        const SizedBox(height: 8),
                        Container(
                          width: 45,
                          height: statusPost != 'SELESAI'
                              ? 10
                              : (nilaiPosttest * 2).toDouble(),
                          decoration: BoxDecoration(
                            color: statusPost != 'SELESAI'
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
                                color: statusPost == 'SELESAI'
                                    ? Colors.green
                                    : Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              if (statusPost == 'SELESAI')
                ValueListenableBuilder<bool>(
                  valueListenable: PretestRepository.statusPosttestLive,
                  builder: (context, isPosttestLive, child) {
                    if (isPosttestLive) return const SizedBox.shrink();
                    return SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.rate_review_outlined),
                        label: const Text('Lihat Evaluasi Posttest'),
                        onPressed: () => _tampilkanEvaluasiMahasiswa(
                            snapshot.data!.data() as Map<String, dynamic>),
                      ),
                    );
                  },
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
