import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart'; // ✅ BARU: Import library untuk buka link

class ModulPage extends StatefulWidget {
  final bool isAdmin;
  final bool isDosen;

  const ModulPage({
    super.key,
    this.isAdmin = false,
    this.isDosen = false,
  });

  @override
  State<ModulPage> createState() => _ModulPageState();
}

class _ModulPageState extends State<ModulPage> {
  final Color maroonPrimary = const Color(0xFF6B1D2F);
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();

  // ✅ BARU: Fungsi pintar untuk membuka link di browser eksternal
  Future<void> _bukaLinkMateri(String urlString, BuildContext context) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    // Bersihkan spasi jika ada stuy
    String formattedUrl = urlString.trim();

    if (formattedUrl.isEmpty) return;

    // Pastikan link memiliki prefix http atau https
    if (!formattedUrl.startsWith('http://') &&
        !formattedUrl.startsWith('https://')) {
      formattedUrl = 'https://$formattedUrl';
    }

    final Uri url = Uri.parse(formattedUrl);

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode
              .externalApplication, // ✅ Buka langsung di browser bawaan HP
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(
              content:
                  Text('Format link tidak valid atau tidak bisa dibuka stuy!')),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal membuka link: $e')),
      );
    }
  }

  void _showModulForm(
      {String? docId, String? currentJudul, String? currentDeskripsi}) {
    if (docId != null) {
      _judulController.text = currentJudul ?? "";
      _deskripsiController.text = currentDeskripsi ?? "";
    } else {
      _judulController.clear();
      _deskripsiController.clear();
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(docId == null ? "Tambah Modul Baru" : "Edit Modul"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _judulController,
              decoration: const InputDecoration(
                  labelText: "Judul Modul",
                  hintText: "Contoh: Anatomi Jantung Utama"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _deskripsiController,
              decoration: const InputDecoration(
                  labelText: "Deskripsi Singkat / Link Materi"),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: maroonPrimary),
            onPressed: () async {
              if (_judulController.text.trim().isEmpty) return;

              final navigator = Navigator.of(dialogContext);
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              if (docId == null) {
                await _firestore.collection('modul_pembelajaran').add({
                  'judul': _judulController.text.trim(),
                  'deskripsi': _deskripsiController.text.trim(),
                  'created_at': FieldValue.serverTimestamp(),
                });
              } else {
                await _firestore
                    .collection('modul_pembelajaran')
                    .doc(docId)
                    .update({
                  'judul': _judulController.text.trim(),
                  'deskripsi': _deskripsiController.text.trim(),
                });
              }

              navigator.pop();
              scaffoldMessenger.showSnackBar(
                SnackBar(
                    content: Text(docId == null
                        ? "Modul berhasil ditambahkan!"
                        : "Modul berhasil diperbarui!")),
              );
            },
            child: const Text("Simpan", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteModul(String docId) async {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Hapus Modul"),
        content:
            const Text("Apakah kamu yakin ingin menghapus modul ini stuy?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final navigator = Navigator.of(dialogContext);
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              await _firestore
                  .collection('modul_pembelajaran')
                  .doc(docId)
                  .delete();

              navigator.pop();
              scaffoldMessenger.showSnackBar(
                const SnackBar(content: Text("Modul berhasil dihapus!")),
              );
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool bolehMengelola = widget.isAdmin || widget.isDosen;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F6),
      appBar: AppBar(
        title: const Text("Modul Pembelajaran",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        backgroundColor: maroonPrimary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      floatingActionButton: bolehMengelola
          ? FloatingActionButton(
              backgroundColor: maroonPrimary,
              onPressed: () => _showModulForm(),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('modul_pembelajaran')
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.menu_book, size: 80, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      "Modul Belum Tersedia",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      bolehMengelola
                          ? "Halo Admin/Dosen, silakan klik tombol '+' di kanan bawah untuk meng-input modul materi kuliah pertama stuy!"
                          : "Dosen atau Laboran belum meng-upload materi kuliah. Harap tunggu atau hubungi tim akademis ya stuy!",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              String deskripsiMateri = data['deskripsi'] ?? "";

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: maroonPrimary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.picture_as_pdf_rounded,
                        color: maroonPrimary, size: 24),
                  ),
                  title: Text(
                    data['judul'] ?? "Tanpa Judul",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    deskripsiMateri.isEmpty
                        ? "Tidak ada deskripsi."
                        : deskripsiMateri,
                    // ✅ MODIFIKASI: Menyesuaikan gaya teks tautan jika diawali http agar mahasiswa tahu itu link
                    style: TextStyle(
                      fontSize: 12,
                      color: deskripsiMateri.startsWith('http')
                          ? Colors.blue
                          : Colors.black54,
                      decoration: deskripsiMateri.startsWith('http')
                          ? TextDecoration.underline
                          : TextDecoration.none,
                    ),
                  ),
                  trailing: bolehMengelola
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_rounded,
                                  color: Colors.blue, size: 20),
                              onPressed: () => _showModulForm(
                                docId: doc.id,
                                currentJudul: data['judul'],
                                currentDeskripsi: data['deskripsi'],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_rounded,
                                  color: Colors.red, size: 20),
                              onPressed: () => _deleteModul(doc.id),
                            ),
                          ],
                        )
                      : const Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: Colors.grey),
                  onTap: () {
                    // ✅ PERBAIKAN: Jika ditekan, langsung panggil fungsi pembuka tautan
                    if (deskripsiMateri.isNotEmpty) {
                      _bukaLinkMateri(deskripsiMateri, context);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
