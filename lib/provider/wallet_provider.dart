import 'package:flutter/material.dart';
import 'package:nainkart_user/api_services/home_page_api_services.dart';

class WalletProvider extends ChangeNotifier {
  int _walletAmount = 0;
  final HomePageApiServices _api = HomePageApiServices();
  bool _isLoading = false;

  int get walletAmount => _walletAmount;
  bool get isLoading => _isLoading;

  Future<void> fetchWallet(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final amount = await _api.fetchWalletBalance(token);
      _walletAmount = amount;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Error fetching wallet: $e');
      rethrow;
    }
  }

  void updateWalletAmount(int amount) {
    _walletAmount = amount;
    notifyListeners();
  }
}
