import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  // ✅ 'dosen' SENGAJA tidak dimasukkan ke daftar ini. Role dosen tidak
  // bisa diberikan lewat aplikasi ini sama sekali -- kalau perlu bikin
  // akun dosen baru, harus diubah manual lewat Firebase Console. Ini
  // mencegah risiko seseorang menaikkan role user (termasuk dirinya
  // sendiri) menjadi dosen dari dalam aplikasi.
  final List<String> _roles = ['mahasiswa', 'aslab'];

  @override
  void initState() {
    super.initState();
    _guardAccess();
  }

  // ✅ Pertahanan tambahan (defense-in-depth): meskipun tombol menu ini
  // sudah disembunyikan untuk aslab di DosenBerandaPage, halaman ini
  // tetap mengecek ulang role secara mandiri. Ini penting karena rute
  // Flutter bisa saja dipanggil langsung (misal lewat deep link) tanpa
  // lewat menu, jadi tidak boleh cuma mengandalkan UI disembunyikan.
  Future<void> _guardAccess() async {
    final uid = _currentUserId;
    if (uid == null) return;
    final doc = await _firestore.collection('users').doc(uid).get();
    final role = doc.data()?['role'];
    if (role != 'dosen' && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Halaman ini hanya untuk dosen.')),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _updateUserRole(String userId, String newRole) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .update({'role': newRole});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Role pengguna berhasil diubah menjadi $newRole.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengubah role: $e')),
        );
      }
    }
  }

  Future<void> _deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data pengguna berhasil dihapus.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus pengguna: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F6),
      appBar: AppBar(
        title: const Text('Manajemen Pengguna'),
        backgroundColor: const Color(0xFF6B1D2F),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').orderBy('nama').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Terjadi error: ${snapshot.error}'));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('Belum ada data pengguna.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final String nama = data['nama'] ?? '-';
              final String email = data['email'] ?? '-';
              final String role = data['role'] ?? 'mahasiswa';
              final String npm = data['npm'] ?? '-';

              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              nama,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'hapus') {
                                _deleteUser(doc.id);
                              } else if (value == 'self') {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Akun sendiri tidak dapat dihapus.'),
                                  ),
                                );
                              }
                            },
                            itemBuilder: (context) {
                              final items = <PopupMenuEntry<String>>[];
                              if (doc.id != _currentUserId) {
                                items.add(const PopupMenuItem(
                                  value: 'hapus',
                                  child: Text('Hapus pengguna'),
                                ));
                              } else {
                                items.add(const PopupMenuItem(
                                  value: 'self',
                                  child: Text('Tidak bisa hapus akun sendiri'),
                                ));
                              }
                              return items;
                            },
                            child: const Icon(Icons.more_vert),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Email: $email',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text('NPM: $npm',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('Role:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 12),
                          Expanded(
                            // ✅ Akun dengan role 'dosen' TIDAK ditampilkan
                            // sebagai dropdown yang bisa diubah -- role
                            // dosen dikunci, hanya bisa diubah manual lewat
                            // Firebase Console. Ini juga mencegah error
                            // Flutter: DropdownButtonFormField akan crash
                            // kalau initialValue ('dosen') tidak ada di
                            // dalam daftar items (_roles sekarang cuma
                            // berisi mahasiswa & aslab).
                            child: role == 'dosen'
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'DOSEN (terkunci)',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black54),
                                    ),
                                  )
                                : DropdownButtonFormField<String>(
                                    initialValue: role,
                                    items: _roles
                                        .map((roleOption) => DropdownMenuItem(
                                              value: roleOption,
                                              child: Text(
                                                  roleOption.toUpperCase()),
                                            ))
                                        .toList(),
                                    onChanged: (newRole) {
                                      if (newRole != null && newRole != role) {
                                        _updateUserRole(doc.id, newRole);
                                      }
                                    },
                                    decoration: InputDecoration(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 10),
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
