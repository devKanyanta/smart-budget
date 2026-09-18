import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/api_exception.dart';
import '../services/auth_service.dart';

class WalletProvider extends ChangeNotifier {
  Map<String, dynamic>? _wallet;
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = false;
  AuthService? _auth;

  Map<String, dynamic>? get wallet => _wallet;
  List<Map<String, dynamic>> get transactions => _transactions;
  bool get isLoading => _isLoading;

  double get balance =>
      double.tryParse(_wallet?['balance']?.toString() ?? '0') ?? 0.0;
  String get paymentMode => _wallet?['payment_mode'] ?? 'simulated';

  void update(AuthService auth) {
    _auth = auth;
    if (auth.isAuthenticated) fetchWallet();
  }

  ApiService get _api => _auth!.api;

  Future<void> fetchWallet() async {
    if (_auth == null || !_auth!.isAuthenticated) return;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.getWallet();
      _wallet = response['data'];
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchTransactions() async {
    if (_auth == null || !_auth!.isAuthenticated) return;
    try {
      final response = await _api.getWalletTransactions();
      _transactions = List<Map<String, dynamic>>.from(response['data'] ?? []);
      notifyListeners();
    } catch (_) {}
  }

  Future<String?> topUp({
    required double amount,
    required String phoneNumber,
    required String network,
  }) async {
    if (_auth == null || !_auth!.isAuthenticated) return 'Not signed in';
    try {
      final response = await _api.topUpWallet({
        'amount': amount,
        'phone_number': phoneNumber,
        'network': network,
      });
      await fetchWallet();
      await fetchTransactions();
      return response['data']?['message'] as String?;
    } catch (e) {
      return _extractError(e);
    }
  }

  Future<String?> pay({required double amount, String? description}) async {
    if (_auth == null || !_auth!.isAuthenticated) return 'Not signed in';
    try {
      await _api.payFromWallet({
        'amount': amount,
        if (description != null) 'description': description,
      });
      await fetchWallet();
      await fetchTransactions();
      return null; // success
    } catch (e) {
      return _extractError(e);
    }
  }  Future<bool> updateLimits({double? dailyLimit, double? monthlyLimit}) async {
    if (_auth == null || !_auth!.isAuthenticated) return false;
    try {
      await _api.updateWalletLimits({
        'daily_limit': dailyLimit,
        'monthly_limit': monthlyLimit,
      });
      await fetchWallet();
      return true;
    } catch (_) {
      return false;
    }
  }

  String _extractError(Object e) => ApiException.from(e).displayMessage;
}
