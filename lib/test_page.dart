import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pretest_repository.dart'; // Tetap mempertahankan repository pendeteksi status kamu

class TestPage extends StatefulWidget {
  final String testType; // 'Pre-Test' atau 'Post-Test'
  const TestPage({super.key, required this.testType});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  bool isTestStarted = false;
  int _remainingTime = 180; // 3 Menit (180 Detik)
  Timer? _timer;
  int _currentQuestionIndex = 0;

  // Menyimpan jawaban mahasiswa {index_soal: 'pilihan_jawaban'}
  final Map<int, String> _selectedAnswers = {};
  bool _isSubmitting = false;

  void _startTimer() {
    setState(() {
      isTestStarted = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        _timer?.cancel();
        // Otomatis submit data ketika waktu habis agar nilai tidak hangus
        _autoSubmitOnTimeout();
      }
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const maroonColor = Color(0xFF801A24);
    String collectionName =
        widget.testType == 'Pre-Test' ? 'soal_pretest' : 'soal_postest';

    return ValueListenableBuilder<bool>(
      valueListenable: PretestRepository.statusUjianLive,
      builder: (context, apakahUjianTerbuka, child) {
        // 1. JIKA BELUM DIBUKA DOSEN / LABORAN
        if (!apakahUjianTerbuka) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.testType),
              backgroundColor: maroonColor,
              foregroundColor: Colors.white,
            ),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_clock, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Ujian Belum Dibuka',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Akses ujian masih dikunci oleh Dosen/Laboran. Silakan tunggu instruksi praktikum dimulai di ruangan.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // 2. TAMPILAN SEBELUM MULAI (START PAGE MAHASISWA)
        if (!isTestStarted) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.testType),
              backgroundColor: maroonColor,
              foregroundColor: Colors.white,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.assignment, size: 80, color: maroonColor),
                    const SizedBox(height: 16),
                    Text(
                      'Ujian ${widget.testType} Siap!',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer, color: Colors.amber[800]),
                          const SizedBox(width: 8),
                          const Text(
                            'Durasi Waktu: 3 Menit (180 Detik)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: maroonColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 12),
                      ),
                      onPressed: _startTimer,
                      child: const Text(
                        'MULAI UJIAN NOW',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // 3. TAMPILAN LEMBAR SOAL REAL-TIME DARI FIRESTORE
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection(collectionName)
              .orderBy('nomor')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Scaffold(
                  body: Center(child: Text("Gagal memuat soal dari server.")));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                  body: Center(
                      child: CircularProgressIndicator(color: maroonColor)));
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return Scaffold(
                appBar: AppBar(
                    title: Text(widget.testType),
                    backgroundColor: maroonColor,
                    foregroundColor: Colors.white),
                body: const Center(
                    child: Text(
                        "Belum ada bank soal yang di-upload oleh Laboran/Admin.")),
              );
            }

            // Validasi index penunjuk soal agar tidak out of bounds
            if (_currentQuestionIndex >= docs.length) {
              _currentQuestionIndex = docs.length - 1;
            }

            var currentQuestionData =
                docs[_currentQuestionIndex].data() as Map<String, dynamic>;
            String pertanyaan = currentQuestionData['pertanyaan'] ?? '';
            Map<String, dynamic> pilihan = currentQuestionData['pilihan'] ?? {};

            return Scaffold(
              appBar: AppBar(
                title: Text(
                    '${widget.testType} - No. ${_currentQuestionIndex + 1}'),
                backgroundColor: maroonColor,
                foregroundColor: Colors.white,
                automaticallyImplyLeading:
                    false, // Mencegah mhs back manual lewat panah device
                actions: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: Text(
                        _formatTime(_remainingTime),
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber),
                      ),
                    ),
                  )
                ],
              ),
              body: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(
                      value: _remainingTime / 180,
                      color: maroonColor,
                      backgroundColor: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      pertanyaan,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 24),

                    // Render List Pilihan Ganda secara Dinamis
                    Expanded(
                      child: ListView(
                        children: pilihan.entries.map((entry) {
                          String opsiKey = entry.key; // 'A', 'B', 'C', dll
                          String opsiTeks = entry.value;
                          bool isSelected =
                              _selectedAnswers[_currentQuestionIndex] ==
                                  opsiKey;

                          return Card(
                            elevation: 2,
                            color: isSelected
                                ? const Color(0xFFF3EBE9)
                                : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                  color: isSelected
                                      ? maroonColor
                                      : Colors.transparent,
                                  width: 1.5),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    isSelected ? maroonColor : Colors.grey[200],
                                child: Text(
                                  opsiKey,
                                  style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(opsiTeks),
                              onTap: _isSubmitting
                                  ? null
                                  : () {
                                      setState(() {
                                        _selectedAnswers[
                                            _currentQuestionIndex] = opsiKey;
                                      });

                                      // Jika masih ada soal berikutnya, otomatis geser index
                                      if (_currentQuestionIndex <
                                          docs.length - 1) {
                                        Future.delayed(
                                            const Duration(milliseconds: 250),
                                            () {
                                          if (mounted) {
                                            setState(() {
                                              _currentQuestionIndex++;
                                            });
                                          }
                                        });
                                      } else {
                                        // Jika ini soal terakhir, picu kalkulasi ganda
                                        _processSubmitTest(docs);
                                      }
                                    },
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // Tombol Navigasi Manual Bawah Tambahan
                    if (_currentQuestionIndex > 0)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _currentQuestionIndex--;
                            });
                          },
                          icon:
                              const Icon(Icons.arrow_back, color: maroonColor),
                          label: const Text("Soal Sebelumnya",
                              style: TextStyle(color: maroonColor)),
                          style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: maroonColor)),
                        ),
                      )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Pengiriman Otomatis saat Waktu di Atas Habis (Detik = 0)
  Future<void> _autoSubmitOnTimeout() async {
    String collectionName =
        widget.testType == 'Pre-Test' ? 'soal_pretest' : 'soal_postest';
    final snapshot = await FirebaseFirestore.instance
        .collection(collectionName)
        .orderBy('nomor')
        .get();
    _processSubmitTest(snapshot.docs);
  }

  // Kalkulasi & Kirim Skor Bersamaan ke Sisi Mahasiswa & Rekap Dosen/Admin
  Future<void> _processSubmitTest(List<QueryDocumentSnapshot> totalSoal) async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });
    _timer?.cancel();

    int jawabanBenar = 0;

    // Pengecekan jawaban mhs dicocokkan dengan field 'kunci' dari admin
    for (int i = 0; i < totalSoal.length; i++) {
      var dataSoal = totalSoal[i].data() as Map<String, dynamic>;
      String kunciAsli = dataSoal['kunci'] ?? '';
      String jawabanMhs = _selectedAnswers[i] ?? '';

      if (jawabanMhs == kunciAsli) {
        jawabanBenar++;
      }
    }

    double skorAkhir =
        totalSoal.isNotEmpty ? (jawabanBenar / totalSoal.length) * 100 : 0.0;
    String statusKelulusan = skorAkhir >= 60 ? 'LULUS' : 'TIDAK LULUS';

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Tarik data nama & npm mhs pendukung untuk berkas admin
        DocumentSnapshot profileDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        String namaMhs = "Mahasiswa";
        String npmMhs = "NPM Tidak Terbaca";

        if (profileDoc.exists && profileDoc.data() != null) {
          var data = profileDoc.data() as Map<String, dynamic>;
          namaMhs = data['nama'] ?? namaMhs;
          npmMhs = data['npm'] ?? npmMhs;
        }

        WriteBatch batch = FirebaseFirestore.instance.batch();

        // JALUR 1: Simpan ke data pribadi Mahasiswa (Update Dashboard Beranda)
        DocumentReference mhsRef =
            FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
        if (widget.testType == 'Pre-Test') {
          batch.update(mhsRef, {
            'nilai_pretest': skorAkhir.round(),
            'status_pretest': statusKelulusan,
          });
        } else {
          batch.update(mhsRef, {
            'nilai_postest': skorAkhir.round(),
            'status_postest': statusKelulusan,
          });
        }

        // JALUR 2: Simpan ke Rekap Pengawasan Dosen/Admin
        String rekapPath =
            widget.testType == 'Pre-Test' ? 'rekap_pretest' : 'rekap_postest';
        DocumentReference adminRef = FirebaseFirestore.instance
            .collection(rekapPath)
            .doc(currentUser.uid);
        batch.set(adminRef, {
          'uid': currentUser.uid,
          'nama': namaMhs,
          'npm': npmMhs,
          'skor': skorAkhir.round(),
          'status': statusKelulusan,
          'waktu_selesai': FieldValue.serverTimestamp(),
        });

        // Eksekusi Atomic Batch
        await batch.commit();

        if (mounted) {
          _showResultDialog(skorAkhir.round(), statusKelulusan);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Gagal mengirim nilai: $e")));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showResultDialog(int skor, String status) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Ujian Selesai'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Waktu habis atau kamu telah mengirim jawaban. Nilai kamu berhasil direkap ke dosen/admin.'),
            const SizedBox(height: 16),
            Text("SKOR KAMU: $skor",
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF801A24))),
            Text("STATUS: $status",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: status == 'LULUS' ? Colors.green : Colors.red)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Tutup Dialog
              Navigator.pop(context); // Kembali ke Beranda
            },
            child: const Text('OK',
                style: TextStyle(
                    color: Color(0xFF801A24), fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}
