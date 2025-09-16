import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'career_mock.dart';

class CareerManagePage extends StatelessWidget {
  const CareerManagePage({super.key});

  static const _primary = Color(0xFF3D5CFF);
  static const _muted   = Color(0xFF858597);
  static const _soft    = Color(0xFFF6F7FF);
  static const _border  = Color(0xFFEFF1F7);
  static const _shadow  = Color(0x0D000000);

  @override
  Widget build(BuildContext context) {
    final items = CareerStore.all();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/admin/config'), // ✅ กลับ Dashboard (Config)
        ),
        title: const Text('Career management'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _primary,
        onPressed: () => context.go('/admin/config/careers/add'),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final c = items[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border),
              boxShadow: const [
                BoxShadow(color: _shadow, blurRadius: 12, offset: Offset(0, 4))
              ],
            ),
            child: ListTile(
              leading: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _soft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.menu_book_outlined,
                    color: _primary, size: 26),
              ),
              title: Text(c.name,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(c.skillRequirement,
                  style: const TextStyle(color: _muted)),
              trailing: IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () =>
                    context.go('/admin/config/careers/${c.id}/edit'),
              ),
            ),
          );
        },
      ),
    );
  }
}
