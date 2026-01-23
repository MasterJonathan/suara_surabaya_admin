// lib/screens/dashboard/tema_siaran_page.dart

import 'package:suara_surabaya_admin/core/theme/app_colors.dart';
import 'package:suara_surabaya_admin/models/dashboard/infoss/tema_siaran_model.dart';
import 'package:suara_surabaya_admin/providers/auth/authentication_provider.dart';
import 'package:suara_surabaya_admin/providers/dashboard/infoss/tema_siaran_provider.dart';
import 'package:suara_surabaya_admin/widgets/common/custom_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class TemaSiaranPage extends StatefulWidget {
  const TemaSiaranPage({super.key});

  @override
  State<TemaSiaranPage> createState() => _TemaSiaranPageState();
}

class _TemaSiaranPageState extends State<TemaSiaranPage> {
  late List<TemaSiaranModel> _filteredData;
  final TextEditingController _searchController = TextEditingController();
  final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd\nHH:mm:ss');
  final DateFormat _rangeDateFormatter = DateFormat('dd MMMM yyyy HH:mm:ss');
  String _entriesToShow = '10';

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<TemaSiaranProvider>(context, listen: false);
    _filteredData = provider.temas;
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performFilter(String query, List<TemaSiaranModel> allData) {
    if (query.isEmpty) {
      _filteredData = allData;
    } else {
      _filteredData =
          allData
              .where(
                (tema) =>
                    tema.namaTema.toLowerCase().contains(query.toLowerCase()) ||
                    tema.dipostingOleh.toLowerCase().contains(
                      query.toLowerCase(),
                    ),
              )
              .toList();
    }
  }

  void _showAddEditDialog({TemaSiaranModel? tema, required bool canWrite}) {
    final isEditing = tema != null;
    final formKey = GlobalKey<FormState>();
    final namaController = TextEditingController(text: tema?.namaTema);
    final imageUrlController = TextEditingController(text: tema?.temaImageUrl);

    const String defaultImageUrl =
        "https://firebasestorage.googleapis.com/v0/b/kp-ss-a8e05.appspot.com/o/default%2FDefaultSS.jpg?alt=media&token=10065842-5f33-4148-abc2-387013a3399b";

    DateTime tanggalMulai = tema?.tanggalAktifMulai ?? DateTime.now();
    DateTime tanggalSelesai =
        tema?.tanggalAktifSelesai ??
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
              if (!canWrite) return;

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
                title: Text(
                  isEditing ? 'Edit Tema Siaran' : 'Tambah Tema Siaran',
                ),
                content: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: namaController,
                          readOnly: !canWrite,
                          decoration: const InputDecoration(
                            labelText: 'Nama Tema',
                          ),
                          validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: imageUrlController,
                          readOnly: !canWrite,
                          decoration: const InputDecoration(
                            labelText: 'Image URL',
                          ),
                          validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                        ),
                        const SizedBox(height: 8),
                        if (canWrite)
                          TextButton(
                            onPressed: () {
                              imageUrlController.text = defaultImageUrl;
                            },
                            child: const Text('Gunakan Gambar Default'),
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
                  if (canWrite)
                    ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          final provider = context.read<TemaSiaranProvider>();
                          
                          if (isEditing) {
                            // --- PERBAIKAN: Ganti copyWith dengan constructor manual ---
                            final updatedTema = TemaSiaranModel(
                              id: tema.id,
                              namaTema: namaController.text,
                              temaImageUrl: imageUrlController.text,
                              tanggalAktifMulai: tanggalMulai,
                              tanggalAktifSelesai: tanggalSelesai,
                              // Salin properti yang tidak diubah dari objek asli
                              status: tema.status,
                              hits: tema.hits,
                              tanggalPosting: tema.tanggalPosting,
                              dipostingOleh: tema.dipostingOleh,
                            );
                            await provider.updateTemaSiaran(updatedTema);
                          } else {
                            final newTema = TemaSiaranModel(
                              id: '',
                              namaTema: namaController.text,
                              temaImageUrl: imageUrlController.text,
                              tanggalAktifMulai: tanggalMulai,
                              tanggalAktifSelesai: tanggalSelesai,
                              status: true,
                              hits: 0,
                              tanggalPosting: DateTime.now(),
                              dipostingOleh: 'Admin',
                            );
                            await provider.addTemaSiaran(newTema);
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
    final authProvider = context.read<AuthenticationProvider>();
    final hakAkses = authProvider.user?.hakAkses ?? {};
    final String? accessLevel = hakAkses['temaSiaran'];
    final bool canWrite = accessLevel == 'write';

    return Consumer<TemaSiaranProvider>(
      builder: (context, provider, child) {
        _performFilter(_searchController.text, provider.temas);

        return Column(
          key: const PageStorageKey('temaSiaranPage'),
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
                        _buildTableControls(canWrite),
                        const SizedBox(height: 20),
                        if (provider.state == TemaSiaranViewState.Busy &&
                            provider.temas.isEmpty)
                          const Center(child: CircularProgressIndicator())
                        else if (provider.errorMessage != null)
                          Center(child: Text('Error: ${provider.errorMessage}'))
                        else
                          SizedBox(
                            width: double.infinity,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: _buildDataTable(provider, canWrite),
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

  Widget _buildTableControls(bool canWrite) {
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
                  color: AppColors.foreground.withOpacity(0.2),
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _entriesToShow,
                  items:
                      <String>['10', '25', '50', '100', 'All']
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
        Row(
          children: [
            SizedBox(
              width: 250,
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Search:',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 16),
            if (canWrite)
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Tambah Tema Siaran'),
                onPressed: () => _showAddEditDialog(canWrite: canWrite),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDataTable(TemaSiaranProvider provider, bool canWrite) {
    final paginatedData =
        _filteredData
            .take(int.tryParse(_entriesToShow) ?? _filteredData.length)
            .toList();
    return DataTable(
      columns: const [
        DataColumn(label: Text('Nama Tema')),
        DataColumn(label: Text('Default')),
        DataColumn(label: Text('Tanggal Aktif')),
        DataColumn(label: Text('Gambar Tema')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Hits')),
        DataColumn(label: Text('Tanggal\nPosting')),
        DataColumn(label: Text('Diposting\nOleh')),
        DataColumn(label: Text('Aksi')),
      ],
      rows:
          paginatedData.map((tema) {
            return DataRow(
              color: MaterialStateProperty.resolveWith<Color?>((
                Set<MaterialState> states,
              ) {
                if (tema.isDefault) return AppColors.success.withOpacity(0.05);
                return null;
              }),
              cells: [
                DataCell(Text(tema.namaTema)),
                DataCell(
                  tema.isDefault
                      ? Icon(Icons.star, color: AppColors.warning, size: 20)
                      : const SizedBox.shrink(),
                ),
                DataCell(
                  Text(
                    '${_rangeDateFormatter.format(tema.tanggalAktifMulai)} Sampai\n${_rangeDateFormatter.format(tema.tanggalAktifSelesai)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 200,
                    child: Image.network(
                      tema.temaImageUrl,
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
                  Icon(
                    tema.status
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color:
                        tema.status
                            ? AppColors.success
                            : AppColors.foreground.withOpacity(0.5),
                  ),
                ),
                DataCell(Text(tema.hits.toString())),
                DataCell(Text(_dateFormatter.format(tema.tanggalPosting))),
                DataCell(Text(tema.dipostingOleh)),
                DataCell(
                  Row(
                    children: [
                      if (canWrite) ...[
                        _actionButton(
                          icon: Icons.edit,
                          color: AppColors.primary,
                          tooltip: 'Edit Tema',
                          onPressed: () => _showAddEditDialog(tema: tema, canWrite: canWrite),
                        ),
                        const SizedBox(width: 8),
                        _actionButton(
                          icon: Icons.close,
                          color: AppColors.error,
                          tooltip: 'Delete Tema',
                          onPressed: () async => await provider.deleteTemaSiaran(tema.id),
                        ),
                        if (!tema.isDefault)
                          _actionButton(
                            icon: Icons.star_outline,
                            color: AppColors.warning,
                            tooltip: 'Set as Default',
                            onPressed: () async {
                              await provider.setAsDefault(tema.id);
                            },
                          ),
                      ]
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