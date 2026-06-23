import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PretestRepository {
  // 📡 Pemantau Status Live Ujian (Bisa dibaca langsung oleh Dosen & Mahasiswa)
  static final ValueNotifier<bool> statusUjianLive = ValueNotifier<bool>(false);

  // 1. Fungsi untuk Dosen: Mengubah Status ON/OFF Ujian di Firestore
  static Future<void> ubahStatusUjian(bool statusBaru) async {
    try {
      await FirebaseFirestore.instance
          .collection('bank_soal')
          .doc('kontrol_pretest')
          .set({
        'is_aktif': statusBaru,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      statusUjianLive.value = statusBaru;
    } catch (e) {
      debugPrint("Gagal mengubah status akses ujian: $e");
    }
  }

  // 2. Fungsi untuk Mahasiswa: Standby dengerin perubahan sakelar Dosen (Real-time)
  static void listenStatusUjian() {
    FirebaseFirestore.instance
        .collection('bank_soal')
        .doc('kontrol_pretest')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        var data = snapshot.data() as Map<String, dynamic>;
        statusUjianLive.value = data['is_aktif'] ?? false;
      }
    });
  }

  // 3. Fungsi untuk Mahasiswa: Mengirim Nilai Hasil Ujian ke Database Baru
  static Future<void> simpanHasilPretest({
    required String userId,
    required int nilai,
    required String status,
  }) async {
    try {
      // Menyimpan rekap nilai ke collection 'nilai_pretest' dengan Document ID berupa ID Mahasiswa
      await FirebaseFirestore.instance
          .collection('nilai_pretest')
          .doc(userId)
          .set({
        'user_id': userId,
        'nilai': nilai,
        'status': status,
        'waktu_selesai': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint("Nilai mahasiswa $userId berhasil direkam stuy!");
    } catch (e) {
      debugPrint("Gagal menyimpan nilai pretest ke database: $e");
    }
  }

  // 📥 4. FUNGSI BARU: Import Excel Massal ke Firebase dengan Aman (Null-Safety)
  // Masukkan parameter list data dari sheet Excel ke sini stuy!
  static Future<void> importMassalBankSoal(List<List<dynamic>> rows) async {
    try {
      final collectionRef = FirebaseFirestore.instance
          .collection('bank_soal')
          .doc('paket_utama_pretest')
          .collection('daftar_soal');

      for (var row in rows) {
        // A. Abaikan baris header (misal baris pertama yang berisi teks "No" atau "Pertanyaan")
        if (row.isEmpty || row[0].toString().toLowerCase().contains('no')) {
          continue;
        }

        // B. Cegah "Unexpected null value" akibat baris kosong di bawah data Excel
        // Jika kolom Pertanyaan (indeks 1) null atau kosong, lewati baris ini stuy!
        if (row.length < 2 ||
            row[1] == null ||
            row[1].toString().trim().isEmpty) {
          continue;
        }

        // C. Ekstrak data sel dengan aman (menggunakan null-coalescing '??')
        String pertanyaan = row[1].toString().trim();
        String opsiA =
            row.length > 2 && row[2] != null ? row[2].toString().trim() : '';
        String opsiB =
            row.length > 3 && row[3] != null ? row[3].toString().trim() : '';
        String opsiC =
            row.length > 4 && row[4] != null ? row[4].toString().trim() : '';
        String opsiD =
            row.length > 5 && row[5] != null ? row[5].toString().trim() : '';

        // Baca kunci huruf (A/B/C/D)
        String kunciHuruf = row.length > 6 && row[6] != null
            ? row[6].toString().trim().toUpperCase()
            : 'A';

        // D. Konversi Kunci Jawaban Huruf (Excel) -> Angka 0-3 (Untuk Kuis UI)
        int kunciAngka = 0;
        switch (kunciHuruf) {
          case 'A':
            kunciAngka = 0;
            break;
          case 'B':
            kunciAngka = 1;
            break;
          case 'C':
            kunciAngka = 2;
            break;
          case 'D':
            kunciAngka = 3;
            break;
          default:
            kunciAngka = 0; // Fallback default ke A stuy jika tidak valid
        }

        // E. Unggah data ke Cloud Firestore
        await collectionRef.add({
          'pertanyaan': pertanyaan,
          'opsi': [opsiA, opsiB, opsiC, opsiD],
          'jawaban_benar': kunciAngka, // Disimpan dalam bentuk int stuy!
          'created_at': FieldValue.serverTimestamp(),
        });
      }
      debugPrint("Semua soal berhasil di-import massal ke Firebase stuy!");
    } catch (e) {
      // Melempar error kembali agar bisa ditangkap oleh UI ("Gagal memproses import: ...")
      throw Exception(e.toString());
    }
  }
}
