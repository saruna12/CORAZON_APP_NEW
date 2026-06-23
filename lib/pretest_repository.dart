import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PretestRepository {
  // 📡 Pemantau Status Live Ujian
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

  // 3. ✅ FIX: Simpan nilai ke users/{uid} agar beranda bisa baca langsung
  static Future<void> simpanHasilPretest({
    required String userId,
    required int nilai,
    required String status,
  }) async {
    try {
      // ✅ Simpan ke users/{uid} — sesuai yang dibaca beranda.dart
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'nilai_pretest': nilai,
        'status_pretest': status,
        'waktu_pretest': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // merge: true agar data lain tidak tertimpa

      debugPrint("Nilai pretest mahasiswa $userId berhasil direkam!");
    } catch (e) {
      debugPrint("Gagal menyimpan nilai pretest ke database: $e");
    }
  }

  // 4. ✅ Simpan nilai postest ke users/{uid}
  static Future<void> simpanHasilPosttest({
    required String userId,
    required int nilai,
    required String status,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'nilai_postest': nilai,
        'status_postest': status,
        'waktu_postest': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint("Nilai postest mahasiswa $userId berhasil direkam!");
    } catch (e) {
      debugPrint("Gagal menyimpan nilai postest ke database: $e");
    }
  }

  // 5. Fungsi Import Excel Massal ke Firebase
  static Future<void> importMassalBankSoal(List<List<dynamic>> rows) async {
    try {
      final collectionRef = FirebaseFirestore.instance
          .collection('bank_soal')
          .doc('paket_utama_pretest')
          .collection('daftar_soal');

      for (var row in rows) {
        if (row.isEmpty || row[0].toString().toLowerCase().contains('no')) {
          continue;
        }

        if (row.length < 2 ||
            row[1] == null ||
            row[1].toString().trim().isEmpty) {
          continue;
        }

        String pertanyaan = row[1].toString().trim();
        String opsiA =
            row.length > 2 && row[2] != null ? row[2].toString().trim() : '';
        String opsiB =
            row.length > 3 && row[3] != null ? row[3].toString().trim() : '';
        String opsiC =
            row.length > 4 && row[4] != null ? row[4].toString().trim() : '';
        String opsiD =
            row.length > 5 && row[5] != null ? row[5].toString().trim() : '';

        String kunciHuruf = row.length > 6 && row[6] != null
            ? row[6].toString().trim().toUpperCase()
            : 'A';

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
            kunciAngka = 0;
        }

        await collectionRef.add({
          'pertanyaan': pertanyaan,
          'opsi': [opsiA, opsiB, opsiC, opsiD],
          'jawaban_benar': kunciAngka,
          'created_at': FieldValue.serverTimestamp(),
        });
      }
      debugPrint("Semua soal berhasil di-import massal ke Firebase!");
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
