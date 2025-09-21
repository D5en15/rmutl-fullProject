import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserManagePage extends StatefulWidget {
  const UserManagePage({super.key});

  @override
  State<UserManagePage> createState() => _UserManagePageState();
}

class _UserManagePageState extends State<UserManagePage> {
  final _controller = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  String? _filterRole;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final extra = GoRouterState.of(context).extra as Map?;
      setState(() {
        _filterRole = extra?['filterRole'] as String?;
      });
      _load();
    });
  }

  Future<void> _load() async {
    try {
      final colRef = FirebaseFirestore.instance
          .collection('users')
          .withConverter<Map<String, dynamic>>(
            fromFirestore: (snap, _) => snap.data() ?? {},
            toFirestore: (data, _) => data,
          );

      final snap = (_filterRole != null &&
              _filterRole!.isNotEmpty &&
              _filterRole != "เลือกบทบาท")
          ? await colRef.where('role', isEqualTo: _filterRole!.toLowerCase()).get()
          : await colRef.get();

      final data = snap.docs.map((d) {
        final map = d.data();
        return {
          'id': d.id,
          'studentId': map['studentId'] ?? '',
          'displayName': map['displayName'] ?? '',
          'className': map['className'] ?? '',
          'email': map['email'] ?? '',
        };
      }).toList();

      if (mounted) {
        setState(() {
          _users = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("โหลดข้อมูลผิดพลาด: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _controller.text.toLowerCase();
    final filtered = q.isEmpty
        ? _users
        : _users.where((u) {
            return (u['studentId'] as String).toLowerCase().contains(q) ||
                (u['displayName'] as String).toLowerCase().contains(q) ||
                (u['className'] as String).toLowerCase().contains(q);
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('User list'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // ✅ เปิดหน้าเพิ่มผู้ใช้งานใหม่
              context.go('/admin/users/add');
            },
          ),
        ],
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
                      hintText: 'Search by Student ID / Name / Class',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: const Color(0xFFF6F7FF),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
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
                      ? const Center(child: Text("ไม่พบผู้ใช้"))
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final user = filtered[i];
                            return ListTile(
                              leading: _InitialsAvatar(
                                  name: user['displayName'].isNotEmpty
                                      ? user['displayName']
                                      : user['studentId']),
                              title: Text(
                                user['displayName'].isNotEmpty
                                    ? user['displayName']
                                    : "(No Name)",
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(
                                  "ID: ${user['studentId']} • Class: ${user['className']}"),
                              trailing:
                                  const Icon(Icons.chevron_right_rounded),
                              onTap: () {
                                final id = user['id'];
                                final email = user['email'];
                                context.go('/admin/users/$id?email=$email');
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.name, this.size = 36});
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty ? name[0] : '?';
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: const Color(0xFFE9ECFF),
      child: Text(
        initials.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF3D5CFF),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}