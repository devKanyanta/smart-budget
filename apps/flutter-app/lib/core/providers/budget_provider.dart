import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class BudgetProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _budgets = [];
  bool _isLoading = false;
  AuthService? _auth;

  List<Map<String, dynamic>> get budgets => _budgets;
  bool get isLoading => _isLoading;

  void update(AuthService auth) {
    _auth = auth;
    if (auth.isAuthenticated) fetchBudgets();
  }

  ApiService get _api => _auth!.api;

  Future<void> fetchBudgets() async {
    if (_auth == null || !_auth!.isAuthenticated) return;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.getBudgets();
      _budgets = List<Map<String, dynamic>>.from(response['data']);
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createBudget(Map<String, dynamic> data) async {
    if (_auth == null || !_auth!.isAuthenticated) return false;
    try {
      await _api.createBudget(data);
      await fetchBudgets();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteBudget(String id) async {
    if (_auth == null || !_auth!.isAuthenticated) return false;
    try {
      await _api.deleteBudget(id);
      _budgets.removeWhere((b) => b['id'] == id);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}
