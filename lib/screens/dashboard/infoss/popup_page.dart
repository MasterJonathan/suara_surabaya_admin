// lib/screens/dashboard/popup_page.dart

import 'package:suara_surabaya_admin/core/theme/app_colors.dart';
import 'package:suara_surabaya_admin/models/dashboard/infoss/popup_model.dart';
import 'package:suara_surabaya_admin/providers/dashboard/infoss/popup_provider.dart';
import 'package:suara_surabaya_admin/widgets/common/custom_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class PopUpPage extends StatefulWidget {
  const PopUpPage({super.key});

  @override
  State<PopUpPage> createState() => _PopUpPageState();
}

class _PopUpPageState extends State<PopUpPage> {
  late List<PopUpModel> _filteredData;
  final TextEditingController _searchController = TextEditingController();
  final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd\nHH:mm:ss');
  final DateFormat _rangeDateFormatter = DateFormat('dd MMMM yyyy HH:mm:ss');
  String _entriesToShow = '10';

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<PopUpProvider>(context, listen: false);
    _filteredData = provider.popups;
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performFilter(String query, List<PopUpModel> allData) {
    if (query.isEmpty) {
      _filteredData = allData;
    } else {
      _filteredData =
          allData
              .where(
                (item) =>
                    item.namaPopUp.toLowerCase().contains(
                      query.toLowerCase(),
                    ) ||
                    item.dipostingOleh.toLowerCase().contains(
                      query.toLowerCase(),
                    ),
              )
              .toList();
    }
  }

  void _showAddEditDialog({PopUpModel? popUp}) {
    final isEditing = popUp != null;
    final formKey = GlobalKey<FormState>();
    final namaController = TextEditingController(text: popUp?.namaPopUp);
    final imageUrlController = TextEditingController(
      text: popUp?.popUpImageUrl,
    );
    String selectedPosition = popUp?.position ?? 'Square';
    DateTime tanggalMulai = popUp?.tanggalAktifMulai ?? DateTime.now();
    DateTime tanggalSelesai =
        popUp?.tanggalAktifSelesai ??
        DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Future<void> selectDate(
              BuildContext context,
              bool isStartDate,
            ) async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: isStartDate ? tanggalMulai : tanggalSelesai,
                firstDate: DateTime(2020),
                lastDate: DateTime(2101),
              );
              if (picked != null) {
                final TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(
                    isStartDate ? tanggalMulai : tanggalSelesai,
                  ),
                );
                if (pickedTime != null) {
                  setStateDialog(() {
                    if (isStartDate) {
                      tanggalMulai = DateTime(
                        picked.year,
                        picked.month,
                        picked.day,
                        pickedTime.hour,
                        pickedTime.minute,
                      );
                    } else {
                      tanggalSelesai = DateTime(
                        picked.year,
                        picked.month,
                        picked.day,
                        pickedTime.hour,
                        pickedTime.minute,
                      );
                    }
                  });
                }
              }
            }

            return ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 400),
              child: AlertDialog(
                title: Text(isEditing ? 'Edit Pop Up' : 'Tambah Pop Up'),
                content: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: namaController,
                          decoration: const InputDecoration(
                            labelText: 'Nama Pop Up',
                          ),
                          validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: imageUrlController,
                          decoration: const InputDecoration(
                            labelText: 'Image URL',
                          ),
                          validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedPosition,
                          decoration: const InputDecoration(
                            labelText: 'Posisi Pop Up',
                          ),
                          items: const [
                            // Ubah teks dan nilai (value) di sini
                            DropdownMenuItem(
                              value: 'Potrait',
                              child: Text('Potrait'),
                            ),
                            DropdownMenuItem(
                              value: 'Square',
                              child: Text('Square'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setStateDialog(() => selectedPosition = value);
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Tanggal Aktif Mulai',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () => selectDate(context, true),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.calendar_today_outlined),
                            ),
                            child: Text(
                              DateFormat(
                                'dd MMMM yyyy, HH:mm',
                              ).format(tanggalMulai),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tanggal Aktif Selesai',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () => selectDate(context, false),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.calendar_today_outlined),
                            ),
                            child: Text(
                              DateFormat(
                                'dd MMMM yyyy, HH:mm',
                              ).format(tanggalSelesai),
                            ),
                          ),
                        ),
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
                        final provider = context.read<PopUpProvider>();
                        final now = DateTime.now();

                        if (isEditing) {
                          final updatedPopUp = PopUpModel(
                            id: popUp.id,
                            namaPopUp: namaController.text,
                            popUpImageUrl: imageUrlController.text,
                            position: selectedPosition,
                            tanggalAktifMulai: tanggalMulai,
                            tanggalAktifSelesai: tanggalSelesai,
                            status: popUp.status,
                            hits: popUp.hits,
                            tanggalPosting: popUp.tanggalPosting,
                            dipostingOleh: popUp.dipostingOleh,
                          );
                          await provider.updatePopUp(updatedPopUp);
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
                            tanggalPosting: now,
                            dipostingOleh: "Admin",
                          );
                          await provider.addPopUp(newPopUp);
                        }
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text('Simpan'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PopUpProvider>(
      builder: (context, provider, child) {
        _performFilter(_searchController.text, provider.popups);

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
                        _buildTableControls(),
                        const SizedBox(height: 20),
                        if (provider.state == PopUpViewState.Busy &&
                            provider.popups.isEmpty)
                          const Center(child: CircularProgressIndicator())
                        else if (provider.errorMessage != null)
                          Center(child: Text('Error: ${provider.errorMessage}'))
                        else
                          SizedBox(
                            width: double.infinity,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: _buildDataTable(provider),
                            ),
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
    );
  }

  Widget _buildTableControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            SizedBox(
              width: 250,
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Search',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
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
                      <String>['10', '25', '50', '100']
                          .map(
                            (String value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                  onChanged:
                      (String? newValue) =>
                          setState(() => _entriesToShow = newValue!),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text('entries'),
          ],
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Tambah Pop Up'),
          onPressed: () => _showAddEditDialog(),
        ),
      ],
    );
  }

  Widget _buildDataTable(PopUpProvider provider) {
    final paginatedData =
        _filteredData
            .take(int.tryParse(_entriesToShow) ?? _filteredData.length)
            .toList();
    return DataTable(
      columns: const [
        DataColumn(label: Text('Nama Pop Up')),
        DataColumn(label: Text('Position')),
        DataColumn(label: Text('Tanggal Aktif')),
        DataColumn(label: Text('Gambar Pop Up')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Hits')),
        DataColumn(label: Text('Tanggal\nPosting')),
        DataColumn(label: Text('Diposting\nOleh')),
        DataColumn(label: Text('Aksi')),
      ],
      rows:
          paginatedData.map((item) {
            return DataRow(
              cells: [
                DataCell(Text(item.namaPopUp)),
                DataCell(
                  Chip(
                    label: Text(item.position),
                    backgroundColor:
                        item.position == 'Top'
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : AppColors.warning.withValues(alpha: 0.1),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color:
                          item.position == 'Top'
                              ? AppColors.primary
                              : AppColors.warning,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    '${_rangeDateFormatter.format(item.tanggalAktifMulai)} Sampai\n${_rangeDateFormatter.format(item.tanggalAktifSelesai)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 200,
                    child: Image.network(
                      item.popUpImageUrl,
                      fit: BoxFit.contain,
                      errorBuilder:
                          (c, o, s) => const Icon(
                            Icons.image_not_supported,
                            color: AppColors.error,
                          ),
                    ),
                  ),
                ),
                DataCell(
                  Chip(
                    label: Text(item.status ? 'Active' : 'Inactive'),
                    backgroundColor:
                        item.status
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.error.withValues(alpha: 0.1),
                    labelStyle: TextStyle(
                      color: item.status ? AppColors.success : AppColors.error,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                  ),
                ),
                DataCell(Text(item.hits.toString())),
                DataCell(Text(_dateFormatter.format(item.tanggalPosting))),
                DataCell(Text(item.dipostingOleh)),
                DataCell(
                  Row(
                    children: [
                      _actionButton(
                        icon: Icons.edit,
                        color: AppColors.primary,
                        tooltip: 'Edit Pop Up',
                        onPressed: () => _showAddEditDialog(popUp: item),
                      ),
                      const SizedBox(width: 8),
                      _actionButton(
                        icon: Icons.close,
                        color: AppColors.error,
                        tooltip: 'Delete Pop Up',
                        onPressed:
                            () async => await provider.deletePopUp(item.id),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: 32,
      height: 32,
      child: ElevatedButton(
        onPressed: onPressed ?? () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          padding: EdgeInsets.zero,
        ),
        child: Tooltip(message: tooltip, child: Icon(icon, size: 16)),
      ),
    );
  }
}
