import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../providers/fundraiser_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/loading_overlay.dart';

class CreateFundraiserScreen extends StatefulWidget {
  const CreateFundraiserScreen({super.key});

  @override
  State<CreateFundraiserScreen> createState() => _CreateFundraiserScreenState();
}

class _CreateFundraiserScreenState extends State<CreateFundraiserScreen> {
  final PageController _pageController = PageController();
  final int _totalSteps = 4;
  int _currentStep = 0;

  // Form data
  String _selectedCategory = 'mortgage';
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _goalController = TextEditingController();
  String _paymentMethod = 'card';
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _bankController = TextEditingController();
  final _sbpPhoneController = TextEditingController();
  String? _selectedBank;
  List<String> _imagePaths = [];
  bool _isLoading = false;

  final List<Map<String, String>> _categories = [
    {'value': 'mortgage', 'label': 'Ипотека', 'emoji': '🏠', 'desc': 'Первый взнос, аренда'},
    {'value': 'medical', 'label': 'Лечение', 'emoji': '💊', 'desc': 'Медицина, операции'},
    {'value': 'education', 'label': 'Образование', 'emoji': '📚', 'desc': 'Обучение, курсы'},
    {'value': 'other', 'label': 'Другое', 'emoji': '🎯', 'desc': 'Другие цели'},
  ];

  final List<String> _banks = [
    'Сбербанк', 'Тинькофф', 'Альфа-Банк', 'ВТБ', 'Газпромбанк',
    'Райффайзен Банк', 'Банк Открытие', 'Совкомбанк', 'Росбанк',
    'МТС Банк', 'Промсвязьбанк', 'Почта Банк',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _goalController.dispose();
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _bankController.dispose();
    _sbpPhoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_imagePaths.length >= 5) {
      _showSnackBar('Максимум 5 фотографий');
      return;
    }

    final picker = ImagePicker();
    final images = await picker.pickMultiImage();

    if (images.isNotEmpty) {
      setState(() {
        final remaining = 5 - _imagePaths.length;
        final toAdd = images.take(remaining).map((e) => e.path).toList();
        _imagePaths.addAll(toAdd);
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _titleController.text.isNotEmpty;
      case 1:
        return _descriptionController.text.isNotEmpty && _goalController.text.isNotEmpty;
      case 2:
        if (_paymentMethod == 'card') {
          return _cardNumberController.text.length >= 16;
        } else {
          return _sbpPhoneController.text.isNotEmpty && _selectedBank != null;
        }
      case 3:
        return true;
      default:
        return false;
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _createFundraiser();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _createFundraiser() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user!.totalDonated < 100) {
      _showSnackBar('Сначала помогите кому-то (минимум 100₽)', isError: true);
      return;
    }

    final goalAmount = double.tryParse(_goalController.text);
    if (goalAmount == null || goalAmount < 1000) {
      _showSnackBar('Минимальная сумма сбора - 1000₽', isError: true);
      return;
    }

    LoadingDialog.show(context, message: 'Создание сбора...');

    final provider = Provider.of<FundraiserProvider>(context, listen: false);
    final success = await provider.createFundraiser(
      title: _titleController.text,
      description: _descriptionController.text,
      category: _selectedCategory,
      goalAmount: goalAmount,
      paymentMethod: _paymentMethod,
      cardNumber: _paymentMethod == 'card' ? _cardNumberController.text : null,
      cardHolderName: _paymentMethod == 'card' ? _cardHolderController.text : null,
      bankName: _paymentMethod == 'card' && _bankController.text.isNotEmpty
          ? _bankController.text
          : null,
      sbpPhone: _paymentMethod == 'sbp' ? _sbpPhoneController.text : null,
      sbpBank: _paymentMethod == 'sbp' ? _selectedBank : null,
      imagePaths: _imagePaths.isNotEmpty ? _imagePaths : null,
    );

    if (!mounted) return;
    LoadingDialog.hide(context);

    if (success) {
      _showSnackBar('Сбор успешно создан!');
      Navigator.pop(context);
    } else {
      _showSnackBar(provider.error ?? 'Ошибка создания сбора', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Шаг ${_currentStep + 1} из $_totalSteps'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildProgressIndicator(theme),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) => setState(() => _currentStep = index),
              children: [
                _buildCategoryStep(theme),
                _buildDetailsStep(theme),
                _buildPaymentStep(theme),
                _buildPhotosStep(theme),
              ],
            ),
          ),
          _buildBottomBar(theme),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Row(
            children: List.generate(_totalSteps, (index) {
              final isCompleted = index < _currentStep;
              final isCurrent = index == _currentStep;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? theme.colorScheme.primary
                        : isCurrent
                            ? theme.colorScheme.primary.withValues(alpha: 0.5)
                            : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            TextButton(
              onPressed: _previousStep,
              child: const Text('Назад'),
            ),
          const Spacer(),
          ElevatedButton(
            onPressed: _canProceed() ? _nextStep : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(_currentStep == _totalSteps - 1 ? 'Создать' : 'Далее'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryStep(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Выберите категорию',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'К какой сфере относится ваш сбор?',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ..._categories.map((cat) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildCategoryCard(cat, theme),
              )),
          const SizedBox(height: 24),
          const Text(
            'Название сбора',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: 'Например: Помощь на первый взнос',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, String> cat, ThemeData theme) {
    final isSelected = _selectedCategory == cat['value'];
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? theme.colorScheme.primary : Colors.grey[200]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => setState(() => _selectedCategory = cat['value']!),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primaryContainer
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(cat['emoji']!, style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cat['label']!,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? theme.colorScheme.primary : null,
                      ),
                    ),
                    Text(
                      cat['desc']!,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: theme.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsStep(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Опишите вашу историю',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Расскажите подробнее о себе и цели сбора',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          const Text(
            'Описание',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: 'Расскажите вашу историю, почему нужна помощь...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Целевая сумма',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _goalController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: '100000',
              prefixText: '',
              suffixText: '₽',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Минимальная сумма - 1000₽',
                    style: TextStyle(fontSize: 13, color: Colors.blue[800]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStep(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Как получать средства',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Выберите удобный способ',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildPaymentMethodCard(
                  icon: Icons.credit_card,
                  title: 'Карта',
                  isSelected: _paymentMethod == 'card',
                  onTap: () => setState(() => _paymentMethod = 'card'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPaymentMethodCard(
                  icon: Icons.phone_android,
                  title: 'СБП',
                  isSelected: _paymentMethod == 'sbp',
                  onTap: () => setState(() => _paymentMethod = 'sbp'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_paymentMethod == 'card') _buildCardForm(theme),
          if (_paymentMethod == 'sbp') _buildSbpForm(theme),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[600],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Theme.of(context).colorScheme.primary : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Номер карты',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _cardNumberController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(16),
          ],
          decoration: InputDecoration(
            hintText: '1234 5678 9012 3456',
            prefixIcon: const Icon(Icons.credit_card),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Владелец карты',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _cardHolderController,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            hintText: 'IVAN IVANOV',
            prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Банк (необязательно)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _bankController,
          decoration: InputDecoration(
            hintText: 'Сбербанк',
            prefixIcon: const Icon(Icons.account_balance),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange[700], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Имя владельца должно совпадать с именем на карте',
                  style: TextStyle(fontSize: 13, color: Colors.orange[900]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSbpForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Номер телефона',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _sbpPhoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: '+7 999 123-45-67',
            prefixText: '+7 ',
            prefixIcon: const Icon(Icons.phone),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Банк',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedBank,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.account_balance),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          hint: const Text('Выберите банк'),
          items: _banks.map((bank) {
            return DropdownMenuItem(value: bank, child: Text(bank));
          }).toList(),
          onChanged: (value) => setState(() => _selectedBank = value),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[700], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Мгновенные переводы 24/7 без комиссии',
                  style: TextStyle(fontSize: 13, color: Colors.green[800]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotosStep(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Добавьте фотографии',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'До 5 фотографий для привлечения внимания',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (_imagePaths.length < 5) _buildAddPhotoButton(theme),
              ..._imagePaths.asMap().entries.map((entry) {
                return _buildPhotoThumbnail(entry.value, entry.key, theme);
              }),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Совет',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Добавьте фото документов, себя с табличкой или другие подтверждения - это повысит доверие',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSummaryCard(theme),
        ],
      ),
    );
  }

  Widget _buildAddPhotoButton(ThemeData theme) {
    return InkWell(
      onTap: _pickImages,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo, size: 32, color: Colors.grey[500]),
            const SizedBox(height: 4),
            Text(
              '${_imagePaths.length}/5',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoThumbnail(String path, int index, ThemeData theme) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            image: DecorationImage(
              image: FileImage(File(path)),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => setState(() => _imagePaths.removeAt(index)),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(ThemeData theme) {
    final goalAmount = double.tryParse(_goalController.text) ?? 0;
    final formatter = NumberFormat('#,###', 'ru_RU');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Проверьте данные',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildSummaryRow('Категория', _categories.firstWhere((c) => c['value'] == _selectedCategory)['label']!),
            _buildSummaryRow('Название', _titleController.text),
            _buildSummaryRow('Цель', '${formatter.format(goalAmount)} ₽'),
            _buildSummaryRow('Способ', _paymentMethod == 'card' ? 'Карта' : 'СБП'),
            _buildSummaryRow('Фото', _imagePaths.isEmpty ? 'Нет' : '${_imagePaths.length} шт.'),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}