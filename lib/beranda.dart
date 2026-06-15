import 'package:flutter/material.dart';
import 'pretest_model.dart';
import 'sign_in.dart';
import 'test_page.dart';
import 'dosen/modul_page.dart';

class BerandaPage extends StatefulWidget {
  final String namaMahasiswa;
  final String npmMahasiswa;

  const BerandaPage({
    super.key,
    required this.namaMahasiswa,
    this.npmMahasiswa = "210810100xx",
  });

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage> {
  final Color maroonPrimary = const Color(0xFF6B1D2F);
  final Color maroonLight = const Color(0xFFF3EBE9);
  final Color textDark = const Color(0xFF2C2C2C);

  final PretestModel dataPretest = PretestModel(
    id: "1",
    judul: "Pretest Syarat Masuk Lab",
    waktuMulai: DateTime(2026, 6, 11, 8, 30),
  );

  bool cekApakahSudahBuka(DateTime waktuJadwal) {
    DateTime waktuSekarang = DateTime.now();
    return waktuSekarang.isAfter(waktuJadwal) ||
        waktuSekarang.isAtSameMomentAs(waktuJadwal);
  }

  @override
  Widget build(BuildContext context) {
    bool isPretestBuka = cekApakahSudahBuka(dataPretest.waktuMulai);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F6),
      appBar: AppBar(
        backgroundColor: maroonPrimary,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.favorite, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'CORAZON',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Log Out',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const SignInPage()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: maroonPrimary,
                  child: const Icon(
                    Icons.person_outline,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo, Selamat Datang Mahasiswa!',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      widget.namaMahasiswa,
                      style: TextStyle(
                        color: textDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'NPM: ${widget.npmMahasiswa}',
                      style: TextStyle(
                        color: maroonPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [maroonPrimary, const Color(0xFF902A3F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_stories, color: Colors.white70, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '“Siap mengeksplorasi visualisasi anatomi kardiovaskular hari ini?”',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (value) {
                  debugPrint("Mencari: $value");
                },
                decoration: InputDecoration(
                  hintText: 'Cari modul atau materi...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: maroonPrimary),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildCustomCard(
                    title: 'VISUALISASI JANTUNG',
                    rightWidget: Icon(Icons.threed_rotation,
                        color: maroonPrimary, size: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          'Eksplorasi Jantung AR',
                          style:
                              TextStyle(color: Colors.grey[700], fontSize: 11),
                        ),
                        const SizedBox(height: 16),
                        _buildOutlineButton('Mulai AR', () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                  'Membuka Kamera Scan AR Anatomi Jantung...'),
                              backgroundColor: maroonPrimary,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCustomCard(
                    title: 'MODUL PEMBELAJARAN',
                    rightWidget: Icon(Icons.menu_book_outlined,
                        color: maroonPrimary, size: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.book, color: maroonPrimary, size: 22),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Anatomi Jantung',
                                    style: TextStyle(
                                      color: maroonPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Modul Utama',
                                    style: TextStyle(
                                        color: Colors.grey[700], fontSize: 10),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildOutlineButton('Mulai Modul', () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ModulPage()),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCustomCard(
              title: 'PRETEST',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: maroonPrimary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.assignment_turned_in_outlined,
                            color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          dataPretest.judul,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildElevatedButton(
                    isPretestBuka ? 'Ambil Pretest' : 'Pretest Belum Dibuka',
                    onPressed: isPretestBuka
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const TestPage(testType: 'Pre-Test'),
                              ),
                            );
                          }
                        : null,
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      'Batas kelulusan minimal skor: 60',
                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildCustomCard(
              title: 'POSTEST',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Icon(Icons.emoji_events_outlined,
                            color: maroonPrimary, size: 30),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Postest Pembelajaran',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildElevatedButton(
                    'Ambil Postest',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TestPage(testType: 'Post-Test'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      'Batas kelulusan minimal skor: 60',
                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildCustomCard(
              title: 'DASHBOARD KEMAMPUAN',
              titleAlign: TextAlign.center,
              child: Row(
                children: [
                  Expanded(
                    child: _buildProgressCard(
                      title: 'PRETEST HASIL',
                      subtitle: 'Skor Pretest Terbaik',
                      status: 'BELUM DIAMBIL',
                      statusColor: const Color.fromARGB(255, 0, 0, 0),
                      progressValue: 0.0,
                      progressText: '-',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildProgressCard(
                      title: 'POSTEST HASIL',
                      subtitle: 'Skor Postest Terbaik',
                      status: 'BELUM DIAMBIL',
                      statusColor: textDark,
                      progressValue: 0.0,
                      progressText: '-',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomCard({
    required String title,
    TextAlign titleAlign = TextAlign.start,
    Widget? rightWidget,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: maroonLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  textAlign: titleAlign,
                  style: TextStyle(
                    color: textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              if (rightWidget != null) rightWidget,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildOutlineButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: maroonPrimary, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          text,
          style: TextStyle(
              color: maroonPrimary, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildElevatedButton(String text, {VoidCallback? onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: maroonPrimary,
          disabledBackgroundColor: maroonPrimary.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: Text(
          text,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildProgressCard({
    required String title,
    required String subtitle,
    required String status,
    required Color statusColor,
    required double progressValue,
    required String progressText,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              textAlign: TextAlign.center),
          Text(subtitle,
              style: TextStyle(color: Colors.grey[600], fontSize: 9),
              textAlign: TextAlign.center),
          const SizedBox(height: 14),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 65,
                height: 65,
                child: CircularProgressIndicator(
                  value: progressValue == 0.0 ? 1.0 : progressValue,
                  strokeWidth: 6,
                  backgroundColor: const Color(0xFFEFEFEF),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progressValue == 0.0
                        ? const Color(0xFFDCDCDC)
                        : maroonPrimary,
                  ),
                ),
              ),
              Text(
                progressText,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Status: ',
                  style: TextStyle(fontSize: 10, color: Colors.grey)),
              Flexible(
                child: Text(
                  status,
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: statusColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
