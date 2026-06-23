import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:cloud_firestore/cloud_firestore.dart';

class ImportSoalPage extends StatefulWidget {
  const ImportSoalPage({super.key});

  @override
  State<ImportSoalPage> createState() => _ImportSoalPageState();
}

class _ImportSoalPageState extends State<ImportSoalPage> {
  final Color maroonPrimary = const Color(0xFF6B1D2F);

  PlatformFile? _fileTerpilih;
  bool _isUploading = false;
  String _statusPesan = "";

  // 1. Fungsi memilih file Excel (.xlsx) dari penyimpanan stuy
  Future<void> _pilihFileExcel() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result != null) {
        setState(() {
          _fileTerpilih = result.files.first;
          _statusPesan = "File siap diimport stuy!";
        });
      }
    } catch (e) {
      setState(() {
        _statusPesan = "Gagal memilih file: $e";
      });
    }
  }

  // 2. Fungsi membaca file Excel dan mengirim datanya ke Cloud Firestore
  Future<void> _prosesImportExcel() async {
    if (_fileTerpilih == null) return;

    setState(() {
      _isUploading = true;
      _statusPesan = "Sedang membaca file Excel...";
    });

    try {
      List<int> bytes;

      // Mengatasi pembacaan file berdasarkan platform (Web / Mobile)
      if (kIsWeb) {
        bytes = _fileTerpilih!.bytes!;
      } else {
        bytes = File(_fileTerpilih!.path!).readAsBytesSync();
      }

      var excel = excel_pkg.Excel.decodeBytes(bytes);
      String sheetName = excel.tables.keys.first;
      var table = excel.tables[sheetName];

      if (table == null || table.maxRows <= 1) {
        throw "File Excel kosong atau format tidak sesuai stuy.";
      }

      int jumlahSoalBerhasil = 0;
      WriteBatch batch = FirebaseFirestore.instance.batch();
      CollectionReference collectionTarget = FirebaseFirestore.instance
          .collection('bank_soal')
          .doc('paket_utama_pretest')
          .collection('daftar_soal');

      // Iterasi baris Excel (Mulai dari indeks 1 untuk melewati judul kolom/header)
      for (int i = 1; i < table.maxRows; i++) {
        var row = table.rows[i];

        // Memastikan kolom pertanyaan (indeks 1) tidak kosong
        if (row.length > 1 && row[1]?.value != null) {
          String soal = row[1]!.value.toString();
          String opsiA = row[2]?.value?.toString() ?? "";
          String opsiB = row[3]?.value?.toString() ?? "";
          String opsiC = row[4]?.value?.toString() ?? "";
          String opsiD = row[5]?.value?.toString() ?? "";
          String kunci = row[6]?.value?.toString() ?? "";

          DocumentReference docRef = collectionTarget.doc();

          batch.set(docRef, {
            'soal': soal,
            'opsi_a': opsiA,
            'opsi_b': opsiB,
            'opsi_c': opsiC,
            'opsi_d': opsiD,
            'kunci': kunci.trim().toUpperCase(),
            'created_at': FieldValue.serverTimestamp(),
          });

          jumlahSoalBerhasil++;
        }
      }

      // Eksekusi pengiriman data massal ke Firebase sekaligus
      await batch.commit();

      setState(() {
        _isUploading = false;
        _fileTerpilih = null;
        _statusPesan =
            "🔥 BERHASIL! $jumlahSoalBerhasil soal anatomi sukses dimasukkan ke database!";
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
        _statusPesan = "❌ Gagal memproses import: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F6),
      appBar: AppBar(
        title: const Text("Import Massal Bank Soal",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: maroonPrimary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
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
                  Icon(Icons.description_rounded,
                      size: 70, color: maroonPrimary),
                  const SizedBox(height: 16),
                  const Text(
                    "Format Template Excel",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Pastikan file .xlsx memiliki urutan kolom berikut:\nKolom 1: No | Kolom 2: Pertanyaan | Kolom 3: Opsi A | Kolom 4: Opsi B | Kolom 5: Opsi C | Kolom 6: Opsi D | Kolom 7: Kunci (A/B/C/D)",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),

                  // Tombol Pilih File
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: maroonPrimary),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    // ✅ FIXED: Kata 'const' sudah dihapus karena mengandung variabel dinamis maroonPrimary stuy
                    icon: Icon(Icons.file_upload_rounded, color: maroonPrimary),
                    label: Text("Pilih File Excel (.xlsx)",
                        style: TextStyle(
                            color: maroonPrimary, fontWeight: FontWeight.bold)),
                    onPressed: _isUploading ? null : _pilihFileExcel,
                  ),

                  if (_fileTerpilih != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      "📄 File Terpilih: ${_fileTerpilih!.name}",
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, color: Colors.teal),
                    ),
                    const SizedBox(height: 16),

                    // Tombol Upload Eksekusi
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: maroonPrimary),
                        onPressed: _isUploading ? null : _prosesImportExcel,
                        child: _isUploading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text("Mulai Import ke Firebase stuy!",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],

                  if (_statusPesan.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      _statusPesan,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _statusPesan.contains("❌")
                              ? Colors.red
                              : Colors.grey.shade800),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
