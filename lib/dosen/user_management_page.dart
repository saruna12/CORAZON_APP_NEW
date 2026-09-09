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
  String _selectedRole = 'mahasiswa';
  String _activeClassCode = '-';

  @override
  void initState() {
    super.initState();
    _guardAccess();
    _loadClassSettings();
  }

  Future<void> _loadClassSettings() async {
    final snapshot =
        await _firestore.collection('class_settings').doc('app').get();
    if (mounted) {
      setState(() {
        _activeClassCode = snapshot.data()?['active_code']?.toString() ?? '-';
      });
    }
  }

  Future<void> _ubahKodeKelas() async {
    final controller = TextEditingController(
        text: _activeClassCode == '-' ? 'Anatomi2026' : _activeClassCode);
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Kode Kelas'),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Kode kelas aktif',
            hintText: 'Contoh: Anatomi2026',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Simpan')),
        ],
      ),
    );
    controller.dispose();
    if (code == null || code.isEmpty) return;

    await _firestore.collection('class_settings').doc('app').set({
      'active_code': code,
      'class_id': 'app',
      'active': true,
      'updated_at': FieldValue.serverTimestamp(),
      'updated_by': _currentUserId,
    }, SetOptions(merge: true));
    if (mounted) {
      setState(() => _activeClassCode = code);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kode kelas berhasil diperbarui.')),
      );
    }
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
      final userRef = _firestore.collection('users').doc(userId);
      final userSnapshot = await userRef.get();
      if (userSnapshot.exists && userSnapshot.data() != null) {
        await _firestore.collection('archived_users').doc(userId).set({
          ...userSnapshot.data()!,
          'archived_at': FieldValue.serverTimestamp(),
          'archived_by': _currentUserId,
        });
      }
      await userRef.delete();
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
        actions: [
          IconButton(
            tooltip: 'Ubah kode kelas',
            icon: const Icon(Icons.key_rounded),
            onPressed: _ubahKodeKelas,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('users')
            .where('role', isEqualTo: _selectedRole)
            .orderBy('nama')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Terjadi error: ${snapshot.error}'));
          }
          final docs = snapshot.data?.docs ?? [];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    const Icon(Icons.key_rounded, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Kode kelas aktif: $_activeClassCode'),
                    ),
                    TextButton(
                        onPressed: _ubahKodeKelas, child: const Text('Ubah')),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildRoleButton(
                        label: 'Mahasiswa',
                        role: 'mahasiswa',
                        icon: Icons.school_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildRoleButton(
                        label: 'Aslab',
                        role: 'aslab',
                        icon: Icons.science_rounded,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: docs.isEmpty
                    ? Center(
                        child: Text(
                            'Belum ada data ${_selectedRole == 'mahasiswa' ? 'mahasiswa' : 'aslab'}.'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
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
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16),
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        onSelected: (value) {
                                          if (value == 'hapus') {
                                            _deleteUser(doc.id);
                                          } else if (value == 'self') {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'Akun sendiri tidak dapat dihapus.'),
                                              ),
                                            );
                                          }
                                        },
                                        itemBuilder: (context) {
                                          final items =
                                              <PopupMenuEntry<String>>[];
                                          if (doc.id != _currentUserId) {
                                            items.add(const PopupMenuItem(
                                              value: 'hapus',
                                              child: Text('Hapus pengguna'),
                                            ));
                                          } else {
                                            items.add(const PopupMenuItem(
                                              value: 'self',
                                              child: Text(
                                                  'Tidak bisa hapus akun sendiri'),
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
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
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
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 10),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade200,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: const Text(
                                                  'DOSEN (terkunci)',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.black54),
                                                ),
                                              )
                                            : DropdownButtonFormField<String>(
                                                initialValue: role,
                                                items: _roles
                                                    .map((roleOption) =>
                                                        DropdownMenuItem(
                                                          value: roleOption,
                                                          child: Text(roleOption
                                                              .toUpperCase()),
                                                        ))
                                                    .toList(),
                                                onChanged: (newRole) {
                                                  if (newRole != null &&
                                                      newRole != role) {
                                                    _updateUserRole(
                                                        doc.id, newRole);
                                                  }
                                                },
                                                decoration: InputDecoration(
                                                  contentPadding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 12,
                                                          vertical: 10),
                                                  border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12)),
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
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRoleButton({
    required String label,
    required String role,
    required IconData icon,
  }) {
    final selected = _selectedRole == role;
    return OutlinedButton.icon(
      onPressed: () => setState(() => _selectedRole = role),
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? Colors.white : const Color(0xFF6B1D2F),
        backgroundColor: selected ? const Color(0xFF6B1D2F) : Colors.white,
        side: const BorderSide(color: Color(0xFF6B1D2F)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}
