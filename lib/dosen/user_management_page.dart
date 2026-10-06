import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;
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

  Future<void> _tambahAslab() async {
    final data = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const _TambahAslabDialog(),
    );
    if (data == null) return;

    try {
      final secondaryApp = await Firebase.initializeApp(
        name: 'aslab-${DateTime.now().microsecondsSinceEpoch}',
        options: Firebase.app().options,
      );
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      User? createdUser;

      try {
        final credential = await secondaryAuth.createUserWithEmailAndPassword(
          email: data['email']!,
          password: data['password']!,
        );
        createdUser = credential.user;
        final uid = createdUser?.uid;
        if (uid == null) throw StateError('Akun aslab gagal dibuat.');

        await _firestore.collection('users').doc(uid).set({
          'uid': uid,
          'nama': data['nama'],
          'npm': data['npm'],
          'nip': data['npm'],
          'email': data['email'],
          'role': 'aslab',
          'class_id': 'app',
          'class_code': _activeClassCode,
          'is_aktif': true,
          'status_pretest': 'BELUM DIAMBIL',
          'status_posttest': 'BELUM DIAMBIL',
          'waktu_daftar': DateTime.now().toString(),
        });
      } catch (_) {
        await createdUser?.delete();
        rethrow;
      } finally {
        await secondaryApp.delete();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Akun aslab berhasil ditambahkan.')),
        );
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        final message = error.code == 'email-already-in-use'
            ? 'Email tersebut sudah terdaftar.'
            : 'Gagal membuat akun aslab: ${error.message ?? error.code}';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menambahkan aslab: $error')),
        );
      }
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _tambahAslab,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Tambah Aslab'),
        backgroundColor: const Color(0xFF6B1D2F),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('users')
            .where('role', isEqualTo: 'aslab')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Terjadi error: ${snapshot.error}'));
          }
          final activeClassCode = _activeClassCode.trim().toLowerCase();
          final docs = (snapshot.data?.docs ?? []).where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final classCode =
                data['class_code']?.toString().trim().toLowerCase();
            return activeClassCode != '-' && classCode == activeClassCode;
          }).toList();
          docs.sort((first, second) {
            final firstData = first.data() as Map<String, dynamic>;
            final secondData = second.data() as Map<String, dynamic>;
            final firstName = firstData['nama']?.toString().toLowerCase() ?? '';
            final secondName =
                secondData['nama']?.toString().toLowerCase() ?? '';
            return firstName.compareTo(secondName);
          });
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1E8EC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE6D4DB)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B1D2F),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.school_rounded,
                            color: Colors.white, size: 19),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        ' Kode Kelas ',
                        style: TextStyle(
                            color: Color(0xFF6B1D2F),
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      Text(
                        _activeClassCode,
                        style: const TextStyle(
                            color: Color(0xFF6B1D2F),
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: docs.isEmpty
                    ? const Center(child: Text('Belum ada data aslab.'))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final String nama = data['nama'] ?? '-';
                          final String email = data['email'] ?? '-';
                          final String npm = data['npm'] ?? '-';

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: const Color(0xFFEDE7EA)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: const Color(0xFFF1E8EC),
                                      child: Text(
                                        _initials(nama),
                                        style: const TextStyle(
                                            color: Color(0xFF6B1D2F),
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            nama,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            email,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 9, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE9F4EC),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        'Aslab',
                                        style: TextStyle(
                                            color: Color(0xFF287A3D),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      padding: EdgeInsets.zero,
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
                                        if (doc.id != _currentUserId) {
                                          return const [
                                            PopupMenuItem(
                                              value: 'hapus',
                                              child: Text('Hapus aslab'),
                                            ),
                                          ];
                                        }
                                        return const [
                                          PopupMenuItem(
                                            value: 'self',
                                            child: Text(
                                                'Tidak bisa hapus akun sendiri'),
                                          ),
                                        ];
                                      },
                                      icon:
                                          const Icon(Icons.more_vert, size: 21),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F6F7),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.badge_outlined,
                                          size: 16,
                                          color: Colors.grey.shade600),
                                      const SizedBox(width: 8),
                                      Text(
                                        'NPM/NIP  $npm',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade700,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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

  String _initials(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first[0].toUpperCase();
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }
}

class _TambahAslabDialog extends StatefulWidget {
  const _TambahAslabDialog();

  @override
  State<_TambahAslabDialog> createState() => _TambahAslabDialogState();
}

class _TambahAslabDialogState extends State<_TambahAslabDialog> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _npmController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _namaController.dispose();
    _npmController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Aslab'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(_namaController, 'Nama lengkap'),
              _field(_npmController, 'NPM / NIP',
                  keyboardType: TextInputType.number),
              _field(_emailController, 'Email',
                  keyboardType: TextInputType.emailAddress),
              _field(_passwordController, 'Password', obscureText: true),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Role: ASLAB',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(context, {
              'nama': _namaController.text.trim(),
              'npm': _npmController.text.trim(),
              'email': _emailController.text.trim().toLowerCase(),
              'password': _passwordController.text,
            });
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(labelText: label),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return 'Wajib diisi';
          if (label == 'NPM / NIP' &&
              !RegExp(r'^[0-9]+$').hasMatch(value.trim())) {
            return 'Gunakan angka saja';
          }
          if (label == 'Password' && value.length < 6) {
            return 'Minimal 6 karakter';
          }
          return null;
        },
      ),
    );
  }
}
