import 'package:flutter/material.dart';
import '../pretest_repository.dart'; // Import repository biar sinkron stuy

class ModulPage extends StatefulWidget {
  const ModulPage({super.key});

  @override
  State<ModulPage> createState() => _ModulPageState();
}

class _ModulPageState extends State<ModulPage> {
  // Setup warna khas tema CORAZON
  final Color maroonPrimary = const Color(0xFF6B1D2F);
  final Color textDark = const Color(0xFF2C2C2C);

  // Controller untuk menangkap ketikan dosen di pop-up
  final _titleController = TextEditingController();
  final _urlController = TextEditingController();

  // Fungsi untuk memunculkan pop-up dialog tambah modul
  void _showAddModulDialog() {
    _titleController.clear();
    _urlController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            Icon(Icons.picture_as_pdf, color: maroonPrimary),
            const SizedBox(width: 10),
            const Text('Tambah Modul Baru',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Silakan masukkan judul materi anatomi dan tempelkan tautan (link) file PDF/PPT dari Google Drive/Canva.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Judul Modul',
                  hintText: 'Misal: Modul 2: Sistem Pembuluh Darah',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: 'Link File PDF / PPT',
                  hintText: 'https://drive.google.com/...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.link),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: maroonPrimary, foregroundColor: Colors.white),
            onPressed: () {
              // Validasi agar inputan tidak boleh kosong
              if (_titleController.text.isNotEmpty &&
                  _urlController.text.isNotEmpty) {
                setState(() {
                  // Eksekusi fungsi tambah modul yang kita buat di repository tadi stuy!
                  PretestRepository().addModul(
                    _titleController.text,
                    _urlController.text,
                  );
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Modul berhasil ditambahkan!'),
                      backgroundColor: Colors.green),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Membaca list modul terbaru dari repository
    final listModul = PretestRepository().moduls;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F6),
      appBar: AppBar(
        title: const Text('KELOLA MODUL',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 16)),
        backgroundColor: maroonPrimary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: listModul.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.menu_book, size: 60, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Belum ada modul praktikum.',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: listModul.length,
              itemBuilder: (context, index) {
                final modul = listModul[index];
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          const Icon(Icons.picture_as_pdf, color: Colors.red),
                    ),
                    title: Text(
                      modul.title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: textDark,
                          fontSize: 14),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        modul.fileUrl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                            decoration: TextDecoration.underline),
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          // Eksekusi fungsi hapus modul di repository stuy!
                          PretestRepository().deleteModul(modul.id);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Modul berhasil dihapus!'),
                              backgroundColor: Colors.red),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
      // Tombol melayang untuk memicu dialog input stuy
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: maroonPrimary,
        foregroundColor: Colors.white,
        onPressed: _showAddModulDialog,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Modul',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
