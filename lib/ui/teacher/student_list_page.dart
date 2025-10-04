import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentListPage extends StatefulWidget {
  const StudentListPage({super.key});

  @override
  State<StudentListPage> createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage> {
  final _controller = TextEditingController();
  bool _loading = true;
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('user')
          .where('user_role', isEqualTo: 'Student')
          .get();

      final data = snap.docs.map((d) {
        final u = d.data();
        return {
          'id': d.id,
          'user_fullname': u['user_fullname'] ?? 'ไม่ระบุชื่อ',
          'user_email': u['user_email'] ?? '',
          'user_code': u['user_code'] ?? '',
          'user_class': u['user_class'] ?? '',
          'user_img': u['user_img'] ?? '',
        };
      }).toList();

      setState(() {
        _students = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("โหลดข้อมูลนักศึกษาไม่สำเร็จ: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _controller.text.toLowerCase();

    final filtered = q.isEmpty
        ? _students
        : _students.where((s) {
            return (s['user_fullname'] as String)
                    .toLowerCase()
                    .contains(q) ||
                (s['user_email'] as String)
                    .toLowerCase()
                    .contains(q) ||
                (s['user_code'] as String).contains(q);
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student List'),
        backgroundColor: const Color(0xFF3D5CFF),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextField(
                    controller: _controller,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'ค้นหาชื่อ / อีเมล / รหัสนักศึกษา',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: const Color(0xFFF6F7FF),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 0),
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text("ไม่พบนักศึกษา"))
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final s = filtered[i];
                            final name = s['user_fullname'];
                            final email = s['user_email'];
                            final code = s['user_code'];
                            final img = s['user_img'];

                            return ListTile(
                              leading: _Avatar(
                                name: name,
                                imageUrl: img,
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(
                                email.isNotEmpty
                                    ? email
                                    : 'รหัสนักศึกษา: ${code.isNotEmpty ? code : "-"}',
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () => context.push(
                                '/teacher/students/${s['id']}',
                                extra: s,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.imageUrl, this.size = 38});
  final String name;
  final String imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty
        ? name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : '?';
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: const Color(0xFFE9ECFF),
      backgroundImage:
          imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
      child: imageUrl.isEmpty
          ? Text(initials,
              style: const TextStyle(
                color: Color(0xFF3D5CFF),
                fontWeight: FontWeight.w700,
              ))
          : null,
    );
  }
}