// lib/ui/student/subjects_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubjectsPage extends StatefulWidget {
  const SubjectsPage({super.key});
  static const _primary = Color(0xFF3D5CFF);

  @override
  State<SubjectsPage> createState() => _SubjectsPageState();
}

class _SubjectsPageState extends State<SubjectsPage> {
  List<String> _userIdKeys = [];
  bool _resolvingUserKey = true;
  String _search = "";
  String _gradeFilter = "All Grades";
  String _termFilter = "All Terms";
  List<String> _gradeOptions = ["All Grades"];
  List<String> _termOptions = ["All Terms"];
  bool _hasAnyEnrollment = false;
  bool _initialLoaded = false;
  List<Map<String, dynamic>> _cachedEnrollments = const [];

  void _handleAddPressed(BuildContext context) {
    context.push('/student/subjects/add');
  }

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) {
      setState(() => _resolvingUserKey = false);
      return;
    }

    final keys = <String>{};
    void addKey(String? value, {bool sanitize = true}) {
      final trimmed = value?.trim();
      if (trimmed == null || trimmed.isEmpty) return;
      keys.add(trimmed);
      if (sanitize) {
        final normalized = trimmed.replaceAll(RegExp(r'[^0-9A-Za-z]'), '');
        if (normalized.isNotEmpty) keys.add(normalized);
      }
    }

    addKey(authUser.uid, sanitize: false);

    final email = authUser.email;
    if (email != null) {
      final snap = await FirebaseFirestore.instance
          .collection("user")
          .where("user_email", isEqualTo: email)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        final doc = snap.docs.first;
        final data = doc.data();
        addKey(doc.id, sanitize: false);
        addKey(data["user_id"]?.toString());
        addKey(data["user_code"]?.toString());
      }
    }

    final keyList = keys.toList();
    if (keyList.length > 10) keyList.removeRange(10, keyList.length);

    setState(() {
      _userIdKeys = keyList;
      _resolvingUserKey = false;
    });
  }

  Stream<List<Map<String, dynamic>>> _loadEnrollments() {
    if (_userIdKeys.isEmpty) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection("enrollment")
        .where("user_id", whereIn: _userIdKeys)
        .snapshots()
        .asyncMap((enrollSnap) async {
      List<Map<String, dynamic>> results = [];
      for (var e in enrollSnap.docs) {
        final enroll = e.data();
        final subjectId = enroll["subject_id"];
        if (subjectId == null) continue;

        final subjDoc = await FirebaseFirestore.instance
            .collection("subject")
            .doc(subjectId)
            .get();

        if (subjDoc.exists) {
          final subject = subjDoc.data()!;
          results.add({
            "id": e.id,
            "subject_id": subject["subject_id"],
            "subject_thname": subject["subject_thname"],
            "subject_enname": subject["subject_enname"],
            "subject_credits": subject["subject_credits"],
            "enrollment_semester": enroll["enrollment_semester"],
            "enrollment_grade": enroll["enrollment_grade"],
          });
        }
      }
      return results;
    });
  }

  Future<void> _openFilterSheet() async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        String localGrade = _gradeOptions.contains(_gradeFilter)
            ? _gradeFilter
            : "All Grades";
        String localTerm = _termOptions.contains(_termFilter)
            ? _termFilter
            : "All Terms";

        return StatefulBuilder(
          builder: (context, modalSetState) {
            return Container(
              color: Colors.white,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  const Text(
                    "Filter subjects",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: localGrade,
                    decoration: InputDecoration(
                      labelText: "Grade",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    items: _gradeOptions
                        .map(
                          (g) => DropdownMenuItem(
                            value: g,
                            child: Text(g),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val == null) return;
                      modalSetState(() => localGrade = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: localTerm,
                    decoration: InputDecoration(
                      labelText: "Semester",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    items: _termOptions
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(t),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val == null) return;
                      modalSetState(() => localTerm = val);
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => Navigator.pop(
                          context,
                          {"grade": localGrade, "term": localTerm},
                        ),
                        child: const Text("Apply"),
                      ),
                    ],
                  ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        _gradeFilter = result["grade"] ?? _gradeFilter;
        _termFilter = result["term"] ?? _termFilter;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Subjects",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: "Filter grades & terms",
                    icon: const Icon(Icons.tune, color: Colors.black87),
                    onPressed: _openFilterSheet,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Search by code or name...",
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Colors.black12, width: 1),
                  ),
                ),
                onChanged: (v) =>
                    setState(() => _search = v.trim().toLowerCase()),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _resolvingUserKey
                  ? const Center(child: CircularProgressIndicator())
                  : StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _loadEnrollments(),
                      builder: (context, snapshot) {
                        final isWaiting = snapshot.connectionState ==
                            ConnectionState.waiting;
                        if (isWaiting && !_initialLoaded) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        List<Map<String, dynamic>> dataList =
                            snapshot.data ?? _cachedEnrollments;
                        if (snapshot.hasData) {
                          _cachedEnrollments = snapshot.data!;
                          _initialLoaded = true;
                        }

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted || !snapshot.hasData) return;
                          final hasAny = dataList.isNotEmpty;
                          if (_hasAnyEnrollment != hasAny) {
                            setState(() => _hasAnyEnrollment = hasAny);
                          }
                        });

                        final gradeSet = <String>{};
                        final termSet = <String>{};
                        for (final data in dataList) {
                          final grade = (data['enrollment_grade'] ?? '')
                              .toString()
                              .trim();
                          if (grade.isNotEmpty) gradeSet.add(grade);
                          final term = (data['enrollment_semester'] ?? '')
                              .toString()
                              .trim();
                          if (term.isNotEmpty) termSet.add(term);
                        }

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          final newGrades = [
                            "All Grades",
                            ...gradeSet.toList()..sort(),
                          ];
                          final newTerms = [
                            "All Terms",
                            ...termSet.toList()..sort(),
                          ];
                          if (!listEquals(newGrades, _gradeOptions) ||
                              !listEquals(newTerms, _termOptions)) {
                            setState(() {
                              _gradeOptions = newGrades;
                              _termOptions = newTerms;
                              if (!_gradeOptions.contains(_gradeFilter)) {
                                _gradeFilter = "All Grades";
                              }
                              if (!_termOptions.contains(_termFilter)) {
                                _termFilter = "All Terms";
                              }
                            });
                          }
                        });

                        final docs = dataList.where((data) {
                          final code =
                              (data['subject_id'] ?? '').toString().toLowerCase();
                          final nameTh =
                              (data['subject_thname'] ?? '').toString().toLowerCase();
                          final nameEn =
                              (data['subject_enname'] ?? '').toString().toLowerCase();
                          final matchSearch = code.contains(_search) ||
                              nameTh.contains(_search) ||
                              nameEn.contains(_search);
                          final grade = (data['enrollment_grade'] ?? '')
                              .toString()
                              .trim();
                          final term = (data['enrollment_semester'] ?? '')
                              .toString()
                              .trim();
                          final matchGrade =
                              _gradeFilter == "All Grades" || grade == _gradeFilter;
                          final matchTerm =
                              _termFilter == "All Terms" || term == _termFilter;
                          return matchSearch && matchGrade && matchTerm;
                        }).toList();

                        if (docs.isEmpty) {
                          return const Center(child: Text("No subjects yet"));
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                          itemCount: docs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final data = docs[i];
                            final subjectId =
                                (data['subject_id'] ?? '').toString();
                            final thName =
                                (data['subject_thname'] ?? '').toString();
                            final enName =
                                (data['subject_enname'] ?? '').toString();
                            final displayName =
                                "$subjectId - $thName ($enName)";

                            return _SubjectTile(
                              id: data["id"],
                              name: displayName,
                              grade: data['enrollment_grade'] ?? '',
                              credits:
                                  data['subject_credits']?.toString() ?? '',
                              semester: data['enrollment_semester'] ?? '',
                              onEdit: () => context.push(
                                '/student/subjects/${data["id"]}/edit',
                                extra: data,
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _handleAddPressed(context),
        backgroundColor: SubjectsPage._primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _SubjectTile extends StatelessWidget {
  const _SubjectTile({
    required this.id,
    required this.name,
    required this.grade,
    required this.credits,
    required this.semester,
    required this.onEdit,
  });

  final String id;
  final String name;
  final String grade;
  final String credits;
  final String semester;
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Grade $grade - $credits credits - $semester',
                      style: const TextStyle(
                        color: Color(0xFF8B90A0),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
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

















