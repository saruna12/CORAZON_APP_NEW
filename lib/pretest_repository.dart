import 'dart:collection';
import 'package:flutter/material.dart'; // PASTIKAN IMPORT INI ADA STUY!

// ================= MODEL SOAL & UJIAN =================
class Question {
  final String id;
  final String text;
  final List<String> options;
  final int answerIndex;

  Question({
    required this.id,
    required this.text,
    required this.options,
    required this.answerIndex,
  });
}

class PretestItem {
  final String id;
  String title;
  DateTime scheduledAt;
  final List<Question> questions;
  final List<PretestResult> results;
  bool isOpenedByDosen;

  PretestItem({
    required this.id,
    required this.title,
    required this.scheduledAt,
    List<Question>? questions,
    List<PretestResult>? results,
    this.isOpenedByDosen = false,
  })  : questions = questions ?? [],
        results = results ?? [];
}

class PretestResult {
  final String studentId;
  final String studentName;
  final int score;
  final DateTime takenAt;
  final Map<String, dynamic> answers;

  PretestResult({
    required this.studentId,
    required this.studentName,
    required this.score,
    required this.takenAt,
    required this.answers,
  });
}

// ================= MODEL MODUL BARU (DIKTIK SESUAI ALUR KITA) =================
class ModulItem {
  final String id;
  final String title;
  final String fileUrl;
  final DateTime createdAt;

  ModulItem({
    required this.id,
    required this.title,
    required this.fileUrl,
    required this.createdAt,
  });
}

// ================= REPOSITORY UTAMA =================
class PretestRepository {
  PretestRepository._internal();
  static final PretestRepository _instance = PretestRepository._internal();
  factory PretestRepository() => _instance;

  final List<PretestItem> _pretests = [];

  // 1. Penampung list modul (diisi 1 data contoh bawaan buat anatomi jantung)
  final List<ModulItem> _moduls = [
    ModulItem(
      id: 'm1',
      title: 'Modul 1: Anatomi Jantung & Kardiovaskular',
      fileUrl: 'https://drive.google.com/file/d/contoh-link-pdf/view',
      createdAt: DateTime.now(),
    ),
  ];

  // ================= DEKLARASI WAJIB (INI YANG DICARI TEST_PAGE) =================
  static final ValueNotifier<bool> statusUjianLive = ValueNotifier<bool>(false);

  UnmodifiableListView<PretestItem> get pretests =>
      UnmodifiableListView(_pretests);

  // ================= UTAL-ATIL DATA MODUL (BARU) =================

  // Getter agar halaman dosen & mahasiswa bisa membaca list modul stuy
  List<ModulItem> get moduls => _moduls;

  // Fungsi untuk menambahkan modul baru lewat pop-up dosen nanti
  void addModul(String title, String url) {
    _moduls.add(
      ModulItem(
        id: DateTime.now()
            .millisecondsSinceEpoch
            .toString(), // ID unik berbasis waktu
        title: title,
        fileUrl: url,
        createdAt: DateTime.now(),
      ),
    );
  }

  // Fungsi untuk menghapus modul jika dosen salah input
  void deleteModul(String id) {
    _moduls.removeWhere((m) => m.id == id);
  }

  // ================= FUNGSI BAWAAN ASLI (TIDAK BERUBAH) =================

  // Fungsi untuk mengubah status ujian secara global
  void setStatusUjian(String pretestId, bool status) {
    statusUjianLive.value = status; // Mengubah pemicu sinyal live
    final p = getPretestById(pretestId);
    if (p != null) {
      p.isOpenedByDosen = status;
    }
  }

  void addPretest(PretestItem item) {
    _pretests.add(item);
  }

  void updatePretest(String id, {String? title, DateTime? scheduledAt}) {
    final idx = _pretests.indexWhere((p) => p.id == id);
    if (idx >= 0) {
      final p = _pretests[idx];
      if (title != null) p.title = title;
      if (scheduledAt != null) p.scheduledAt = scheduledAt;
    }
  }

  void deletePretest(String id) {
    _pretests.removeWhere((p) => p.id == id);
  }

  PretestItem? getPretestById(String id) {
    try {
      return _pretests.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  void addQuestion(String pretestId, Question q) {
    final p = getPretestById(pretestId);
    if (p != null) p.questions.add(q);
  }

  List<Question> getQuestions(String pretestId) {
    final p = getPretestById(pretestId);
    return p?.questions ?? [];
  }

  void updateQuestion(String pretestId, String questionId,
      {String? text, List<String>? options, int? answerIndex}) {
    final p = getPretestById(pretestId);
    if (p == null) return;
    final idx = p.questions.indexWhere((q) => q.id == questionId);
    if (idx < 0) return;
    final old = p.questions[idx];
    final updated = Question(
      id: old.id,
      text: text ?? old.text,
      options: options ?? old.options,
      answerIndex: answerIndex ?? old.answerIndex,
    );
    p.questions[idx] = updated;
  }

  void deleteQuestion(String pretestId, String questionId) {
    final p = getPretestById(pretestId);
    if (p == null) return;
    p.questions.removeWhere((q) => q.id == questionId);
  }

  void saveResult(String pretestId, PretestResult result) {
    final p = getPretestById(pretestId);
    if (p != null) p.results.add(result);
  }

  List<PretestResult> getResults(String pretestId) {
    final p = getPretestById(pretestId);
    return p?.results ?? [];
  }

  PretestItem? getActivePretest() {
    if (_pretests.isEmpty) return null;
    final now = DateTime.now();
    final future = _pretests.where((p) => p.scheduledAt.isAfter(now)).toList();
    if (future.isNotEmpty) {
      future.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      return future.first;
    }
    return _pretests.last;
  }
}
