class ApiConfig {
  static const String baseUrl = 'http://185.40.4.195:3003/api';
  static const String serverUrl = 'http://185.40.4.195:3003';

  // Helper method to get full image URL
  static String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    // Убрать начальный слеш если есть
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '$serverUrl/$cleanPath';
  }

  // Auth
  static const String register = '$baseUrl/auth/register';
  static const String login = '$baseUrl/auth/login';
  static const String profile = '$baseUrl/auth/profile';

  // Fundraisers
  static const String fundraisers = '$baseUrl/fundraisers';
  static String fundraiserDetail(int id) => '$baseUrl/fundraisers/$id';
  static const String myFundraisers = '$baseUrl/fundraisers/my';

  // Donations
  static const String donations = '$baseUrl/donations';
  static const String myDonations = '$baseUrl/donations/my';
  static const String pendingDonations = '$baseUrl/donations/pending';
  static String approveDonation(int id) => '$baseUrl/donations/$id/approve';
  static String rejectDonation(int id) => '$baseUrl/donations/$id/reject';

  // Achievements
  static const String myAchievements = '$baseUrl/achievements/my';
  static const String allAchievements = '$baseUrl/achievements/all';

  // Notifications
  static const String notifications = '$baseUrl/notifications';
  static String markAsRead(int id) => '$baseUrl/notifications/$id/read';
  static const String markAllAsRead = '$baseUrl/notifications/read-all';

  // Users
  static String userProfile(int id) => '$baseUrl/users/$id';

  // Legal
  static const String privacyPolicy = 'https://moedobro.ru/privacy';
  static const String termsOfService = 'https://moedobro.ru/terms';
  static const String offer = 'https://moedobro.ru/offer';

  // Support
  static const String support = '$baseUrl/support';
  static const String supportMy = '$baseUrl/support/my';
  static const String supportAll = '$baseUrl/support';

  // Legal Documents
  static const String legal = '$baseUrl/legal';
}
