class CareerRule {
  final String id;
  final String title;
  final double minAvg;
  final String description;
  const CareerRule({
    required this.id,
    required this.title,
    required this.minAvg,
    this.description = '',
  });
}
