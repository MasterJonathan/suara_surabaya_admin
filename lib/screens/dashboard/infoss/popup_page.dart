import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:suara_surabaya_admin/core/theme/app_colors.dart';
import 'package:suara_surabaya_admin/models/dashboard/infoss/popup_model.dart';
import 'package:suara_surabaya_admin/providers/auth/authentication_provider.dart';
import 'package:suara_surabaya_admin/providers/dashboard/infoss/popup_provider.dart';
import 'package:suara_surabaya_admin/widgets/common/custom_card.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

class PopUpPage extends StatefulWidget {
  const PopUpPage({super.key});

  @override
  State<PopUpPage> createState() => _PopUpPageState();
}

class _PopUpPageState extends State<PopUpPage> {
  final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd\nHH:mm:ss');
  final DateFormat _rangeDateFormatter = DateFormat('dd MMM yyyy HH:mm');

  // Sorting
  int? _sortColumnIndex;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PopUpProvider>().loadInitialData();
    });
  }

  // --- FEEDBACK ---
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

  // --- FILTER DIALOG ---
  Future<void> _showSearchFilterDialog() async {
    final provider = context.read<PopUpProvider>();
    final TextEditingController queryController = TextEditingController();
    String searchField = 'Nama PopUp';
    DateTime startDate = DateTime.now().subtract(const Duration(days: 30));
    DateTime endDate = DateTime.now();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Filter & Cari Pop Up'),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Rentang Tanggal Posting", style: TextStyle(fontWeight: FontWeight.bold)),
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
                              items: ['Nama PopUp', 'Oleh']
                                  .map((label) => DropdownMenuItem(value: label, child: Text(label)))
                                  .toList(),
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

  void _doSearch(PopUpProvider provider, String field, String query, DateTime start, DateTime end) {
    if (query.trim().isEmpty) return;
    final adjustedEnd = DateTime(end.year, end.month, end.day, 23, 59, 59);
    provider.searchPopUps(
      searchField: field,
      searchQuery: query,
      startDate: start,
      endDate: adjustedEnd,
    );
    Navigator.of(context).pop();
  }

  // --- ADD / EDIT DIALOG ---
  void _showAddEditDialog({PopUpModel? popUp}) {
    final isEditing = popUp != null;
    final formKey = GlobalKey<FormState>();
    final namaController = TextEditingController(text: popUp?.namaPopUp);
    final imageUrlController = TextEditingController(text: popUp?.popUpImageUrl);
    String selectedPosition = popUp?.position ?? 'Square';
    DateTime tanggalMulai = popUp?.tanggalAktifMulai ?? DateTime.now();
    DateTime tanggalSelesai = popUp?.tanggalAktifSelesai ?? DateTime.now().add(const Duration(days: 30));

    final authProvider = context.read<AuthenticationProvider>();
    final currentUserName = authProvider.user?.nama ?? 'Admin';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            bool isSaving = false;

            Future<void> selectDate(bool isStartDate) async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: isStartDate ? tanggalMulai : tanggalSelesai,
                firstDate: DateTime(2020),
                lastDate: DateTime(2101),
              );
              if (picked != null) {
                final TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(isStartDate ? tanggalMulai : tanggalSelesai),
                );
                if (pickedTime != null) {
                  setStateDialog(() {
                    final newDate = DateTime(picked.year, picked.month, picked.day, pickedTime.hour, pickedTime.minute);
                    if (isStartDate) tanggalMulai = newDate; else tanggalSelesai = newDate;
                  });
                }
              }
            }

            Future<void> handleSave() async {
              if (formKey.currentState!.validate()) {
                setStateDialog(() => isSaving = true);
                final provider = context.read<PopUpProvider>();
                
                try {
                  bool success;
                  if (isEditing) {
                    final updatedPopUp = popUp!.copyWith(
                      namaPopUp: namaController.text,
                      popUpImageUrl: imageUrlController.text,
                      position: selectedPosition,
                      tanggalAktifMulai: tanggalMulai,
                      tanggalAktifSelesai: tanggalSelesai,
                    );
                    success = await provider.updatePopUp(updatedPopUp);
                  } else {
                    final newPopUp = PopUpModel(
                      id: '',
                      namaPopUp: namaController.text,
                      popUpImageUrl: imageUrlController.text,
                      position: selectedPosition,
                      tanggalAktifMulai: tanggalMulai,
                      tanggalAktifSelesai: tanggalSelesai,
                      status: true,
                      hits: 0,
                      tanggalPosting: DateTime.now(),
                      dipostingOleh: currentUserName,
                    );
                    success = await provider.addPopUp(newPopUp);
                  }

                  if (!mounted) return;
                  if (success) {
                    Navigator.pop(context);
                    _showFeedback(isEditing ? "Pop Up berhasil diperbarui" : "Pop Up berhasil ditambahkan");
                  } else {
                    _showFeedback("Gagal menyimpan data", isError: true);
                  }
                } catch (e) {
                   if (mounted) _showFeedback("Terjadi kesalahan", isError: true);
                } finally {
                  if (mounted) setStateDialog(() => isSaving = false);
                }
              }
            }

            return AlertDialog(
              title: Text(isEditing ? 'Edit Pop Up' : 'Tambah Pop Up'),
              content: Form(
                key: formKey,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 400),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(controller: namaController, decoration: const InputDecoration(labelText: 'Nama Pop Up'), validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
                        const SizedBox(height: 16),
                        TextFormField(controller: imageUrlController, decoration: const InputDecoration(labelText: 'Image URL'), validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedPosition,
                          decoration: const InputDecoration(labelText: 'Posisi Pop Up'),
                          items: const [
                            DropdownMenuItem(value: 'Potrait', child: Text('Potrait')),
                            DropdownMenuItem(value: 'Square', child: Text('Square')),
                          ],
                          onChanged: (v) => setStateDialog(() => selectedPosition = v!),
                        ),
                        const SizedBox(height: 20),
                        Row(children: [
                          Expanded(child: InkWell(onTap: () => selectDate(true), child: InputDecorator(decoration: const InputDecoration(labelText: 'Mulai Aktif', prefixIcon: Icon(Icons.calendar_today)), child: Text(DateFormat('dd MMM yyyy, HH:mm').format(tanggalMulai))))),
                          const SizedBox(width: 16),
                          Expanded(child: InkWell(onTap: () => selectDate(false), child: InputDecorator(decoration: const InputDecoration(labelText: 'Selesai Aktif', prefixIcon: Icon(Icons.calendar_today)), child: Text(DateFormat('dd MMM yyyy, HH:mm').format(tanggalSelesai))))),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: isSaving ? null : () => Navigator.pop(context), child: const Text('Batal')),
                ElevatedButton(onPressed: isSaving ? null : handleSave, child: isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Simpan')),
              ],
            );
          },
        );
      },
    );
  }

  // --- DELETE HANDLER ---
  Future<void> _handleDelete(PopUpProvider provider, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pop Up'),
        content: const Text('Yakin ingin menghapus Pop Up ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.error), onPressed: () => Navigator.pop(context, true), child: const Text('Hapus', style: TextStyle(color: Colors.white))),
        ],
      ),
    );

    if (confirm == true) {
      final success = await provider.deletePopUp(id);
      if (success) _showFeedback("Pop Up berhasil dihapus");
      else _showFeedback("Gagal menghapus data", isError: true);
    }
  }

  // --- SORTING ---
  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<PopUpProvider>(
        builder: (context, provider, child) {
          return Column(
            key: const PageStorageKey('popUpPage'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: CustomCard(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTableControls(provider),
                          const SizedBox(height: 20),
                          if (provider.state == PopUpViewState.Busy && provider.popups.isEmpty)
                            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                          else if (provider.errorMessage != null)
                             const Center(child: Text("Gagal memuat data (Cek Log)", style: TextStyle(color: Colors.red)))
                          else if (provider.popups.isEmpty)
                            const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Tidak ada data ditemukan.")))
                          else
                            Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: _buildDataTable(provider),
                                  ),
                                ),
                                if (provider.showContinueSearchButton)
                                  _buildContinueSearchButton(provider)
                                else if (provider.hasMoreData && provider.popups.isNotEmpty)
                                  _buildLoadMoreButton(provider),
                                const SizedBox(height: 30),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTableControls(PopUpProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
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
        ElevatedButton.icon(
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Tambah Pop Up'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18)),
          onPressed: () => _showAddEditDialog(),
        ),
      ],
    );
  }

  Widget _buildContinueSearchButton(PopUpProvider provider) {
    return Padding(padding: const EdgeInsets.only(top: 16.0), child: OutlinedButton.icon(icon: const Icon(Icons.search), onPressed: () => provider.continueSearch(), label: const Text("Lanjutkan Pencarian (Scan 200 Berikutnya)")));
  }

  Widget _buildLoadMoreButton(PopUpProvider provider) {
    return Container(margin: const EdgeInsets.only(top: 20.0), width: double.infinity, child: provider.state == PopUpViewState.LoadingMore ? const Center(child: CircularProgressIndicator()) : OutlinedButton.icon(onPressed: () => provider.continueSearch(), icon: const Icon(Icons.arrow_downward, size: 16), label: const Text("Muat Lebih Banyak Data (Load More)"), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16))));
  }

  Widget _buildDataTable(PopUpProvider provider) {
    final List<PopUpModel> sortedData = List.from(provider.popups);
    if (_sortColumnIndex != null) {
      sortedData.sort((a, b) {
        int result = 0;
        switch (_sortColumnIndex) {
          case 0: result = a.namaPopUp.compareTo(b.namaPopUp); break;
          case 1: result = a.position.compareTo(b.position); break;
          case 2: result = a.tanggalAktifMulai.compareTo(b.tanggalAktifMulai); break;
          case 4: result = (a.status ? 1 : 0).compareTo(b.status ? 1 : 0); break;
          case 5: result = a.hits.compareTo(b.hits); break;
          case 6: result = a.tanggalPosting.compareTo(b.tanggalPosting); break;
          case 7: result = a.dipostingOleh.compareTo(b.dipostingOleh); break;
        }
        return _sortAscending ? result : -result;
      });
    }

    return Theme(
      data: Theme.of(context).copyWith(dataTableTheme: DataTableThemeData(headingRowColor: MaterialStateColor.resolveWith((states) => AppColors.primary), headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), iconTheme: const IconThemeData(color: Colors.white)),
      child: DataTable(
        sortColumnIndex: _sortColumnIndex,
        sortAscending: _sortAscending,
        columns: [
          DataColumn(label: const Text('Nama Pop Up'), onSort: _onSort),
          DataColumn(label: const Text('Position'), onSort: _onSort),
          DataColumn(label: const Text('Tanggal Aktif'), onSort: _onSort),
          const DataColumn(label: Text('Gambar')),
          DataColumn(label: const Text('Status'), onSort: _onSort),
          DataColumn(label: const Text('Hits'), numeric: true, onSort: _onSort),
          DataColumn(label: const Text('Tanggal\nPosting'), onSort: _onSort),
          DataColumn(label: const Text('Diposting\nOleh'), onSort: _onSort),
          const DataColumn(label: Text('Aksi')),
        ],
        rows: sortedData.map((item) {
          return DataRow(
            cells: [
              DataCell(Text(item.namaPopUp)),
              DataCell(Chip(label: Text(item.position), backgroundColor: item.position == 'Top' ? AppColors.primary.withOpacity(0.1) : AppColors.warning.withOpacity(0.1))),
              DataCell(Text('${_rangeDateFormatter.format(item.tanggalAktifMulai)} s/d\n${_rangeDateFormatter.format(item.tanggalAktifSelesai)}', style: const TextStyle(fontSize: 12))),
              DataCell(SizedBox(width: 80, height: 80, child: Image.network(item.popUpImageUrl, fit: BoxFit.contain, errorBuilder: (c, o, s) => const Icon(Icons.broken_image)))),
              DataCell(Chip(label: Text(item.status ? 'Active' : 'Inactive'), backgroundColor: item.status ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1))),
              DataCell(Text(item.hits.toString())),
              DataCell(Text(_dateFormatter.format(item.tanggalPosting))),
              DataCell(Text(item.dipostingOleh)),
              DataCell(Row(children: [
                _actionButton(icon: Icons.edit, color: AppColors.primary, tooltip: 'Edit', onPressed: () => _showAddEditDialog(popUp: item)),
                const SizedBox(width: 8),
                _actionButton(icon: Icons.close, color: AppColors.error, tooltip: 'Delete', onPressed: () => _handleDelete(provider, item.id)),
              ])),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _actionButton({required IconData icon, required Color color, required String tooltip, VoidCallback? onPressed}) {
    return SizedBox(width: 32, height: 32, child: ElevatedButton(onPressed: onPressed, style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))), child: Tooltip(message: tooltip, child: Icon(icon, size: 16))));
  }
}