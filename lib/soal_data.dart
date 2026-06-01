class Soal {
  final String pertanyaan;
  final List<String>? pilihan; // Diperbolehkan null jika soal berbentuk esai
  final int? jawabanBenarIndex; // Diperbolehkan null jika soal berbentuk esai
  final bool isEsai;

  const Soal({
    required this.pertanyaan,
    this.pilihan,
    this.jawabanBenarIndex,
    this.isEsai = false,
  });
}

const List<Soal> daftarSoal = [
  // PILIHAN GANDA (MUDAH & SEDANG)
  Soal(
    pertanyaan: 'Di mana letak organ jantung pada tubuh manusia?',
    pilihan: ['A. Rongga perut sebelah kanan', 'B. Rongga dada sebelah kiri', 'C. Di dalam rongga panggul', 'D. Di bawah hati'],
    jawabanBenarIndex: 1,
    isEsai: false,
  ),
  Soal(
    pertanyaan: 'Apa fungsi utama dari komponen jantung di dalam sistem peredaran darah manusia?',
    pilihan: ['A. Membawa oksigen ke seluruh tubuh', 'B. Memompa darah ke seluruh tubuh', 'C. Menyaring racun di dalam darah', 'D. Menghasilkan sel darah merah'],
    jawabanBenarIndex: 1,
    isEsai: false,
  ),
  Soal(
    pertanyaan: 'Jantung manusia memiliki berapa ruang utama?',
    pilihan: ['A. 2 Ruang', 'B. 3 Ruang', 'C. 4 Ruang', 'D. 5 Ruang'],
    jawabanBenarIndex: 2,
    isEsai: false,
  ),
  Soal(
    pertanyaan: 'Pembuluh darah yang bertugas membawa darah kembali menuju ke jantung dinamakan...',
    pilihan: ['A. Pembuluh Arteri', 'B. Pembuluh Vena', 'C. Pembuluh Kapiler', 'D. Aorta'],
    jawabanBenarIndex: 1,
    isEsai: false,
  ),

  // ESAI (SUSAH - Melatih Analisis)
  Soal(
    pertanyaan: 'Jelaskan perbedaan fungsi antara pembuluh darah Arteri (Nadi) dengan pembuluh darah Vena (Balik)!',
    isEsai: true,
  ),
  Soal(
    pertanyaan: 'Mengapa bagian Bilik Kiri (Ventrikel Kiri) jantung memiliki dinding otot yang jauh lebih tebal dibandingkan bagian lainnya?',
    isEsai: true,
  ),
];