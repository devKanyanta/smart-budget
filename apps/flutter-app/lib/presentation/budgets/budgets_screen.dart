import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/budget_provider.dart';
import '../../core/services/auth_service.dart';
import '../common/app_colors.dart';
import '../common/app_widgets.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  Map<String, dynamic>? _prediction;

  @override
  void initState() {
    super.initState();
    _loadPrediction();
  }

  Future<void> _loadPrediction() async {
    try {
      final auth = context.read<AuthService>();
      final response = await auth.api.getBudgetPrediction();
      if (mounted) {
        setState(() => _prediction = response['data']);
      }
    } catch (_) {
      // Prediction unavailable — banner simply won't show
    }
  }

  @override
  Widget build(BuildContext context) {
    final budgetProvider = context.watch<BudgetProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Solid header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: const BoxDecoration(
              color: AppColors.heroSolid,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Budgets',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Track your spending limits',
                            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                          ),
                        ],
                      ),
                      // Quick stats
                      if (budgetProvider.budgets.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${budgetProvider.budgets.length} active',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Budget list
          Expanded(
            child: budgetProvider.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : RefreshIndicator(
                    onRefresh: () async {
                      await budgetProvider.fetchBudgets();
                      await _loadPrediction();
                    },
                    color: AppColors.primary,
                    child: budgetProvider.budgets.isEmpty
                        ? const EmptyState(
                            icon: Icons.pie_chart_outline,
                            title: 'No Budgets Yet',
                            subtitle: 'Create a budget to start tracking your spending limits',
                            actionText: 'Create Budget',
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                            itemCount: budgetProvider.budgets.length + (_showPredictionBanner ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (_showPredictionBanner && index == 0) {
                                return _buildPredictionBanner();
                              }
                              final budget = budgetProvider.budgets[_showPredictionBanner ? index - 1 : index];
                              return _buildBudgetCard(context, budget);
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          color: AppColors.primarySolid,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _showAddBudgetDialog(context),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  bool get _showPredictionBanner =>
      _prediction != null &&
      _prediction!['prediction_available'] == true &&
      (_prediction!['risk_level'] == 'high' || _prediction!['risk_level'] == 'medium');

  Widget _buildPredictionBanner() {
    final p = _prediction!;
    final isHigh = p['risk_level'] == 'high';
    final color = isHigh ? AppColors.expense : AppColors.warning;
    final bg = isHigh ? const Color(0xFFFFEBEE) : const Color(0xFFFFF3E0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology_rounded, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AI Overspending Prediction — ${p['risk_level'].toString().toUpperCase()} risk',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            p['message'] ?? '',
            style: TextStyle(color: Colors.grey[700], fontSize: 12),
          ),
          if (p['recommended_daily_spend'] != null) ...[
            const SizedBox(height: 6),
            Text(
              'Suggested: keep daily spending under K${(p['recommended_daily_spend'] as num).toStringAsFixed(2)}',
              style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBudgetCard(BuildContext context, Map<String, dynamic> budget) {
    final category = budget['category'];
    final amount = double.tryParse(budget['amount']?.toString() ?? '0') ?? 0.0;
    final spent = double.tryParse(budget['spent_amount']?.toString() ?? '0') ?? 0.0;
    final remaining = double.tryParse(budget['remaining']?.toString() ?? '0') ?? 0.0;
    final percentage = double.tryParse((budget['percentage_used'] ?? 0).toString()) ?? 0.0;
    final isOverBudget = percentage > 100;

    final Color progressColor;
    if (isOverBudget) {
      progressColor = AppColors.expense;
    } else if (percentage > 80) {
      progressColor = AppColors.warning;
    } else {
      progressColor = AppColors.success;
    }

    final categoryColor = Color(
      int.parse(category?['color']?.replaceFirst('#', '0xFF') ?? '0xFF4CAF50'),
    );

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Circular progress
              SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: (percentage / 100).clamp(0.0, 1.0).toDouble(),
                      strokeWidth: 6,
                      backgroundColor: Colors.grey[200],
                      color: progressColor,
                      strokeCap: StrokeCap.round,
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${percentage.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: progressColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: categoryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            category?['name'] ?? 'Overall Budget',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${budget['period'] ?? 'monthly'} - K${amount.toStringAsFixed(0)} limit',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                        if (budget['enforce'] == true) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'STRICT',
                              style: TextStyle(
                                color: AppColors.warning,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          SolidProgressIndicator(
            progress: (percentage / 100).clamp(0.0, 1.0).toDouble(),
            height: 8,
            borderRadius: 4,
            color: progressColor,
          ),
          const SizedBox(height: 12),
          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniStat('Spent', 'K${spent.toStringAsFixed(0)}', AppColors.expense),
              _buildMiniStat('Remaining', 'K${remaining.toStringAsFixed(0)}', AppColors.income),
              _buildMiniStat('Budget', 'K${amount.toStringAsFixed(0)}', AppColors.primary),
            ],
          ),
          if (isOverBudget) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.expense, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Over budget by K${(spent - amount).toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppColors.expense,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey[500], fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: color,
          ),
        ),
      ],
    );
  }

  void _showAddBudgetDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddBudgetSheet(),
    );
  }
}

class AddBudgetSheet extends StatefulWidget {
  const AddBudgetSheet({super.key});

  @override
  State<AddBudgetSheet> createState() => _AddBudgetSheetState();
}

class _AddBudgetSheetState extends State<AddBudgetSheet> {
  final _amountController = TextEditingController();
  String _period = 'monthly';
  String? _categoryId;
  List<Map<String, dynamic>> _categories = [];
  bool _enforce = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final auth = context.read<AuthService>();
      final response = await auth.api.getCategories();
      if (mounted) {
        setState(() {
          _categories = List<Map<String, dynamic>>.from(response['data'] ?? []);
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Create Budget',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              labelText: 'Budget Amount (K)',
              prefixText: 'K ',
              prefixStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _categoryId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Category (overall budget if empty)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Overall budget (all categories)', style: TextStyle(fontStyle: FontStyle.italic)),
              ),
              ..._categories.map((c) => DropdownMenuItem<String>(
                    value: c['id'] as String,
                    child: Text(c['name'] ?? 'Category'),
                  )),
            ],
            onChanged: (v) => setState(() => _categoryId = v),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _period,
            decoration: InputDecoration(
              labelText: 'Period',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: const [
              DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
              DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
              DropdownMenuItem(value: 'quarterly', child: Text('Quarterly')),
              DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
            ],
            onChanged: (v) => setState(() => _period = v ?? 'monthly'),
          ),
          const SizedBox(height: 16),
          // Strict budget toggle — enforces a spending control
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _enforce ? const Color(0xFFFFF3E0) : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.shield_rounded,
                  color: _enforce ? AppColors.warning : Colors.grey[500],
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Strict budget',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: _enforce ? AppColors.warning : Colors.black87,
                        ),
                      ),
                      Text(
                        'Block transactions that would exceed this limit',
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _enforce,
                  activeColor: AppColors.warning,
                  onChanged: (v) => setState(() => _enforce = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () async {
                if (_amountController.text.isEmpty) return;
                final success = await context.read<BudgetProvider>().createBudget({
                  'amount': double.parse(_amountController.text),
                  'period': _period,
                  if (_categoryId != null) 'category_id': _categoryId,
                  'enforce': _enforce,
                  'start_date': DateTime.now().toIso8601String().split('T')[0],
                });
                if (success && mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Create Budget', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}
