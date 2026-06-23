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

  // Mengubah inputan kunci dari Excel secara aman stuy
  int _konversiKunciKeIndeks(dynamic value) {
    if (value == null) return 0;

    String nilaiString = value.toString().trim().toUpperCase();

    if (nilaiString == '0' || nilaiString == 'A') return 0;
    if (nilaiString == '1' || nilaiString == 'B') return 1;
    if (nilaiString == '2' || nilaiString == 'C') return 2;
    if (nilaiString == '3' || nilaiString == 'D') return 3;

    return 0; // Default aman ke opsi A stuy
  }

  // Pembasmi utama eror Unexpected null value stuy!
  String _ambilTeksCell(dynamic cell) {
    if (cell == null || cell.value == null) return "";
    return cell.value.toString().trim();
  }

  // 1. Fungsi memilih file Excel (.xlsx) stuy
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
        _statusPesan = "❌ Gagal memilih file: $e";
      });
    }
  }

  // 2. Fungsi membaca file Excel dengan validasi berlapis stuy
  Future<void> _prosesImportExcel() async {
    if (_fileTerpilih == null) return;

    setState(() {
      _isUploading = true;
      _statusPesan = "Sedang membaca file Excel...";
    });

    try {
      List<int> bytes;

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

      // Loop lembar baris secara aman stuy
      for (var row in table.rows) {
        // FILTER 1: Jika baris data null atau kosong, langsung lewati stuy!
        if (row.isEmpty) continue;

        // FILTER 2: Ekstrak teks cell dengan validasi kepastian panjang index row
        String col0 =
            row.isNotEmpty && row[0] != null ? _ambilTeksCell(row[0]) : "";
        String col1 =
            row.length > 1 && row[1] != null ? _ambilTeksCell(row[1]) : "";
        String col2 =
            row.length > 2 && row[2] != null ? _ambilTeksCell(row[2]) : "";
        String col3 =
            row.length > 3 && row[3] != null ? _ambilTeksCell(row[3]) : "";
        String col4 =
            row.length > 4 && row[4] != null ? _ambilTeksCell(row[4]) : "";
        String col5 =
            row.length > 5 && row[5] != null ? _ambilTeksCell(row[5]) : "";
        String col6 =
            row.length > 6 && row[6] != null ? _ambilTeksCell(row[6]) : "";

        String soalStr = "";
        String opsiA = "";
        String opsiB = "";
        String opsiC = "";
        String opsiD = "";
        String kunciRaw = "";

        // DETEKSI LAYOUT: Otomatis mendeteksi Excel yang pakai kolom No atau yang langsung Pertanyaan
        if (col0.toLowerCase() == "no" || double.tryParse(col0) != null) {
          soalStr = col1;
          opsiA = col2;
          opsiB = col3;
          opsiC = col4;
          opsiD = col5;
          kunciRaw = col6;
        } else {
          soalStr = col0;
          opsiA = col1;
          opsiB = col2;
          opsiC = col3;
          opsiD = col4;
          kunciRaw = col5;
        }

        // FILTER 3: Jalur bypass baris header template atau baris hantu kosong di excel
        if (soalStr.trim().isEmpty ||
            soalStr.toLowerCase().contains("pertanyaan") ||
            soalStr.toLowerCase().contains("soal")) {
          continue;
        }

        // FILTER 4: Jika opsi jawaban kosong semua (baris rusak), jangan dimasukkan ke Firebase
        if (opsiA.isEmpty && opsiB.isEmpty) {
          continue;
        }

        int jawabanBenarIndeks = _konversiKunciKeIndeks(kunciRaw);
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
              "🔥 BERHASIL! $jumlahSoalBerhasil soal anatomi sukses masuk database stuy!";
        });
      } else {
        setState(() {
          _isUploading = false;
          _statusPesan = "❌ Gagal: Tidak ada soal valid yang ter-import stuy.";
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
        title: const Text("Import Massal Bank Soal",
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
                  Icon(Icons.description_rounded,
                      size: 70, color: maroonPrimary),
                  const SizedBox(height: 16),
                  const Text(
                    "Format Template Excel",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Bisa menggunakan kolom No atau langsung Pertanyaan di kolom pertama stuy.",
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
