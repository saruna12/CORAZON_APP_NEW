import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pretest_repository.dart'; // ✅ Pakai repository yang sama dengan pretest

// Kontrol akses posttest sekarang satu sumber lewat PretestRepository
// (statusPosttestLive), supaya sinkron dengan gerbang_posttest_page.dart
// dan tidak ada duplikasi listener status.

class KuisPosttestPage extends StatefulWidget {
  final String userId;
  const KuisPosttestPage({super.key, required this.userId});

  @override
  State<KuisPosttestPage> createState() => _KuisPosttestPageState();
}

class _KuisPosttestPageState extends State<KuisPosttestPage>
    with WidgetsBindingObserver {
  final Color maroonPrimary = const Color(0xFF6B1D2F);
  final Color textDark = const Color(0xFF2C2C2C);

  List<DocumentSnapshot> _daftarSoal = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  final List<TextEditingController> _jawabanEssay = [];

  Timer? _timer;
  static const int _batasWaktuDetik = 10 * 60;
  int _waktuTersisa = 0;
  int _totalWaktuAwal = 0; // ✅ TAMBAHAN: untuk hitung durasi pengerjaan
  DateTime? _waktuMulai;
  bool _sedangMengirim = false;
  bool _sudahBerakhir = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    PretestRepository.listenStatusUjian();
    _muatSoalDanMulaiTimer();
  }

  // Soal posttest diambil dari bank soal posttest secara acak.
  void _muatSoalDanMulaiTimer() async {
    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection('bank_soal')
          .doc('paket_utama_posttest')
          .collection('daftar_soal')
          .where('tipe', isEqualTo: 'essay')
          .get();

      var soalRaw = querySnapshot.docs;

      if (soalRaw.length >= 5) {
        List<DocumentSnapshot> listAcak = List.from(soalRaw);
        listAcak.shuffle(); // Acak soal biar beda urutannya dari pretest

        if (mounted) {
          final soalTerpilih = listAcak.take(5).toList();
          _jawabanEssay
            ..clear()
            ..addAll(List.generate(
              soalTerpilih.length,
              (_) => TextEditingController(),
            ));
          setState(() {
            _daftarSoal = soalTerpilih;
          });
        }
        await _mulaiAtauPulihkanTimer();
        if (mounted && !_sudahBerakhir) {
          setState(() => _isLoading = false);
        }
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

  Future<void> _mulaiAtauPulihkanTimer() async {
    final userRef =
        FirebaseFirestore.instance.collection('users').doc(widget.userId);
    final snapshot = await userRef.get();
    final data = snapshot.data();
    final waktuTersimpan = data?['waktu_mulai_posttest'] as Timestamp?;
    final waktuMulai = waktuTersimpan?.toDate() ?? DateTime.now();

    if (waktuTersimpan == null) {
      await userRef.set({
        'waktu_mulai_posttest': Timestamp.fromDate(waktuMulai),
      }, SetOptions(merge: true));
    }

    _waktuMulai = waktuMulai;
    _totalWaktuAwal = _batasWaktuDetik;
    _perbaruiWaktuDariJam();
    if (!_sudahBerakhir) {
      _mulaiTimerMundur();
    }
  }

  void _perbaruiWaktuDariJam() {
    if (_waktuMulai == null || _sudahBerakhir) return;
    final elapsed = DateTime.now().difference(_waktuMulai!).inSeconds;
    final tersisa = _batasWaktuDetik - elapsed;
    if (tersisa <= 0) {
      _waktuTersisa = 0;
      _timer?.cancel();
      _handleWaktuHabis();
      return;
    }
    if (mounted) {
      setState(() => _waktuTersisa = tersisa);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _perbaruiWaktuDariJam();
    }
  }

  void _mulaiTimerMundur() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _perbaruiWaktuDariJam();
    });
  }

  String _formatWaktu(int totalDetik) {
    int menit = totalDetik ~/ 60;
    int detik = totalDetik % 60;
    return '${menit.toString().padLeft(2, '0')}:${detik.toString().padLeft(2, '0')}';
  }

  Future<void> _handleWaktuHabis() async {
    if (_sudahBerakhir || _sedangMengirim) return;
    _sudahBerakhir = true;
    await _hapusWaktuMulai();

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Waktu Habis'),
        content: const Text(
            'Waktu 10 menit telah habis. Jawaban tidak dihitung dan sesi ini tetap dianggap belum mengerjakan posttest.'),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: maroonPrimary),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Kembali', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _submitKuisManual() async {
    if (_sudahBerakhir || _sedangMengirim) return;
    _perbaruiWaktuDariJam();
    if (_sudahBerakhir) return;
    _sedangMengirim = true;
    _timer?.cancel();

    // ✅ TAMBAHAN: hitung durasi pengerjaan
    int durasiDetik = _totalWaktuAwal - _waktuTersisa;
    if (durasiDetik < 0) durasiDetik = 0;

    final jawaban = List.generate(_daftarSoal.length, (index) {
      final data = _daftarSoal[index].data() as Map<String, dynamic>;
      return {
        'soal_id': _daftarSoal[index].id,
        'pertanyaan': data['pertanyaan']?.toString() ?? '',
        'jawaban_mahasiswa': _jawabanEssay[index].text.trim(),
        'nilai': null,
        'catatan_penilai': null,
      };
    });

    final berhasilDisimpan = await PretestRepository.simpanJawabanEssayPosttest(
      userId: widget.userId,
      jawaban: jawaban,
      durasiDetik: durasiDetik,
    );
    if (!berhasilDisimpan) {
      _sedangMengirim = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Jawaban gagal disimpan. Silakan coba lagi.')),
        );
      }
      return;
    }
    await _hapusWaktuMulai();

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Jawaban Berhasil Dikirim',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text(
              'Jawaban essay kamu sudah tersimpan dan menunggu penilaian dari aslab atau dosen.'),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: maroonPrimary),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child:
                  const Text('Selesai', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _jawabanEssay) {
      controller.dispose();
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _hapusWaktuMulai() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .update({'waktu_mulai_posttest': FieldValue.delete()});
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: PretestRepository
          .statusPosttestLive, // ✅ Satu sumber status dengan gerbang_posttest_page
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
                    Text(
                      "POSTTEST DITUTUP OLEH DOSEN",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textDark),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Waktu akses habis atau sesi pengerjaan telah dikunci oleh dosen.",
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

        if (_isLoading) {
          return Scaffold(
            backgroundColor: const Color(0xFFF9F6F6),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: maroonPrimary),
                  const SizedBox(height: 16),
                  const Text("Mengekstrak soal posttest acak kamu...",
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
                  const Text("Belum ada soal tersedia.",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        }

        var dataSoalSekarang =
            _daftarSoal[_currentIndex].data() as Map<String, dynamic>;
        String pertanyaan = dataSoalSekarang['pertanyaan'] ?? '';

        return Scaffold(
          backgroundColor: const Color(0xFFF9F6F6),
          appBar: AppBar(
            title: Text(
                'POSTTEST | SOAL ${_currentIndex + 1}/${_daftarSoal.length} | 10 MENIT',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 13)),
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
                Expanded(
                  child: SingleChildScrollView(
                    child: TextField(
                      controller: _jawabanEssay[_currentIndex],
                      minLines: 7,
                      maxLines: 12,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: 'Tulis jawaban kamu di sini...',
                        filled: true,
                        fillColor: Colors.white,
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                    ),
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
                        if (_jawabanEssay[_currentIndex].text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Isi jawaban terlebih dahulu.')),
                          );
                          return;
                        }
                        if (_currentIndex < _daftarSoal.length - 1) {
                          setState(() {
                            _currentIndex++;
                          });
                        } else {
                          _submitKuisManual();
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
