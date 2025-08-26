import '../models/career_rule.dart';

class CareerService {
  Future<List<CareerRule>> fetchRules() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return const [
      CareerRule(
        id: 'dev',
        title: 'Software Developer',
        minAvg: 75,
        description: 'เขียนโปรแกรม สร้างระบบเว็บ/มือถือ ร่วมทีมพัฒนา',
      ),
      CareerRule(
        id: 'ds',
        title: 'Data Scientist',
        minAvg: 80,
        description: 'วิเคราะห์ข้อมูล สร้างโมเดล ML/AI และ data pipeline',
      ),
      CareerRule(
        id: 'qa',
        title: 'QA Engineer',
        minAvg: 70,
        description: 'ทดสอบคุณภาพ วาง Test Plan/Automation',
      ),
    ];
  }
}
