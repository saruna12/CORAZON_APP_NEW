import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel_pkg;

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
  final _bobotController = TextEditingController(text: '20');
  final List<TextEditingController> _opsiController =
      List.generate(4, (_) => TextEditingController());
  int _jawabanBenarIndex = 0; // 0=A, 1=B, 2=C, 3=D
  String _jenisSoalPilihan = 'pretest'; // Opsi: pretest, posttest, keduanya

  // Untuk Import Excel
  PlatformFile? _fileTerpilih;
  bool _isUploading = false;
  String _statusPesan = "";
  String _jenisImport = 'pretest'; // pretest atau posttest

  // Helper: Konversi kunci dari Excel (A-D atau 0-3) ke indeks
  int _konversiKunciKeIndeks(dynamic value) {
    if (value == null) return 0;
    String nilaiString = value.toString().trim().toUpperCase();
    if (nilaiString == '0') return 0;
    if (nilaiString == '1') return 1;
    if (nilaiString == '2') return 2;
    if (nilaiString == '3') return 3;
    switch (nilaiString) {
      case 'A':
        return 0;
      case 'B':
        return 1;
      case 'C':
        return 2;
      case 'D':
        return 3;
      default:
        return 0;
    }
  }

  // Fungsi memilih file Excel (.xlsx)
  Future<void> _pilihFileExcel() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );

      if (result != null) {
        setState(() {
          _fileTerpilih = result.files.first;
          _statusPesan = "File Excel siap diimport!";
        });
      }
    } catch (e) {
      setState(() {
        _statusPesan = "❌ Gagal memilih file: $e";
      });
    }
  }

  // Fungsi import Excel ke bank_soal/daftar_soal dengan field jenis_soal
  Future<void> _prosesImportExcel() async {
    if (_fileTerpilih == null) return;

    setState(() {
      _isUploading = true;
      _statusPesan = "Sedang membaca file Excel...";
    });

    try {
      List<int> bytes;

      if (kIsWeb) {
        if (_fileTerpilih!.bytes == null) {
          setState(() {
            _isUploading = false;
            _statusPesan =
                "❌ Gagal: Data file tidak terbaca. Coba pilih file ulang.";
          });
          return;
        }
        bytes = _fileTerpilih!.bytes!;
      } else {
        if (_fileTerpilih!.path == null) {
          setState(() {
            _isUploading = false;
            _statusPesan = "❌ Gagal: Path file tidak ditemukan.";
          });
          return;
        }
        bytes = File(_fileTerpilih!.path!).readAsBytesSync();
      }

      var excel = excel_pkg.Excel.decodeBytes(bytes);
      String sheetName = excel.tables.keys.first;
      var table = excel.tables[sheetName];

      if (table == null || table.maxRows <= 1) {
        throw "File Excel kosong atau format tidak sesuai.";
      }

      int jumlahSoalBerhasil = 0;
      WriteBatch batch = FirebaseFirestore.instance.batch();

      // Simpan pretest dan posttest pada paket yang dibaca masing-masing alur.
      CollectionReference collectionTarget = FirebaseFirestore.instance
          .collection('bank_soal')
          .doc(_jenisImport == 'posttest'
              ? 'paket_utama_posttest'
              : 'paket_utama_pretest')
          .collection('daftar_soal');

      // Iterasi baris Excel
      for (int i = 1; i < table.maxRows; i++) {
        var row = table.rows[i];

        final isPosttest = _jenisImport == 'posttest';
        if ((!isPosttest && row.length < 7) || (isPosttest && row.length < 2)) {
          continue;
        }

        // REVISI: cellNo dan nomorStr dihapus karena tidak terpakai (Menghilangkan Warning)
        var cellSoal = row[1]?.value;
        var cellA = isPosttest ? null : row[2]?.value;
        var cellB = isPosttest ? null : row[3]?.value;
        var cellC = isPosttest ? null : row[4]?.value;
        var cellD = isPosttest ? null : row[5]?.value;
        var cellKunci = isPosttest ? null : row[6]?.value;

        String soalStr = cellSoal?.toString().trim() ?? "";

        if (soalStr.isEmpty) {
          continue;
        }

        DocumentReference docRef = collectionTarget.doc();

        if (isPosttest) {
          final bobot = num.tryParse(
                  row.length > 2 ? row[2]?.value?.toString() ?? '' : '') ??
              20;
          batch.set(docRef, {
            'pertanyaan': soalStr,
            'tipe': 'essay',
            'bobot': bobot,
            'created_at': FieldValue.serverTimestamp(),
          });
        } else {
          String opsiA = cellA?.toString().trim() ?? "";
          String opsiB = cellB?.toString().trim() ?? "";
          String opsiC = cellC?.toString().trim() ?? "";
          String opsiD = cellD?.toString().trim() ?? "";
          int jawabanBenarIndeks = _konversiKunciKeIndeks(cellKunci);

          batch.set(docRef, {
            'pertanyaan': soalStr,
            'opsi': [opsiA, opsiB, opsiC, opsiD],
            'jawaban_benar': jawabanBenarIndeks,
            'jenis_soal': 'pretest',
            'created_at': FieldValue.serverTimestamp(),
          });
        }

        jumlahSoalBerhasil++;
      }

      if (jumlahSoalBerhasil > 0) {
        await batch.commit();
        setState(() {
          _isUploading = false;
          _fileTerpilih = null;
          _statusPesan = "";
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '$jumlahSoalBerhasil soal $_jenisImport berhasil ditambahkan.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _isUploading = false;
          _statusPesan = "❌ Gagal: Tidak ada baris soal valid yang ditemukan.";
        });
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _statusPesan = "❌ Error: $e";
      });
    }
  }

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
                    Text(
                      _jenisSoalPilihan == 'posttest'
                          ? 'Tambah Soal Essay Posttest'
                          : 'Tambah Soal Pilihan Ganda Pretest',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
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
                if (_jenisSoalPilihan != 'posttest') ...[
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
                        validator: (v) => v!.isEmpty
                            ? 'Pilihan $labelOpsi wajib diisi'
                            : null,
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
                    onChanged: (val) =>
                        setState(() => _jawabanBenarIndex = val!),
                  ),
                ],
                if (_jenisSoalPilihan == 'posttest')
                  TextFormField(
                    controller: _bobotController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Bobot Nilai',
                      prefixIcon: Icon(Icons.score_outlined),
                    ),
                    validator: (value) {
                      final bobot = num.tryParse(value?.trim() ?? '');
                      return bobot == null || bobot <= 0
                          ? 'Bobot harus berupa angka positif'
                          : null;
                    },
                  ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _jenisSoalPilihan,
                  decoration: const InputDecoration(
                    labelText: 'Jenis Soal',
                    prefixIcon: Icon(Icons.category_rounded, size: 18),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'pretest', child: Text('Pretest')),
                    DropdownMenuItem(
                        value: 'posttest', child: Text('Posttest')),
                  ],
                  onChanged: (val) => setState(() {
                    _jenisSoalPilihan = val!;
                    _jenisImport = val == 'posttest' ? 'posttest' : 'pretest';
                  }),
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

  // Menyimpan data ke paket bank soal sesuai jenis ujian.
  void _simpanSoalKeFirestore() async {
    if (_formKey.currentState!.validate()) {
      final isPosttest = _jenisSoalPilihan == 'posttest';
      final data = <String, dynamic>{
        'pertanyaan': _pertanyaanController.text.trim(),
        'created_at': FieldValue.serverTimestamp(),
      };
      if (isPosttest) {
        data['tipe'] = 'essay';
        data['bobot'] = num.parse(_bobotController.text.trim());
      } else {
        data['opsi'] = _opsiController.map((c) => c.text.trim()).toList();
        data['jawaban_benar'] = _jawabanBenarIndex;
        data['jenis_soal'] = 'pretest';
      }

      await FirebaseFirestore.instance
          .collection('bank_soal')
          .doc(isPosttest ? 'paket_utama_posttest' : 'paket_utama_pretest')
          .collection('daftar_soal')
          .add(data);

      if (mounted) {
        Navigator.pop(context); // Tutup bottom sheet setelah sukses
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Soal $_jenisSoalPilihan berhasil disimpan!'),
            backgroundColor: Colors.green,
          ),
        );
        // Reset isi textfield agar bersih saat dibuka kembali
        _pertanyaanController.clear();
        for (var c in _opsiController) {
          c.clear();
        }
        _bobotController.text = '20';
        setState(() {
          _jenisSoalPilihan = 'pretest'; // Reset ke default
        });
      }
    }
  }

  Future<void> _hapusSoal(String soalId, String pertanyaan) async {
    final setujuHapus = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Soal'),
        content: Text('Yakin ingin menghapus soal ini?\n\n$pertanyaan'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (setujuHapus != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('bank_soal')
          .doc(_jenisImport == 'posttest'
              ? 'paket_utama_posttest'
              : 'paket_utama_pretest')
          .collection('daftar_soal')
          .doc(soalId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Soal berhasil dihapus.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus soal: $error')),
        );
      }
    }
  }

  @override
  void dispose() {
    _pertanyaanController.dispose();
    for (var c in _opsiController) {
      c.dispose();
    }
    _bobotController.dispose();
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
      ),
      body: Column(
        children: [
          // Tombol Import Excel
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _jenisImport,
                    decoration: InputDecoration(
                      labelText: 'Tipe Import',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'pretest', child: Text('Pretest')),
                      DropdownMenuItem(
                          value: 'posttest', child: Text('Posttest')),
                    ],
                    onChanged: (val) => setState(() => _jenisImport = val!),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B1D2F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  onPressed: _pilihFileExcel,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Pilih File'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  onPressed: _isUploading ? null : _prosesImportExcel,
                  icon: _isUploading
                      ? const Icon(Icons.sync)
                      : const Icon(Icons.check),
                  label: Text(_isUploading ? 'Proses...' : 'Import'),
                ),
              ],
            ),
          ),

          if (_statusPesan.isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _statusPesan.contains('BERHASIL')
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _statusPesan.contains('BERHASIL')
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
                child: Text(
                  _statusPesan,
                  style: TextStyle(
                    color: _statusPesan.contains('BERHASIL')
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18.0, vertical: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Daftar Soal:",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Mengambil soal dari paket sesuai tipe import yang dipilih.
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bank_soal')
                  .doc(_jenisImport == 'posttest'
                      ? 'paket_utama_posttest'
                      : 'paket_utama_pretest')
                  .collection('daftar_soal')
                  .orderBy('created_at', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Tampilkan hanya tipe soal yang sesuai dengan pilihan dropdown.
                final isPosttest = _jenisImport == 'posttest';
                var docs = snapshot.data?.docs.where((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      final isEssay = data['tipe'] == 'essay';
                      return data.containsKey('pertanyaan') &&
                          (isPosttest ? isEssay : !isEssay);
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
                    final isEssay = item['tipe'] == 'essay';
                    List<String> opsi = List<String>.from(item['opsi'] ?? []);
                    int jawabanBenar = item['jawaban_benar'] ?? 0;
                    String jenisSoal = isEssay
                        ? 'posttest essay'
                        : (item['jenis_soal'] ?? 'pretest');

                    Color badgeColor;
                    if (jenisSoal == 'pretest') {
                      badgeColor = Colors.blue;
                    } else if (jenisSoal == 'posttest') {
                      badgeColor = Colors.orange;
                    } else {
                      badgeColor = Colors.purple;
                    }

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
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: maroonPrimary.withAlpha(25),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'No. ${qIndex + 1}',
                                        style: TextStyle(
                                            color: maroonPrimary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: badgeColor.withAlpha(25),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        jenisSoal.toUpperCase(),
                                        style: TextStyle(
                                            color: badgeColor,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                PopupMenuButton<String>(
                                  tooltip: 'Opsi soal',
                                  onSelected: (value) {
                                    if (value == 'hapus') {
                                      _hapusSoal(docs[qIndex].id, pertanyaan);
                                    }
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: 'hapus',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline,
                                              color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Hapus'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
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
                            if (isEssay)
                              Text(
                                'Bobot: ${item['bobot'] ?? 20} poin',
                                style: TextStyle(
                                    color: Colors.orange.shade800,
                                    fontWeight: FontWeight.w600),
                              )
                            else
                              ...List.generate(opsi.length, (aIndex) {
                                bool isCorrect = aIndex == jawabanBenar;

                                return Container(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4),
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
