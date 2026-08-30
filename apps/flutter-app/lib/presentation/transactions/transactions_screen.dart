import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/providers/transaction_provider.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _searchQuery = '';
  String? _selectedType;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().fetchTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTransactionDialog(context),
        child: const Icon(Icons.add),
      ),
      body: txProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => txProvider.fetchTransactions(),
              child: txProvider.transactions.isEmpty
                  ? const Center(child: Text('No transactions yet. Tap + to add one.'))
                  : ListView.builder(
                      itemCount: txProvider.transactions.length,
                      itemBuilder: (context, index) {
                        final tx = txProvider.transactions[index];
                        return _buildTransactionTile(tx);
                      },
                    ),
            ),
    );
  }

  Widget _buildTransactionTile(Map<String, dynamic> tx) {
    final category = tx['category'];
    final isIncome = tx['type'] == 'income';
    final amount = double.tryParse(tx['amount'].toString()) ?? 0;
    final date = DateTime.tryParse(tx['transaction_date'] ?? '');

    return Dismissible(
      key: Key(tx['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Transaction?'),
            content: const Text('This action cannot be undone.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
            ],
          ),
        );
      },
      onDismissed: (_) {
        context.read<TransactionProvider>().deleteTransaction(tx['id']);
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isIncome ? Colors.green[50] : Colors.red[50],
            child: Icon(
              isIncome ? Icons.arrow_upward : Icons.arrow_downward,
              color: isIncome ? Colors.green : Colors.red,
              size: 18,
            ),
          ),
          title: Text(tx['description'] ?? 'Transaction', maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            '${category?['name'] ?? "Uncategorized"} • ${date != null ? DateFormat('dd MMM yyyy').format(date) : ''}',
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? '+' : '-'}K${amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isIncome ? Colors.green : Colors.red,
                ),
              ),
              if (tx['source'] != null)
                Text(tx['source'], style: TextStyle(fontSize: 10, color: Colors.grey[500])),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddTransactionDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const AddTransactionSheet(),
    );
  }
}

class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _type = 'expense';
  DateTime _date = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24, right: 24, top: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Add Transaction', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Type selector
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'expense', label: Text('Expense'), icon: Icon(Icons.arrow_downward)),
                ButtonSegment(value: 'income', label: Text('Income'), icon: Icon(Icons.arrow_upward)),
                ButtonSegment(value: 'transfer', label: Text('Transfer'), icon: Icon(Icons.swap_horiz)),
              ],
              selected: {_type},
              onSelectionChanged: (v) => setState(() => _type = v.first),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount (K)', prefixText: 'K '),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Amount is required';
                if (double.tryParse(v) == null || double.parse(v) <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              validator: (v) => v?.isNotEmpty == true ? null : 'Description is required',
            ),
            const SizedBox(height: 16),

            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              subtitle: Text(_date.toString().split(' ')[0]),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _handleSubmit,
              child: const Text('Save Transaction'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState?.validate() != true) return;

    final success = await context.read<TransactionProvider>().createTransaction({
      'amount': double.parse(_amountController.text),
      'type': _type,
      'description': _descriptionController.text.trim(),
      'transaction_date': _date.toIso8601String(),
      'source': 'manual',
    });

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction added'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
