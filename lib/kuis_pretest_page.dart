import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pretest_repository.dart';

class KuisPretestPage extends StatefulWidget {
  final String userId; // Oper ID Mahasiswa saat login stuy

  const KuisPretestPage({super.key, required this.userId});

  @override
  State<KuisPretestPage> createState() => _KuisPretestPageState();
}

class _KuisPretestPageState extends State<KuisPretestPage> {
  final Color maroonPrimary = const Color(0xFF6B1D2F);
  final Color textDark = const Color(0xFF2C2C2C);

  List<DocumentSnapshot> _daftarSoal = [];
  bool _isLoading = true; // Indikator loading data awal stuy
  int _currentIndex = 0;

  // 📝 Map menyimpan jawaban mahasiswa (Indeks Soal -> Indeks Opsi yang dipilih: 0, 1, 2, 3)
  final Map<int, int> _jawabanMahasiswa = {};

  // Logika Timer Kontrol
  Timer? _timer;
  int _waktuTersisa = 600; // 10 Menit

  @override
  void initState() {
    super.initState();
    // Ambil data sekali saja saat halaman dibuka stuy, aman dari infinite-loop!
    _muatSoalDanMulaiTimer();
  }

  // 🎰 Membaca Bank Soal Baru secara Acak Dinamis
  void _muatSoalDanMulaiTimer() async {
    try {
      // Mengambil soal dari jalur sub-collection bank_soal paket_utama_pretest
      var querySnapshot = await FirebaseFirestore.instance
          .collection('bank_soal')
          .doc('paket_utama_pretest')
          .collection('daftar_soal')
          .get();

      var soalRaw = querySnapshot.docs;

      if (soalRaw.isNotEmpty) {
        List<DocumentSnapshot> listAcak = List.from(soalRaw);
        listAcak.shuffle(); // 🎲 Acak soal di perangkat mahasiswa stuy

        if (mounted) {
          setState(() {
            // TIPS: Kamu bisa ubah angka 5 ini jadi 20 kalau mau memunculkan 20 soal stuy!
            _daftarSoal = listAcak.take(5).toList();
            _isLoading = false;
          });
        }
        _mulaiTimerMundur();
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Gagal memuat kuis baru: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _mulaiTimerMundur() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_waktuTersisa > 0) {
        if (mounted) {
          setState(() {
            _waktuTersisa--;
          });
        }
      } else {
        _timer?.cancel();
        _submitKuisOtomatis(); // Kumpul otomatis kalau waktu habis stuy
      }
    });
  }

  String _formatWaktu(int totalDetik) {
    int menit = totalDetik ~/ 60;
    int detik = totalDetik % 60;
    return '${menit.toString().padLeft(2, '0')}:${detik.toString().padLeft(2, '0')}';
  }

  // 💾 Koreksi Jawaban Otomatis Berdasarkan Struktur Angka Database Baru
  void _submitKuisOtomatis() async {
    _timer?.cancel();

    int jumlahBenar = 0;
    for (int i = 0; i < _daftarSoal.length; i++) {
      var dataSoal = _daftarSoal[i].data() as Map<String, dynamic>;

      // Ambil index jawaban benar (0=A, 1=B, 2=C, 3=D) dari Firestore hasil import Excel
      int jawabanBenar = dataSoal['jawaban_benar'] ?? 0;
      int? jawabanMhs =
          _jawabanMahasiswa[i]; // Angka opsi pilihan mahasiswa stuy

      if (jawabanMhs != null && jawabanMhs == jawabanBenar) {
        jumlahBenar++;
      }
    }

    // Hitung Nilai Akhir secara adil sesuai total soal yang ditampilkan stuy
    int totalNilai = _daftarSoal.isNotEmpty
        ? ((jumlahBenar / _daftarSoal.length) * 100).round()
        : 0;

    String statusKelulusan = totalNilai >= 70 ? 'LULUS' : 'TIDAK LULUS';

    // Kirim data hasil ke Firebase melalui Repository
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Kuis Selesai!',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content:
              Text('Nilai kamu: $totalNilai\nStatus: $statusKelulusan stuy.'),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: maroonPrimary),
              onPressed: () {
                Navigator.pop(context); // Tutup dialog
                Navigator.pop(context); // Kembali ke Pintu Gerbang Pretest
              },
              child:
                  const Text('Kembali', style: TextStyle(color: Colors.white)),
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
    return ValueListenableBuilder<bool>(
      valueListenable: PretestRepository.statusUjianLive,
      builder: (context, isLive, child) {
        // ❌ KONDISI A: Ujian ditutup dosen saat sedang berjalan
        if (!isLive) {
          return Scaffold(
            backgroundColor: const Color(0xFFF9F6F6),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_clock_rounded,
                        size: 80, color: maroonPrimary),
                    const SizedBox(height: 24),
                    Text(
                      "PRETEST DITUTUP OLEH DOSEN",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textDark),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Waktu akses habis atau sesi pengerjaan telah dikunci oleh dosen stuy.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: maroonPrimary),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Kembali ke Beranda",
                          style: TextStyle(color: Colors.white)),
                    )
                  ],
                ),
              ),
            ),
          );
        }

        // 🔄 TAMPILAN LOADING DATA
        if (_isLoading) {
          return Scaffold(
            backgroundColor: const Color(0xFFF9F6F6),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: maroonPrimary),
                  const SizedBox(height: 16),
                  const Text("Mengekstrak kuis acak kamu stuy...",
                      style: TextStyle(fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          );
        }

        // ⚠️ JIKA DATA KOSONG DI FIREBASE
        if (_daftarSoal.isEmpty) {
          return Scaffold(
            backgroundColor: const Color(0xFFF9F6F6),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_late_rounded,
                      size: 60, color: maroonPrimary),
                  const SizedBox(height: 16),
                  const Text("Belum ada soal pretest tersedia stuy.",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        }

        // 📜 TAMPILKAN LEMBAR SOAL BARU
        var dataSoalSekarang =
            _daftarSoal[_currentIndex].data() as Map<String, dynamic>;
        String pertanyaan = dataSoalSekarang['pertanyaan'] ?? '';
        List<String> opsi = List<String>.from(dataSoalSekarang['opsi'] ?? []);

        return Scaffold(
          backgroundColor: const Color(0xFFF9F6F6),
          appBar: AppBar(
            title: Text(
                'PRETEST - SOAL ${_currentIndex + 1}/${_daftarSoal.length}',
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
                      color: Colors.white.withAlpha(
                          51), // Memakai .withAlpha agar aman di versi SDK stuy
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(_formatWaktu(_waktuTersisa),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
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
                // Kotak Teks Pertanyaan
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

                // Render List Opsi Jawaban (A, B, C, D)
                Expanded(
                  child: ListView.builder(
                    itemCount: opsi.length,
                    itemBuilder: (context, index) {
                      String hurufAwalan =
                          String.fromCharCode(65 + index); // Jadi A, B, C, D
                      bool isSelected =
                          _jawabanMahasiswa[_currentIndex] == index;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _jawabanMahasiswa[_currentIndex] =
                                index; // Simpan indeks pilihan stuy
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? maroonPrimary.withAlpha(25)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? maroonPrimary
                                  : Colors.grey.shade200,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: isSelected
                                    ? maroonPrimary
                                    : Colors.grey[300],
                                child: Text(
                                  hurufAwalan,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color:
                                          isSelected ? Colors.white : textDark,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  opsi[index],
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

                // Tombol Navigasi Lembar Ujian
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
                      style: ElevatedButton.styleFrom(
                          backgroundColor: maroonPrimary),
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
      },
    );
  }
}
