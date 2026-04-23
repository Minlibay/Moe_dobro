class SupportMessage {
  final int id;
  final int? ticketId;
  final int? senderId;
  final String? senderName;
  final String message;
  final DateTime createdAt;

  SupportMessage({
    required this.id,
    this.ticketId,
    this.senderId,
    this.senderName,
    required this.message,
    required this.createdAt,
  });

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    return SupportMessage(
      id: json['id'] ?? 0,
      ticketId: json['ticket_id'],
      senderId: json['sender_id'],
      senderName: json['sender_name'] ?? 'Пользователь',
      message: json['message'] ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }
}

class SupportTicket {
  final int id;
  final int userId;
  final String? userName;
  final String subject;
  final String status;
  final String? lastMessage;
  final List<SupportMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  SupportTicket({
    required this.id,
    required this.userId,
    this.userName,
    required this.subject,
    required this.status,
    this.lastMessage,
    this.messages = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    List<SupportMessage> msgs = [];
    if (json['messages'] != null) {
      msgs = (json['messages'] as List)
          .map((m) => SupportMessage.fromJson(m))
          .toList();
    }

    return SupportTicket(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      userName: json['user_name'],
      subject: json['subject'] ?? '',
      status: json['status'] ?? 'open',
      lastMessage: json['last_message'],
      messages: msgs,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
    );
  }
}