import 'package:flutter/material.dart';
import '../models/career_rule.dart';

class CareerCard extends StatelessWidget {
  final CareerRule rule;
  final VoidCallback? onTap;

  const CareerCard({
    super.key,
    required this.rule,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 ไอคอนหรือรูปอาชีพ
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFFE9ECFF),
                child: Icon(
                  Icons.work_outline_rounded,
                  color: Colors.blue.shade700,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),

              // 🔹 เนื้อหาหลัก
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rule.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rule.description,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: -4,
                      children: rule.skills.map((s) {
                        return Chip(
                          label: Text(
                            s,
                            style: const TextStyle(fontSize: 11),
                          ),
                          backgroundColor: Colors.blue.shade50,
                          side: BorderSide.none,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}