import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/savings_provider.dart';

class SavingsScreen extends StatelessWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final savingsProvider = context.watch<SavingsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Savings Goals')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddGoalDialog(context),
        child: const Icon(Icons.add),
      ),
      body: savingsProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => savingsProvider.fetchGoals(),
              child: savingsProvider.goals.isEmpty
                  ? const Center(child: Text('No savings goals yet. Tap + to create one.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: savingsProvider.goals.length,
                      itemBuilder: (context, index) {
                        final goal = savingsProvider.goals[index];
                        return _buildGoalCard(context, goal);
                      },
                    ),
            ),
    );
  }

  Widget _buildGoalCard(BuildContext context, Map<String, dynamic> goal) {
    final targetAmount = double.tryParse(goal['target_amount'].toString()) ?? 0;
    final currentAmount = double.tryParse(goal['current_amount'].toString()) ?? 0;
    final progress = goal['progress_percentage'] ?? 0.0;
    final status = goal['status'] ?? 'active';

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
                Text(goal['name'] ?? 'Goal', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Chip(
                  label: Text(status, style: const TextStyle(fontSize: 12)),
                  backgroundColor: status == 'completed' ? Colors.green[100] : Colors.blue[100],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress circle
            Row(
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: (progress / 100).clamp(0, 1),
                        strokeWidth: 8,
                        backgroundColor: Colors.grey[200],
                        color: progress >= 100 ? Colors.green : Colors.blue,
                      ),
                      Center(
                        child: Text(
                          '${progress.toStringAsFixed(0)}%',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatRow('Saved', 'K${currentAmount.toStringAsFixed(0)}'),
                      _buildStatRow('Target', 'K${targetAmount.toStringAsFixed(0)}'),
                      _buildStatRow('Remaining', 'K${(targetAmount - currentAmount).toStringAsFixed(0)}'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showAddEntryDialog(context, goal),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Savings'),
                ),
                TextButton.icon(
                  onPressed: () => _showPrediction(context, goal),
                  icon: const Icon(Icons.insights, size: 18),
                  label: const Text('Predict'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  void _showAddGoalDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const AddGoalSheet(),
    );
  }

  void _showAddEntryDialog(BuildContext context, Map<String, dynamic> goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddEntrySheet(goalId: goal['id']),
    );
  }

  void _showPrediction(BuildContext context, Map<String, dynamic> goal) async {
    final prediction = await context.read<SavingsProvider>().getPrediction(goal['id']);
    if (context.mounted && prediction != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Savings Prediction'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (prediction['prediction_available'] == true) ...[
                Text('Monthly Savings: K${prediction['predicted_monthly_savings']?.toStringAsFixed(2) ?? '0'}'),
                Text('Months Remaining: ${prediction['months_remaining'] ?? 'N/A'}'),
                Text('Confidence: ${prediction['confidence'] ?? 'N/A'}'),
                const SizedBox(height: 8),
                Text(prediction['message'] ?? '', style: const TextStyle(fontSize: 13)),
              ] else
                Text(prediction['message'] ?? 'No prediction available'),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
    }
  }
}

class AddGoalSheet extends StatefulWidget {
  const AddGoalSheet({super.key});

  @override
  State<AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends State<AddGoalSheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  String _frequency = 'monthly';
  DateTime _targetDate = DateTime.now().add(const Duration(days: 180));

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
          const Text('Create Savings Goal', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Goal Name')),
          const SizedBox(height: 16),
          TextFormField(controller: _amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Target Amount (K)', prefixText: 'K ')),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _frequency,
            decoration: const InputDecoration(labelText: 'Savings Frequency'),
            items: const [
              DropdownMenuItem(value: 'daily', child: Text('Daily')),
              DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
              DropdownMenuItem(value: 'biweekly', child: Text('Biweekly')),
              DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
            ],
            onChanged: (v) => setState(() => _frequency = v ?? 'monthly'),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Target Date'),
            subtitle: Text(_targetDate.toString().split(' ')[0]),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final picked = await showDatePicker(context: context, initialDate: _targetDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 3650)));
              if (picked != null) setState(() => _targetDate = picked);
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              if (_nameController.text.isEmpty || _amountController.text.isEmpty) return;
              final success = await context.read<SavingsProvider>().createGoal({
                'name': _nameController.text.trim(),
                'target_amount': double.parse(_amountController.text),
                'target_date': _targetDate.toIso8601String().split('T')[0],
                'frequency': _frequency,
              });
              if (success && mounted) Navigator.pop(context);
            },
            child: const Text('Create Goal'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}

class AddEntrySheet extends StatefulWidget {
  final String goalId;
  const AddEntrySheet({super.key, required this.goalId});

  @override
  State<AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends State<AddEntrySheet> {
  final _amountController = TextEditingController();

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
          const Text('Add Savings Entry', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Amount (K)', prefixText: 'K '),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              if (_amountController.text.isEmpty) return;
              final success = await context.read<SavingsProvider>().addEntry(widget.goalId, {
                'amount': double.parse(_amountController.text),
                'entry_date': DateTime.now().toIso8601String().split('T')[0],
              });
              if (success && mounted) Navigator.pop(context);
            },
            child: const Text('Add Entry'),
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
