class CareerRule {
  final String id;
  final String title;
  final String description;
  final List<String> skills; // ✅ เพิ่ม field นี้

  CareerRule({
    required this.id,
    required this.title,
    required this.description,
    required this.skills,
  });

  // ✅ Factory สำหรับแปลงจาก JSON
  factory CareerRule.fromJson(Map<String, dynamic> json) {
    return CareerRule(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      skills: (json['skills'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [], // ป้องกัน null
    );
  }

  // ✅ เผื่อกรณีต้องแปลงกลับเป็น JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'skills': skills,
      };
}