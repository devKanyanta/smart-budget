import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Text('Join Smart Budget ZM',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Start managing your finances today',
                    style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 32),

                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outlined)),
                    validator: (v) => v != null && v.length >= 2 ? null : 'Name must be at least 2 characters',
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                    validator: (v) => v?.contains('@') == true ? null : 'Enter a valid email',
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number (optional)',
                      prefixIcon: Icon(Icons.phone_outlined),
                      prefixText: '+260 ',
                    ),
                  ),
                  const SizedBox(height: 16),

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
                    validator: (v) {
                      if (v == null || v.length < 8) return 'Password must be at least 8 characters';
                      if (!RegExp(r'[a-zA-Z]').hasMatch(v)) return 'Must contain at least one letter';
                      if (!RegExp(r'[0-9]').hasMatch(v)) return 'Must contain at least one number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Confirm Password', prefixIcon: Icon(Icons.lock_outlined)),
                    validator: (v) => v == _passwordController.text ? null : 'Passwords do not match',
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _handleRegister,
                      child: auth.isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Create Account'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Already have an account? Login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState?.validate() != true) return;

    final auth = context.read<AuthService>();
    final success = await auth.register(
      email: _emailController.text.trim(),
      fullName: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    if (success && mounted) {
      context.go('/');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration failed. Please try again.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
