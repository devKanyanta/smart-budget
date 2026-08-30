import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/budget_provider.dart';

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final budgetProvider = context.watch<BudgetProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Budgets')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBudgetDialog(context),
        child: const Icon(Icons.add),
      ),
      body: budgetProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => budgetProvider.fetchBudgets(),
              child: budgetProvider.budgets.isEmpty
                  ? const Center(child: Text('No budgets yet. Tap + to create one.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: budgetProvider.budgets.length,
                      itemBuilder: (context, index) {
                        final budget = budgetProvider.budgets[index];
                        return _buildBudgetCard(context, budget);
                      },
                    ),
            ),
    );
  }

  Widget _buildBudgetCard(BuildContext context, Map<String, dynamic> budget) {
    final category = budget['category'];
    final amount = double.tryParse(budget['amount'].toString()) ?? 0;
    final spent = double.tryParse(budget['spent_amount']?.toString() ?? '0') ?? 0;
    final remaining = double.tryParse(budget['remaining']?.toString() ?? '0') ?? 0;
    final percentage = (budget['percentage_used'] ?? 0).toDouble();
    final isOverBudget = percentage > 100;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (category != null) ...[
                      Icon(Icons.circle, color: Color(int.parse(category['color']?.replaceFirst('#', '0xFF') ?? '0xFFAEB6BF')), size: 12),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      category?['name'] ?? 'Overall Budget',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                Text(budget['period'] ?? 'monthly', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: (percentage / 100).clamp(0, 1),
              backgroundColor: Colors.grey[200],
              color: isOverBudget ? Colors.red : percentage > 80 ? Colors.orange : Colors.green,
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('K${spent.toStringAsFixed(0)} spent'),
                Text('K${amount.toStringAsFixed(0)} budget'),
              ],
            ),
            if (isOverBudget)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '⚠️ Over budget by K${(spent - amount).toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'K${remaining.toStringAsFixed(0)} remaining (${(100 - percentage).toStringAsFixed(0)}%)',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddBudgetDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24, right: 24, top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Create Budget', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Budget Amount (K)', prefixText: 'K '),
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: _period,
            decoration: const InputDecoration(labelText: 'Period'),
            items: const [
              DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
              DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
              DropdownMenuItem(value: 'quarterly', child: Text('Quarterly')),
              DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
            ],
            onChanged: (v) => setState(() => _period = v ?? 'monthly'),
          ),
          const SizedBox(height: 16),

          ElevatedButton(
            onPressed: () async {
              if (_amountController.text.isEmpty) return;
              final success = await context.read<BudgetProvider>().createBudget({
                'amount': double.parse(_amountController.text),
                'period': _period,
                'start_date': DateTime.now().toIso8601String().split('T')[0],
              });
              if (success && mounted) Navigator.pop(context);
            },
            child: const Text('Create Budget'),
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
