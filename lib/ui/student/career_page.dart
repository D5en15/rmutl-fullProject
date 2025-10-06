import 'package:flutter/material.dart';
import '../common/page_template.dart';
import '../../services/career_service.dart';
import '../../widgets/career_card.dart';
import '../../models/career_rule.dart';

class CareerPage extends StatefulWidget {
  const CareerPage({super.key});

  @override
  State<CareerPage> createState() => _CareerPageState();
}

class _CareerPageState extends State<CareerPage> {
  late Future<List<CareerRule>> future;

  @override
  void initState() {
    super.initState();
    future = CareerService().fetchRules();
  }

  @override
  Widget build(BuildContext context) {
    return PageTemplate(
      title: 'Career',
      child: FutureBuilder<List<CareerRule>>(
        future: future,
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final rules = snap.data!;
          if (rules.isEmpty) {
            return const Center(child: Text('No career data available.'));
          }

          return ListView.separated(
            itemCount: rules.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => CareerCard(rule: rules[i]), // ✅ แก้ตรงนี้
          );
        },
      ),
    );
  }
}