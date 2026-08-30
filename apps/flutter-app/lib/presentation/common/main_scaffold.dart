import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  static int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/transactions')) return 1;
    if (location.startsWith('/budgets')) return 2;
    if (location.startsWith('/savings')) return 3;
    if (location.startsWith('/analytics')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          switch (index) {
            case 0: context.go('/');
            case 1: context.go('/transactions');
            case 2: context.go('/budgets');
            case 3: context.go('/savings');
            case 4: context.go('/analytics');
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Transactions'),
          NavigationDestination(icon: Icon(Icons.pie_chart_outlined), selectedIcon: Icon(Icons.pie_chart), label: 'Budgets'),
          NavigationDestination(icon: Icon(Icons.savings_outlined), selectedIcon: Icon(Icons.savings), label: 'Savings'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Analytics'),
        ],
      ),
    );
  }
}
