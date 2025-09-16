import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StudentListPage extends StatefulWidget {
  const StudentListPage({super.key});

  @override
  State<StudentListPage> createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage> {
  final _controller = TextEditingController();
  final _students = const [
    ('Jacob Jones', '12345'),
    ('Esther Howard', '12345'),
    ('Cameron Williamson', '12345'),
    ('Kristin Watson', '12345'),
    ('Devon Lane', '12345'),
    ('Theresa Webb', '12345'),
    ('Marvin McKinney', '12345'),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _controller.text.isEmpty
        ? _students
        : _students
            .where((s) =>
                s.$1.toLowerCase().contains(_controller.text.toLowerCase()) ||
                s.$2.contains(_controller.text))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student list'),
        centerTitle: false,
      ),
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
          Expanded(
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final name = filtered[i].$1;
                final id = filtered[i].$2;
                return ListTile(
                  leading: _InitialsAvatar(name: name),
                  title: Text(name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('ID: $id'),
                  trailing: const Icon(Icons.search),
                  onTap: () => context.go('/teacher/students/$id'),
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
    final parts = name.split(' ');
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts[1][0]}'
        : name.substring(0, 1);
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: const Color(0xFFE9ECFF),
      child: Text(
        initials.toUpperCase(),
        style:
            const TextStyle(color: Color(0xFF3D5CFF), fontWeight: FontWeight.w700),
      ),
    );
  }
}
