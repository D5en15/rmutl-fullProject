import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// ===================== MOCK DATA (ชั่วคราว) =====================
class Subject {
  String id;
  String name;
  int credits;
  String semester; // ex. "1/2567"
  String grade;    // ex. "A", "B+"

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
    Subject(
      id: 's1',
      name: 'Programming 101',
      credits: 3,
      semester: '1/2567',
      grade: 'A',
    ),
    Subject(
      id: 's2',
      name: 'Linear Algebra',
      credits: 3,
      semester: '1/2567',
      grade: 'B+',
    ),
    Subject(
      id: 's3',
      name: 'Physics for Engineer',
      credits: 4,
      semester: '2/2567',
      grade: 'C',
    ),
  ];

  static List<Subject> all() => List.unmodifiable(_items);

  static Subject? byId(String id) =>
      _items.cast<Subject?>().firstWhere((e) => e!.id == id, orElse: () => null);

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
/// ===============================================================

class SubjectsPage extends StatefulWidget {
  const SubjectsPage({super.key});

  @override
  State<SubjectsPage> createState() => _SubjectsPageState();
}

class _SubjectsPageState extends State<SubjectsPage> {
  static const _primary = Color(0xFF3D5CFF);

  List<Subject> _subjects = [];

  @override
  void initState() {
    super.initState();
    _subjects = SubjectStore.all();
  }

  Future<void> _openAdd() async {
    final result = await context.push('/student/subjects/add');
    if (result is Subject) {
      SubjectStore.upsert(result);
      setState(() => _subjects = SubjectStore.all());
    }
  }

  Future<void> _openEdit(Subject s) async {
    final result = await context.push(
      '/student/subjects/${s.id}/edit',
      extra: s, // ส่งข้อมูลไปด้วย (edit page จะอ่านจาก state.extra)
    );
    if (result is Map && result['deleted'] == true) {
      // ลบแล้ว
      setState(() => _subjects = SubjectStore.all());
    } else if (result is Subject) {
      // อัปเดตแล้ว
      SubjectStore.upsert(result);
      setState(() => _subjects = SubjectStore.all());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ✅ AppBar สีเทาอ่อน + ตัวอักษรดำ + ไม่มีเงา
      appBar: AppBar(
        title: const Text('Subjects'),
        centerTitle: false,
        backgroundColor: const Color(0xFFF1F2F6),
        foregroundColor: Colors.black87,
        elevation: 0,
      ),

      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        itemCount: _subjects.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final s = _subjects[i];
          return _SubjectTile(
            subject: s,
            onEdit: () => _openEdit(s),
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _openAdd,
        backgroundColor: _primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _SubjectTile extends StatelessWidget {
  const _SubjectTile({required this.subject, required this.onEdit});
  final Subject subject;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return PhysicalModel(
      color: Colors.white,
      elevation: 3,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(
            children: [
              // ไอคอนหนังสือ
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.menu_book_outlined,
                  color: Color(0xFF3D5CFF),
                ),
              ),
              const SizedBox(width: 12),

              // ชื่อวิชา + เกรด/เครดิต
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Grade ${subject.grade} • ${subject.credits} credits',
                      style: const TextStyle(
                        color: Color(0xFF8B90A0),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),

              // ปุ่มแก้ไข
              IconButton(
                tooltip: 'Edit',
                onPressed: onEdit,
                icon: const Icon(Icons.edit, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
