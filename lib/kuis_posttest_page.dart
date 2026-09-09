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
  final Map<int, int> _jawabanMahasiswa = {};
  final Map<int, List<String>> _opsiAcak = {};
  final Map<int, int> _jawabanBenarAcak = {};

  Timer? _timer;
  static const int _batasWaktuDetik = 30;
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
          .get();

      var soalRaw = querySnapshot.docs;

      if (soalRaw.isNotEmpty) {
        List<DocumentSnapshot> listAcak = List.from(soalRaw);
        listAcak.shuffle(); // Acak soal biar beda urutannya dari pretest

        if (mounted) {
          final soalTerpilih = listAcak.take(5).toList();
          _siapkanOpsiAcak(soalTerpilih);
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

  void _siapkanOpsiAcak(List<DocumentSnapshot> soal) {
    for (int soalIndex = 0; soalIndex < soal.length; soalIndex++) {
      final data = soal[soalIndex].data() as Map<String, dynamic>;
      final opsiAsli = List<String>.from(data['opsi'] ?? []);
      final urutan = List<int>.generate(opsiAsli.length, (index) => index)
        ..shuffle();
      _opsiAcak[soalIndex] = [for (final index in urutan) opsiAsli[index]];
      _jawabanBenarAcak[soalIndex] =
          urutan.indexOf((data['jawaban_benar'] as num?)?.toInt() ?? 0);
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
            'Waktu 30 detik telah habis. Jawaban tidak dihitung dan sesi ini tetap dianggap belum mengerjakan posttest.'),
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

    int jumlahBenar = 0;
    for (int i = 0; i < _daftarSoal.length; i++) {
      int jawabanBenar = _jawabanBenarAcak[i] ?? 0;
      int? jawabanMhs = _jawabanMahasiswa[i];
      if (jawabanMhs != null && jawabanMhs == jawabanBenar) {
        jumlahBenar++;
      }
    }

    int totalNilai = _daftarSoal.isNotEmpty
        ? ((jumlahBenar / _daftarSoal.length) * 100).round()
        : 0;

    const String statusHasil = 'SELESAI';

    // ✅ TAMBAHAN: hitung durasi pengerjaan
    int durasiDetik = _totalWaktuAwal - _waktuTersisa;
    if (durasiDetik < 0) durasiDetik = 0;

    // ✅ Simpan via PretestRepository → field nilai_posttest & status_posttest
    final berhasilDisimpan = await PretestRepository.simpanHasilPosttest(
      userId: widget.userId,
      nilai: totalNilai,
      status: statusHasil,
      durasiDetik: durasiDetik,
    );
    if (!berhasilDisimpan) {
      _sedangMengirim = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Nilai gagal disimpan. Silakan coba lagi.')),
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
          title: const Text('Posttest Selesai!',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text(
              'Nilai akhir: $totalNilai\nStatus jawaban: $jumlahBenar/${_daftarSoal.length}'),
          actions: [
            TextButton(
              onPressed: _tampilkanSoalSalah,
              child: const Text('Review Ujian'),
            ),
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

  void _tampilkanSoalSalah() {
    var reviewIndex = 0;
    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final data = _daftarSoal[reviewIndex].data() as Map<String, dynamic>;
          final opsi = _opsiAcak[reviewIndex] ?? <String>[];
          final jawabanDipilih = _jawabanMahasiswa[reviewIndex];
          final jawabanBenar = _jawabanBenarAcak[reviewIndex] ?? 0;
          return AlertDialog(
            title: Text('Review Soal ${reviewIndex + 1}/${_daftarSoal.length}'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${data['pertanyaan'] ?? ''}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  for (int index = 0; index < opsi.length; index++)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: index == jawabanBenar
                            ? Colors.green.shade50
                            : index == jawabanDipilih
                                ? Colors.red.shade50
                                : Colors.grey.shade100,
                        border: Border.all(
                          color: index == jawabanBenar
                              ? Colors.green
                              : index == jawabanDipilih
                                  ? Colors.red
                                  : Colors.grey.shade300,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                          '${String.fromCharCode(65 + index)}. ${opsi[index]}'),
                    ),
                  const SizedBox(height: 4),
                  Text('Jawaban benar: ${opsi[jawabanBenar]}',
                      style: const TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: reviewIndex == 0
                    ? null
                    : () => setDialogState(() => reviewIndex--),
                child: const Text('Sebelumnya'),
              ),
              if (reviewIndex < _daftarSoal.length - 1)
                TextButton(
                  onPressed: () => setDialogState(() => reviewIndex++),
                  child: const Text('Selanjutnya'),
                )
              else
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Selesai'),
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
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
        List<String> opsi = _opsiAcak[_currentIndex] ?? [];

        return Scaffold(
          backgroundColor: const Color(0xFFF9F6F6),
          appBar: AppBar(
            title: Text(
                'POSTTEST | SOAL ${_currentIndex + 1}/${_daftarSoal.length} | 30 DETIK',
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
                        if (!_jawabanMahasiswa.containsKey(_currentIndex)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Pilih jawaban terlebih dahulu.')),
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
