import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  Map<String, dynamic>? _categoryBreakdown;
  List<Map<String, dynamic>> _monthlyComparison = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthService>();
    if (!auth.isAuthenticated) return;

    try {
      final breakdown = await auth.api.getCategoryBreakdown();
      final comparison = await auth.api.getMonthlyComparison(months: 6);
      setState(() {
        _categoryBreakdown = breakdown['data'];
        _monthlyComparison = List<Map<String, dynamic>>.from(comparison['data']);
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSectionTitle('Spending by Category'),
                  const SizedBox(height: 8),
                  _buildCategoryPieChart(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Monthly Comparison'),
                  const SizedBox(height: 8),
                  _buildMonthlyBarChart(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold));
  }

  Widget _buildCategoryPieChart() {
    final categories = _categoryBreakdown?['categories'] as List? ?? [];
    if (categories.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No spending data available'))));
    }

    final colors = [
      Colors.orange, Colors.teal, Colors.blue, Colors.purple,
      Colors.amber, Colors.pink, Colors.indigo, Colors.green,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: categories.asMap().entries.map((entry) {
                    final i = entry.key;
                    final cat = entry.value;
                    return PieChartSectionData(
                      value: cat['percentage']?.toDouble() ?? 0,
                      title: '${(cat['percentage'] ?? 0).toStringAsFixed(0)}%',
                      color: colors[i % colors.length],
                      radius: 80,
                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: categories.asMap().entries.map((entry) {
                final i = entry.key;
                final cat = entry.value;
                final name = cat['category']?['name'] ?? 'Other';
                final total = cat['total'] ?? 0;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 12, height: 12, color: colors[i % colors.length]),
                    const SizedBox(width: 4),
                    Text('$name: K$total', style: const TextStyle(fontSize: 12)),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyBarChart() {
    if (_monthlyComparison.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No comparison data'))));
    }

    final maxY = _monthlyComparison.fold<double>(0, (max, m) {
      final income = (m['income'] ?? 0).toDouble();
      final expenses = (m['expenses'] ?? 0).toDouble();
      return income > max ? income : (expenses > max ? expenses : max);
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY * 1.2,
              barGroups: _monthlyComparison.asMap().entries.map((entry) {
                final i = entry.key;
                final m = entry.value;
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(toY: (m['income'] ?? 0).toDouble(), color: Colors.green, width: 12),
                    BarChartRodData(toY: (m['expenses'] ?? 0).toDouble(), color: Colors.red, width: 12),
                  ],
                );
              }).toList(),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < _monthlyComparison.length) {
                        return Text(_monthlyComparison[i]['month']?.toString().substring(5) ?? '', style: const TextStyle(fontSize: 10));
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: false),
            ),
          ),
        ),
      ),
    );
  }
}
