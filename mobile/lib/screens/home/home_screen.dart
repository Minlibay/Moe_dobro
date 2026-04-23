import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/fundraiser_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/fundraiser_card.dart';
import '../../widgets/completed_fundraiser_card.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/loading_skeleton.dart';
import '../../config/api_config.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String? _selectedCategory;

  final List<Map<String, String>> _categories = [
    {'value': 'mortgage', 'label': 'Ипотека', 'emoji': '🏠'},
    {'value': 'medical', 'label': 'Лечение', 'emoji': '💊'},
    {'value': 'education', 'label': 'Образование', 'emoji': '📚'},
    {'value': 'other', 'label': 'Другое', 'emoji': '🎯'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    context.read<NotificationProvider>().loadNotifications();
    _loadFundraisers();
  }

  Future<void> _loadFundraisers() async {
    final provider = Provider.of<FundraiserProvider>(context, listen: false);
    await provider.loadFundraisers(category: _selectedCategory);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final theme = Theme.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeTab(),
          _buildMyFundraisersTab(),
          _buildCompletedTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
          if (index == 1) {
            Provider.of<FundraiserProvider>(context, listen: false).loadMyFundraisers();
          } else if (index == 2) {
            Provider.of<FundraiserProvider>(context, listen: false).loadCompletedFundraisers();
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Главная',
          ),
          const NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: 'Мои',
          ),
          const NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle),
            label: 'Завершённые',
          ),
        ],
      ),
      floatingActionButton: user != null
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(context, '/create-fundraiser'),
              icon: const Icon(Icons.add),
              label: const Text('Создать'),
            )
          : null,
    );
  }

  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: _loadFundraisers,
      child: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: _buildHeader(),
          ),
          SliverToBoxAdapter(
            child: _buildCategories(),
          ),
          _buildFundraisersList(),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.favorite, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          const Text(
            'Моё добро',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
        ],
      ),
      actions: [
        Consumer<NotificationProvider>(
          builder: (context, provider, _) {
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () => Navigator.pushNamed(context, '/notifications'),
                ),
                if (provider.unreadCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        provider.unreadCount > 9 ? '9+' : provider.unreadCount.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        _buildProfileButton(),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildProfileButton() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.user;
        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/profile'),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: Theme.of(context).colorScheme.primary,
            backgroundImage: user?.avatarUrl != null
                ? NetworkImage(ApiConfig.getImageUrl(user!.avatarUrl))
                : null,
            child: user?.avatarUrl == null
                ? Text(
                    (user?.fullName ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Помогите осуществить мечту',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Каждый рубль приближает к цели',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.volunteer_activism, size: 32),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Категории',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryChip('Все', '✨', null),
                ..._categories.map((cat) => _buildCategoryChip(
                      cat['label']!,
                      cat['emoji']!,
                      cat['value'],
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, String emoji, String? value) {
    final isSelected = _selectedCategory == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text('$emoji $label'),
        selected: isSelected,
        onSelected: (_) {
          setState(() => _selectedCategory = value);
          _loadFundraisers();
        },
        selectedColor: Theme.of(context).colorScheme.primaryContainer,
        checkmarkColor: Theme.of(context).colorScheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
    );
  }

  Widget _buildFundraisersList() {
    return Consumer<FundraiserProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const SliverFillRemaining(
            child: LoadingSkeletonList(itemCount: 5),
          );
        }

        if (provider.fundraisers.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Нет активных сборов',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final fundraiser = provider.fundraisers[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: FundraiserCard(
                    fundraiser: fundraiser,
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/fundraiser-detail',
                      arguments: fundraiser.id,
                    ),
                  ),
                );
              },
              childCount: provider.fundraisers.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildMyFundraisersTab() {
    return Consumer<FundraiserProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const LoadingSkeletonList(itemCount: 3);
        }

        if (provider.myFundraisers.isEmpty) {
          return _buildEmptyState(
            '📋',
            'У вас пока нет сборов',
            'Создайте свой первый сбор',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: provider.myFundraisers.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Мои сборы',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              );
            }
            final fundraiser = provider.myFundraisers[index - 1];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: FundraiserCard(
                fundraiser: fundraiser,
                onTap: () => Navigator.pushNamed(
                  context,
                  '/fundraiser-detail',
                  arguments: fundraiser.id,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCompletedTab() {
    return Consumer<FundraiserProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const LoadingSkeletonList(itemCount: 3);
        }

        if (provider.completedFundraisers.isEmpty) {
          return _buildEmptyState(
            '✅',
            'Пока нет завершённых',
            'Здесь появятся успешные сборы',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: provider.completedFundraisers.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: const Text(
                  'Завершённые сборы',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              );
            }
            final fundraiser = provider.completedFundraisers[index - 1];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: CompletedFundraiserCard(
                fundraiser: fundraiser,
                onTap: () => Navigator.pushNamed(
                  context,
                  '/fundraiser-detail',
                  arguments: fundraiser.id,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String emoji, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}