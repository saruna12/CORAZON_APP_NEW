import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PretestRepository {
  // 📡 Pemantau Status Live Pretest & Posttest
  static final ValueNotifier<bool> statusPretestLive = ValueNotifier<bool>(false);
  static final ValueNotifier<String> kunciPretestLive = ValueNotifier<String>("");

  static final ValueNotifier<bool> statusPosttestLive = ValueNotifier<bool>(false);
  static final ValueNotifier<String> kunciPosttestLive = ValueNotifier<String>("");

  // ValueNotifier kompatibilitas lama
  static final ValueNotifier<bool> statusUjianLive = statusPretestLive;

  // 1. Fungsi untuk Dosen: Mengubah Status ON/OFF Ujian & Token Pretest di Firestore
  static Future<void> ubahStatusUjian(bool statusBaru, {String? kunciAkses}) async {
    try {
      Map<String, dynamic> data = {
        'is_aktif': statusBaru,
        'updated_at': FieldValue.serverTimestamp(),
      };
      if (kunciAkses != null) {
        data['kunci_akses'] = kunciAkses.trim();
      }

      await FirebaseFirestore.instance
          .collection('bank_soal')
          .doc('kontrol_pretest')
          .set(data, SetOptions(merge: true));

      statusPretestLive.value = statusBaru;
      if (kunciAkses != null) {
        kunciPretestLive.value = kunciAkses.trim();
      }
    } catch (e) {
      debugPrint("Gagal mengubah status akses ujian pretest: $e");
    }
  }

  // 1b. Fungsi untuk Dosen: Mengubah Status ON/OFF Ujian & Token Posttest di Firestore
  static Future<void> ubahStatusPosttest(bool statusBaru, {String? kunciAkses}) async {
    try {
      Map<String, dynamic> data = {
        'is_aktif': statusBaru,
        'updated_at': FieldValue.serverTimestamp(),
      };
      if (kunciAkses != null) {
        data['kunci_akses'] = kunciAkses.trim();
      }

      await FirebaseFirestore.instance
          .collection('bank_soal')
          .doc('kontrol_posttest')
          .set(data, SetOptions(merge: true));

      statusPosttestLive.value = statusBaru;
      if (kunciAkses != null) {
        kunciPosttestLive.value = kunciAkses.trim();
      }
    } catch (e) {
      debugPrint("Gagal mengubah status akses ujian posttest: $e");
    }
  }

  // 2. Fungsi untuk Mahasiswa: Standby dengerin perubahan sakelar Dosen (Real-time)
  static void listenStatusUjian() {
    // Listen Pretest
    FirebaseFirestore.instance
        .collection('bank_soal')
        .doc('kontrol_pretest')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        var data = snapshot.data() as Map<String, dynamic>;
        statusPretestLive.value = data['is_aktif'] ?? false;
        kunciPretestLive.value = data['kunci_akses'] ?? "";
      }
    });

    // Listen Posttest
    FirebaseFirestore.instance
        .collection('bank_soal')
        .doc('kontrol_posttest')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        var data = snapshot.data() as Map<String, dynamic>;
        statusPosttestLive.value = data['is_aktif'] ?? false;
        kunciPosttestLive.value = data['kunci_akses'] ?? "";
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
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'nilai_pretest': nilai,
        'status_pretest': status,
        'waktu_pretest': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint("Nilai pretest mahasiswa $userId berhasil direkam!");
    } catch (e) {
      debugPrint("Gagal menyimpan nilai pretest ke database: $e");
    }
  }

  // 4. ✅ Simpan nilai posttest ke users/{uid} (menggunakan dua 't' secara standar)
  static Future<void> simpanHasilPosttest({
    required String userId,
    required int nilai,
    required String status,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'nilai_posttest': nilai,
        'status_posttest': status,
        'waktu_posttest': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint("Nilai posttest mahasiswa $userId berhasil direkam!");
    } catch (e) {
      debugPrint("Gagal menyimpan nilai posttest ke database: $e");
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
