import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pretest_repository.dart';

class KuisPretestPage extends StatefulWidget {
  final String userId; // Oper ID Mahasiswa yang sedang login saat ini stuy

  const KuisPretestPage({super.key, required this.userId});

  @override
  State<KuisPretestPage> createState() => _KuisPretestPageState();
}

class _KuisPretestPageState extends State<KuisPretestPage> {
  // DIPERBAIKI: Mengubah 'const' menjadi 'final' sesuai aturan class State
  final Color maroonPrimary = const Color(0xFF6B1D2F);
  final Color textDark = const Color(0xFF2C2C2C);

  List<QueryDocumentSnapshot> _daftarSoal = [];
  bool _isLoading = true;
  int _currentIndex = 0;

  // Map untuk menyimpan jawaban mahasiswa sementara (Indeks Soal -> Indeks Opsi yang Dipilih)
  final Map<int, int> _jawabanMahasiswa = {};

  // Logika Timer Kontrol
  Timer? _timer;
  int _waktuTersisa = 600; // Contoh: 10 Menit dalam hitungan detik

  @override
  void initState() {
    super.initState();
    _muatSoalDanMulaiTimer();
  }

  void _muatSoalDanMulaiTimer() async {
    try {
      var soal = await PretestRepository.ambilSemuaSoal();
      setState(() {
        _daftarSoal = soal;
        _isLoading = false;
      });
      _mulaiTimerMundur();
    } catch (e) {
      debugPrint("Gagal memuat kuis: $e");
    }
  }

  void _mulaiTimerMundur() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_waktuTersisa > 0) {
        setState(() {
          _waktuTersisa--;
        });
      } else {
        _timer?.cancel();
        _submitKuisOtomatis(); // Otomatis kumpul jika waktu habis stuy
      }
    });
  }

  String _formatWaktu(int totalDetik) {
    int menit = totalDetik ~/ 60;
    int detik = totalDetik % 60;
    return '${menit.toString().padLeft(2, '0')}:${detik.toString().padLeft(2, '0')}';
  }

  void _submitKuisOtomatis() async {
    _timer?.cancel();

    int jumlahBenar = 0;
    for (int i = 0; i < _daftarSoal.length; i++) {
      var dataSoal = _daftarSoal[i].data() as Map<String, dynamic>;
      int kunciJawaban = dataSoal['jawaban_benar'] ?? 0;
      if (_jawabanMahasiswa[i] == kunciJawaban) {
        jumlahBenar++;
      }
    }

    // Hitung Nilai Skala 100
    int totalNilai = _daftarSoal.isNotEmpty
        ? ((jumlahBenar / _daftarSoal.length) * 100).round()
        : 0;

    // Syarat kelulusan anatomi: Misal minimal nilai 70 stuy
    String statusKelulusan = totalNilai >= 70 ? 'LULUS' : 'TIDAK LULUS';

    await PretestRepository.simpanHasilPretest(
      userId: widget.userId,
      nilai: totalNilai,
      status: statusKelulusan,
    );

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Kuis Selesai!'),
          content: Text('Nilai kamu: $totalNilai\nStatus: $statusKelulusan'),
          actions: [
            ElevatedButton(
              // DIPERBAIKI: Memasang properti warna di dalam styleFrom agar valid
              style: ElevatedButton.styleFrom(backgroundColor: maroonPrimary),
              onPressed: () {
                Navigator.pop(context); // Tutup dialog
                Navigator.pop(context); // Kembali ke Beranda
              },
              child: const Text('Kembali ke Beranda',
                  style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_daftarSoal.isEmpty) {
      return const Scaffold(
          body: Center(child: Text("Dosen belum menginput soal pretest.")));
    }

    var dataSoalSekarang =
        _daftarSoal[_currentIndex].data() as Map<String, dynamic>;
    String pertanyaan = dataSoalSekarang['pertanyaan'] ?? '';
    List<dynamic> opsi = dataSoalSekarang['opsi'] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F6),
      appBar: AppBar(
        title: Text('PRETEST - SOAL ${_currentIndex + 1}/${_daftarSoal.length}',
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 15)),
        backgroundColor: maroonPrimary,
        automaticallyImplyLeading:
            false, // Biar mhs ga sengaja pencet back pas kuis
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(_formatWaktu(_waktuTersisa),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kotak Pertanyaan
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  pertanyaan,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textDark),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Opsi Jawaban A, B, C, D
            Expanded(
              child: ListView.builder(
                itemCount: opsi.length,
                itemBuilder: (context, index) {
                  bool isSelected = _jawabanMahasiswa[_currentIndex] == index;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _jawabanMahasiswa[_currentIndex] = index;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? maroonPrimary.withValues(alpha: 0.1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              isSelected ? maroonPrimary : Colors.grey.shade200,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor:
                                isSelected ? maroonPrimary : Colors.grey[300],
                            child: Text(
                              String.fromCharCode(65 + index),
                              style: TextStyle(
                                  fontSize: 11,
                                  color: isSelected ? Colors.white : textDark,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              opsi[index].toString(),
                              style: TextStyle(
                                  fontSize: 13,
                                  color: textDark,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Tombol Navigasi Bawah (Sebelumnya / Selanjutnya)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentIndex > 0)
                  OutlinedButton(
                    onPressed: () => setState(() => _currentIndex--),
                    child: const Text('Sebelumnya'),
                  )
                else
                  const SizedBox(),
                ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(backgroundColor: maroonPrimary),
                  onPressed: () {
                    if (_currentIndex < _daftarSoal.length - 1) {
                      setState(() => _currentIndex++);
                    } else {
                      _submitKuisOtomatis();
                    }
                  },
                  // DIPERBAIKI: Memasang const pada text widget untuk efisiensi render
                  child: Text(
                    _currentIndex == _daftarSoal.length - 1
                        ? 'Selesai & Kumpulkan'
                        : 'Selanjutnya',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
