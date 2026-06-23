import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:cloud_firestore/cloud_firestore.dart';

class ImportSoalPosttestPage extends StatefulWidget {
  const ImportSoalPosttestPage({super.key});

  @override
  State<ImportSoalPosttestPage> createState() => _ImportSoalPosttestPageState();
}

class _ImportSoalPosttestPageState extends State<ImportSoalPosttestPage> {
  final Color maroonPrimary = const Color(0xFF6B1D2F);

  PlatformFile? _fileTerpilih;
  bool _isUploading = false;
  String _statusPesan = "";

  // Mengubah inputan kunci dari Excel (bisa Huruf A-D atau Angka 0-3) secara aman
  int _konversiKunciKeIndeks(dynamic value) {
    if (value == null) return 0;

    String nilaiString = value.toString().trim().toUpperCase();

    // Jika di excel diisi angka murni (0, 1, 2, 3)
    if (nilaiString == '0') return 0;
    if (nilaiString == '1') return 1;
    if (nilaiString == '2') return 2;
    if (nilaiString == '3') return 3;

    // Jika di excel diisi huruf teks (A, B, C, D)
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

  // 1. Fungsi memilih file Excel (.xlsx)
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
          _statusPesan = "File Posttest siap diimport stuy!";
        });
      }
    } catch (e) {
      setState(() {
        _statusPesan = "❌ Gagal memilih file: $e";
      });
    }
  }

  // 2. Fungsi membaca file Excel dengan arah penyimpanan ke paket_utama_posttest
  Future<void> _prosesImportExcel() async {
    if (_fileTerpilih == null) return;

    setState(() {
      _isUploading = true;
      _statusPesan = "Sedang membaca file Excel Posttest...";
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
        throw "File Excel kosong atau format tidak sesuai stuy.";
      }

      int jumlahSoalBerhasil = 0;
      WriteBatch batch = FirebaseFirestore.instance.batch();

      // 🎯 TARGET DIREKTORI DIUBAH KE POSTTEST
      CollectionReference collectionTarget = FirebaseFirestore.instance
          .collection('bank_soal')
          .doc('paket_utama_posttest')
          .collection('daftar_soal');

      // Iterasi baris Excel
      for (int i = 0; i < table.maxRows; i++) {
        var row = table.rows[i];

        if (row.length < 7) continue;

        var cellNo = row[0]?.value;
        var cellSoal = row[1]?.value;
        var cellA = row[2]?.value;
        var cellB = row[3]?.value;
        var cellC = row[4]?.value;
        var cellD = row[5]?.value;
        var cellKunci = row[6]?.value;

        String nomorStr = cellNo?.toString().trim() ?? "";
        String soalStr = cellSoal?.toString().trim() ?? "";

        if (nomorStr.toLowerCase().contains("no") ||
            soalStr.toLowerCase().contains("panduan") ||
            soalStr.isEmpty) {
          continue;
        }

        String opsiA = cellA?.toString().trim() ?? "";
        String opsiB = cellB?.toString().trim() ?? "";
        String opsiC = cellC?.toString().trim() ?? "";
        String opsiD = cellD?.toString().trim() ?? "";

        int jawabanBenarIndeks = _konversiKunciKeIndeks(cellKunci);
        List<String> daftarOpsi = [opsiA, opsiB, opsiC, opsiD];

        DocumentReference docRef = collectionTarget.doc();

        batch.set(docRef, {
          'pertanyaan': soalStr,
          'opsi': daftarOpsi,
          'jawaban_benar': jawabanBenarIndeks,
          'created_at': FieldValue.serverTimestamp(),
        });

        jumlahSoalBerhasil++;
      }

      if (jumlahSoalBerhasil > 0) {
        await batch.commit();
        setState(() {
          _isUploading = false;
          _fileTerpilih = null;
          _statusPesan =
              "🔥 BERHASIL! $jumlahSoalBerhasil soal POSTTEST sukses dimasukkan ke database!";
        });
      } else {
        setState(() {
          _isUploading = false;
          _statusPesan = "❌ Gagal: Tidak ada baris soal valid yang ditemukan.";
        });
      }
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
        title: const Text("Import Massal Bank Soal Posttest",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
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
                  Icon(Icons.assignment_turned_in_rounded,
                      size: 70, color: maroonPrimary),
                  const SizedBox(height: 16),
                  const Text(
                    "Format Template Excel Posttest",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Pastikan file .xlsx memiliki urutan kolom berikut:\nKolom 1: No | Kolom 2: Pertanyaan | Kolom 3: Opsi A | Kolom 4: Opsi B | Kolom 5: Opsi C | Kolom 6: Opsi D | Kolom 7: Kunci (A/B/C/D)",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: maroonPrimary),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    icon: Icon(Icons.file_upload_rounded, color: maroonPrimary),
                    label: Text("Pilih File Excel Posttest (.xlsx)",
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
                              : _statusPesan.contains("🔥")
                                  ? Colors.green
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
