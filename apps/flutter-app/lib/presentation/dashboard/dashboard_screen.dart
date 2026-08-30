import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/dashboard_provider.dart';
import '../../core/providers/transaction_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();
    final data = dashboard.dashboardData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Budget ZM'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: dashboard.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => dashboard.fetchDashboard(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Monthly Summary Cards
                  if (data != null) ...[
                    _buildSummaryRow(context, data),
                    const SizedBox(height: 16),
                    _buildBudgetProgress(context, data),
                    const SizedBox(height: 16),
                    _buildSavingsProgress(context, data),
                    const SizedBox(height: 16),
                  ],

                  // Recent Transactions
                  _buildSectionTitle(context, 'Recent Transactions'),
                  const SizedBox(height: 8),
                  if (data?['recent_transactions'] != null)
                    ...(data!['recent_transactions'] as List).map(
                      (t) => _buildTransactionTile(t),
                    ),
                  const SizedBox(height: 16),

                  // Financial Insights
                  _buildSectionTitle(context, 'Financial Insights'),
                  const SizedBox(height: 8),
                  if (dashboard.insights.isNotEmpty)
                    ...dashboard.insights.take(3).map(
                      (insight) => _buildInsightCard(insight),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, Map<String, dynamic> data) {
    final summary = data['monthly_summary'] ?? {};
    return Row(
      children: [
        Expanded(child: _buildSummaryCard(
          'Income', 'K${(summary['income'] ?? 0).toStringAsFixed(2)}',
          Icons.arrow_upward, Colors.green,
        )),
        const SizedBox(width: 8),
        Expanded(child: _buildSummaryCard(
          'Expenses', 'K${(summary['expenses'] ?? 0).toStringAsFixed(2)}',
          Icons.arrow_downward, Colors.red,
        )),
        const SizedBox(width: 8),
        Expanded(child: _buildSummaryCard(
          'Net', 'K${(summary['net'] ?? 0).toStringAsFixed(2)}',
          Icons.account_balance_wallet, Colors.blue,
        )),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String amount, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 2),
            Text(amount, style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold, color: color,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetProgress(BuildContext context, Map<String, dynamic> data) {
    final budgets = data['budgets'] ?? {};
    final totalBudget = (budgets['total_budget'] ?? 0).toDouble();
    final totalSpent = (budgets['total_spent'] ?? 0).toDouble();
    final progress = totalBudget > 0 ? totalSpent / totalBudget : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Monthly Budget', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress.clamp(0, 1),
              backgroundColor: Colors.grey[200],
              color: progress > 0.9 ? Colors.red : progress > 0.7 ? Colors.orange : Colors.green,
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('K${totalSpent.toStringAsFixed(0)} spent'),
                Text('K${totalBudget.toStringAsFixed(0)} budget'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavingsProgress(BuildContext context, Map<String, dynamic> data) {
    final savings = data['savings'] ?? {};
    final target = (savings['total_target'] ?? 0).toDouble();
    final saved = (savings['total_saved'] ?? 0).toDouble();
    final progress = target > 0 ? saved / target : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Savings Goals', style: TextStyle(fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => context.go('/savings'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (target > 0) ...[
              LinearProgressIndicator(
                value: progress.clamp(0, 1),
                backgroundColor: Colors.grey[200],
                color: Colors.blue,
                minHeight: 8,
              ),
              const SizedBox(height: 8),
              Text('K${saved.toStringAsFixed(0)} saved of K${target.toStringAsFixed(0)} target'),
            ] else
              const Text('No active savings goals. Tap "Savings" to create one.'),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold));
  }

  Widget _buildTransactionTile(Map<String, dynamic> transaction) {
    final category = transaction['category'];
    final isIncome = transaction['type'] == 'income';
    final amount = double.tryParse(transaction['amount'].toString()) ?? 0;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isIncome ? Colors.green[50] : Colors.red[50],
          child: Icon(
            isIncome ? Icons.arrow_upward : Icons.arrow_downward,
            color: isIncome ? Colors.green : Colors.red,
            size: 18,
          ),
        ),
        title: Text(transaction['description'] ?? 'Transaction', maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(category?['name'] ?? 'Uncategorized'),
        trailing: Text(
          '${isIncome ? '+' : '-'}K${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isIncome ? Colors.green : Colors.red,
          ),
        ),
      ),
    );
  }

  Widget _buildInsightCard(Map<String, dynamic> insight) {
    final priority = insight['priority'];
    final color = priority == 'high' ? Colors.orange : priority == 'medium' ? Colors.blue : Colors.grey;

    return Card(
      child: ListTile(
        leading: Icon(Icons.lightbulb_outline, color: color),
        title: Text(insight['title'] ?? '', style: const TextStyle(fontSize: 14)),
        subtitle: Text(insight['body'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}
