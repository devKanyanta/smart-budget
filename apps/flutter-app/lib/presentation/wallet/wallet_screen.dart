import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/providers/wallet_provider.dart';
import '../common/app_colors.dart';
import '../common/app_widgets.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().fetchTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header with balance
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
                            'Wallet',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            wallet.paymentMode == 'live'
                                ? 'Powered by Flutterwave'
                                : 'Payments powered by Flutterwave (sandbox)',
                            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => _showLimitsSheet(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Available Balance',
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'K${wallet.balance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showTopUpSheet(context),
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          label: const Text('Top Up'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showPaySheet(context),
                          icon: const Icon(Icons.send_rounded, size: 20),
                          label: const Text('Pay'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Spending limits summary
                  if (_hasLimits(wallet.wallet)) ...[
                    const SizedBox(height: 14),
                    _buildLimitsSummary(wallet.wallet!),
                  ],
                ],
              ),
            ),
          ),
          // Transactions
          Expanded(
            child: wallet.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : RefreshIndicator(
                    onRefresh: () async {
                      await wallet.fetchWallet();
                      await wallet.fetchTransactions();
                    },
                    color: AppColors.primary,
                    child: wallet.transactions.isEmpty
                        ? const EmptyState(
                            icon: Icons.account_balance_wallet_rounded,
                            title: 'No Wallet Activity',
                            subtitle: 'Top up your wallet using Airtel Money or MTN MoMo to get started',
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                            itemCount: wallet.transactions.length,
                            itemBuilder: (context, index) =>
                                _buildWalletTxTile(wallet.transactions[index]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  bool _hasLimits(Map<String, dynamic>? w) {
    if (w == null) return false;
    return double.tryParse(w['daily_limit']?.toString() ?? '') != null ||
        double.tryParse(w['monthly_limit']?.toString() ?? '') != null;
  }

  Widget _buildLimitsSummary(Map<String, dynamic> wallet) {
    final daily = double.tryParse(wallet['daily_limit']?.toString() ?? '');
    final monthly = double.tryParse(wallet['monthly_limit']?.toString() ?? '');
    final dailySpent = double.tryParse(wallet['daily_spent']?.toString() ?? '0') ?? 0;
    final monthlySpent = double.tryParse(wallet['monthly_spent']?.toString() ?? '0') ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (daily != null)
            Expanded(
              child: Text(
                'Daily: K${dailySpent.toStringAsFixed(0)} / K${daily.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          if (monthly != null)
            Expanded(
              child: Text(
                'Monthly: K${monthlySpent.toStringAsFixed(0)} / K${monthly.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWalletTxTile(Map<String, dynamic> tx) {
    final isTopUp = tx['type'] == 'topup';
    final amount = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0;
    final date = DateTime.tryParse(tx['created_at']?.toString() ?? '');
    final status = tx['status'] ?? 'completed';
    final failed = status == 'failed';

    return AppCard(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: failed
                  ? AppColors.expenseSolid
                  : isTopUp
                      ? AppColors.incomeSolid
                      : AppColors.blueSolid,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              failed
                  ? Icons.error_outline_rounded
                  : isTopUp
                      ? Icons.add_rounded
                      : Icons.send_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx['description'] ?? (isTopUp ? 'Wallet top-up' : 'Wallet payment'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  date != null ? DateFormat('dd MMM yyyy, HH:mm').format(date) : '',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isTopUp ? '+' : '-'}K${amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: failed
                      ? AppColors.expense
                      : isTopUp
                          ? AppColors.income
                          : AppColors.transfer,
                ),
              ),
              Text(
                failed ? 'Failed' : 'Completed',
                style: TextStyle(
                  fontSize: 10,
                  color: failed ? AppColors.expense : Colors.grey[400],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showTopUpSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TopUpSheet(),
    );
  }

  void _showPaySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PaySheet(),
    );
  }

  void _showLimitsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const LimitsSheet(),
    );
  }
}

class TopUpSheet extends StatefulWidget {
  const TopUpSheet({super.key});

  @override
  State<TopUpSheet> createState() => _TopUpSheetState();
}

class _TopUpSheetState extends State<TopUpSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  String _network = 'airtel_money';
  bool _submitting = false;

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
      child: Form(
        key: _formKey,
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
            const Text('Top Up Wallet',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              'Fund your wallet via mobile money',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              decoration: const InputDecoration(
                labelText: 'Amount (K)',
                prefixText: 'K ',
                prefixStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Amount is required';
                final n = double.tryParse(v);
                if (n == null || n <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Mobile Money Number',
                hintText: '+260971234567',
              ),
              validator: (v) =>
                  v == null || v.trim().length < 9 ? 'Enter a valid phone number' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildNetworkOption(
                      'airtel_money', 'Airtel Money', Icons.cell_tower_rounded, const Color(0xFFE40000)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNetworkOption(
                      'mtn_momo', 'MTN MoMo', Icons.signal_cellular_alt_rounded, const Color(0xFFFFCC00)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _submitting ? null : _handleSubmit,
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Top Up',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkOption(String value, String label, IconData icon, Color color) {
    final isSelected = _network == value;
    return GestureDetector(
      onTap: () => setState(() => _network = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isSelected ? color : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _submitting = true);

    final message = await context.read<WalletProvider>().topUp(
          amount: double.parse(_amountController.text),
          phoneNumber: _phoneController.text.trim(),
          network: _network,
        );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (message != null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}

class PaySheet extends StatefulWidget {
  const PaySheet({super.key});

  @override
  State<PaySheet> createState() => _PaySheetState();
}

class _PaySheetState extends State<PaySheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _submitting = false;

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
      child: Form(
        key: _formKey,
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
            const Text('Pay from Wallet',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              decoration: const InputDecoration(
                labelText: 'Amount (K)',
                prefixText: 'K ',
                prefixStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Amount is required';
                final n = double.tryParse(v);
                if (n == null || n <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'e.g. Lunch, airtime, fare',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _submitting ? null : _handleSubmit,
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Pay Now',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _submitting = true);

    final error = await context.read<WalletProvider>().pay(
          amount: double.parse(_amountController.text),
          description:
              _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (error == null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Payment successful'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      // Spending limit or insufficient funds — show the control message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.expense,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
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

class LimitsSheet extends StatefulWidget {
  const LimitsSheet({super.key});

  @override
  State<LimitsSheet> createState() => _LimitsSheetState();
}

class _LimitsSheetState extends State<LimitsSheet> {
  late final TextEditingController _dailyController;
  late final TextEditingController _monthlyController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final wallet = context.read<WalletProvider>().wallet;
    final daily = double.tryParse(wallet?['daily_limit']?.toString() ?? '');
    final monthly = double.tryParse(wallet?['monthly_limit']?.toString() ?? '');
    _dailyController = TextEditingController(text: daily?.toStringAsFixed(0) ?? '');
    _monthlyController = TextEditingController(text: monthly?.toStringAsFixed(0) ?? '');
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
          const Text('Spending Limits',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            'Set controls to keep your spending in check',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _dailyController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Daily Limit (K, optional)',
              prefixText: 'K ',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _monthlyController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Monthly Limit (K, optional)',
              prefixText: 'K ',
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _handleSubmit,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Save Limits',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    setState(() => _saving = true);
    final provider = context.read<WalletProvider>();

    final daily = double.tryParse(_dailyController.text);
    final monthly = double.tryParse(_monthlyController.text);

    final ok = await provider.updateLimits(dailyLimit: daily, monthlyLimit: monthly);

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Spending limits updated'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _dailyController.dispose();
    _monthlyController.dispose();
    super.dispose();
  }
}
