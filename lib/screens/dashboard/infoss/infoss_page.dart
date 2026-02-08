import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:suara_surabaya_admin/core/theme/app_colors.dart';
import 'package:suara_surabaya_admin/models/dashboard/infoss/infoss_model.dart';
import 'package:suara_surabaya_admin/models/kategori_model.dart';
import 'package:suara_surabaya_admin/providers/auth/authentication_provider.dart';
import 'package:suara_surabaya_admin/providers/dashboard/infoss/infoss_provider.dart';
import 'package:suara_surabaya_admin/providers/kategori_provider.dart';
import 'package:suara_surabaya_admin/screens/dashboard/infoss/infoss_detail_page.dart';
import 'package:suara_surabaya_admin/widgets/common/custom_card.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

class InfossPage extends StatefulWidget {
  const InfossPage({super.key});

  @override
  State<InfossPage> createState() => _InfossPageState();
}

class _InfossPageState extends State<InfossPage> {
  final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd\nHH:mm:ss');

  // State untuk Sorting
  int? _sortColumnIndex;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    // Pastikan data awal dimuat saat halaman dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InfossProvider>().loadInitialData();
    });
  }

  // --- HELPER: Tampilkan Feedback (Toast/SnackBar) ---
  void _showFeedback(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // --- Modal Filter & Search ---
  Future<void> _showSearchFilterDialog() async {
    final provider = context.read<InfossProvider>();
    final TextEditingController queryController = TextEditingController();
    String searchField = 'Judul'; // Default
    DateTime startDate = DateTime.now().subtract(const Duration(days: 30));
    DateTime endDate = DateTime.now();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Filter & Cari Info SS'),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Rentang Tanggal",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 300,
                        child: SfDateRangePicker(
                          onSelectionChanged: (
                            DateRangePickerSelectionChangedArgs args,
                          ) {
                            if (args.value is PickerDateRange) {
                              startDate =
                                  args.value.startDate ?? DateTime.now();
                              endDate =
                                  args.value.endDate ??
                                  args.value.startDate ??
                                  DateTime.now();
                            }
                          },
                          selectionMode: DateRangePickerSelectionMode.range,
                          initialSelectedRange: PickerDateRange(
                            startDate,
                            endDate,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Kriteria Pencarian",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: searchField,
                              items:
                                  ['Judul', 'Kategori']
                                      .map(
                                        (label) => DropdownMenuItem(
                                          value: label,
                                          child: Text(label),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (value) {
                                if (value != null)
                                  setDialogState(() => searchField = value);
                              },
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: queryController,
                              decoration: const InputDecoration(
                                labelText: 'Kata Kunci...',
                                border: OutlineInputBorder(),
                              ),
                              onSubmitted:
                                  (_) => _doSearch(
                                    provider,
                                    searchField,
                                    queryController.text,
                                    startDate,
                                    endDate,
                                  ),
                            ),
                          ),
                        ],
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
                  onPressed:
                      () => _doSearch(
                        provider,
                        searchField,
                        queryController.text,
                        startDate,
                        endDate,
                      ),
                  child: const Text('Cari'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _doSearch(
    InfossProvider provider,
    String field,
    String query,
    DateTime start,
    DateTime end,
  ) {
    if (query.trim().isEmpty) return;

    // Inklusif sampai akhir hari
    final adjustedEnd = DateTime(end.year, end.month, end.day, 23, 59, 59);

    provider.searchInfoss(
      searchField: field,
      searchQuery: query,
      startDate: start,
      endDate: adjustedEnd,
    );
    Navigator.of(context).pop();
  }

  // --- Dialog Tambah/Edit dengan Feedback ---
  void _showAddEditDialog({InfossModel? infoss, required bool canWrite}) {
    final isEditing = infoss != null;
    final formKey = GlobalKey<FormState>();
    final judulController = TextEditingController(text: infoss?.judul);
    final detailController = TextEditingController(text: infoss?.detail);
    final locationController = TextEditingController(text: infoss?.location);
    String? selectedKategori = infoss?.kategori;
    Uint8List? selectedImageBytes;
    String? existingImageUrl = infoss?.gambar;

    showDialog(
      context: context,
      barrierDismissible: false, // Mencegah tutup tidak sengaja saat upload
      builder: (context) {
        final kategoriProvider = context.watch<KategoriProvider>();
        return StatefulBuilder(
          builder: (context, setDialogState) {
            bool isSaving = false;

            Future<void> pickImage() async {
              final ImagePicker picker = ImagePicker();
              final XFile? image = await picker.pickImage(
                source: ImageSource.gallery,
              );
              if (image != null) {
                final bytes = await image.readAsBytes();
                setDialogState(() {
                  selectedImageBytes = bytes;
                  existingImageUrl = null;
                });
              }
            }

            // Fungsi Simpan Internal
            Future<void> handleSave() async {
              if (formKey.currentState!.validate()) {
                setDialogState(() => isSaving = true);
                final provider = context.read<InfossProvider>();

                try {
                  String imageUrl = existingImageUrl ?? '';
                  // Upload gambar jika ada yang baru dipilih
                  if (selectedImageBytes != null) {
                    imageUrl = await provider.uploadImage(
                      selectedImageBytes!,
                      '${DateTime.now().millisecondsSinceEpoch}.jpg',
                    );
                  }

                  final model = InfossModel(
                    id: isEditing ? infoss!.id : '',
                    judul: judulController.text,
                    detail: detailController.text,
                    gambar: imageUrl,
                    kategori: selectedKategori!,
                    location: locationController.text,
                    uploadDate: isEditing ? infoss!.uploadDate : DateTime.now(),
                    jumlahComment: isEditing ? infoss!.jumlahComment : 0,
                    jumlahLike: isEditing ? infoss!.jumlahLike : 0,
                    jumlahShare: isEditing ? infoss!.jumlahShare : 0,
                    jumlahView: isEditing ? infoss!.jumlahView : 0,
                    latitude: isEditing ? infoss!.latitude : null,
                    longitude: isEditing ? infoss!.longitude : null,
                  );

                  bool success;
                  if (isEditing) {
                    success = await provider.updateInfoss(model);
                  } else {
                    success = await provider.addInfoss(model);
                  }

                  if (!mounted) return;

                  if (success) {
                    Navigator.pop(context); // Tutup dialog
                    _showFeedback(
                      isEditing
                          ? "Data berhasil diperbarui"
                          : "Data berhasil ditambahkan",
                    );
                  } else {
                    _showFeedback(
                      provider.errorMessage ?? "Gagal menyimpan data",
                      isError: true,
                    );
                  }
                } catch (e) {
                  if (mounted)
                    _showFeedback("Terjadi kesalahan: $e", isError: true);
                } finally {
                  if (mounted) setDialogState(() => isSaving = false);
                }
              }
            }

            return AlertDialog(
              title: Text(isEditing ? 'Edit Info SS' : 'Tambah Info SS'),
              content: Form(
                key: formKey,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.5,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Gambar Info SS",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: InkWell(
                            onTap: canWrite ? pickImage : null,
                            child:
                                selectedImageBytes != null
                                    ? Image.memory(
                                      selectedImageBytes!,
                                      fit: BoxFit.cover,
                                    )
                                    : (existingImageUrl != null &&
                                        existingImageUrl!.isNotEmpty)
                                    ? Image.network(
                                      existingImageUrl!,
                                      fit: BoxFit.cover,
                                    )
                                    : const Center(
                                      child: Icon(Icons.add_photo_alternate),
                                    ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: judulController,
                          readOnly: !canWrite,
                          decoration: const InputDecoration(
                            labelText: 'Judul',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v!.isEmpty ? 'Wajib' : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedKategori,
                          hint:
                              kategoriProvider.state == KategoriViewState.Busy
                                  ? const Text("Memuat...")
                                  : const Text('Pilih Kategori'),
                          items:
                              kategoriProvider.allKategori
                                  .where((k) => k.jenis == 'kategoriInfoSS')
                                  .map(
                                    (k) => DropdownMenuItem(
                                      value: k.namaKategori,
                                      child: Text(k.namaKategori),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              canWrite
                                  ? (v) =>
                                      setDialogState(() => selectedKategori = v)
                                  : null,
                          decoration: const InputDecoration(
                            labelText: 'Kategori',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v == null ? 'Pilih Kategori' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: detailController,
                          readOnly: !canWrite,
                          decoration: const InputDecoration(
                            labelText: 'Detail',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: locationController,
                          readOnly: !canWrite,
                          decoration: const InputDecoration(
                            labelText: 'Lokasi',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                if (canWrite)
                  ElevatedButton(
                    onPressed: isSaving ? null : handleSave,
                    child:
                        isSaving
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Text('Simpan'),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  // --- Fungsi Hapus dengan Konfirmasi & Feedback ---
  Future<void> _handleDelete(InfossProvider provider, String id) async {
    // Tampilkan dialog konfirmasi dulu
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Hapus Data'),
            content: const Text('Apakah Anda yakin ingin menghapus data ini?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Hapus',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (confirm == true) {
      final success = await provider.deleteInfoss(id);
      if (!mounted) return;

      if (success) {
        _showFeedback("Data berhasil dihapus");
      } else {
        _showFeedback(
          provider.errorMessage ?? "Gagal menghapus data",
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthenticationProvider>();
    final hakAkses = authProvider.user?.hakAkses ?? {};
    final String? accessLevel = hakAkses['infoSS'];
    final bool canWrite = accessLevel == 'write';

    return SafeArea(
      // 1. IMPLEMENTASI SAFE AREA DI ROOT
      child: Consumer<InfossProvider>(
        builder: (context, provider, child) {
          return Column(
            key: const PageStorageKey('infossPage'),
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
                          _buildTableControls(canWrite, provider),
                          const SizedBox(height: 20),
                          if (provider.state == InfossViewState.Busy &&
                              provider.infossList.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else if (provider.errorMessage != null)
                            Center(
                              child: Text(
                                'Error: ${provider.errorMessage}',
                                style: const TextStyle(color: Colors.red),
                              ),
                            )
                          else if (provider.infossList.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Text("Tidak ada data ditemukan."),
                              ),
                            )
                          else
                            Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: _buildDataTable(
                                      provider.infossList,
                                      canWrite,
                                      provider,
                                    ),
                                  ),
                                ),

                                // --- UPDATE LOGIKANYA DISINI ---
                                if (provider.showContinueSearchButton)
                                  _buildContinueSearchButton(provider)
                                // Tampilkan tombol jika ada data lebih DAN list tidak kosong
                                else if (provider.hasMoreData &&
                                    provider.infossList.isNotEmpty)
                                  _buildLoadMoreButton(provider),

                                // Tambahkan padding bawah agar tombol tidak mepet
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

  Widget _buildContinueSearchButton(InfossProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child:
          provider.state == InfossViewState.LoadingMore
              ? const CircularProgressIndicator()
              : Column(
                children: [
                  const Text("Hasil tidak ditemukan dalam 200 data pertama."),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.search),
                    onPressed: () => provider.continueSearch(),
                    label: const Text(
                      "Lanjutkan Pencarian (Scan 200 Berikutnya)",
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildLoadMoreButton(InfossProvider provider) {
    return Container(
      margin: const EdgeInsets.only(top: 20.0),
      width: double.infinity, // Buat tombol selebar container
      child:
          provider.state == InfossViewState.LoadingMore
              ? const Center(child: CircularProgressIndicator())
              : OutlinedButton.icon(
                onPressed: () => provider.continueSearch(),
                icon: const Icon(Icons.arrow_downward, size: 16),
                label: const Text("Muat Lebih Banyak Data (Load More)"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
    );
  }

  Widget _buildTableControls(bool canWrite, InfossProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.filter_list, size: 16),
              label: const Text('Filter & Cari'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
              ),
              onPressed: _showSearchFilterDialog,
            ),
            if (provider.isSearching) ...[
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => provider.resetSearch(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                ),
                child: const Tooltip(
                  message: 'Reset Filter',
                  child: Icon(Icons.refresh, size: 18),
                ),
              ),
            ],
          ],
        ),
        if (canWrite)
          ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Tambah Info SS'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            ),
            onPressed: () => _showAddEditDialog(canWrite: canWrite),
          ),
      ],
    );
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  Widget _buildDataTable(
    List<InfossModel> data,
    bool canWrite,
    InfossProvider provider,
  ) {
    int numCol = 0;
    final List<InfossModel> sortedData = List.from(data);
    if (_sortColumnIndex != null) {
      sortedData.sort((a, b) {
        int result = 0;
        switch (_sortColumnIndex) {
          case 0:
            result = a.judul.compareTo(b.judul);
            break;
          case 1:
            result = a.kategori.compareTo(b.kategori);
            break;
          case 2:
            result = a.jumlahView.compareTo(b.jumlahView);
            break;
          case 3:
            result = a.jumlahLike.compareTo(b.jumlahLike);
            break;
          case 4:
            result = a.jumlahComment.compareTo(b.jumlahComment);
            break;
          case 5:
            result = a.uploadDate.compareTo(b.uploadDate);
            break;
        }
        return _sortAscending ? result : -result;
      });
    }

    return Theme(
      data: Theme.of(context).copyWith(
        dataTableTheme: DataTableThemeData(
          headingRowColor: MaterialStateColor.resolveWith(
            (states) => AppColors.primary,
          ),
          headingTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      child: DataTable(
        sortColumnIndex: _sortColumnIndex,
        sortAscending: _sortAscending,
        columns: [
          const DataColumn(label: Text('No')),
          DataColumn(label: const Text('Judul'), onSort: _onSort),
          DataColumn(label: const Text('Kategori'), onSort: _onSort),
          DataColumn(
            label: const Text('Dilihat'),
            numeric: true,
            onSort: _onSort,
          ),
          DataColumn(label: const Text('Like'), numeric: true, onSort: _onSort),
          DataColumn(
            label: const Text('Comment'),
            numeric: true,
            onSort: _onSort,
          ),
          DataColumn(label: const Text('Tanggal\nPublish'), onSort: _onSort),
          const DataColumn(label: Text('Aksi')),
        ],
        rows:
            sortedData.map((item) {
              numCol += 1;
              return DataRow(
                cells: [
                  DataCell(Text(numCol.toString())),
                  DataCell(
                    SizedBox(
                      width: 250,
                      child: Text(item.judul, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  DataCell(Text(item.kategori)),
                  DataCell(Text(item.jumlahView.toString())),
                  DataCell(Text(item.jumlahLike.toString())),
                  DataCell(Text(item.jumlahComment.toString())),
                  DataCell(Text(_dateFormatter.format(item.uploadDate))),
                  DataCell(
                    Row(
                      children: [
                        _actionButton(
                          icon: Icons.search,
                          color: AppColors.warning,
                          tooltip: 'Lihat Detail',
                          onPressed:
                              () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          InfossDetailPage(infoss: item),
                                ),
                              ),
                        ),
                        const SizedBox(width: 4),
                        if (canWrite) ...[
                          _actionButton(
                            icon: Icons.edit,
                            color: AppColors.primary,
                            tooltip: 'Edit',
                            onPressed:
                                () => _showAddEditDialog(
                                  infoss: item,
                                  canWrite: true,
                                ),
                          ),
                          const SizedBox(width: 4),
                          // 2. IMPLEMENTASI DELETE DENGAN FEEDBACK
                          _actionButton(
                            icon: Icons.close,
                            color: AppColors.error,
                            tooltip: 'Hapus',
                            onPressed: () => _handleDelete(provider, item.id),
                          ),
                          const SizedBox(width: 4),
                        ],
                        _actionButton(
                          icon: Icons.notifications,
                          color: Colors.blue,
                          tooltip: 'Send Notification',
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
      ),
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
