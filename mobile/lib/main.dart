import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/auth_provider.dart';
import 'providers/fundraiser_provider.dart';
import 'providers/donation_provider.dart';
import 'providers/achievement_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/support_provider.dart';
import 'providers/legal_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/fundraiser/create_fundraiser_screen.dart';
import 'screens/fundraiser/fundraiser_detail_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/achievements/achievements_screen.dart';
import 'screens/donations/pending_donations_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/user/user_profile_screen.dart';
import 'screens/support/support_screen.dart';
import 'screens/support/support_chat_screen.dart';
import 'screens/legal/legal_document_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru_RU', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FundraiserProvider()),
        ChangeNotifierProvider(create: (_) => DonationProvider()),
        ChangeNotifierProvider(create: (_) => AchievementProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => SupportProvider()),
        ChangeNotifierProvider(create: (_) => LegalProvider()),
      ],
      child: MaterialApp(
        title: 'Моё добро',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6C63FF),
            brightness: Brightness.light,
          ),
          textTheme: GoogleFonts.interTextTheme(),
          scaffoldBackgroundColor: const Color(0xFFF8F9FA),
          appBarTheme: const AppBarTheme(
            elevation: 0,
            centerTitle: true,
            backgroundColor: Colors.transparent,
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/onboarding': (context) => const OnboardingScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeScreen(),
          '/create-fundraiser': (context) => const CreateFundraiserScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/edit-profile': (context) => const EditProfileScreen(),
          '/achievements': (context) => const AchievementsScreen(),
          '/pending-donations': (context) => const PendingDonationsScreen(),
          '/notifications': (context) => const NotificationsScreen(),
          '/admin': (context) => const AdminDashboardScreen(),
          '/support': (context) => const SupportScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/fundraiser-detail') {
            final id = settings.arguments as int;
            return MaterialPageRoute(
              builder: (context) => FundraiserDetailScreen(fundraiserId: id),
            );
          }
          if (settings.name == '/user-profile') {
            final id = settings.arguments as int;
            return MaterialPageRoute(
              builder: (context) => UserProfileScreen(userId: id),
            );
          }
          if (settings.name == '/support-chat') {
            final id = settings.arguments as int;
            return MaterialPageRoute(
              builder: (context) => SupportChatScreen(ticketId: id),
            );
          }
          return null;
        },
      ),
    );
  }
}
