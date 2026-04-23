class UserProfile {
  final int id;
  final String fullName;
  final String? bio;
  final String? avatarUrl;
  final DateTime createdAt;
  final UserStats stats;
  final List<RecentDonation> recentDonations;
  final List<UserFundraiser> fundraisers;

  UserProfile({
    required this.id,
    required this.fullName,
    this.bio,
    this.avatarUrl,
    required this.createdAt,
    required this.stats,
    required this.recentDonations,
    required this.fundraisers,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['user']['id'],
      fullName: json['user']['full_name'],
      bio: json['user']['bio'],
      avatarUrl: json['user']['avatar_url'],
      createdAt: DateTime.parse(json['user']['created_at']),
      stats: UserStats.fromJson(json['stats']),
      recentDonations: (json['recent_donations'] as List)
          .map((d) => RecentDonation.fromJson(d))
          .toList(),
      fundraisers: (json['fundraisers'] as List)
          .map((f) => UserFundraiser.fromJson(f))
          .toList(),
    );
  }
}

class UserStats {
  final int donationsCount;
  final double totalDonated;
  final int fundraisersCreated;
  final double totalRaised;

  UserStats({
    required this.donationsCount,
    required this.totalDonated,
    required this.fundraisersCreated,
    required this.totalRaised,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      donationsCount: json['donations_count'],
      totalDonated: double.parse(json['total_donated'].toString()),
      fundraisersCreated: json['fundraisers_created'],
      totalRaised: double.parse(json['total_raised'].toString()),
    );
  }
}

class RecentDonation {
  final int id;
  final double amount;
  final String? message;
  final DateTime createdAt;
  final int fundraiserId;
  final String fundraiserTitle;
  final String? fundraiserImage;

  RecentDonation({
    required this.id,
    required this.amount,
    this.message,
    required this.createdAt,
    required this.fundraiserId,
    required this.fundraiserTitle,
    this.fundraiserImage,
  });

  factory RecentDonation.fromJson(Map<String, dynamic> json) {
    return RecentDonation(
      id: json['id'],
      amount: double.parse(json['amount'].toString()),
      message: json['message'],
      createdAt: DateTime.parse(json['created_at']),
      fundraiserId: json['fundraiser_id'],
      fundraiserTitle: json['fundraiser_title'],
      fundraiserImage: json['fundraiser_image'],
    );
  }
}

class UserFundraiser {
  final int id;
  final String title;
  final String description;
  final String? imageUrl;
  final double goalAmount;
  final double currentAmount;
  final String status;
  final String category;
  final DateTime createdAt;

  UserFundraiser({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.goalAmount,
    required this.currentAmount,
    required this.status,
    required this.category,
    required this.createdAt,
  });

  factory UserFundraiser.fromJson(Map<String, dynamic> json) {
    return UserFundraiser(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      imageUrl: json['image_url'],
      goalAmount: double.parse(json['goal_amount'].toString()),
      currentAmount: double.parse(json['current_amount'].toString()),
      status: json['status'],
      category: json['category'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
