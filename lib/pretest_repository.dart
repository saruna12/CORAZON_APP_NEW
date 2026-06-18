import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PretestRepository {
  static final ValueNotifier<bool> statusUjianLive = ValueNotifier<bool>(false);

  // Mendengarkan status ujian live secara real-time stream
  static void listenStatusUjian() {
    FirebaseFirestore.instance
        .collection('pengaturan')
        .doc('pretest')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        // Mengambil data field 'is_live'
        bool statusDariServer = snapshot.data()?['is_live'] ?? false;
        statusUjianLive.value = statusDariServer;
        debugPrint("📡 STATUS UJIAN LIVE BERUBAH: $statusDariServer");
      }
    }, onError: (error) {
      debugPrint("❌ GAGAL MENDENGARKAN STATUS UJIAN: $error");
    });
  }

  // Mengubah status ujian (Dipakai oleh tombol Admin stuy)
  static Future<void> ubahStatusUjian(bool statusBaru) async {
    await FirebaseFirestore.instance
        .collection('pengaturan')
        .doc('pretest')
        .set({'is_live': statusBaru}, SetOptions(merge: true));
  }

  // Fungsi untuk Hasil Pretest Page
  static Stream<QuerySnapshot> getActivePretest() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'mahasiswa')
        .snapshots();
  }

  // ==========================================
  // MANAJEMEN MODUL
  // ==========================================

  // Mengambil data modul terupdate secara real-time
  static Stream<QuerySnapshot> get moduls {
    return FirebaseFirestore.instance
        .collection('modul')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Menambah modul baru ke Firestore
  static Future<void> addModul(
      String judul, String deskripsi, String urlPdf) async {
    await FirebaseFirestore.instance.collection('modul').add({
      'judul': judul,
      'deskripsi': deskripsi,
      'url_pdf': urlPdf,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Menghapus modul dari Firestore berdasarkan ID dokumen
  static Future<void> deleteModul(String docId) async {
    await FirebaseFirestore.instance.collection('modul').doc(docId).delete();
  }

  // ==========================================
  // FITUR KUIS MAHASISWA (FITUR BARU)
  // ==========================================

  // Mengambil semua soal pretest untuk dikerjakan mahasiswa
  static Future<List<QueryDocumentSnapshot>> ambilSemuaSoal() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('soal_pretest')
        .orderBy('timestamp', descending: true)
        .get();
    return snapshot.docs;
  }

  // Menyimpan hasil pretest mahasiswa ke dokumen user-nya masing-masing
  static Future<void> simpanHasilPretest({
    required String userId,
    required int nilai,
    required String status,
  }) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'nilai_pretest': nilai,
      'status_pretest': status,
      'waktu_selesai_pretest': FieldValue.serverTimestamp(),
    });
  }
}
