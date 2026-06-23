import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../pretest_repository.dart'; // Mengarah ke file repository di luar folder dosen
import '../import_soal_page.dart'; // ⬅️ FIX: Mundur 1 folder untuk membaca file Import Excel stuy!

class BankSoalPage extends StatefulWidget {
  const BankSoalPage({super.key});

  @override
  State<BankSoalPage> createState() => _BankSoalPageState();
}

class _BankSoalPageState extends State<BankSoalPage> {
  // Setup warna khas tema CORAZON
  final Color maroonPrimary = const Color(0xFF6B1D2F);
  final Color textDark = const Color(0xFF2C2C2C);

  // Controller untuk Form Input Soal Baru
  final _formKey = GlobalKey<FormState>();
  final _pertanyaanController = TextEditingController();
  final List<TextEditingController> _opsiController =
      List.generate(4, (_) => TextEditingController());
  int _jawabanBenarIndex = 0; // 0=A, 1=B, 2=C, 3=D

  // Fungsi memunculkan Bottom Sheet Input Soal ke Firestore
  void _showAddQuestionDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context)
              .viewInsets
              .bottom, // Menghindari ketutup keyboard
          top: 20, left: 16, right: 16,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.add_task, color: maroonPrimary),
                    const SizedBox(width: 10),
                    const Text(
                      'Tambah Soal Pretest Baru',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(),
                TextFormField(
                  controller: _pertanyaanController,
                  decoration: const InputDecoration(
                    labelText: 'Pertanyaan Soal',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                  validator: (v) =>
                      v!.isEmpty ? 'Pertanyaan wajib diisi' : null,
                ),
                const SizedBox(height: 10),
                ...List.generate(4, (index) {
                  String labelOpsi = String.fromCharCode(65 + index);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: TextFormField(
                      controller: _opsiController[index],
                      decoration: InputDecoration(
                        labelText: 'Pilihan Konten Opsi $labelOpsi',
                        prefixIcon: Icon(Icons.arrow_right,
                            color: maroonPrimary, size: 18),
                      ),
                      validator: (v) =>
                          v!.isEmpty ? 'Pilihan $labelOpsi wajib diisi' : null,
                    ),
                  );
                }),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _jawabanBenarIndex,
                  decoration: const InputDecoration(
                    labelText: 'Kunci Jawaban Benar',
                    prefixIcon: Icon(Icons.verified_user_outlined, size: 18),
                  ),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Opsi A')),
                    DropdownMenuItem(value: 1, child: Text('Opsi B')),
                    DropdownMenuItem(value: 2, child: Text('Opsi C')),
                    DropdownMenuItem(value: 3, child: Text('Opsi D')),
                  ],
                  onChanged: (val) => setState(() => _jawabanBenarIndex = val!),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: maroonPrimary,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _simpanSoalKeFirestore,
                  child: const Text(
                    'Simpan Ke Bank Soal',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Menyimpan data ke /bank_soal/paket_utama_pretest/daftar_soal
  void _simpanSoalKeFirestore() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance
          .collection('bank_soal')
          .doc('paket_utama_pretest')
          .collection('daftar_soal')
          .add({
        'pertanyaan': _pertanyaanController.text.trim(),
        'opsi': _opsiController.map((c) => c.text.trim()).toList(),
        'jawaban_benar': _jawabanBenarIndex,
        'created_at':
            FieldValue.serverTimestamp(), // Digunakan untuk urutan orderBy
      });

      if (mounted) {
        Navigator.pop(context); // Tutup bottom sheet setelah sukses
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Soal berhasil disimpan ke Jalur Bank Soal Baru!'),
            backgroundColor: Colors.green,
          ),
        );
        // Reset isi textfield agar bersih saat dibuka kembali
        _pertanyaanController.clear();
        for (var c in _opsiController) {
          c.clear();
        }
      }
    }
  }

  @override
  void dispose() {
    _pertanyaanController.dispose();
    for (var c in _opsiController) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F6),
      appBar: AppBar(
        title: const Text(
          'BANK SOAL ANATOMI',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
        ),
        backgroundColor: maroonPrimary,
        iconTheme: const IconThemeData(color: Colors.white),
        // ➕ Menambahkan tombol navigasi Import Excel di pojok kanan atas AppBar stuy
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ImportSoalPage()),
              );
            },
            icon: const Icon(Icons.drive_folder_upload_rounded,
                color: Colors.white, size: 20),
            label: const Text(
              "Import Excel",
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Sakelar Akses Ujian Live di bagian atas
          Card(
            margin: const EdgeInsets.all(16),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ValueListenableBuilder<bool>(
              valueListenable: PretestRepository.statusUjianLive,
              builder: (context, isLive, child) {
                return SwitchListTile(
                  title: const Text(
                    "Status Akses Pretest Mahasiswa",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    isLive
                        ? "Ujian LIVE (Terbuka)"
                        : "Ujian DITUTUP (Terkunci)",
                    style: const TextStyle(fontSize: 12),
                  ),
                  value: isLive,
                  activeThumbColor: maroonPrimary,
                  activeTrackColor: maroonPrimary.withAlpha(76),
                  onChanged: (value) =>
                      PretestRepository.ubahStatusUjian(value),
                );
              },
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Daftar Soal di Database Baru:",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Mengambil list soal secara live dari sub-collection baru stuy
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bank_soal')
                  .doc('paket_utama_pretest')
                  .collection('daftar_soal')
                  .orderBy('created_at', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Menyaring dokumen agar hanya memproses dokumen soal asli
                var docs = snapshot.data?.docs.where((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      return data.containsKey('pertanyaan');
                    }).toList() ??
                    [];

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                        "Belum ada soal di database baru. Silakan tambah soal."),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, qIndex) {
                    var item = docs[qIndex].data() as Map<String, dynamic>;
                    String pertanyaan = item['pertanyaan'] ?? '';
                    List<String> opsi = List<String>.from(item['opsi'] ?? []);
                    int jawabanBenar = item['jawaban_benar'] ?? 0;

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: maroonPrimary.withAlpha(25),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Pilihan Ganda - No. ${qIndex + 1}',
                                    style: TextStyle(
                                        color: maroonPrimary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const Icon(Icons.more_vert,
                                    color: Colors.grey, size: 20),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              pertanyaan,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                  fontSize: 14),
                            ),
                            const SizedBox(height: 12),
                            ...List.generate(opsi.length, (aIndex) {
                              bool isCorrect = aIndex == jawabanBenar;

                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isCorrect
                                      ? Colors.green[50]
                                      : Colors.grey[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isCorrect
                                        ? Colors.green.shade300
                                        : Colors.grey.shade200,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor: isCorrect
                                          ? Colors.green[600]
                                          : Colors.grey[300],
                                      child: Text(
                                        String.fromCharCode(65 + aIndex),
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        opsi[aIndex],
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isCorrect
                                              ? Colors.green[900]
                                              : textDark,
                                          fontWeight: isCorrect
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    if (isCorrect)
                                      const Icon(Icons.check_circle,
                                          color: Colors.green, size: 18),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: maroonPrimary,
        foregroundColor: Colors.white,
        onPressed: _showAddQuestionDialog,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Soal',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
