// lib/screens/dashboard/change_password_page.dart

import 'package:suara_surabaya_admin/core/theme/app_colors.dart';
import 'package:suara_surabaya_admin/providers/auth/authentication_provider.dart';
import 'package:suara_surabaya_admin/widgets/common/custom_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Pastikan form valid sebelum melanjutkan
    if (_formKey.currentState!.validate()) {
      // Tampilkan loading indicator di tombol
      setState(() => _isLoading = true);

      final authProvider = context.read<AuthenticationProvider>();
      final error = await authProvider.changePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );

      // Pastikan widget masih ada di tree sebelum menampilkan SnackBar
      if (mounted) {
        if (error == null) {
          // --- KASUS BERHASIL ---
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password berhasil diubah!'),
              backgroundColor: AppColors.success, // Gunakan warna sukses
              behavior:
                  SnackBarBehavior
                      .floating, // Opsional: agar terlihat lebih bagus di desktop
              margin: EdgeInsets.all(10),
            ),
          );
          // Kosongkan semua field setelah berhasil
          _formKey.currentState?.reset();
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        } else {
          // --- KASUS GAGAL ---
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error), // Tampilkan pesan error dari provider
              backgroundColor: AppColors.error, // Gunakan warna error
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(10),
            ),
          );
        }

        // Hentikan loading indicator
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600), // Batasi lebar form
          child: CustomCard(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ganti Password',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(
                    label: 'Password Lama',
                    controller: _currentPasswordController,
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password lama tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    label: 'Password Baru (Min 6 Karakter)',
                    controller: _newPasswordController,
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return 'Password baru minimal 6 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    label: 'Konfirmasi Password Baru',
                    controller: _confirmPasswordController,
                    isPassword: true,
                    validator: (value) {
                      if (value != _newPasswordController.text) {
                        return 'Konfirmasi password tidak cocok';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Text('Submit'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget untuk membuat form field
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.foreground,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          validator: validator,
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}
