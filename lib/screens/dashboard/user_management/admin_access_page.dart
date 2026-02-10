import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suara_surabaya_admin/core/navigation/navigation_service.dart';
import 'package:suara_surabaya_admin/core/theme/app_colors.dart';
import 'package:suara_surabaya_admin/models/dashboard/user_management/user_model.dart';
import 'package:suara_surabaya_admin/providers/dashboard/user_management/admin_provider.dart';
import 'package:suara_surabaya_admin/widgets/common/custom_card.dart';

class AdminAccessPage extends StatefulWidget {
  const AdminAccessPage({super.key});

  @override
  State<AdminAccessPage> createState() => _AdminAccessPageState();
}

class _AdminAccessPageState extends State<AdminAccessPage> {
  // Daftar modul yang bisa diatur hak aksesnya
  final List<String> _modules = DashboardPage.values.map((page) => page.name).toList();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadAdmins(refresh: true);
    });
  }

  void _showFeedback(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --- DIALOG PROMOTE USER ---
  void _showPromoteDialog() {
    final emailController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Angkat Admin Baru'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Masukkan email user yang sudah terdaftar untuk dijadikan Admin."),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email User',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                if (isLoading) const Padding(
                  padding: EdgeInsets.only(top: 16.0),
                  child: LinearProgressIndicator(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(context), 
                child: const Text('Batal')
              ),
              ElevatedButton(
                onPressed: isLoading ? null : () async {
                  if (emailController.text.isEmpty) return;
                  
                  setStateDialog(() => isLoading = true);
                  final provider = context.read<AdminProvider>();
                  final errorMsg = await provider.promoteUserToAdmin(emailController.text.trim());
                  
                  if (mounted) {
                    Navigator.pop(context);
                    if (errorMsg == null) {
                      _showFeedback("User berhasil diangkat menjadi Admin");
                    } else {
                      _showFeedback(errorMsg, isError: true);
                    }
                  }
                },
                child: const Text('Promote'),
              ),
            ],
          );
        });
      },
    );
  }

  // --- DIALOG EDIT HAK AKSES ---
  void _showPermissionsDialog(UserModel admin) {
    // Copy existing permissions
    Map<String, String> tempPermissions = Map.from(admin.hakAkses);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text('Hak Akses: ${admin.nama}'),
            content: SizedBox(
              width: 500,
              height: 400,
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    color: Colors.grey[100],
                    child: const Row(
                      children: [
                        Expanded(flex: 2, child: Padding(padding: EdgeInsets.only(left: 8), child: Text("Modul", style: TextStyle(fontWeight: FontWeight.bold)))),
                        Expanded(child: Center(child: Text("Read", style: TextStyle(fontWeight: FontWeight.bold)))),
                        Expanded(child: Center(child: Text("Write", style: TextStyle(fontWeight: FontWeight.bold)))),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  
                  // List Modul
                  Expanded(
                    child: ListView.separated(
                      itemCount: _modules.length,
                      separatorBuilder: (c, i) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final module = _modules[index];
                        final currentPerm = tempPermissions[module] ?? 'none';
                        
                        final bool isRead = currentPerm == 'read' || currentPerm == 'write';
                        final bool isWrite = currentPerm == 'write';

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              // Nama Modul
                              Expanded(
                                flex: 2, 
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Text(_formatModuleName(module)),
                                )
                              ),
                              // Checkbox Read
                              Expanded(
                                child: Checkbox(
                                  value: isRead,
                                  onChanged: (val) {
                                    setStateDialog(() {
                                      if (val == true) {
                                        // Jika Read dicentang, set 'read' (kecuali udah write)
                                        if (currentPerm == 'none') tempPermissions[module] = 'read';
                                      } else {
                                        // Jika Read uncheck, matikan semua
                                        tempPermissions[module] = 'none';
                                      }
                                    });
                                  },
                                ),
                              ),
                              // Checkbox Write
                              Expanded(
                                child: Checkbox(
                                  value: isWrite,
                                  activeColor: AppColors.error, // Merah untuk indikasi berbahaya
                                  onChanged: (val) {
                                    setStateDialog(() {
                                      if (val == true) {
                                        // Write on -> Read otomatis on
                                        tempPermissions[module] = 'write';
                                      } else {
                                        // Write off -> Turun ke Read
                                        tempPermissions[module] = 'read';
                                      }
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
              ElevatedButton(
                onPressed: () async {
                  final success = await context.read<AdminProvider>().updateAdminPermissions(admin.id, tempPermissions);
                  if (mounted) {
                    Navigator.pop(context);
                    if (success) _showFeedback("Hak akses diperbarui");
                    else _showFeedback("Gagal memperbarui hak akses", isError: true);
                  }
                },
                child: const Text('Simpan Akses'),
              ),
            ],
          );
        });
      },
    );
  }

  String _formatModuleName(String key) {
    switch (key) {
      case 'infoSS': return 'Info Suara Surabaya';
      case 'kawanSS': return 'Kawan Suara Surabaya';
      case 'userManagement': return 'Manajemen User (General)';
      case 'adminManagement': return 'Manajemen Admin (SUPER)';
      case 'temaSiaran': return 'Tema Siaran';
      case 'banner': return 'Banner Top';
      case 'popup': return 'Pop Up';
      default: return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<AdminProvider>(
        builder: (context, provider, child) {
          return CustomCard(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- HEADER ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Manajemen Hak Akses Admin", style: Theme.of(context).textTheme.titleLarge),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.person_add),
                      label: const Text("Angkat Admin Baru"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16)
                      ),
                      onPressed: _showPromoteDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // --- CONTENT ---
                if (provider.state == AdminViewState.Busy)
                  const Expanded(child: Center(child: CircularProgressIndicator()))
                else if (provider.admins.isEmpty)
                  const Expanded(child: Center(child: Text("Belum ada admin terdaftar.")))
                else
                  Expanded(
                    child: SingleChildScrollView(
                      child: SizedBox(
                        width: double.infinity,
                        child: DataTable(
                          headingRowColor: MaterialStateColor.resolveWith((states) => AppColors.primary),
                          columns: const [
                            DataColumn(label: Text('Nama')),
                            DataColumn(label: Text('Email')),
                            DataColumn(label: Text('Role')),
                            DataColumn(label: Text('Aksi')),
                          ],
                          rows: provider.admins.map((admin) {
                            return DataRow(
                              cells: [
                                DataCell(Text(admin.nama, style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataCell(Text(admin.email)),
                                DataCell(
                                  Chip(
                                    label: const Text('Admin'), 
                                    backgroundColor: AppColors.primary.withOpacity(0.1),
                                    labelStyle: const TextStyle(color: AppColors.primary),
                                  )
                                ),
                                DataCell(
                                  Row(
                                    children: [
                                      // Tombol Edit Hak Akses
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.lock_open, size: 14),
                                        label: const Text("Atur Akses"),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blueAccent,
                                          foregroundColor: Colors.white,
                                          textStyle: const TextStyle(fontSize: 12),
                                        ),
                                        onPressed: () => _showPermissionsDialog(admin),
                                      ),
                                      const SizedBox(width: 12),
                                      
                                      // Tombol Demote (Kecuali user ini Super Admin, tapi logic itu nanti)
                                      OutlinedButton(
                                        child: const Text("Turunkan"),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.error,
                                          side: const BorderSide(color: AppColors.error),
                                          textStyle: const TextStyle(fontSize: 12),
                                        ),
                                        onPressed: () async {
                                          final confirm = await showDialog(
                                            context: context, 
                                            builder: (c) => AlertDialog(
                                              title: const Text("Konfirmasi"),
                                              content: Text("Yakin ingin menurunkan ${admin.nama} menjadi User biasa?"),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Batal")),
                                                ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text("Ya, Turunkan")),
                                              ],
                                            )
                                          );
                                          
                                          if (confirm == true) {
                                            // PANGGIL PROVIDER DENGAN OBJECT ADMIN (BUKAN ID)
                                            final error = await provider.demoteToUser(admin);
                                            
                                            if (error == null) {
                                              _showFeedback("Admin berhasil diturunkan menjadi User");
                                            } else {
                                              _showFeedback(error, isError: true);
                                            }
                                          }
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
      ),
    );
  }
}