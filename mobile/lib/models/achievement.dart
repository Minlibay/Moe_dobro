class Achievement {
  final int id;
  final String code;
  final String title;
  final String description;
  final String icon;
  final String category;
  final String requirementType;
  final int requirementValue;
  final bool isEarned;
  final DateTime? earnedAt;

  Achievement({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    required this.requirementType,
    required this.requirementValue,
    required this.isEarned,
    this.earnedAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'],
      code: json['code'],
      title: json['title'],
      description: json['description'],
      icon: json['icon'],
      category: json['category'],
      requirementType: json['requirement_type'],
      requirementValue: json['requirement_value'],
      isEarned: json['is_earned'] ?? false,
      earnedAt: json['earned_at'] != null ? DateTime.parse(json['earned_at']) : null,
    );
  }
}
