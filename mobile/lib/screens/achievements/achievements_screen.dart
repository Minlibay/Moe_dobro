import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/achievement_provider.dart';
import '../../models/achievement.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    Provider.of<AchievementProvider>(context, listen: false).loadAchievements();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Достижения'),
      ),
      body: SafeArea(
        child: Consumer<AchievementProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final achievements = _selectedCategory == 'all'
                ? provider.achievements
                : provider.getAchievementsByCategory(_selectedCategory);

            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildProgressItem(
                            provider.earnedCount.toString(),
                            'Получено',
                            Colors.green,
                          ),
                          Container(width: 1, height: 40, color: Colors.grey[300]),
                          _buildProgressItem(
                            provider.totalCount.toString(),
                            'Всего',
                            Colors.blue,
                          ),
                          Container(width: 1, height: 40, color: Colors.grey[300]),
                          _buildProgressItem(
                            '${((provider.earnedCount / provider.totalCount) * 100).toStringAsFixed(0)}%',
                            'Прогресс',
                            Colors.orange,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildCategoryChip('all', 'Все', '✨'),
                            _buildCategoryChip('donor', 'Донор', '❤️'),
                            _buildCategoryChip('fundraiser', 'Сборы', '🎯'),
                            _buildCategoryChip('community', 'Сообщество', '⭐'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: achievements.isEmpty
                      ? const Center(child: Text('Нет достижений'))
                      : GridView.builder(
                          padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 32),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.9,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: achievements.length,
                          itemBuilder: (context, index) {
                            return _buildAchievementCard(achievements[index]);
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProgressItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String value, String label, String emoji) {
    final isSelected = _selectedCategory == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text('$emoji $label'),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = value;
          });
        },
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    return Card(
      elevation: achievement.isEarned ? 4 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: achievement.isEarned ? Colors.amber : Colors.grey[300]!,
          width: achievement.isEarned ? 2 : 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: achievement.isEarned
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.amber[50]!,
                    Colors.orange[50]!,
                  ],
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    achievement.icon,
                    style: TextStyle(
                      fontSize: 40,
                      color: achievement.isEarned ? null : Colors.grey[400],
                    ),
                  ),
                  if (!achievement.isEarned)
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                achievement.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: achievement.isEarned ? Colors.black : Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                achievement.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: achievement.isEarned ? Colors.grey[700] : Colors.grey[500],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (achievement.isEarned && achievement.earnedAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${achievement.earnedAt!.day}.${achievement.earnedAt!.month}.${achievement.earnedAt!.year}',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}