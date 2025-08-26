class AdminService {
  Future<List<Map<String, String>>> listUsers() async {
    await Future.delayed(const Duration(milliseconds: 180));
    return [
      {'email': 'stud@example.com', 'role': 'student'},
      {'email': 'teach@example.com', 'role': 'teacher'},
      {'email': 'admin@example.com', 'role': 'admin'},
    ];
  }

  Future<List<Map<String, dynamic>>> moderationQueue() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return [
      {'id': 'p99', 'reason': 'spam', 'author': 'studX'},
      {'id': 'p77', 'reason': 'off-topic', 'author': 'studY'},
    ];
  }
}
