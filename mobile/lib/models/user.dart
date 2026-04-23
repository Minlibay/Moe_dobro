class User {
  final int id;
  final String phone;
  final String fullName;
  final String? avatarUrl;
  final String? bio;
  final bool isVerified;
  final bool? isAdmin;
  final bool isBlocked;
  final String? blockReason;
  final double totalDonated;
  final double totalReceived;
  final int peopleHelped;
  final int fundraisersCount;
  final DateTime createdAt;

  User({
    required this.id,
    required this.phone,
    required this.fullName,
    this.avatarUrl,
    this.bio,
    required this.isVerified,
    this.isAdmin,
    this.isBlocked = false,
    this.blockReason,
    required this.totalDonated,
    required this.totalReceived,
    required this.peopleHelped,
    required this.fundraisersCount,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      phone: json['phone'],
      fullName: json['full_name'],
      avatarUrl: json['avatar_url'],
      bio: json['bio'],
      isVerified: json['is_verified'] ?? false,
      isAdmin: json['is_admin'],
      isBlocked: json['is_blocked'] ?? false,
      blockReason: json['block_reason'],
      totalDonated: double.parse(json['total_donated']?.toString() ?? '0'),
      totalReceived: double.parse(json['total_received']?.toString() ?? '0'),
      peopleHelped: json['people_helped'] ?? 0,
      fundraisersCount: json['fundraisers_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
