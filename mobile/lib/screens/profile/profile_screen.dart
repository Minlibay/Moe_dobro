import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/achievement_provider.dart';
import '../../config/api_config.dart';
import '../legal/legal_document_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final achievementProvider = Provider.of<AchievementProvider>(context, listen: false);

    await Future.wait([
      authProvider.loadProfile(),
      achievementProvider.loadAchievements(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = NumberFormat('#,###', 'ru_RU');

    return Scaffold(
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.user;
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return CustomScrollView(
            slivers: [
              _buildAppBar(user, theme),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildUserInfo(user, theme, formatter),
                      const SizedBox(height: 20),
                      _buildStatsCard(user, theme, formatter),
                      const SizedBox(height: 20),
                      _buildMenuItems(user, theme),
                      const SizedBox(height: 20),
                      if (user.totalDonated < 100) _buildMotivationCard(theme),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(user, ThemeData theme) {
    return SliverAppBar(
      floating: true,
      title: const Text('Профиль'),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => Navigator.pushNamed(context, '/edit-profile'),
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () async {
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            await authProvider.logout();
            if (!mounted) return;
            Navigator.pushReplacementNamed(context, '/login');
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildUserInfo(user, ThemeData theme, NumberFormat formatter) {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: theme.colorScheme.primary,
              backgroundImage: user.avatarUrl != null
                  ? NetworkImage(ApiConfig.getImageUrl(user.avatarUrl))
                  : null,
              child: user.avatarUrl == null
                  ? Text(
                      (user.fullName[0]).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(
                  Icons.edit,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          user.fullName,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          user.phone,
          style: TextStyle(fontSize: 15, color: Colors.grey[600]),
        ),
        if (user.bio != null) ...[
          const SizedBox(height: 12),
          Text(
            user.bio!,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
        ],
      ],
    );
  }

  Widget _buildStatsCard(user, ThemeData theme, NumberFormat formatter) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Text(
            '💰 Ваша статистика',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                '${formatter.format(user.totalDonated)} ₽',
                'Пожертвовано',
              ),
              Container(width: 1, height: 50, color: Colors.white30),
              _buildStatItem(
                '${user.peopleHelped}',
                'Помог людям',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white30),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                '${formatter.format(user.totalReceived)} ₽',
                'Получено',
              ),
              Container(width: 1, height: 50, color: Colors.white30),
              _buildStatItem(
                '${user.fundraisersCount}',
                'Сборов',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildMenuItems(user, ThemeData theme) {
    return Column(
      children: [
        Consumer<AchievementProvider>(
          builder: (context, achievementProvider, _) {
            return _buildMenuCard(
              icon: '🏆',
              iconColor: Colors.amber,
              title: 'Достижения',
              subtitle: '${achievementProvider.earnedCount} из ${achievementProvider.totalCount}',
              onTap: () => Navigator.pushNamed(context, '/achievements'),
            );
          },
        ),
        const SizedBox(height: 12),
        const SizedBox(height: 12),
        _buildMenuCard(
          icon: '💬',
          iconColor: Colors.blue,
          title: 'Помощь',
          subtitle: 'Написать в поддержку',
          onTap: () => Navigator.pushNamed(context, '/support'),
        ),
        if (user.fundraisersCount > 0)
          _buildMenuCard(
            icon: '💚',
            iconColor: Colors.green,
            title: 'Ожидающие пожертвования',
            subtitle: 'Проверьте новые донаты',
            onTap: () => Navigator.pushNamed(context, '/pending-donations'),
          ),
        if (user.fundraisersCount > 0) const SizedBox(height: 12),
if (user.isAdmin == true)
          _buildMenuCard(
            icon: '👑',
            iconColor: Colors.purple,
            title: 'Админ-панель',
            subtitle: 'Управление платформой',
            onTap: () => Navigator.pushNamed(context, '/admin'),
          ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _buildLinkChip('Политика конфиденциальности', '/privacy'),
            _buildLinkChip('Пользовательское соглашение', '/terms'),
            _buildLinkChip('Оферта', '/offer'),
          ],
        ),
      ],
    );
  }

  Widget _buildLinkChip(String label, String route) {
    return GestureDetector(
      onTap: () {
        String type = 'privacy';
        String title = 'Политика конфиденциальности';
        if (route == '/terms') {
          type = 'terms';
          title = 'Пользовательское соглашение';
        } else if (route == '/offer') {
          type = 'offer';
          title = 'Оферта';
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LegalDocumentScreen(
              documentType: type,
              title: title,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required String icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(icon, style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMotivationCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange[50]!, Colors.amber[50]!],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Text('🌟', style: TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Начните помогать',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Сделайте первый донат от 100₽ и получите возможность создать свой сбор',
                      style: TextStyle(fontSize: 13, color: Colors.orange[800]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Выберите сбор на главной странице'),
                    duration: Duration(seconds: 2),
                  ),
                );
                Navigator.pushNamed(context, '/home');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Пожертвовать'),
            ),
          ),
        ],
      ),
    );
  }
}