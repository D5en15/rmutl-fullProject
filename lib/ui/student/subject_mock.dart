// lib/ui/student/subject_mock.dart
import 'package:flutter/foundation.dart';

class Subject {
  String id;
  String name;
  int credits;
  String semester;
  String grade;

  Subject({
    required this.id,
    required this.name,
    required this.credits,
    required this.semester,
    required this.grade,
  });

  Subject copyWith({
    String? id,
    String? name,
    int? credits,
    String? semester,
    String? grade,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      credits: credits ?? this.credits,
      semester: semester ?? this.semester,
      grade: grade ?? this.grade,
    );
  }
}

class SubjectStore {
  static final List<Subject> _items = [
    Subject(id: 's1', name: 'Programming 101', credits: 3, semester: '1/2567', grade: 'A'),
    Subject(id: 's2', name: 'Linear Algebra',   credits: 3, semester: '1/2567', grade: 'B+'),
    Subject(id: 's3', name: 'Physics for Engineer', credits: 4, semester: '2/2567', grade: 'C'),
  ];

  static List<Subject> all() => List.unmodifiable(_items);

  static Subject? byId(String id) {
    try { return _items.firstWhere((e) => e.id == id); }
    catch (_) { return null; }
  }

  static void upsert(Subject s) {
    final i = _items.indexWhere((e) => e.id == s.id);
    if (i == -1) {
      _items.add(s);
    } else {
      _items[i] = s;
    }
  }

  static void delete(String id) {
    _items.removeWhere((e) => e.id == id);
  }
}
