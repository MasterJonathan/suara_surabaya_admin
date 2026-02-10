import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suara_surabaya_admin/core/navigation/app_routes.dart';
import 'package:suara_surabaya_admin/core/theme/app_colors.dart';
import 'package:suara_surabaya_admin/providers/auth/authentication_provider.dart';
import 'package:suara_surabaya_admin/widgets/common/custom_card.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;

  // Login Email Biasa
  Future<void> _login(BuildContext context, AuthenticationProvider authProvider) async {
    if (_formKey.currentState!.validate()) {
      setState(() { _errorMessage = null; });
      final String? error = await authProvider.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (error != null && mounted) {
        setState(() { _errorMessage = error; });
      }
    }
  }

  // Login Google
  Future<void> _loginGoogle(BuildContext context, AuthenticationProvider authProvider) async {
    setState(() { _errorMessage = null; });
    final String? error = await authProvider.signInWithGoogle();
    if (error != null && mounted) {
      setState(() { _errorMessage = error; });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthenticationProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          backgroundColor: AppColors.surface,
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: CustomCard(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.admin_panel_settings, size: 60, color: AppColors.primary),
                      const SizedBox(height: 16),
                      Text('Admin Panel Login', style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 24),
                      
                      // --- FORM EMAIL ---
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) => (value == null || !value.contains('@')) ? 'Email tidak valid' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline_rounded)),
                        obscureText: true,
                        validator: (value) => (value == null || value.isEmpty) ? 'Password wajib diisi' : null,
                        onFieldSubmitted: (_) => _login(context, authProvider),
                      ),
                      
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 14)),
                        ),
                      
                      const SizedBox(height: 24),
                      
                      // --- TOMBOL LOGIN (EMAIL) ---
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: authProvider.status == AuthStatus.Authenticating ? null : () => _login(context, authProvider),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: authProvider.status == AuthStatus.Authenticating
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Login'),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // --- PEMBATAS / DIVIDER ---
                      const Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey)),
                          Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text("OR", style: TextStyle(color: Colors.grey))),
                          Expanded(child: Divider(color: Colors.grey)),
                        ],
                      ),
                      
                      const SizedBox(height: 20),

                      // --- TOMBOL GOOGLE SIGN IN (HYBRID) ---
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.g_mobiledata, size: 30, color: Colors.red),
                          label: const Text("Sign in with Google", style: TextStyle(color: Colors.black87, fontSize: 16)),
                          onPressed: authProvider.status == AuthStatus.Authenticating 
                              ? null 
                              : () => _loginGoogle(context, authProvider),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.grey),
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      
                      // --- LINK KE REGISTER ---
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed(AppRoutes.register);
                        },
                        child: const Text('Belum punya akun? Register Admin Baru'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}