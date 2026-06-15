import 'package:flutter/material.dart';
import 'soal_data.dart';
import 'sign_in.dart'; 

class HasilTestPage extends StatelessWidget {
  final List<int> userAnswersChoice;
  final List<String> userAnswersEsai;

  const HasilTestPage({
    super.key, 
    required this.userAnswersChoice, 
    required this.userAnswersEsai,
  });

  int _hitungSkorChoice() {
    int jawabanBenar = 0;
    int totalSoalChoice = 0;
    
    for (int i = 0; i < daftarSoal.length; i++) {
      if (!daftarSoal[i].isEsai) {
        totalSoalChoice++;
        if (userAnswersChoice[i] == daftarSoal[i].jawabanBenarIndex) {
          jawabanBenar++;
        }
      }
    }
    return totalSoalChoice > 0 ? (jawabanBenar / totalSoalChoice * 100).round() : 0;
  }

  @override
  Widget build(BuildContext context) {
    const maroonColor = Color(0xFF801A24);
    const navyColor = Color(0xFF1B2A52);
    final skorChoice = _hitungSkorChoice();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: maroonColor,
        elevation: 0,
        title: const Text('HASIL PRE TEST', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: daftarSoal.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(16), 
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Column(
                children: [
                  const Text('Skor Pilihan Ganda Anda', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Text('$skorChoice', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: maroonColor)),
                  const SizedBox(height: 12),
                  const Text('*Jawaban esai disimpan untuk penilaian manual.', style: TextStyle(fontSize: 12, color: Colors.black54, fontStyle: FontStyle.italic)),
                ],
              ),
            );
          }

          final soalIndex = index - 1;
          final soal = daftarSoal[soalIndex];

          if (soal.isEsai) {
            final jawabanEsai = userAnswersEsai[soalIndex];
            return Container(
              margin: const EdgeInsets.only(bottom: 16), // PERBAIKAN: Menggunakan .only(bottom: 16)
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(12), 
                border: Border.all(color: Colors.blue.shade200, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Soal Esai', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      Icon(Icons.edit_note, color: Colors.blue),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(soal.pertanyaan, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.4)),
                  const SizedBox(height: 12),
                  const Text('Jawaban Esai Anda:', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(jawabanEsai.isNotEmpty ? jawabanEsai : 'Tidak dijawab', style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4)),
                ],
              ),
            );
          } else {
            final jawabanUser = userAnswersChoice[soalIndex];
            final kunciJawaban = soal.jawabanBenarIndex;
            final isBenar = jawabanUser == kunciJawaban;

            return Container(
              margin: const EdgeInsets.only(bottom: 16), // PERBAIKAN: Menggunakan .only(bottom: 16)
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(12), 
                border: Border.all(color: isBenar ? Colors.green.shade200 : Colors.red.shade200, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Soal Pilihan Ganda', style: TextStyle(fontWeight: FontWeight.bold, color: navyColor)),
                      Icon(isBenar ? Icons.check_circle : Icons.cancel, color: isBenar ? Colors.green : Colors.red),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(soal.pertanyaan, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.4)),
                  const SizedBox(height: 12),
                  Text('Jawaban Anda: ${jawabanUser != -1 ? soal.pilihan![jawabanUser] : "Tidak dijawab"}', style: TextStyle(color: isBenar ? Colors.green.shade700 : Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 13)),
                  if (!isBenar && kunciJawaban != null) ...[
                    const SizedBox(height: 4),
                    Text('Kunci Jawaban: ${soal.pilihan![kunciJawaban]}', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ],
              ),
            );
          }
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navyColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(context, skorChoice);
                  },
                  child: const Text('KEMBALI KE BERANDA', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context, 
                      MaterialPageRoute(builder: (context) => const SignInPage()), 
                      (route) => false,
                    );
                  },
                  child: const Text('SIGN OUT', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}