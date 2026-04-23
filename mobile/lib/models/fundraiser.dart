class Fundraiser {
  final int id;
  final int userId;
  final String title;
  final String description;
  final String category;
  final double goalAmount;
  final double currentAmount;
  final String paymentMethod; // 'sbp' или 'card'
  final String? cardNumber;
  final String? cardHolderName;
  final String? bankName;
  final String? sbpPhone;
  final String? sbpBank;
  final String? imageUrl;
  final List<String>? imageUrls;
  final String status;
  final bool isFeatured;
  final DateTime createdAt;
  final String? creatorName;
  final String? creatorAvatar;
  final String? creatorPhone;
  final double? progressPercent;
  final int? donorsCount;
  final String? completionProofUrl;
  final String? completionMessage;
  final DateTime? completionSubmittedAt;
  final bool completionVerified;
  final DateTime? completionVerifiedAt;

  Fundraiser({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.goalAmount,
    required this.currentAmount,
    required this.paymentMethod,
    this.cardNumber,
    this.cardHolderName,
    this.bankName,
    this.sbpPhone,
    this.sbpBank,
    this.imageUrl,
    this.imageUrls,
    required this.status,
    required this.isFeatured,
    required this.createdAt,
    this.creatorName,
    this.creatorAvatar,
    this.creatorPhone,
    this.progressPercent,
    this.donorsCount,
    this.completionProofUrl,
    this.completionMessage,
    this.completionSubmittedAt,
    this.completionVerified = false,
    this.completionVerifiedAt,
  });

  factory Fundraiser.fromJson(Map<String, dynamic> json) {
    return Fundraiser(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      goalAmount: double.parse(json['goal_amount'].toString()),
      currentAmount: double.parse(json['current_amount'].toString()),
      paymentMethod: json['payment_method'] ?? 'card',
      cardNumber: json['card_number'],
      cardHolderName: json['card_holder_name'],
      bankName: json['bank_name'],
      sbpPhone: json['sbp_phone'],
      sbpBank: json['sbp_bank'],
      imageUrl: json['image_url'],
      imageUrls: json['image_urls'] != null 
          ? List<String>.from(json['image_urls'])
          : null,
      status: json['status'],
      isFeatured: json['is_featured'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      creatorName: json['creator_name'],
      creatorAvatar: json['creator_avatar'],
      creatorPhone: json['creator_phone'],
      progressPercent: json['progress_percent'] != null
          ? double.parse(json['progress_percent'].toString())
          : null,
      donorsCount: json['donors_count'] != null
          ? int.parse(json['donors_count'].toString())
          : null,
      completionProofUrl: json['completion_proof_url'],
      completionMessage: json['completion_message'],
      completionSubmittedAt: json['completion_submitted_at'] != null
          ? DateTime.parse(json['completion_submitted_at'])
          : null,
      completionVerified: json['completion_verified'] ?? false,
      completionVerifiedAt: json['completion_verified_at'] != null
          ? DateTime.parse(json['completion_verified_at'])
          : null,
    );
  }

  String get categoryName {
    switch (category) {
      case 'mortgage':
        return 'Ипотека';
      case 'medical':
        return 'Лечение';
      case 'education':
        return 'Образование';
      default:
        return 'Другое';
    }
  }

  String get categoryEmoji {
    switch (category) {
      case 'mortgage':
        return '🏠';
      case 'medical':
        return '💊';
      case 'education':
        return '📚';
      default:
        return '🎯';
    }
  }
}
