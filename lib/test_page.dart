import 'dart:async';
import 'package:flutter/material.dart';
import 'pretest_repository.dart'; // Import repository pendeteksi status

class TestPage extends StatefulWidget {
  final String testType;
  const TestPage({super.key, required this.testType});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  bool isTestStarted = false;
  int _remainingTime = 180; // 3 Menit
  Timer? _timer;
  int _currentQuestionIndex = 0;

  final List<Map<String, dynamic>> _questions = [
    {
      'question':
          'Tulang terbesar dan terkuat pada tubuh manusia yang menyusun bagian paha adalah...',
      'answers': ['Femur', 'Humerus', 'Tibia', 'Fibula'],
      'correctIndex': 0
    },
    {
      'question':
          'Otot yang terletak di lengan atas bagian depan dan berfungsi untuk fleksi siku adalah...',
      'answers': [
        'Triceps Brachii',
        'Biceps Brachii',
        'Deltoid',
        'Pectoralis Major'
      ],
      'correctIndex': 1
    }
  ];

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
        _finishTest();
      }
    });
  }

  void _finishTest() {
    _timer?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Ujian Selesai'),
        content: const Text(
            'Waktu habis atau kamu telah mengirim jawaban. Nilai kamu berhasil direkap ke dosen.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK',
                style: TextStyle(
                    color: Color(0xFF801A24), fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
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

    // Memantau status menggunakan nama variabel baru di repository
    return ValueListenableBuilder<bool>(
      valueListenable: PretestRepository.statusUjianLive,
      builder: (context, apakahUjianTerbuka, child) {
        // 1. JIKA BELUM DIBUKA DOSEN
        if (!apakahUjianTerbuka) {
          return Scaffold(
            appBar: AppBar(
                title: Text(widget.testType),
                backgroundColor: maroonColor,
                foregroundColor: Colors.white),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_clock, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Pre-Test Belum Dibuka',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Akses ujian masih dikunci oleh Dosen. Silakan tunggu instruksi praktikum dimulai di ruangan.',
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
                foregroundColor: Colors.white),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.assignment, size: 80, color: maroonColor),
                    const SizedBox(height: 16),
                    Text('Ujian ${widget.testType} Siap!',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer, color: Colors.amber[800]),
                          const SizedBox(width: 8),
                          const Text('Durasi Waktu: 3 Menit (180 Detik)',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: maroonColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 12)),
                      onPressed: _startTimer,
                      child: const Text('MULAI UJIAN NOW',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),
            ),
          );
        }

        // 3. TAMPILAN LEMBAR SOAL
        var currentQuestion = _questions[_currentQuestionIndex];
        return Scaffold(
          appBar: AppBar(
            title:
                Text('${widget.testType} - No. ${_currentQuestionIndex + 1}'),
            backgroundColor: maroonColor,
            foregroundColor: Colors.white,
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
              crossAxisAlignment:
                  CrossAxisAlignment.start, // <--- SUDAH REKAD DAN BENAR STUY
              children: [
                LinearProgressIndicator(
                    value: _remainingTime / 180,
                    color: maroonColor,
                    backgroundColor: Colors.grey.shade300),
                const SizedBox(height: 20),
                Text(currentQuestion['question'],
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w500)),
                const SizedBox(height: 24),
                ...List.generate(currentQuestion['answers'].length, (index) {
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(currentQuestion['answers'][index]),
                      leading: CircleAvatar(
                          child: Text(String.fromCharCode(65 + index))),
                      onTap: () {
                        if (_currentQuestionIndex < _questions.length - 1) {
                          setState(() {
                            _currentQuestionIndex++;
                          });
                        } else {
                          _finishTest();
                        }
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
