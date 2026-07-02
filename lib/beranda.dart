import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'sign_in.dart';
import 'dosen/modul_page.dart';
import 'gerbang_ujian_page.dart';
import 'gerbang_posttest_page.dart'; // ✅ Tetap dipertahankan stuy

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

  String namaTampil = "";
  String npmTampil = "";
  bool isLoading = true;
  bool _checkingAuthorization = true;
  bool _isAuthorized = false;

  int skorPretest = 0;
  String statusPretest = "BELUM DIAMBIL";
  int skorPostest = 0;
  String statusPostest = "BELUM DIAMBIL";

  @override
  void initState() {
    super.initState();
    namaTampil = widget.namaMahasiswa;
    npmTampil = widget.npmMahasiswa;
    _checkAuthorization();
  }

  Future<void> _checkAuthorization() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _redirectToSignIn();
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final role = snapshot.exists && snapshot.data() != null
          ? (snapshot.data() as Map<String, dynamic>)['role']?.toString() ?? ''
          : '';

      if (role != 'mahasiswa') {
        await FirebaseAuth.instance.signOut();
        _redirectToSignIn();
        return;
      }

      _listenDataMahasiswaDanNilai();
      if (mounted) {
        setState(() {
          _isAuthorized = true;
          _checkingAuthorization = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _checkingAuthorization = false;
          _isAuthorized = false;
        });
      }
      await FirebaseAuth.instance.signOut();
      _redirectToSignIn();
    }
  }

  void _redirectToSignIn() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SignInPage()),
      (route) => false,
    );
  }

  void _listenDataMahasiswaDanNilai() {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .snapshots()
          .listen((userDoc) {
        if (userDoc.exists && userDoc.data() != null) {
          Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              namaTampil = data['nama'] ?? widget.namaMahasiswa;
              npmTampil = data['npm'] ?? widget.npmMahasiswa;

              skorPretest = data['nilai_pretest'] ?? 0;
              statusPretest = data['status_pretest'] ?? "BELUM DIAMBIL";
              skorPostest = data['nilai_postest'] ?? 0;
              statusPostest = data['status_postest'] ?? "BELUM DIAMBIL";

              isLoading = false;
            });
          }
        }
      }, onError: (e) {
        debugPrint("Gagal mendengarkan data Firestore: $e");
        if (mounted) setState(() => isLoading = false);
      });
    } else {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingAuthorization) {
      return const Scaffold(
        backgroundColor: Color(0xFFF9F6F6),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAuthorized) {
      return const Scaffold(
        backgroundColor: Color(0xFFF9F6F6),
        body: Center(
            child: Text('Akses tidak diizinkan. Mengarahkan ke login...')),
      );
    }

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
            onPressed: () async {
              final navigator = Navigator.of(context);
              await FirebaseAuth.instance.signOut();
              navigator.pushReplacement(
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
                Expanded(
                  child: Column(
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
                      isLoading
                          ? const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(
                              namaTampil,
                              style: TextStyle(
                                color: textDark,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                      Text(
                        'NPM: $npmTampil',
                        style: TextStyle(
                          color: maroonPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
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
                        fontStyle: FontStyle.italic,
                      ),
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

            // 🚨 MODIFIKASI DISINI STUY - KELOMPOK CARD PRETEST 🚨
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
                      const Expanded(
                        child: Text(
                          "Pretest Syarat Masuk Lab",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // ✅ FIX: Tombol selalu aktif (onPressed tidak dilempar null) agar bisa pindah ke GerbangUjianPage yang dinamis
                  _buildElevatedButton(
                    'Ambil Pretest',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const GerbangUjianPage(isPretest: true),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      'Batas kelulusan minimal skor: 70',
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
                          builder: (_) => const GerbangPosttestPage(),
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
                      status: statusPretest,
                      statusColor: statusPretest == 'LULUS'
                          ? Colors.green
                          : (statusPretest == 'TIDAK LULUS'
                              ? Colors.red
                              : textDark),
                      progressValue: skorPretest / 100,
                      progressText: statusPretest == 'BELUM DIAMBIL'
                          ? '-'
                          : '$skorPretest',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildProgressCard(
                      title: 'POSTEST HASIL',
                      subtitle: 'Skor Postest Terbaik',
                      status: statusPostest,
                      statusColor: statusPostest == 'LULUS'
                          ? Colors.green
                          : (statusPostest == 'TIDAK LULUS'
                              ? Colors.red
                              : textDark),
                      progressValue: skorPostest / 100,
                      progressText: statusPostest == 'BELUM DIAMBIL'
                          ? '-'
                          : '$skorPostest',
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
