import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:suara_surabaya_admin/core/theme/app_colors.dart';
import 'package:suara_surabaya_admin/models/dashboard/user_management/user_model.dart';
import 'package:suara_surabaya_admin/providers/dashboard/user_management/user_provider.dart';
import 'package:suara_surabaya_admin/screens/dashboard/user_activity_page.dart';
import 'package:suara_surabaya_admin/widgets/common/custom_card.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

class GeneralUserPage extends StatefulWidget {
  const GeneralUserPage({super.key});

  @override
  State<GeneralUserPage> createState() => _GeneralUserPageState();
}

class _GeneralUserPageState extends State<GeneralUserPage> {
  final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd HH:mm');
  int? _sortColumnIndex;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadInitialData();
    });
  }

  void _showFeedback(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // --- DIALOG EDIT USER (UPDATED) ---
  void _showEditDialog(UserModel user) {
    final formKey = GlobalKey<FormState>();
    
    // Controllers
    final nameController = TextEditingController(text: user.nama);
    final usernameController = TextEditingController(text: user.username);
    final emailController = TextEditingController(text: user.email);
    final phoneController = TextEditingController(text: user.nomorHp ?? '');
    final addressController = TextEditingController(text: user.alamat ?? '');
    
    // State Variables
    String? selectedGender = user.jenisKelamin;
    bool isActive = user.status;
    
    // Parsing Tanggal Lahir (String 'yyyy-MM-dd' -> DateTime)
    DateTime? birthDate;
    if (user.tanggalLahir != null && user.tanggalLahir!.isNotEmpty) {
      try {
        birthDate = DateFormat('yyyy-MM-dd').parse(user.tanggalLahir!);
      } catch (e) {
        birthDate = null;
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          
          Future<void> selectDate() async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: birthDate ?? DateTime(2000),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              setStateDialog(() => birthDate = picked);
            }
          }

          return AlertDialog(
            title: const Text('Edit Personal Information'),
            content: Form(
              key: formKey,
              child: SizedBox(
                width: 600, // Lebar dialog diperbesar agar muat 2 kolom
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- ROW 1: Nama Lengkap & Username ---
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: nameController,
                              decoration: const InputDecoration(
                                labelText: 'Nama Lengkap',
                                prefixIcon: Icon(Icons.person_outline),
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: usernameController,
                              decoration: const InputDecoration(
                                labelText: 'Username',
                                prefixIcon: Icon(Icons.alternate_email),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // --- ROW 2: Email (ReadOnly) & Nomor HP ---
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email Address',
                                prefixIcon: Icon(Icons.email_outlined),
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.black12, // Indikasi ReadOnly
                              ),
                              readOnly: true,
                              enabled: false,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: phoneController,
                              decoration: const InputDecoration(
                                labelText: 'Nomor HP',
                                prefixIcon: Icon(Icons.phone_android),
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // --- ROW 3: Jenis Kelamin & Tanggal Lahir ---
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedGender,
                              decoration: const InputDecoration(
                                labelText: 'Jenis Kelamin',
                                prefixIcon: Icon(Icons.people_outline),
                                border: OutlineInputBorder(),
                              ),
                              items: ['Laki-laki', 'Perempuan']
                                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                                  .toList(),
                              onChanged: (v) => setStateDialog(() => selectedGender = v),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: selectDate,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Tanggal Lahir',
                                  prefixIcon: Icon(Icons.calendar_today),
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(
                                  birthDate != null 
                                      ? DateFormat('dd MMMM yyyy').format(birthDate!) 
                                      : 'Pilih Tanggal',
                                  style: TextStyle(
                                    color: birthDate != null ? Colors.black87 : Colors.grey
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // --- Alamat (Full Width) ---
                      TextFormField(
                        controller: addressController,
                        decoration: const InputDecoration(
                          labelText: 'Alamat',
                          prefixIcon: Icon(Icons.location_on_outlined),
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      
                      const SizedBox(height: 24),
                      const Divider(),
                      
                      // --- Status Akun Switch ---
                      SwitchListTile(
                        title: const Text("Status Akun", style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          isActive ? "Aktif (Dapat login)" : "Dinonaktifkan (Banned)",
                          style: TextStyle(color: isActive ? AppColors.success : AppColors.error),
                        ),
                        value: isActive,
                        activeColor: AppColors.success,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) => setStateDialog(() => isActive = val),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), 
                child: const Text('Batal')
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final provider = context.read<UserProvider>();
                    
                    // Siapkan data update (Map ke nama field di Firestore)
                    Map<String, dynamic> updateData = {
                      'nama': nameController.text,
                      'username': usernameController.text,
                      'nomor_hp': phoneController.text,
                      'alamat': addressController.text,
                      'jenis_kelamin': selectedGender,
                      'status': isActive, // boolean
                    };

                    // Format tanggal lahir ke string yyyy-MM-dd agar konsisten
                    if (birthDate != null) {
                      updateData['tanggal_lahir'] = DateFormat('yyyy-MM-dd').format(birthDate!);
                    }

                    // Panggil partial update
                    bool success = await provider.updateUserPartial(user.id, updateData);
                    
                    if (mounted) {
                      if (success) {
                        Navigator.pop(context);
                        _showFeedback("Profil pengguna berhasil diperbarui");
                      } else {
                        _showFeedback("Gagal memperbarui data", isError: true);
                      }
                    }
                  }
                },
                child: const Text('Simpan Perubahan'),
              ),
            ],
          );
        });
      },
    );
  }

  // --- FILTER DIALOG ---
  Future<void> _showSearchFilterDialog() async {
    final provider = context.read<UserProvider>();
    final TextEditingController queryController = TextEditingController();
    String searchField = 'Nama';
    DateTime startDate = DateTime.now().subtract(const Duration(days: 30));
    DateTime endDate = DateTime.now();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Filter & Cari User'),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Rentang Tanggal Bergabung", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 300,
                        child: SfDateRangePicker(
                          onSelectionChanged: (DateRangePickerSelectionChangedArgs args) {
                            if (args.value is PickerDateRange) {
                              startDate = args.value.startDate ?? DateTime.now();
                              endDate = args.value.endDate ?? args.value.startDate ?? DateTime.now();
                            }
                          },
                          selectionMode: DateRangePickerSelectionMode.range,
                          initialSelectedRange: PickerDateRange(startDate, endDate),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text("Kriteria Pencarian", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: searchField,
                              items: ['Nama', 'Email', 'Role'].map((label) => DropdownMenuItem(value: label, child: Text(label))).toList(),
                              onChanged: (v) => setDialogState(() => searchField = v!),
                              decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: queryController,
                              decoration: const InputDecoration(labelText: 'Kata Kunci...', border: OutlineInputBorder()),
                              onSubmitted: (_) => _doSearch(provider, searchField, queryController.text, startDate, endDate),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                ElevatedButton(
                  onPressed: () => _doSearch(provider, searchField, queryController.text, startDate, endDate),
                  child: const Text('Cari'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _doSearch(UserProvider provider, String field, String query, DateTime start, DateTime end) {
    if (query.trim().isEmpty) return;
    final adjustedEnd = DateTime(end.year, end.month, end.day, 23, 59, 59);
    provider.searchUsers(
      searchField: field,
      searchQuery: query,
      startDate: start,
      endDate: adjustedEnd,
    );
    Navigator.of(context).pop();
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<UserProvider>(
        builder: (context, provider, child) {
          return CustomCard(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTableControls(provider),
                const SizedBox(height: 20),
                
                // INFO LIVE MODE
                if (provider.isLiveMode)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    color: Colors.red.withOpacity(0.1),
                    child: const Row(
                      children: [
                        Icon(Icons.sensors, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text("LIVE MONITORING (50 Pendaftar Terbaru)", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),

                if (provider.state == UserViewState.Busy && provider.users.isEmpty)
                  const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                else if (provider.errorMessage != null)
                  Center(child: Text('Error: ${provider.errorMessage}'))
                else if (provider.users.isEmpty)
                  const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Tidak ada user ditemukan.")))
                else
                  // --- PERBAIKAN STRUKTUR SCROLLING ---
                  // Hapus Expanded di sini jika parent Column sudah di dalam Expanded/ScrollView
                  Expanded( 
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: _buildDataTable(provider),
                          ),
                          
                          // TOMBOL LOAD MORE
                          if (!provider.isLiveMode) ...[
                            if (provider.showContinueSearchButton)
                              _buildContinueSearchButton(provider)
                            else if (provider.hasMoreData && provider.users.isNotEmpty)
                              _buildLoadMoreButton(provider),
                            
                            const SizedBox(height: 30),
                          ],
                        ],
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

  Widget _buildTableControls(UserProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Text("Live Mode:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Switch(value: provider.isLiveMode, activeColor: Colors.red, onChanged: (val) => provider.toggleLiveMode(val)),
          ],
        ),
        if (!provider.isLiveMode)
          Row(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.filter_list, size: 16),
                label: const Text('Filter & Cari'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18)),
                onPressed: _showSearchFilterDialog,
              ),
              if (provider.isSearching) ...[
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => provider.resetSearch(),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18)),
                  child: const Tooltip(message: 'Reset Filter', child: Icon(Icons.refresh, size: 18)),
                ),
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildContinueSearchButton(UserProvider provider) {
    return Padding(padding: const EdgeInsets.only(top: 16.0), child: OutlinedButton.icon(icon: const Icon(Icons.search), onPressed: () => provider.continueSearch(), label: const Text("Lanjutkan Pencarian (Scan 200 Berikutnya)")));
  }

  Widget _buildLoadMoreButton(UserProvider provider) {
    return Container(
      margin: const EdgeInsets.only(top: 20.0), 
      width: double.infinity, 
      child: provider.state == UserViewState.LoadingMore 
        ? const Center(child: CircularProgressIndicator()) 
        : OutlinedButton.icon(
            onPressed: () => provider.continueSearch(), 
            icon: const Icon(Icons.arrow_downward, size: 16), 
            label: const Text("Muat Lebih Banyak Data (Load More)"), 
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16))
          )
    );
  }

  Widget _buildDataTable(UserProvider provider) {
    final List<UserModel> sortedData = List.from(provider.users);
    if (_sortColumnIndex != null && !provider.isLiveMode) {
      sortedData.sort((a, b) {
        int result = 0;
        switch (_sortColumnIndex) {
          case 0: result = a.nama.compareTo(b.nama); break;
          case 1: result = (a.status ? 1 : 0).compareTo(b.status ? 1 : 0); break;
          case 2: result = a.role.compareTo(b.role); break;
          case 3: result = a.joinDate.compareTo(b.joinDate); break;
        }
        return _sortAscending ? result : -result;
      });
    }

    return DataTable(
      sortColumnIndex: _sortColumnIndex,
      sortAscending: _sortAscending,
      columns: [
        DataColumn(label: const Text('Username'), onSort: !provider.isLiveMode ? _onSort : null),
        DataColumn(label: const Text('Status'), onSort: !provider.isLiveMode ? _onSort : null),
        DataColumn(label: const Text('Role'), onSort: !provider.isLiveMode ? _onSort : null),
        DataColumn(label: const Text('Tanggal Bergabung'), onSort: !provider.isLiveMode ? _onSort : null),
        const DataColumn(label: Text('Aksi')),
      ],
      rows: sortedData.map((user) {
        return DataRow(
          cells: [
            DataCell(InkWell(onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => UserActivityPage(kontributorId: user.id))), child: Text(user.nama, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)))),
            DataCell(Chip(label: Text(user.status ? 'Active' : 'Banned'), backgroundColor: user.status ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1), labelStyle: TextStyle(color: user.status ? AppColors.success : AppColors.error))),
            DataCell(Chip(label: Text(user.role), backgroundColor: AppColors.primary.withOpacity(0.1), labelStyle: const TextStyle(color: AppColors.primary))),
            DataCell(Text(_dateFormatter.format(user.joinDate))),
            DataCell(Row(children: [
              IconButton(
                icon: const Icon(Icons.edit, color: AppColors.primary),
                tooltip: 'Edit Data Pengguna',
                onPressed: () => _showEditDialog(user), // MUNCULKAN DIALOG EDIT
              ),
              IconButton(
                icon: Icon(user.status ? Icons.block : Icons.check_circle, color: user.status ? AppColors.error : AppColors.success),
                tooltip: user.status ? 'Ban User' : 'Aktifkan User',
                onPressed: () async {
                  final success = await provider.updateUserPartial(user.id, {'status': !user.status});
                  if(success) _showFeedback(user.status ? "User dinonaktifkan" : "User diaktifkan");
                }
              ),
            ])),
          ],
        );
      }).toList(),
    );
  }
}