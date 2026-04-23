class Donation {
  final int id;
  final int? fundraiserId;
  final int donorId;
  final double amount;
  final String? screenshotUrl;
  final String? status;
  final String? message;
  final DateTime createdAt;
  final DateTime? verifiedAt;
  final String? fundraiserTitle;
  final String? fundraiserImage;
  final String? donorName;
  final String? donorAvatar;
  final String? recipientName;

  Donation({
    required this.id,
    this.fundraiserId,
    required this.donorId,
    required this.amount,
    this.screenshotUrl,
    this.status,
    this.message,
    required this.createdAt,
    this.verifiedAt,
    this.fundraiserTitle,
    this.fundraiserImage,
    this.donorName,
    this.donorAvatar,
    this.recipientName,
  });

  factory Donation.fromJson(Map<String, dynamic> json) {
    return Donation(
      id: json['id'],
      fundraiserId: json['fundraiser_id'],
      donorId: json['donor_id'],
      amount: double.parse(json['amount'].toString()),
      screenshotUrl: json['screenshot_url'],
      status: json['status'],
      message: json['message'],
      createdAt: DateTime.parse(json['created_at']),
      verifiedAt: json['verified_at'] != null ? DateTime.parse(json['verified_at']) : null,
      fundraiserTitle: json['fundraiser_title'],
      fundraiserImage: json['fundraiser_image'],
      donorName: json['donor_name'],
      donorAvatar: json['donor_avatar'],
      recipientName: json['recipient_name'],
    );
  }

  String get statusText {
    switch (status) {
      case 'pending':
        return 'На проверке';
      case 'approved':
        return 'Подтверждено';
      case 'rejected':
        return 'Отклонено';
      default:
        return status ?? '';
    }
  }
}
