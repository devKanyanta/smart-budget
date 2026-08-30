import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../presentation/auth/login_screen.dart';
import '../presentation/auth/register_screen.dart';
import '../presentation/dashboard/dashboard_screen.dart';
import '../presentation/transactions/transactions_screen.dart';
import '../presentation/budgets/budgets_screen.dart';
import '../presentation/savings/savings_screen.dart';
import '../presentation/analytics/analytics_screen.dart';
import '../presentation/settings/settings_screen.dart';
import '../presentation/common/main_scaffold.dart';

class SmartBudgetApp extends StatelessWidget {
  const SmartBudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Smart Budget ZM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32), // Zambian green
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.interTextTheme(),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      routerConfig: _router,
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
    ShellRoute(
      builder: (context, state, child) => MainScaffold(child: child),
      routes: [
        GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
        GoRoute(path: '/transactions', builder: (context, state) => const TransactionsScreen()),
        GoRoute(path: '/budgets', builder: (context, state) => const BudgetsScreen()),
        GoRoute(path: '/savings', builder: (context, state) => const SavingsScreen()),
        GoRoute(path: '/analytics', builder: (context, state) => const AnalyticsScreen()),
        GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
      ],
    ),
  ],
);
