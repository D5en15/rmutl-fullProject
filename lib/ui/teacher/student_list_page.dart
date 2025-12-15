import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StudentListPage extends StatefulWidget {
  const StudentListPage({super.key});

  @override
  State<StudentListPage> createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage> {
  final _controller = TextEditingController();
  bool _loading = true;
  List<Map<String, dynamic>> _students = [];
  String? _selectedYear;
  bool _viewAll = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final extra = GoRouterState.of(context).extra;
      if (extra is Map) {
        final year = extra['year']?.toString().trim();
        _selectedYear = (year != null && year.isNotEmpty) ? year : null;
        _viewAll = (extra['all'] == true) || (extra['viewAll'] == true);
        if (_viewAll) _selectedYear = null;
      }
      _loadStudents();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
          'user_id': u['user_id'] ?? '',
          'user_fullname': u['user_fullname'] ?? 'Unknown',
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
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถโหลดรายชื่อนักศึกษาได้: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _controller.text.toLowerCase();
    final byYear = (_selectedYear == null || _viewAll)
        ? _students
        : _students.where((s) {
            final uid = (s['user_id'] ?? '').toString();
            return uid.length >= 2 && uid.startsWith(_selectedYear!);
          }).toList();

    final filtered = q.isEmpty
        ? byYear
        : byYear.where((s) {
            return (s['user_fullname'] as String)
                    .toLowerCase()
                    .contains(q) ||
                (s['user_email'] as String).toLowerCase().contains(q) ||
                (s['user_code'] as String).contains(q);
          }).toList();

    final subtitleText = (_selectedYear != null && !_viewAll)
        ? 'Showing students of year ${_selectedYear}'
        : 'Showing all students';

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
                      hintText: 'ค้นหาด้วยชื่อ อีเมล หรือรหัสนักศึกษา',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: const Color(0xFFF6F7FF),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      subtitleText,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text('No students found'))
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final s = filtered[i];
                            final name = s['user_fullname'] as String;
                            final email = s['user_email'] as String;
                            final code = s['user_code'] as String;
                            final img = s['user_img'] as String;

                            return ListTile(
                              leading: _Avatar(
                                name: name,
                                imageUrl: img,
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                email.isNotEmpty
                                    ? email
                                    : 'Student ID: ${code.isNotEmpty ? code : "-"}',
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
      backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
      child: imageUrl.isEmpty
          ? Text(
              initials,
              style: const TextStyle(
                color: Color(0xFF3D5CFF),
                fontWeight: FontWeight.w700,
              ),
            )
          : null,
    );
  }
}
