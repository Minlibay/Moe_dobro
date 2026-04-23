import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/donation_provider.dart';
import '../../config/api_config.dart';

class PendingDonationsScreen extends StatefulWidget {
  const PendingDonationsScreen({super.key});

  @override
  State<PendingDonationsScreen> createState() => _PendingDonationsScreenState();
}

class _PendingDonationsScreenState extends State<PendingDonationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDonations();
    });
  }

  Future<void> _loadDonations() async {
    final provider = Provider.of<DonationProvider>(context, listen: false);
    await provider.loadPendingDonations();
  }

  void _showScreenshotDialog(String screenshotUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Скриншот перевода'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Image.network(
                ApiConfig.getImageUrl(screenshotUrl),
                errorBuilder: (context, error, stackTrace) {
                  return const Text('Ошибка загрузки изображения');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveDonation(int id) async {
    final provider = Provider.of<DonationProvider>(context, listen: false);
    final success = await provider.approveDonation(id);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожертвование подтверждено! 💚'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Ошибка подтверждения'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectDonation(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отклонить пожертвование?'),
        content: const Text('Вы уверены, что хотите отклонить это пожертвование?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Отклонить'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final provider = Provider.of<DonationProvider>(context, listen: false);
    final success = await provider.rejectDonation(id);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожертвование отклонено'),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Ошибка отклонения'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ожидающие подтверждения'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadDonations,
        child: Consumer<DonationProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.pendingDonations.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '✅',
                      style: TextStyle(fontSize: 80),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Нет ожидающих пожертвований',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Все пожертвования обработаны',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.pendingDonations.length,
              itemBuilder: (context, index) {
                final donation = provider.pendingDonations[index];
                final formatter = NumberFormat('#,###', 'ru_RU');

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              child: Text(
                                donation.donorName?[0].toUpperCase() ?? 'U',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    donation.donorName ?? 'Пользователь',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    donation.fundraiserTitle ?? '',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${formatter.format(donation.amount)} ₽',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        if (donation.message != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              donation.message!,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: donation.screenshotUrl != null
                              ? () => _showScreenshotDialog(donation.screenshotUrl!)
                              : null,
                          icon: const Icon(Icons.image),
                          label: const Text('Посмотреть скриншот'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _approveDonation(donation.id),
                                icon: const Icon(Icons.check),
                                label: const Text('Подтвердить'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(0, 48),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _rejectDonation(donation.id),
                                icon: const Icon(Icons.close),
                                label: const Text('Отклонить'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  minimumSize: const Size(0, 48),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Отправлено: ${DateFormat('dd.MM.yyyy HH:mm').format(donation.createdAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
