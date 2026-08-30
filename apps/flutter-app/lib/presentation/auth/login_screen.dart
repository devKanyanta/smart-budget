import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    if (auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/'));
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 16),
                  Text('Smart Budget ZM',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Manage your finances wisely',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                  const SizedBox(height: 40),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (v) => v?.contains('@') == true ? null : 'Enter a valid email',
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) => v?.isNotEmpty == true ? null : 'Password is required',
                  ),
                  const SizedBox(height: 24),

                  // Login button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _handleLogin,
                      child: auth.isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Login'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Register link
                  TextButton(
                    onPressed: () => context.go('/register'),
                    child: const Text("Don't have an account? Register"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState?.validate() != true) return;

    final auth = context.read<AuthService>();
    final success = await auth.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      context.go('/');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid email or password'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
