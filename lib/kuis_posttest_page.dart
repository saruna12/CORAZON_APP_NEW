import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ============================================================
// POSTTEST REPOSITORY (digabung langsung di sini)
// ============================================================
class PosttestRepository {
  static final ValueNotifier<bool> statusUjianLive = ValueNotifier<bool>(false);

  static Future<void> ubahStatusUjian(bool statusBaru) async {
    try {
      await FirebaseFirestore.instance
          .collection('bank_soal')
          .doc('kontrol_posttest')
          .set({
        'is_aktif': statusBaru,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      statusUjianLive.value = statusBaru;
    } catch (e) {
      debugPrint("Gagal mengubah status akses ujian posttest: $e");
    }
  }

  static void listenStatusUjian() {
    FirebaseFirestore.instance
        .collection('bank_soal')
        .doc('kontrol_posttest')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        var data = snapshot.data() as Map<String, dynamic>;
        statusUjianLive.value = data['is_aktif'] ?? false;
      }
    });
  }

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
      debugPrint("Gagal menyimpan nilai posttest: $e");
    }
  }

  static Future<void> importMassalBankSoal(List<List<dynamic>> rows) async {
    try {
      final collectionRef = FirebaseFirestore.instance
          .collection('bank_soal')
          .doc('paket_utama_posttest')
          .collection('daftar_soal');

      for (var row in rows) {
        if (row.isEmpty || row[0].toString().toLowerCase().contains('no')) {
          continue; // ✅ FIX: dibungkus kurung kurawal
        }
        if (row.length < 2 ||
            row[1] == null ||
            row[1].toString().trim().isEmpty) {
          continue; // ✅ FIX: dibungkus kurung kurawal
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
      debugPrint("Semua soal posttest berhasil di-import!");
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}

// ============================================================
// KUIS POSTTEST PAGE
// ============================================================
class KuisPosttestPage extends StatefulWidget {
  final String userId;
  const KuisPosttestPage({super.key, required this.userId});

  @override
  State<KuisPosttestPage> createState() => _KuisPosttestPageState();
}

class _KuisPosttestPageState extends State<KuisPosttestPage> {
  final Color maroonPrimary = const Color(0xFF6B1D2F);
  final Color textDark = const Color(0xFF2C2C2C);

  List<DocumentSnapshot> _daftarSoal = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  final Map<int, int> _jawabanMahasiswa = {};

  Timer? _timer;
  int _waktuTersisa = 600;

  @override
  void initState() {
    super.initState();
    _muatSoalDanMulaiTimer();
  }

  void _muatSoalDanMulaiTimer() async {
    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection('bank_soal')
          .doc('paket_utama_posttest')
          .collection('daftar_soal')
          .get();

      var soalRaw = querySnapshot.docs;

      if (soalRaw.isNotEmpty) {
        List<DocumentSnapshot> listAcak = List.from(soalRaw);
        listAcak.shuffle();
        if (mounted) {
          setState(() {
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
      debugPrint("Gagal memuat kuis posttest: $e");
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
        _submitKuisOtomatis();
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
      int jawabanBenar = dataSoal['jawaban_benar'] ?? 0;
      int? jawabanMhs = _jawabanMahasiswa[i];
      if (jawabanMhs != null && jawabanMhs == jawabanBenar) {
        jumlahBenar++;
      }
    }

    int totalNilai = _daftarSoal.isNotEmpty
        ? ((jumlahBenar / _daftarSoal.length) * 100).round()
        : 0;
    String statusKelulusan = totalNilai >= 70 ? 'LULUS' : 'TIDAK LULUS';

    await PosttestRepository.simpanHasilPosttest(
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
          title: const Text('Posttest Selesai!',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text('Nilai kamu: $totalNilai\nStatus: $statusKelulusan.'),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: maroonPrimary),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
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
      valueListenable: PosttestRepository.statusUjianLive,
      builder: (context, isLive, child) {
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
                    Text("POSTTEST DITUTUP OLEH DOSEN",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textDark)),
                    const SizedBox(height: 12),
                    const Text(
                        "Waktu akses habis atau sesi dikunci oleh dosen.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.grey)),
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

        if (_isLoading) {
          return Scaffold(
            backgroundColor: const Color(0xFFF9F6F6),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: maroonPrimary),
                  const SizedBox(height: 16),
                  const Text("Mengekstrak kuis posttest acak kamu...",
                      style: TextStyle(fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          );
        }

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
                  const Text("Belum ada soal posttest tersedia.",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        }

        var dataSoalSekarang =
            _daftarSoal[_currentIndex].data() as Map<String, dynamic>;
        String pertanyaan = dataSoalSekarang['pertanyaan'] ?? '';
        List<String> opsi = List<String>.from(dataSoalSekarang['opsi'] ?? []);

        return Scaffold(
          backgroundColor: const Color(0xFFF9F6F6),
          appBar: AppBar(
            title: Text(
                'POSTTEST - SOAL ${_currentIndex + 1}/${_daftarSoal.length}',
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
                      color: Colors.white.withAlpha(51),
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
                      child: Text(pertanyaan,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textDark)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: opsi.length,
                    itemBuilder: (context, index) {
                      String hurufAwalan = String.fromCharCode(65 + index);
                      bool isSelected =
                          _jawabanMahasiswa[_currentIndex] == index;

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
                                child: Text(hurufAwalan,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: isSelected
                                            ? Colors.white
                                            : textDark,
                                        fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(opsi[index],
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: textDark,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentIndex > 0)
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                            side: BorderSide(color: maroonPrimary)),
                        onPressed: () {
                          setState(() {
                            _currentIndex--;
                          });
                        },
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
                          setState(() {
                            _currentIndex++;
                          });
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
