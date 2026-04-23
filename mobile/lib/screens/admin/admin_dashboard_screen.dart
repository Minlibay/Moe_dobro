import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AdminProvider>();
      provider.loadStats();
      provider.loadUsers();
      provider.loadFundraisers();
      provider.loadDonations();
      provider.loadPendingFundraisers();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    // Проверка прав администратора
    if (user == null || !(user.isAdmin ?? false)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Доступ запрещен')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('У вас нет прав администратора', style: TextStyle(fontSize: 18)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Админ-панель', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Статистика'),
            Tab(icon: Icon(Icons.people), text: 'Пользователи'),
            Tab(icon: Icon(Icons.favorite), text: 'Сборы'),
            Tab(icon: Icon(Icons.attach_money), text: 'Донаты'),
            Tab(icon: Icon(Icons.verified_user), text: 'Модерация'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStatsTab(),
          _buildUsersTab(),
          _buildFundraisersTab(),
          _buildDonationsTab(),
          _buildModerationTab(),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    return Consumer<AdminProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.stats == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = provider.stats;
        if (stats == null) {
          return const Center(child: Text('Нет данных'));
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadStats(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Общая статистика', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // Карточки со статистикой
              Row(
                children: [
                  Expanded(child: _buildStatCard('Пользователи', stats.totalUsers.toString(), Icons.people, Colors.blue)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatCard('Верифицированы', stats.verifiedUsers.toString(), Icons.verified, Colors.green)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildStatCard('Сборы', stats.totalFundraisers.toString(), Icons.favorite, Colors.red)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatCard('Активные', stats.activeFundraisers.toString(), Icons.trending_up, Colors.orange)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildStatCard('Донаты', stats.totalDonations.toString(), Icons.attach_money, Colors.purple)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatCard('Ожидают', stats.pendingDonations.toString(), Icons.pending, Colors.amber)),
                ],
              ),
              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Финансы', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Всего собрано:', style: TextStyle(fontSize: 16)),
                          Text('${stats.totalAmount.toStringAsFixed(0)} ₽',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Средний донат:', style: TextStyle(fontSize: 16)),
                          Text('${stats.avgDonation.toStringAsFixed(0)} ₽',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab() {
    return Consumer<AdminProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.users.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadUsers(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.users.length,
            itemBuilder: (context, index) {
              final user = provider.users[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(user.fullName[0].toUpperCase()),
                  ),
                  title: Text(user.fullName),
                  subtitle: Text('${user.phone}\nДонатов: ${user.totalDonated}₽ | Получено: ${user.totalReceived}₽'),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (user.isVerified)
                        Icon(Icons.verified, color: Colors.green, size: 20),
                      IconButton(
                        icon: Icon(user.isVerified ? Icons.remove_circle : Icons.check_circle),
                        onPressed: () => provider.verifyUser(user.id, !user.isVerified),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFundraisersTab() {
    return Consumer<AdminProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.fundraisers.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadFundraisers(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.fundraisers.length,
            itemBuilder: (context, index) {
              final fundraiser = provider.fundraisers[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(fundraiser.title),
                  subtitle: Text('${fundraiser.currentAmount}₽ / ${fundraiser.goalAmount}₽\nСтатус: ${fundraiser.status}'),
                  isThreeLine: true,
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'close', child: Text('Закрыть')),
                      const PopupMenuItem(value: 'feature', child: Text('Избранное')),
                      const PopupMenuItem(value: 'delete', child: Text('Удалить')),
                    ],
                    onSelected: (value) {
                      if (value == 'close') {
                        provider.closeFundraiser(fundraiser.id);
                      } else if (value == 'feature') {
                        provider.featureFundraiser(fundraiser.id, !fundraiser.isFeatured);
                      } else if (value == 'delete') {
                        _confirmDelete(context, () => provider.deleteFundraiser(fundraiser.id));
                      }
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDonationsTab() {
    return Consumer<AdminProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.donations.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadDonations(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.donations.length,
            itemBuilder: (context, index) {
              final donation = provider.donations[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text('${donation.amount}₽'),
                  subtitle: Text('Статус: ${donation.status ?? "Неизвестно"}\nДата: ${donation.createdAt}'),
                  isThreeLine: true,
                  trailing: _getStatusIcon(donation.status ?? ''),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _getStatusIcon(String status) {
    switch (status) {
      case 'approved':
        return Icon(Icons.check_circle, color: Colors.green);
      case 'pending':
        return Icon(Icons.pending, color: Colors.orange);
      case 'rejected':
        return Icon(Icons.cancel, color: Colors.red);
      default:
        return Icon(Icons.help);
    }
  }

  void _confirmDelete(BuildContext context, Function onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение'),
        content: const Text('Вы уверены, что хотите удалить этот сбор?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildModerationTab() {
    return Consumer<AdminProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.pendingFundraisers.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final pendingFundraisers = provider.pendingFundraisers;
        
        // Debug info
        print('[ModerationTab] pendingFundraisers.length = ${pendingFundraisers.length}');
        print('[ModerationTab] provider.pendingFundraisers = ${provider.pendingFundraisers}');

        return RefreshIndicator(
          onRefresh: () => provider.loadPendingFundraisers(),
          child: pendingFundraisers.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 64, color: Colors.green),
                      SizedBox(height: 16),
                      Text('Нет сборов на модерации', style: TextStyle(fontSize: 18)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: pendingFundraisers.length,
                  itemBuilder: (context, index) {
                    final fundraiser = pendingFundraisers[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Фото
                            if (fundraiser.imageUrl != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  'http://185.40.4.195:3003${fundraiser.imageUrl}',
                                  width: double.infinity,
                                  height: 180,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 180,
                                    color: Colors.grey[200],
                                    child: Icon(Icons.image, size: 48, color: Colors.grey),
                                  ),
                                ),
                              ),
                            if (fundraiser.imageUrl != null) const SizedBox(height: 12),
                            
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[100],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'На модерации',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange[900],
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  fundraiser.categoryName,
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            // Название
                            Text(
                              fundraiser.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            // Описание
                            Text(
                              fundraiser.description,
                              style: TextStyle(color: Colors.grey[600], height: 1.4),
                            ),
                            const SizedBox(height: 16),
                            
                            // Информация о создателе
                            Row(
                              children: [
                                Icon(Icons.person, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  fundraiser.creatorName ?? 'Неизвестно',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.phone, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  '${fundraiser.creatorPhone ?? 'Не указан'}',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            // Куда переводить
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Реквизиты для перевода:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[900],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (fundraiser.paymentMethod == 'sbp') ...[
                                    Row(
                                      children: [
                                        Icon(Icons.phone_android, size: 16, color: Colors.blue[700]),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            fundraiser.sbpPhone ?? '',
                                            style: TextStyle(color: Colors.blue[900]),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (fundraiser.sbpBank != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Банк: ${fundraiser.sbpBank}',
                                        style: TextStyle(color: Colors.blue[700], fontSize: 12),
                                      ),
                                    ],
                                  ] else ...[
                                    Row(
                                      children: [
                                        Icon(Icons.credit_card, size: 16, color: Colors.blue[700]),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            fundraiser.cardNumber ?? '',
                                            style: TextStyle(color: Colors.blue[900]),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (fundraiser.cardHolderName != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Владелец: ${fundraiser.cardHolderName}',
                                        style: TextStyle(color: Colors.blue[700], fontSize: 12),
                                      ),
                                    ],
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            // Цель
                            Row(
                              children: [
                                Icon(Icons.account_balance_wallet, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  'Цель: ${fundraiser.goalAmount.toStringAsFixed(0)} ₽',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Кнопки
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _showRejectDialog(
                                      context,
                                      () => provider.rejectFundraiser(
                                        fundraiser.id,
                                        'Нарушение правил платформы',
                                      ),
                                    ),
                                    icon: Icon(Icons.close),
                                    label: const Text('Отклонить'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => provider.approveFundraiser(
                                      fundraiser.id,
                                    ),
                                    icon: Icon(Icons.check),
                                    label: const Text('Одобрить'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  void _showRejectDialog(BuildContext context, Function onReject) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отклонить сбор?'),
        content: const Text(
          'При отклонении сбор будет удален и недоступен пользователям.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onReject();
            },
            child: const Text('Отклонить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
