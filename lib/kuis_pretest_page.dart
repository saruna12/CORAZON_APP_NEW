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
  final Color maroonPrimary = const Color(0xFF6B1D2F);
  final Color textDark = const Color(0xFF2C2C2C);

  List<DocumentSnapshot> _daftarSoal = [];
  bool _isLoading = true;
  int _currentIndex = 0;

  // Map untuk menyimpan jawaban mahasiswa (Indeks Soal -> Huruf Opsi "A"/"B"/"C"/"D")
  final Map<int, String> _jawabanMahasiswa = {};

  // Logika Timer Kontrol
  Timer? _timer;
  int _waktuTersisa = 600; // 10 Menit dalam hitungan detik

  @override
  void initState() {
    super.initState();
    _muatSoalDanMulaiTimer();
  }

  void _muatSoalDanMulaiTimer() async {
    try {
      // 1. Ambil data mentah dari Repository
      var soalRaw = await PretestRepository.ambilSemuaSoal();

      if (soalRaw.isNotEmpty) {
        // 2. KUNCI UTAMA ANTI-CURANG: Acak urutan list soal stuy!
        List<DocumentSnapshot> listAcak = List.from(soalRaw);
        listAcak.shuffle();

        // 3. BATASI SOAL: Hanya ambil maksimal 5 soal teratas setelah diacak
        setState(() {
          _daftarSoal = listAcak.take(5).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _daftarSoal = [];
          _isLoading = false;
        });
      }

      _mulaiTimerMundur();
    } catch (e) {
      debugPrint("Gagal memuat kuis: $e");
      setState(() {
        _isLoading = false;
      });
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
      String kunciJawaban =
          dataSoal['kunci'] ?? ""; // Menggunakan 'kunci' dari Excel
      String jawabanMhs = _jawabanMahasiswa[i] ?? "";

      if (jawabanMhs == kunciJawaban) {
        jumlahBenar++;
      }
    }

    // Hitung Nilai Skala 100 berdasarkan 5 soal yang didapat
    int totalNilai = _daftarSoal.isNotEmpty
        ? ((jumlahBenar / _daftarSoal.length) * 100).round()
        : 0;

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
          content:
              Text('Nilai kamu: $totalNilai\nStatus: $statusKelulusan stuy.'),
          actions: [
            ElevatedButton(
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
      return Scaffold(
          body: Center(child: CircularProgressIndicator(color: maroonPrimary)));
    }

    if (_daftarSoal.isEmpty) {
      return const Scaffold(
          body:
              Center(child: Text("Dosen belum menginput soal pretest stuy.")));
    }

    var dataSoalSekarang =
        _daftarSoal[_currentIndex].data() as Map<String, dynamic>;
    String pertanyaan = dataSoalSekarang['soal'] ?? '';

    // Susun opsi ke dalam List pasangan (Key: Huruf, Value: Teks Opsi)
    List<Map<String, String>> listOpsi = [];

    if ((dataSoalSekarang['opsi_a'] ?? '').toString().isNotEmpty) {
      listOpsi.add({"huruf": "A", "teks": dataSoalSekarang['opsi_a']});
    }
    if ((dataSoalSekarang['opsi_b'] ?? '').toString().isNotEmpty) {
      listOpsi.add({"huruf": "B", "teks": dataSoalSekarang['opsi_b']});
    }
    if ((dataSoalSekarang['opsi_c'] ?? '').toString().isNotEmpty) {
      listOpsi.add({"huruf": "C", "teks": dataSoalSekarang['opsi_c']});
    }
    if ((dataSoalSekarang['opsi_d'] ?? '').toString().isNotEmpty) {
      listOpsi.add({"huruf": "D", "teks": dataSoalSekarang['opsi_d']});
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F6),
      appBar: AppBar(
        title: Text('PRETEST - SOAL ${_currentIndex + 1}/${_daftarSoal.length}',
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 15)),
        backgroundColor: maroonPrimary,
        automaticallyImplyLeading: false,
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
          crossAxisAlignment: CrossAxisAlignment
              .start, // ✅ FIXED: Sudah diperbaiki dari 'cross upgrade'
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
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    pertanyaan,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textDark),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Opsi Jawaban A, B, C, D
            Expanded(
              child: ListView.builder(
                itemCount: listOpsi.length,
                itemBuilder: (context, index) {
                  String huruf = listOpsi[index]["huruf"]!;
                  String teksOpsi = listOpsi[index]["teks"]!;
                  bool isSelected = _jawabanMahasiswa[_currentIndex] == huruf;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _jawabanMahasiswa[_currentIndex] = huruf;
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
                              huruf,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: isSelected ? Colors.white : textDark,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              teksOpsi,
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

            // Tombol Navigasi Bawah
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentIndex > 0)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        side: BorderSide(color: maroonPrimary)),
                    onPressed: () => setState(() => _currentIndex--),
                    child: Text('Sebelumnya',
                        style: TextStyle(color: maroonPrimary)),
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
