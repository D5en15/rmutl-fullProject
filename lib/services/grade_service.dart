import '../models/grade_entry.dart';

class GradeService {
  Future<List<GradeEntry>> fetchGrades(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return const [
      GradeEntry(subjectCode: 'CS101', subjectName: 'Intro CS', score: 85),
      GradeEntry(subjectCode: 'MA101', subjectName: 'Calculus I', score: 78),
      GradeEntry(subjectCode: 'EN101', subjectName: 'English I', score: 92),
      GradeEntry(subjectCode: 'DS101', subjectName: 'Discrete Math', score: 74),
    ];
  }

  double average(List<GradeEntry> list) {
    if (list.isEmpty) return 0;
    final sum = list.fold<double>(0, (p, e) => p + e.score);
    return sum / list.length;
  }
}
