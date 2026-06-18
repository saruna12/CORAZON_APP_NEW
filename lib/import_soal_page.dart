import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ImportSoalPage extends StatefulWidget {
  const ImportSoalPage({super.key});

  @override
  State<ImportSoalPage> createState() => _ImportSoalPageState();
}

class _ImportSoalPageState extends State<ImportSoalPage> {
  bool _isUploading = false;
  String _statusMessage = "Silakan pilih file Excel berisi soal.";

  Future<void> _uploadExcel() async {
    // 1. Pilih file Excel dari komputer/laptop
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true, // Wajib true untuk Flutter Web agar mendapat bytes data
    );

    if (result != null && result.files.first.bytes != null) {
      setState(() {
        _isUploading = true;
        _statusMessage = "Sedang membaca file Excel...";
      });

      try {
        Uint8List bytes = result.files.first.bytes!;
        var excel = Excel.decodeBytes(bytes);

        // Mengambil sheet pertama dari file Excel
        String sheetName = excel.tables.keys.first;
        var table = excel.tables[sheetName];

        if (table == null) {
          throw Exception("Sheet tidak ditemukan atau kosong stuy!");
        }

        int totalSoalBerhasil = 0;
        final firestore = FirebaseFirestore.instance;

        // 2. Lakukan perulangan untuk setiap baris di Excel
        // Mulai dari indeks 1 untuk melewati baris header (Baris 0)
        for (int i = 1; i < table.maxRows; i++) {
          var row = table.rows[i];

          // Pastikan baris tersebut tidak kosong
          if (row.isEmpty || row[0] == null) continue;

          // Mengambil nilai dari tiap kolom (sesuai urutan format excel)
          String pertanyaan = row[0]?.value?.toString() ?? "";
          String opsiA = row[1]?.value?.toString() ?? "";
          String opsiB = row[2]?.value?.toString() ?? "";
          String opsiC = row[3]?.value?.toString() ?? "";
          String opsiD = row[4]?.value?.toString() ?? "";
          String jawabanBenar = row[5]?.value?.toString() ?? "";

          if (pertanyaan.isNotEmpty) {
            // 3. Simpan langsung ke Firebase Firestore
            // Di sini kita simpan ke paket bernama 'paket_utama_pretest'
            await firestore
                .collection('bank_soal')
                .doc('paket_utama_pretest')
                .collection('daftar_soal')
                .add({
              'pertanyaan': pertanyaan,
              'opsi_a': opsiA,
              'opsi_b': opsiB,
              'opsi_c': opsiC,
              'opsi_d': opsiD,
              'jawaban_benar': jawabanBenar
                  .trim()
                  .toUpperCase(), // Memastikan huruf kapital (A/B/C/D)
              'created_at': FieldValue.serverTimestamp(),
            });

            totalSoalBerhasil++;
          }
        }

        setState(() {
          _isUploading = false;
          _statusMessage =
              "🎉 Berhasil mengimpor $totalSoalBerhasil soal ke Firestore!";
        });
      } catch (e) {
        setState(() {
          _isUploading = false;
          _statusMessage = "❌ Gagal memproses file: $e";
        });
      }
    } else {
      // User membatalkan pemilihan file
      setState(() {
        _statusMessage = "Pemilihan file dibatalkan.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Color maroonPrimary = const Color(0xFF6B1D2F);

    return Scaffold(
      appBar: AppBar(
        title: const Text("CORAZON Web Admin - Manajemen Soal",
            style: TextStyle(color: Colors.white)),
        backgroundColor: maroonPrimary,
      ),
      body: Center(
        child: Container(
          // ✅ FIX: Membatasi lebar maksimal menggunakan BoxConstraints
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                // ✅ FIX: Menggunakan .withValues() menggantikan .withOpacity() yang deprecated
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.table_view_rounded, size: 64, color: maroonPrimary),
              const SizedBox(height: 16),
              const Text(
                "Import Soal via Excel",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
              ),
              const SizedBox(height: 24),
              _isUploading
                  ? CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(maroonPrimary))
                  : ElevatedButton.icon(
                      onPressed: _uploadExcel,
                      icon: const Icon(Icons.upload_file, color: Colors.white),
                      label: const Text("Pilih & Upload File Excel",
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: maroonPrimary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
