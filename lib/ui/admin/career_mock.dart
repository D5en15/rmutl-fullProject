import 'package:flutter/foundation.dart';

class Career {
  final String id;
  final String name;
  final String skillRequirement; // ใช้เก็บชื่อสกิลที่ต้องการ (ตัวอย่าง)

  Career({
    required this.id,
    required this.name,
    required this.skillRequirement,
  });

  Career copyWith({
    String? id,
    String? name,
    String? skillRequirement,
  }) {
    return Career(
      id: id ?? this.id,
      name: name ?? this.name,
      skillRequirement: skillRequirement ?? this.skillRequirement,
    );
  }
}

/// In-memory store (ตัวอย่าง)
class CareerStore {
  static final List<Career> _items = [
    Career(id: '1', name: 'Project manager',   skillRequirement: 'Digital Communication'),
    Career(id: '2', name: 'System Analysis',   skillRequirement: 'Programming'),
    Career(id: '3', name: 'Data Engineer',     skillRequirement: 'Math'),
  ];

  static List<Career> all() => List.unmodifiable(_items);

  static Career? byId(String id) =>
      _items.where((e) => e.id == id).cast<Career?>().firstOrNull;

  static void upsert(Career c) {
    final i = _items.indexWhere((e) => e.id == c.id);
    if (i >= 0) {
      _items[i] = c;
    } else {
      _items.add(c);
    }
  }

  static void delete(String id) {
    _items.removeWhere((e) => e.id == id);
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
