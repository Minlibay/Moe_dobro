import 'package:flutter/material.dart';
import '../models/fundraiser.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../utils/logger.dart';

class FundraiserProvider with ChangeNotifier {
  List<Fundraiser> _fundraisers = [];
  List<Fundraiser> _myFundraisers = [];
  List<Fundraiser> _completedFundraisers = [];
  Fundraiser? _selectedFundraiser;
  bool _isLoading = false;
  String? _error;

  List<Fundraiser> get fundraisers => _fundraisers;
  List<Fundraiser> get myFundraisers => _myFundraisers;
  List<Fundraiser> get completedFundraisers => _completedFundraisers;
  Fundraiser? get selectedFundraiser => _selectedFundraiser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadFundraisers({String? category}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String url = ApiConfig.fundraisers;
      if (category != null) {
        url += '?category=$category';
      }

      final response = await ApiService.get(url);
      _fundraisers = (response as List)
          .map((json) => Fundraiser.fromJson(json))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadFundraiserDetail(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      Logger.info('Loading fundraiser detail', 'id: $id');
      final response = await ApiService.get(ApiConfig.fundraiserDetail(id));
      Logger.debug('Response received', response);
      _selectedFundraiser = Fundraiser.fromJson(response);
      Logger.info('Fundraiser parsed successfully', _selectedFundraiser?.title);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      Logger.error('Error loading fundraiser detail', e);
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMyFundraisers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.get(ApiConfig.myFundraisers, needsAuth: true);
      _myFundraisers = (response as List)
          .map((json) => Fundraiser.fromJson(json))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createFundraiser({
    required String title,
    required String description,
    required String category,
    required double goalAmount,
    required String paymentMethod,
    String? cardNumber,
    String? cardHolderName,
    String? bankName,
    String? sbpPhone,
    String? sbpBank,
    String? imagePath,
    List<String>? imagePaths,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final fields = {
        'title': title,
        'description': description,
        'category': category,
        'goal_amount': goalAmount.toString(),
        'payment_method': paymentMethod,
        if (cardNumber != null) 'card_number': cardNumber,
        if (cardHolderName != null) 'card_holder_name': cardHolderName,
        if (bankName != null) 'bank_name': bankName,
        if (sbpPhone != null) 'sbp_phone': sbpPhone,
        if (sbpBank != null) 'sbp_bank': sbpBank,
      };

      // Если есть несколько фото - отправляем все
      if (imagePaths != null && imagePaths.isNotEmpty) {
        await ApiService.uploadFiles(
          ApiConfig.fundraisers,
          imagePaths,
          'images',
          fields: fields,
          needsAuth: true,
        );
      } else if (imagePath != null) {
        await ApiService.uploadFile(
          ApiConfig.fundraisers,
          imagePath,
          'image',
          fields: fields,
          needsAuth: true,
        );
      } else {
        await ApiService.post(
          ApiConfig.fundraisers,
          fields,
          needsAuth: true,
        );
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> closeFundraiser(int id) async {
    try {
      await ApiService.patch(
        '${ApiConfig.fundraisers}/$id/close',
        needsAuth: true,
      );
      await loadMyFundraisers();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> submitCompletionProof({
    required int fundraiserId,
    required String message,
    required String proofImagePath,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final fields = {
        'message': message,
      };

      await ApiService.uploadFile(
        '${ApiConfig.fundraisers}/$fundraiserId/completion-proof',
        proofImagePath,
        'proof',
        fields: fields,
        needsAuth: true,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadCompletedFundraisers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.get('${ApiConfig.fundraisers}?status=verified_completed');
      _completedFundraisers = (response as List)
          .map((json) => Fundraiser.fromJson(json))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}
