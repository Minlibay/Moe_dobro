class AdminStats {
  final int totalUsers;
  final int verifiedUsers;
  final int totalFundraisers;
  final int activeFundraisers;
  final int completedFundraisers;
  final int totalDonations;
  final int approvedDonations;
  final int pendingDonations;
  final double totalAmount;
  final double avgDonation;

  AdminStats({
    required this.totalUsers,
    required this.verifiedUsers,
    required this.totalFundraisers,
    required this.activeFundraisers,
    required this.completedFundraisers,
    required this.totalDonations,
    required this.approvedDonations,
    required this.pendingDonations,
    required this.totalAmount,
    required this.avgDonation,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    final overview = json['overview'];
    return AdminStats(
      totalUsers: overview['total_users'] ?? 0,
      verifiedUsers: overview['verified_users'] ?? 0,
      totalFundraisers: overview['total_fundraisers'] ?? 0,
      activeFundraisers: overview['active_fundraisers'] ?? 0,
      completedFundraisers: overview['completed_fundraisers'] ?? 0,
      totalDonations: overview['total_donations'] ?? 0,
      approvedDonations: overview['approved_donations'] ?? 0,
      pendingDonations: overview['pending_donations'] ?? 0,
      totalAmount: double.parse(overview['total_amount']?.toString() ?? '0'),
      avgDonation: double.parse(overview['avg_donation']?.toString() ?? '0'),
    );
  }
}
