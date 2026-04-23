import 'package:flutter/material.dart';
import '../models/donation.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../utils/logger.dart';

class DonationProvider with ChangeNotifier {
  List<Donation> _myDonations = [];
  List<Donation> _pendingDonations = [];
  List<Donation> _fundraiserDonations = [];
  bool _isLoading = false;
  String? _error;

  List<Donation> get myDonations => _myDonations;
  List<Donation> get pendingDonations => _pendingDonations;
  List<Donation> get fundraiserDonations => _fundraiserDonations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> createDonation({
    required int fundraiserId,
    required double amount,
    required String screenshotPath,
    String? message,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      Logger.info('Creating donation', 'fundraiserId=$fundraiserId, amount=$amount');

      final fields = {
        'fundraiser_id': fundraiserId.toString(),
        'amount': amount.toString(),
        if (message != null) 'message': message,
      };

      Logger.debug('Uploading file with fields', fields);

      await ApiService.uploadFile(
        ApiConfig.donations,
        screenshotPath,
        'screenshot',
        fields: fields,
        needsAuth: true,
      );

      Logger.info('Donation created successfully');

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      Logger.error('Error creating donation', e);
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadMyDonations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.get(ApiConfig.myDonations, needsAuth: true);
      _myDonations = (response as List)
          .map((json) => Donation.fromJson(json))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPendingDonations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.get(ApiConfig.pendingDonations, needsAuth: true);
      _pendingDonations = (response as List)
          .map((json) => Donation.fromJson(json))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> approveDonation(int id) async {
    try {
      await ApiService.patch(ApiConfig.approveDonation(id), needsAuth: true);
      await loadPendingDonations();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectDonation(int id) async {
    try {
      await ApiService.patch(ApiConfig.rejectDonation(id), needsAuth: true);
      await loadPendingDonations();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> loadFundraiserDonations(int fundraiserId) async {
    Logger.info('Loading donations for fundraiser', fundraiserId);
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final url = '${ApiConfig.donations}/fundraiser/$fundraiserId';
      Logger.debug('Fetching donations from', url);

      final response = await ApiService.get(
        url,
        needsAuth: false,
      );

      Logger.debug('Donations response received', response);

      _fundraiserDonations = (response as List)
          .map((json) => Donation.fromJson(json))
          .toList();

      Logger.info('Loaded donations', '${_fundraiserDonations.length} donations');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      Logger.error('Error loading fundraiser donations', e);
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}
