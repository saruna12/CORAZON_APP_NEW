import 'package:flutter/material.dart';

class BankSoalPage extends StatefulWidget {
  const BankSoalPage({super.key});

  @override
  State<BankSoalPage> createState() => _BankSoalPageState();
}

class _BankSoalPageState extends State<BankSoalPage> {
  // Setup warna khas tema CORAZON
  final Color maroonPrimary = const Color(0xFF6B1D2F);
  final Color textDark = const Color(0xFF2C2C2C);

  // Data contoh simulasi butir soal
  final List<Map<String, dynamic>> _dummyQuestions = [
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

  // Fungsi memunculkan pop-up tambah soal baru (Simulasi)
  void _showAddQuestionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            Icon(Icons.add_task, color: maroonPrimary),
            const SizedBox(width: 10),
            const Text('Tambah Soal Pretest',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fitur ketik soal baru sedang dalam pengembangan sistem database utama.',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Saat ini butir soal otomatis tersinkronisasi langsung ke lembar ujian mahasiswa (TestPage).',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK',
                style: TextStyle(
                    color: maroonPrimary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F6),
      appBar: AppBar(
        title: const Text(
          'BANK SOAL ANATOMI',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
        ),
        backgroundColor: maroonPrimary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _dummyQuestions.length,
        itemBuilder: (context, qIndex) {
          final item = _dummyQuestions[qIndex];

          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label Nomor Soal stuy (SUDAH DIPERBAIKI MENJADI spaceBetween)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: maroonPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Pilihan Ganda - No. ${qIndex + 1}',
                          style: TextStyle(
                              color: maroonPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Icon(Icons.more_vert, color: Colors.grey, size: 20),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Teks Pertanyaan
                  Text(
                    item['question'],
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textDark,
                        fontSize: 14),
                  ),
                  const SizedBox(height: 12),

                  // List Pilihan Jawaban A, B, C, D
                  ...List.generate(item['answers'].length, (aIndex) {
                    bool isCorrect = aIndex == item['correctIndex'];

                    return Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 4), // SUDAH DIPERBAIKI KE MARGIN
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isCorrect ? Colors.green[50] : Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        // SUDAH DIPERBAIKI MENGGUNAKAN Border.all
                        border: Border.all(
                          color: isCorrect
                              ? Colors.green.shade300
                              : Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Lingkaran Huruf A/B/C/D
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: isCorrect
                                ? Colors.green[600]
                                : Colors.grey[300],
                            child: Text(
                              String.fromCharCode(65 + aIndex),
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Teks Opsi Jawaban
                          Expanded(
                            child: Text(
                              item['answers'][aIndex],
                              style: TextStyle(
                                fontSize: 13,
                                color: isCorrect ? Colors.green[900] : textDark,
                                fontWeight: isCorrect
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),

                          // Tanda Centang Kunci Jawaban stuy
                          if (isCorrect)
                            const Icon(Icons.check_circle,
                                color: Colors.green, size: 18),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
      // Tombol melayang tambah soal stuy
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: maroonPrimary,
        foregroundColor: Colors.white,
        onPressed: _showAddQuestionDialog,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Soal',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
