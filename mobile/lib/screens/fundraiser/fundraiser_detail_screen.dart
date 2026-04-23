import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../providers/fundraiser_provider.dart';
import '../../providers/donation_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/fundraiser.dart';
import '../../config/api_config.dart';
import '../../widgets/donors_list.dart';
import '../../widgets/loading_overlay.dart';
import 'submit_completion_proof_screen.dart';

class FundraiserDetailScreen extends StatefulWidget {
  final int fundraiserId;

  const FundraiserDetailScreen({super.key, required this.fundraiserId});

  @override
  State<FundraiserDetailScreen> createState() => _FundraiserDetailScreenState();
}

class _FundraiserDetailScreenState extends State<FundraiserDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadFundraiser();
    });
  }

  loadFundraiser() async {
    final provider = Provider.of<FundraiserProvider>(context, listen: false);
    await provider.loadFundraiserDetail(widget.fundraiserId);

    final donationProvider = Provider.of<DonationProvider>(context, listen: false);
    await donationProvider.loadFundraiserDonations(widget.fundraiserId);
  }

  void _showDonateSheet(Fundraiser fundraiser) {
    final amountController = TextEditingController();
    final messageController = TextEditingController();
    String? screenshotPath;
    bool isSubmitting = false;
    bool confirmedAge = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                  alignment: Alignment.center,
                ),
                const Text(
                  'Сделать пожертвование',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _buildPaymentInfoCard(fundraiser),
                const SizedBox(height: 20),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    labelText: 'Сумма (₽)',
                    hintText: 'Минимум 100₽',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    prefixIcon: const Icon(Icons.payments, size: 24),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Сообщение (необязательно)',
                    hintText: 'Пожелание или комментарий',
                    helperText: 'Напишите сообщение для всех',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    prefixIcon: const Icon(Icons.message, size: 24),
                  ),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: confirmedAge,
                  onChanged: (value) => setModalState(() => confirmedAge = value ?? false),
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Мне есть 16 лет',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ),
                if (!confirmedAge)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Для пожертвования необходимо подтвердить возраст',
                      style: TextStyle(fontSize: 11, color: Colors.red[700]),
                    ),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: confirmedAge ? () async {
                    final picker = ImagePicker();
                    final image = await picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      setModalState(() => screenshotPath = image.path);
                    }
                  } : null,
                  icon: Icon(
                    screenshotPath != null ? Icons.check_circle : Icons.upload_file,
                    color: screenshotPath != null ? Colors.green : null,
                  ),
                  label: Text(screenshotPath != null ? 'Скриншот прикреплён' : 'Прикрепить скриншот'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Прикрепите скриншот перевода из банка',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: (isSubmitting || !confirmedAge) ? null : () async {
                    if (amountController.text.isEmpty) {
                      _showError('Введите сумму');
                      return;
                    }
                    final amount = double.tryParse(amountController.text);
                    if (amount == null || amount < 100) {
                      _showError('Минимальная сумма 100₽');
                      return;
                    }
                    if (screenshotPath == null) {
                      _showError('Прикрепите скриншот перевода');
                      return;
                    }

                    setModalState(() => isSubmitting = true);

                    final donationProvider = Provider.of<DonationProvider>(context, listen: false);
                    final success = await donationProvider.createDonation(
                      fundraiserId: fundraiser.id,
                      amount: amount,
                      screenshotPath: screenshotPath!,
                      message: messageController.text.isNotEmpty ? messageController.text : null,
                    );

                    if (!mounted) return;
                    Navigator.pop(context);

                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Спасибо! Пожертвование отправлено 💚'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      loadFundraiser();
                    } else {
                      _showError(donationProvider.error ?? 'Ошибка');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Отправить',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentInfoCard(Fundraiser fundraiser) {
    if (fundraiser.paymentMethod == 'sbp') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green[50]!, Colors.green[100]!],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.phone_android, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Перевод по СБП', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Телефон', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(height: 4),
                      Text(fundraiser.sbpPhone != null ? '+7${fundraiser.sbpPhone}' : '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: fundraiser.sbpPhone != null ? '+7${fundraiser.sbpPhone}' : ''));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Скопировано')),
                    );
                  },
                ),
              ],
            ),
            Text('Банк: ${fundraiser.sbpBank}', style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.green[700], size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'В сообщении: Пожертвование "Моё добро"',
                      style: TextStyle(fontSize: 12, color: Colors.green[900]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange[50]!, Colors.orange[100]!],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.credit_card, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Перевод на карту', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Номер карты', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(height: 4),
                    Text(fundraiser.cardNumber ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: fundraiser.cardNumber ?? ''));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Скопировано')),
                  );
                },
              ),
            ],
          ),
          if (fundraiser.cardHolderName != null)
            Text('Владелец: ${fundraiser.cardHolderName}', style: TextStyle(color: Colors.grey[700])),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange[700], size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'В сообщении: Пожертвование "Моё добро"',
                    style: TextStyle(fontSize: 12, color: Colors.orange[900]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _openFullScreenImage(String initialUrl) {
    final fundraiser = Provider.of<FundraiserProvider>(context, listen: false).selectedFundraiser;
    if (fundraiser == null) return;

    final images = <String>[];
    if (fundraiser.imageUrl != null && fundraiser.imageUrl!.isNotEmpty) {
      images.add(fundraiser.imageUrl!);
    }
    if (fundraiser.imageUrls != null) {
      images.addAll(fundraiser.imageUrls!);
    }

    final initialIndex = images.indexOf(initialUrl);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FullScreenGallery(
          images: images,
          initialIndex: initialIndex >= 0 ? initialIndex : 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<FundraiserProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return _buildErrorView(provider.error!);
          }

          final fundraiser = provider.selectedFundraiser;
          if (fundraiser == null) {
            return _buildNotFoundView();
          }

          final formatter = NumberFormat('#,###', 'ru_RU');

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(fundraiser),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCategoryChip(fundraiser),
                      const SizedBox(height: 12),
                      Text(
                        fundraiser.title,
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      _buildProgressCard(fundraiser, formatter),
                      const SizedBox(height: 24),
                      _buildCreatorCard(fundraiser),
                      const SizedBox(height: 24),
                      _buildDescriptionCard(fundraiser),
                      const SizedBox(height: 24),
                      _buildDonationsSection(fundraiser.id),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Consumer<FundraiserProvider>(
        builder: (context, fundProvider, child) {
          final fundraiser = fundProvider.selectedFundraiser;
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          final currentUser = authProvider.user;
          final isAuthor = currentUser != null && currentUser.id == fundraiser?.userId;

          if (fundraiser == null) return const SizedBox.shrink();

          if (fundraiser.status == 'completed' && isAuthor && fundraiser.completionProofUrl == null) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SubmitCompletionProofScreen(fundraiser: fundraiser),
                      ),
                    ).then((_) => loadFundraiser());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.upload_file, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Отправить подтверждение',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          if (fundraiser.status != 'active') {
            return const SizedBox.shrink();
          }

          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: ElevatedButton(
                onPressed: () => _showDonateSheet(fundraiser),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Помочь',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(Fundraiser fundraiser) {
    final images = <String>[];
    if (fundraiser.imageUrl != null && fundraiser.imageUrl!.isNotEmpty) {
      images.add(fundraiser.imageUrl!);
    }
    if (fundraiser.imageUrls != null) {
      images.addAll(fundraiser.imageUrls!);
    }

    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      backgroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.black),
      flexibleSpace: FlexibleSpaceBar(
        background: images.isEmpty
            ? Container(
                color: Colors.grey[200],
                child: Center(
                  child: Text(fundraiser.categoryEmoji, style: const TextStyle(fontSize: 80)),
                ),
              )
            : images.length == 1
                ? GestureDetector(
                    onTap: () => _openFullScreenImage(images.first),
                    child: Image.network(
                      ApiConfig.getImageUrl(images.first),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  )
                : _buildImageCarousel(images),
      ),
    );
  }

  Widget _buildImageCarousel(List<String> images) {
    return PageView.builder(
      itemCount: images.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _openFullScreenImage(images[index]),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                ApiConfig.getImageUrl(images[index]),
                fit: BoxFit.cover,
              ),
              if (images.length > 1)
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${index + 1}/${images.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryChip(Fundraiser fundraiser) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${fundraiser.categoryEmoji} ${fundraiser.categoryName}',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildProgressCard(Fundraiser fundraiser, NumberFormat formatter) {
    final progress = ((fundraiser.progressPercent ?? 0) / 100).clamp(0.0, 1.0);
    final percent = (fundraiser.progressPercent ?? 0).toStringAsFixed(1);

    return Container(
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
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${formatter.format(fundraiser.currentAmount)} ₽',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'из ${formatter.format(fundraiser.goalAmount)} ₽',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$percent%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white,
              valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.primary),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$percent% собрано',
                style: TextStyle(color: Colors.grey[700], fontSize: 12),
              ),
              Text(
                '${fundraiser.donorsCount ?? 0} ${_getDonorsText(fundraiser.donorsCount ?? 0)}',
                style: TextStyle(color: Colors.grey[700], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getDonorsText(int count) {
    if (count % 10 == 1 && count % 100 != 11) return 'донор';
    if (count % 10 >= 2 && count % 10 <= 4 && (count % 100 < 12 || count % 100 > 14)) return 'донора';
    return 'донатов';
  }

  Widget _buildCreatorCard(Fundraiser fundraiser) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Theme.of(context).colorScheme.primary,
            backgroundImage: fundraiser.creatorAvatar != null
                ? NetworkImage(ApiConfig.getImageUrl(fundraiser.creatorAvatar!))
                : null,
            child: fundraiser.creatorAvatar == null
                ? Text(
                    (fundraiser.creatorName ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fundraiser.creatorName ?? 'Пользователь',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                Text(
                  'Организатор сбора',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(Fundraiser fundraiser) {
    final isCompleted = fundraiser.status == 'completed';
    final hasProof = fundraiser.completionProofUrl != null;
    final isVerified = fundraiser.completionVerified;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isCompleted) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: hasProof ? Colors.green[50] : Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: hasProof ? Colors.green[200]! : Colors.orange[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      hasProof ? Icons.check_circle : Icons.hourglass_empty,
                      color: hasProof ? Colors.green[700] : Colors.orange[700],
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      hasProof 
                          ? (isVerified ? 'Сбор успешно завершён' : 'Подтверждение отправлено')
                          : 'Сбор завершён',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: hasProof ? Colors.green[700] : Colors.orange[700],
                      ),
                    ),
                  ],
                ),
                if (hasProof) ...[
                  const SizedBox(height: 12),
                  if (fundraiser.completionMessage != null) ...[
                    Text(
                      'Сообщение: ${fundraiser.completionMessage}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 8),
                  ],
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => _FullScreenGallery(
                            images: [fundraiser.completionProofUrl!],
                            initialIndex: 0,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.image, color: Colors.green[700]),
                          const SizedBox(width: 8),
                          Text(
                            isVerified 
                                ? 'Посмотреть подтверждение'
                                : 'Подтверждающие документы (на проверке)',
                            style: TextStyle(color: Colors.green[700]),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        const Text(
          'Описание',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          fundraiser.description,
          style: TextStyle(fontSize: 15, height: 1.6, color: Colors.grey[800]),
        ),
      ],
    );
  }

  Widget _buildDonationsSection(int fundraiserId) {
    return Consumer<DonationProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final donations = provider.fundraiserDonations;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Пожертвования (${donations.length})',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (donations.isNotEmpty)
                  Text(
                    '≈ ${_formatTotal(donations.fold(0.0, (sum, d) => sum + d.amount))}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (donations.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    'Пока нет пожертвований',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              DonorsList(donations: donations),
          ],
        );
      },
    );
  }

  String _formatTotal(double amount) {
    final formatter = NumberFormat.currency(locale: 'ru_RU', symbol: '₽');
    return formatter.format(amount);
  }

  Widget _buildErrorView(String error) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ошибка')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: loadFundraiser,
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundView() {
    return Scaffold(
      appBar: AppBar(title: const Text('Не найдено')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('Сбор не найден'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Назад'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullScreenGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullScreenGallery({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1} / ${widget.images.length}',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Поделиться: функция недоступна')),
              );
            },
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Image.network(
                ApiConfig.getImageUrl(widget.images[index]),
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const CircularProgressIndicator(
                    color: Colors.white,
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.broken_image,
                    color: Colors.grey,
                    size: 64,
                  );
                },
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: widget.images.length > 1
          ? Container(
              height: 60,
              color: Colors.black,
              child: Center(
                child: SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                    itemCount: widget.images.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final isSelected = index == _currentIndex;
                      return GestureDetector(
                        onTap: () {
                          _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.grey,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Opacity(
                              opacity: isSelected ? 1.0 : 0.5,
                              child: Image.network(
                                ApiConfig.getImageUrl(widget.images[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            )
          : null,
    );
  }
}