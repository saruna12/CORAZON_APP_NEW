import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pretest_repository.dart'; // ✅ FIX: Pakai PretestRepository, bukan PosttestRepository
import 'kuis_posttest_page.dart';

class PosttestPage extends StatefulWidget {
  const PosttestPage({super.key});

  @override
  State<PosttestPage> createState() => _PosttestPageState();
}

class _PosttestPageState extends State<PosttestPage> {
  final Color maroonPrimary = const Color(0xFF6B1D2F);

  @override
  void initState() {
    super.initState();
    PretestRepository
        .listenStatusUjian(); // ✅ FIX: Ganti PosttestRepository → PretestRepository
  }

  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F6),
      appBar: AppBar(
        title: const Text('Halaman Posttest',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: maroonPrimary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.assignment_turned_in_rounded,
                      size: 80, color: maroonPrimary),
                  const SizedBox(height: 16),
                  const Text(
                    "Posttest Anatomi CORAZON",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Kuis ini terdiri dari 5 soal acak yang dipilih langsung oleh sistem. Waktu pengerjaan adalah 10 menit.",
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Info user yang login
                  if (userId.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_rounded,
                              size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 6),
                          Text(
                            FirebaseAuth.instance.currentUser?.email ?? userId,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),

                  // Warning belum login
                  if (userId.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_rounded,
                              color: Colors.red.shade700),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              "Kamu belum login. Silakan login terlebih dahulu.",
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // ✅ FIX: Pakai PretestRepository.statusUjianLive
                  ValueListenableBuilder<bool>(
                    valueListenable: PretestRepository.statusUjianLive,
                    builder: (context, isLive, child) {
                      if (!isLive) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.lock_clock_rounded,
                                  color: Colors.amber.shade800),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Ujian belum dibuka oleh Dosen. Silakan tunggu info selanjutnya.",
                                  style: TextStyle(
                                      color: Colors.amber.shade900,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                userId.isEmpty ? Colors.grey : maroonPrimary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.play_arrow_rounded,
                              color: Colors.white),
                          label: const Text(
                            "Mulai Kerjakan Kuis",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                          onPressed: userId.isEmpty
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          KuisPosttestPage(userId: userId),
                                    ),
                                  );
                                },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
