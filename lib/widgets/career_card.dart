import 'package:flutter/material.dart';
import '../models/career_rule.dart';

class CareerCard extends StatelessWidget {
  final CareerRule rule;
  final VoidCallback? onTap;
  const CareerCard({super.key, required this.rule, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: cs.primaryContainer,
                child: Text(
                  rule.title.characters.first,
                  style: TextStyle(color: cs.onPrimaryContainer),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rule.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ขั้นต่ำ: ${rule.minAvg.toStringAsFixed(0)} คะแนน',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (rule.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        rule.description,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
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
