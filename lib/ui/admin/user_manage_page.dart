import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/admin_service.dart';

class UserManagePage extends StatefulWidget {
  const UserManagePage({super.key});
  @override
  State<UserManagePage> createState() => _UserManagePageState();
}

class _UserManagePageState extends State<UserManagePage> {
  final _controller = TextEditingController();
  List<Map<String, String>> _users = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await AdminService().listUsers(); // [{email, role}, ...]
    setState(() => _users = data);
  }

  @override
  Widget build(BuildContext context) {
    final q = _controller.text.toLowerCase();
    final filtered = q.isEmpty
        ? _users
        : _users
            .where((u) =>
                (u['email'] ?? '').toLowerCase().contains(q) ||
                (u['role'] ?? '').toLowerCase().contains(q))
            .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('User list'), centerTitle: false),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: _controller,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFFF6F7FF),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final email = filtered[i]['email'] ?? '';
                final role = filtered[i]['role'] ?? '';
                return ListTile(
                  leading: _InitialsAvatar(name: email),
                  title: Text(email, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('role: $role'),
                  trailing: const Icon(Icons.search),
                  onTap: () {
                    final id = Uri.encodeComponent(email); // ใช้ email แทน id
                    context.go('/admin/users/$id?email=$id&role=$role');
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
  final String name; final double size;

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty ? name[0] : '?';
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: const Color(0xFFE9ECFF),
      child: Text(
        initials.toUpperCase(),
        style: const TextStyle(color: Color(0xFF3D5CFF), fontWeight: FontWeight.w700),
      ),
    );
  }
}
