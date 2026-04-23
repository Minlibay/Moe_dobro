class AppNotification {
  final int id;
  final int userId;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final int? relatedId;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    this.relatedId,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      userId: json['user_id'],
      type: json['type'],
      title: json['title'],
      message: json['message'],
      isRead: json['is_read'] ?? false,
      relatedId: json['related_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  String getIcon() {
    switch (type) {
      case 'donation_received':
        return '💰';
      case 'donation_approved':
        return '✅';
      case 'donation_rejected':
        return '❌';
      case 'achievement_earned':
        return '🏆';
      default:
        return '🔔';
    }
  }
}
