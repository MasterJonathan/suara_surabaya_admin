import 'package:suara_surabaya_admin/core/navigation/navigation_service.dart';
import 'package:suara_surabaya_admin/core/theme/app_colors.dart';
import 'package:suara_surabaya_admin/models/dashboard/user_management/user_model.dart';
import 'package:suara_surabaya_admin/providers/dashboard/user_management/user_provider.dart';
import 'package:suara_surabaya_admin/screens/dashboard/user_activity_page.dart';
import 'package:suara_surabaya_admin/widgets/common/custom_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class UsersAdminPage extends StatefulWidget {
  const UsersAdminPage({super.key});

  @override
  State<UsersAdminPage> createState() => _UsersAdminPageState();
}

class _UsersAdminPageState extends State<UsersAdminPage> {
  final TextEditingController _searchController = TextEditingController();
  final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd HH:mm');
  String _entriesToShow = '10'; // <-- TAMBAHKAN BARIS INI

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditDialog({UserModel? user}) {
    final isEditing = user != null;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: user?.nama);
    final emailController = TextEditingController(text: user?.email);
    Map<String, String> tempHakAkses = Map<String, String>.from(
      user?.hakAkses ?? {},
    );
    String selectedRole = user?.role ?? 'User';
    final List<String> allFeatures =
        DashboardPage.values.map((page) {
          return page.toString().split('.').last;
        }).toList();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit User' : 'Tambah User'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Nama'),
                        validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                        enabled: !isEditing,
                        validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        decoration: const InputDecoration(labelText: 'Role'),
                        items:
                            ['User', 'Admin', 'Editor', 'Moderator']
                                .map(
                                  (role) => DropdownMenuItem(
                                    value: role,
                                    child: Text(role),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            selectedRole = value;
                          }
                        },
                      ),
                      const Divider(height: 32),
                      const Text(
                        'Pengaturan Hak Akses',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      // Buat daftar dropdown untuk setiap fitur
                      Padding(
                        // Beri padding agar sejajar dengan ListTile
                        padding: const EdgeInsets.only(
                          right: 16.0,
                          left: 16.0,
                          bottom: 8.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Kita beri lebar tetap agar header sejajar dengan checkbox
                            SizedBox(
                              width: 64, // Sesuaikan lebar ini jika perlu
                              child: Center(
                                child: Text(
                                  'Read',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 64, // Samakan lebarnya
                              child: Center(
                                child: Text(
                                  'Write',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),

                      // --- Daftar Checkbox Fitur ---
                      ...allFeatures.map((feature) {
                        // 1. Tentukan status checkbox berdasarkan string hakAkses
                        final String currentPermission =
                            tempHakAkses[feature] ?? 'none';
                        final bool canRead =
                            (currentPermission == 'read' ||
                                currentPermission == 'write');
                        final bool canWrite = (currentPermission == 'write');

                        return ListTile(
                          title: Text(feature),
                          dense: true, // Membuat ListTile lebih ramping
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // --- Checkbox "Read" ---
                              SizedBox(
                                width: 64, // Samakan dengan lebar header
                                child: Checkbox(
                                  value: canRead,
                                  onChanged: (bool? newValue) {
                                    setDialogState(() {
                                      if (newValue == true) {
                                        // Jika 'Read' dicentang & sebelumnya 'none', ubah ke 'read'.
                                        if (currentPermission == 'none') {
                                          tempHakAkses[feature] = 'read';
                                        }
                                      } else {
                                        // newValue == false
                                        // Jika 'Read' tidak dicentang, semua akses hilang.
                                        tempHakAkses[feature] = 'none';
                                      }
                                    });
                                  },
                                ),
                              ),
                              // --- Checkbox "Write" ---
                              SizedBox(
                                width: 64, // Samakan dengan lebar header
                                child: Checkbox(
                                  value: canWrite,
                                  onChanged: (bool? newValue) {
                                    setDialogState(() {
                                      if (newValue == true) {
                                        // Jika 'Write' dicentang, otomatis 'Read' juga tercentang.
                                        tempHakAkses[feature] = 'write';
                                      } else {
                                        // newValue == false
                                        // Jika 'Write' tidak dicentang, kembali ke 'Read'.
                                        tempHakAkses[feature] = 'read';
                                      }
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final provider = context.read<UserProvider>();
                      if (isEditing) {
                        final Map<String, dynamic> updatedData = {
                          'nama': nameController.text,
                          'role': selectedRole,
                          'hakAkses': tempHakAkses,
                        };

                        await provider.updateUserPartial(user.id, updatedData);
                      } else {
                        print(
                          "Penambahan user baru seharusnya melalui halaman registrasi.",
                        );
                      }
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTableControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Text('Show'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.foreground.withValues(alpha: 0.2),
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _entriesToShow,
                  items:
                      <String>['10', '25', '50', '100', 'All'].map((
                        String value,
                      ) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _entriesToShow = newValue!;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text('entries'),
          ],
        ),
        SizedBox(
          width: 250,
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(labelText: 'Search'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, provider, child) {
        List<UserModel> filteredData;
        final query = _searchController.text.toLowerCase();

        if (query.isEmpty) {
          filteredData = provider.users;
        } else {
          filteredData =
              provider.users
                  .where(
                    (user) =>
                        user.nama.toLowerCase().contains(query) ||
                        user.email.toLowerCase().contains(query) ||
                        user.role.toLowerCase().contains(query),
                  )
                  .toList();
        }

        // <-- TAMBAHKAN LOGIKA PAGINASI DI SINI
        final int entriesCount =
            int.tryParse(_entriesToShow) ?? filteredData.length;
        final paginatedData = filteredData.take(entriesCount).toList();
        // -->

        return CustomCard(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTableControls(),
              const SizedBox(height: 20),
              if (provider.state == UserViewState.Busy)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (provider.errorMessage != null)
                Expanded(
                  child: Center(child: Text('Error: ${provider.errorMessage}')),
                )
              else
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SizedBox(
                      width: double.infinity,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Username')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Role')),
                          DataColumn(label: Text('Tanggal Bergabung')),
                          DataColumn(label: Text('Aksi')),
                        ],
                        rows:
                            paginatedData.map((user) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    InkWell(
                                      // Or GestureDetector
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder:
                                                (
                                                  context,
                                                ) => UserActivityPage(
                                                  kontributorId:
                                                      user.id, // Kirim ID kontributor
                                                ),
                                          ),
                                        );
                                        // Add your desired action here, e.g., navigate to another screen
                                      },
                                      child: Text(user.nama),
                                    ),
                                  ),

                                  DataCell(
                                    Chip(
                                      label: Text(
                                        user.status ? 'Active' : 'Inactive',
                                      ),
                                      backgroundColor:
                                          user.status
                                              ? AppColors.success.withValues(alpha: 0.1,
                                              )
                                              : AppColors.error.withValues(alpha: 0.1,
                                              ),
                                      labelStyle: TextStyle(
                                        color:
                                            user.status
                                                ? AppColors.success
                                                : AppColors.error,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Chip(
                                      label: Text(user.role),
                                      backgroundColor: AppColors.primary
                                          .withValues(alpha: 0.1),
                                      labelStyle: const TextStyle(
                                        color: AppColors.primary,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(_dateFormatter.format(user.joinDate)),
                                  ),
                                  DataCell(
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: AppColors.primary,
                                          ),
                                          tooltip: 'Edit User',
                                          onPressed:
                                              () => _showAddEditDialog(
                                                user: user,
                                              ),
                                        ),

                                        IconButton(
                                          icon: Icon(
                                            user.status
                                                ? Icons.block
                                                : Icons.power_settings_new,
                                            color:
                                                user.status
                                                    ? AppColors.error
                                                    : AppColors.success,
                                          ),
                                          tooltip:
                                              user.status
                                                  ? 'Nonaktifkan User'
                                                  : 'Aktifkan User',
                                          onPressed: () async {
                                            final newStatus = !user.status;
                                            await context
                                                .read<UserProvider>()
                                                .updateUserPartial(user.id, {
                                                  'status': newStatus,
                                                });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
