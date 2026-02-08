// lib/screens/dashboard/profile_page.dart

import 'package:suara_surabaya_admin/core/theme/app_colors.dart';
import 'package:suara_surabaya_admin/models/dashboard/user_management/user_model.dart';
import 'package:suara_surabaya_admin/providers/auth/authentication_provider.dart';
import 'package:suara_surabaya_admin/providers/dashboard/user_management/user_provider.dart';
import 'package:suara_surabaya_admin/widgets/common/custom_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _usernameController;
  late TextEditingController _alamatController;
  late TextEditingController _nomorHpController;
  late TextEditingController _tanggalLahirController;

  String? _selectedJenisKelamin;

  final List<String> _genderOptions = ['Laki-laki', 'Perempuan'];

  bool _isEditingInfo = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _usernameController = TextEditingController();
    _alamatController = TextEditingController();
    _nomorHpController = TextEditingController();
    _tanggalLahirController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _populateControllers();
  }

  void _populateControllers() {
    final authProvider = Provider.of<AuthenticationProvider>(context, listen: false);
    final user = authProvider.user;
    if (user != null) {
      _nameController.text = user.nama;
      _emailController.text = user.email;
      _usernameController.text = user.username;
      _alamatController.text = user.alamat ?? '';
      _nomorHpController.text = user.nomorHp ?? '';
      _tanggalLahirController.text = user.tanggalLahir ?? '';

      if (_genderOptions.contains(user.jenisKelamin)) {
        _selectedJenisKelamin = user.jenisKelamin;
      } else {
        _selectedJenisKelamin = null;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _alamatController.dispose();
    _nomorHpController.dispose();
    _tanggalLahirController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    if (!_isEditingInfo) return;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _tanggalLahirController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _saveProfileInfo() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final userProvider = context.read<UserProvider>();
      final authProvider = context.read<AuthenticationProvider>();

      if (authProvider.user != null) {
        final updatedUser = UserModel(
          id: authProvider.user!.id,
          nama: _nameController.text,
          username: _usernameController.text,
          alamat: _alamatController.text,
          nomorHp: _nomorHpController.text,
          tanggalLahir: _tanggalLahirController.text,
          jenisKelamin: _selectedJenisKelamin,
          email: authProvider.user!.email,
          role: authProvider.user!.role,
          hakAkses: authProvider.user!.hakAkses,
          status: authProvider.user!.status,
          joinDate: authProvider.user!.joinDate,
          photoURL: authProvider.user!.photoURL,
          jumlahComment: authProvider.user!.jumlahComment,
          jumlahKontributor: authProvider.user!.jumlahKontributor,
          jumlahLike: authProvider.user!.jumlahLike,
          jumlahShare: authProvider.user!.jumlahShare,
          aktivitas: authProvider.user!.aktivitas,
        );

        // bool success = await userProvider.updateUser(updatedUser);

        // if (mounted) {
        //   ScaffoldMessenger.of(context).showSnackBar(
        //     SnackBar(
        //       content: Text(success ? 'Profil berhasil diperbarui!' : 'Gagal memperbarui profil.'),
        //       backgroundColor: success ? AppColors.success : AppColors.error,
        //       behavior: SnackBarBehavior.floating,
        //     ),
        //   );
        //   if (success) {
        //     setState(() => _isEditingInfo = false);
        //   }
        // }
      }
    }
  }

  // --- Helper Decoration untuk Input Field Modern ---
  InputDecoration _modernInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.primary.withOpacity(0.7), size: 20),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade100),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthenticationProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;

        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          key: const PageStorageKey('profilePage'),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          children: [
            CustomCard(
              padding: const EdgeInsets.all(30),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- HEADER SECTION ---
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary.withOpacity(0.1), width: 4),
                          ),
                          child: CircleAvatar(
                            radius: 45,
                            backgroundColor: AppColors.primary,
                            backgroundImage: user.photoURL != null && user.photoURL!.isNotEmpty
                                ? NetworkImage(user.photoURL!)
                                : null,
                            child: (user.photoURL == null || user.photoURL!.isEmpty)
                                ? Text(
                                    user.nama.isNotEmpty ? user.nama[0].toUpperCase() : 'A',
                                    style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.nama, 
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.email, 
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  user.role.toUpperCase(),
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!_isEditingInfo)
                          IconButton(
                            onPressed: () => setState(() => _isEditingInfo = true),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.grey.shade100,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                            tooltip: 'Edit Profile',
                          )
                      ],
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // --- PERSONAL INFO SECTION ---
                    Row(
                      children: [
                        Icon(Icons.person_outline, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Text(
                          'Personal Information', 
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _nameController,
                            decoration: _modernInputDecoration('Nama Lengkap', Icons.person),
                            enabled: _isEditingInfo,
                            validator: (value) => value!.isEmpty ? 'Nama tidak boleh kosong' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _usernameController,
                            decoration: _modernInputDecoration('Username', Icons.alternate_email),
                            enabled: _isEditingInfo,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _emailController,
                            decoration: _modernInputDecoration('Email Address', Icons.email),
                            enabled: false, // Email biasanya read-only
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _nomorHpController,
                            decoration: _modernInputDecoration('Nomor HP', Icons.phone_android),
                            enabled: _isEditingInfo,
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedJenisKelamin,
                            decoration: _modernInputDecoration('Jenis Kelamin', Icons.people_outline),
                            icon: const Icon(Icons.keyboard_arrow_down),
                            items: _genderOptions.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: _isEditingInfo ? (newValue) => setState(() => _selectedJenisKelamin = newValue) : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context),
                            borderRadius: BorderRadius.circular(12),
                            child: IgnorePointer(
                              child: TextFormField(
                                controller: _tanggalLahirController,
                                decoration: _modernInputDecoration('Tanggal Lahir', Icons.calendar_today),
                                enabled: _isEditingInfo,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _alamatController,
                      decoration: _modernInputDecoration('Alamat', Icons.location_on_outlined),
                      enabled: _isEditingInfo,
                      maxLines: 3,
                    ),
                    
                    const SizedBox(height: 40),

                    // --- STATISTICS SECTION ---
                    Row(
                      children: [
                        Icon(Icons.bar_chart_rounded, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Text(
                          'User Statistics', 
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade100,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          _buildStatCard('Comments', user.jumlahComment.toString(), Icons.chat_bubble_outline),
                          Container(width: 1, height: 40, color: Colors.grey.shade200, margin: const EdgeInsets.symmetric(horizontal: 8)),
                          _buildStatCard('Likes', user.jumlahLike.toString(), Icons.thumb_up_alt_outlined),
                          Container(width: 1, height: 40, color: Colors.grey.shade200, margin: const EdgeInsets.symmetric(horizontal: 8)),
                          _buildStatCard('Shares', user.jumlahShare.toString(), Icons.share_outlined),
                          Container(width: 1, height: 40, color: Colors.grey.shade200, margin: const EdgeInsets.symmetric(horizontal: 8)),
                          _buildStatCard('Contrib.', user.jumlahKontributor.toString(), Icons.article_outlined),
                        ],
                      ),
                    ),

                    // --- BUTTONS ---
                    if (_isEditingInfo) ...[
                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isEditingInfo = false;
                                _populateControllers();
                              });
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey.shade600,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            ),
                            child: const Text('Batal'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _saveProfileInfo,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shadowColor: AppColors.primary.withOpacity(0.3),
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.save_outlined, size: 20),
                            label: const Text('Simpan Perubahan', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            value, 
            style: const TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.w800,
              color: Colors.black87
            )
          ),
          const SizedBox(height: 4),
          Text(
            title, 
            style: TextStyle(
              fontSize: 12, 
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}