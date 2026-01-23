// lib/screens/dashboard/infoss/infoss_page.dart

import 'dart:typed_data';

import 'package:suara_surabaya_admin/core/theme/app_colors.dart';
import 'package:suara_surabaya_admin/models/dashboard/infoss/infoss_model.dart';
import 'package:suara_surabaya_admin/models/kategori_model.dart';
import 'package:suara_surabaya_admin/providers/auth/authentication_provider.dart';
import 'package:suara_surabaya_admin/providers/dashboard/infoss/infoss_provider.dart';
import 'package:suara_surabaya_admin/providers/kategori_provider.dart';
import 'package:suara_surabaya_admin/screens/dashboard/infoss/infoss_detail_page.dart';
import 'package:suara_surabaya_admin/widgets/common/custom_card.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class InfossPage extends StatefulWidget {
  const InfossPage({super.key});

  @override
  State<InfossPage> createState() => _InfossPageState();
}

class _InfossPageState extends State<InfossPage> {
  final TextEditingController _searchController = TextEditingController();
  final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd\nHH:mm:ss');
  String _entriesToShow = '10';

  // --- STATE BARU UNTUK FILTER TANGGAL ---
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30)); // Default 30 hari terakhir
  DateTime _endDate = DateTime.now();
  // ---------------------------------------

  @override
  void initState() {
    super.initState();
    // Tidak perlu listener search controller otomatis lagi, karena kita pakai tombol Search
    // Load data awal (Realtime) dipanggil otomatis oleh init Provider
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- FUNGSI BARU: Trigger Search di Provider ---
  void _doSearch({bool isLoadMore = false}) {
    context.read<InfossProvider>().searchInfoss(
      searchQuery: _searchController.text,
      startDate: _startDate,
      endDate: _endDate,
      isLoadMore: isLoadMore,
    );
  }

  // --- FUNGSI BARU: Reset ke Mode Realtime ---
  void _resetSearch() {
    _searchController.clear();
    setState(() {
      _startDate = DateTime.now().subtract(const Duration(days: 30));
      _endDate = DateTime.now();
    });
    // Kirim query kosong untuk kembali ke mode realtime stream
    context.read<InfossProvider>().searchInfoss(
      searchQuery: '', 
      startDate: _startDate, 
      endDate: _endDate
    );
  }

  // --- FUNGSI BARU: Date Picker ---
  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: AppColors.primary,
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _showAddEditDialog({InfossModel? infoss, required bool canWrite}) {
    // ... (Isi fungsi dialog biarkan SAMA SEPERTI SEBELUMNYA)
    // Saya persingkat di sini agar fokus ke Table Controls
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
      builder: (context) {
        final kategoriProvider = context.watch<KategoriProvider>();
        return StatefulBuilder(
          builder: (context, setDialogState) {
            bool isSaving = false;
            Future<void> pickImage() async {
              final ImagePicker picker = ImagePicker();
              final XFile? image = await picker.pickImage(source: ImageSource.gallery);
              if (image != null) {
                final bytes = await image.readAsBytes();
                setDialogState(() {
                  selectedImageBytes = bytes;
                  existingImageUrl = null;
                });
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
                         const Text("Gambar Info SS", style: TextStyle(fontWeight: FontWeight.bold)),
                         const SizedBox(height: 8),
                         Container(
                          height: 200, width: double.infinity,
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                          child: InkWell(
                            onTap: canWrite ? pickImage : null,
                            child: selectedImageBytes != null ? Image.memory(selectedImageBytes!, fit: BoxFit.cover) : (existingImageUrl != null && existingImageUrl!.isNotEmpty) ? Image.network(existingImageUrl!, fit: BoxFit.cover) : const Center(child: Icon(Icons.add_photo_alternate)),
                          ),
                         ),
                         const SizedBox(height: 16),
                         TextFormField(controller: judulController, readOnly: !canWrite, decoration: const InputDecoration(labelText: 'Judul', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Wajib' : null),
                         const SizedBox(height: 16),
                         DropdownButtonFormField<String>(
                          value: selectedKategori,
                          hint: kategoriProvider.state == KategoriViewState.Busy ? const Text("Memuat...") : const Text('Pilih Kategori'),
                          items: kategoriProvider.allKategori.where((k) => k.jenis == 'kategoriInfoSS').map((k) => DropdownMenuItem(value: k.namaKategori, child: Text(k.namaKategori))).toList(),
                          onChanged: canWrite ? (v) => setDialogState(() => selectedKategori = v) : null,
                          decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder()),
                         ),
                         const SizedBox(height: 16),
                         TextFormField(controller: detailController, readOnly: !canWrite, decoration: const InputDecoration(labelText: 'Detail', border: OutlineInputBorder()), maxLines: 3),
                         const SizedBox(height: 16),
                         TextFormField(controller: locationController, readOnly: !canWrite, decoration: const InputDecoration(labelText: 'Lokasi', border: OutlineInputBorder())),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                if (canWrite) ElevatedButton(onPressed: isSaving ? null : () async {
                   if (formKey.currentState!.validate()) {
                     setDialogState(() => isSaving = true);
                     final provider = context.read<InfossProvider>();
                     String imageUrl = existingImageUrl ?? '';
                     try {
                        if (selectedImageBytes != null) {
                          imageUrl = await provider.uploadImage(selectedImageBytes!, '${DateTime.now().millisecondsSinceEpoch}.jpg');
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
                        if (isEditing) await provider.updateInfoss(model); else await provider.addInfoss(model);
                        if (mounted) Navigator.pop(context);
                     } catch(e) { print(e); } finally { if(mounted) setDialogState(() => isSaving = false); }
                   }
                }, child: isSaving ? const CircularProgressIndicator() : const Text('Simpan'))
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthenticationProvider>();
    final hakAkses = authProvider.user?.hakAkses ?? {};
    final String? accessLevel = hakAkses['infoSS'];
    final bool canWrite = accessLevel == 'write';

    return Consumer<InfossProvider>(
      builder: (context, provider, child) {
        // --- PERBAIKAN: Hapus logika filter client-side lama ---
        // Kita gunakan list langsung dari provider karena provider yang mengurus
        // apakah itu list realtime atau list hasil search.
        final displayData = provider.infossList; 
        // -------------------------------------------------------

        return Column(
          key: const PageStorageKey('infossPage'),
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
                        _buildTableControls(canWrite, provider), // Kirim provider untuk cek status
                        const SizedBox(height: 20),
                        
                        // Tampilan Loading / Error / Data
                        if (provider.state == InfossViewState.Busy && provider.infossList.isEmpty)
                          const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                        else if (provider.errorMessage != null)
                          Center(child: Text('Error: ${provider.errorMessage}', style: const TextStyle(color: Colors.red)))
                        else if (displayData.isEmpty)
                          const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Tidak ada data ditemukan.")))
                        else
                          Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: _buildDataTable(provider, displayData, canWrite),
                                ),
                              ),
                              // Tombol Load More (Hanya muncul jika mode search dan masih ada data)
                              if (provider.isSearching && provider.hasMoreData)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16.0),
                                  child: provider.state == InfossViewState.LoadingMore
                                      ? const CircularProgressIndicator()
                                      : OutlinedButton(
                                          onPressed: () => _doSearch(isLoadMore: true),
                                          child: const Text("Load More"),
                                        ),
                                ),
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
    );
  }

  // --- PERBAIKAN UTAMA: Update Controls dengan Date Picker & Search Button ---
  Widget _buildTableControls(bool canWrite, InfossProvider provider) {
    final dateText = '${DateFormat('dd/MM/yy').format(_startDate)} - ${DateFormat('dd/MM/yy').format(_endDate)}';

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 16.0,
      spacing: 16.0,
      children: [
        // BAGIAN KIRI: Filter & Search
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Date Picker
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.foreground.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: TextButton.icon(
                onPressed: _pickDateRange,
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(dateText, style: const TextStyle(color: Colors.black87)),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18)),
              ),
            ),
            const SizedBox(width: 16),

            // 2. Search Field
            SizedBox(
              width: 250,
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Cari Judul...',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _doSearch(), // Enter untuk search
              ),
            ),
            const SizedBox(width: 8),

            // 3. Tombol Search
            ElevatedButton(
              onPressed: () => _doSearch(),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                backgroundColor: Colors.blueAccent,
              ),
              child: const Icon(Icons.search, size: 18, color: Colors.white),
            ),

            // 4. Tombol Reset (Jika sedang searching)
            if (provider.isSearching) ...[
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _resetSearch,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                ),
                child: const Icon(Icons.refresh, size: 18),
              ),
            ],
          ],
        ),

        // BAGIAN KANAN: Tambah Data
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
  // -----------------------------------------------------------------------

  Widget _buildDataTable(InfossProvider provider, List<InfossModel> data, bool canWrite) {
    return DataTable(
      columns: const [
        DataColumn(label: Text('Judul')),
        DataColumn(label: Text('Kategori')),
        DataColumn(label: Text('Dilihat')),
        DataColumn(label: Text('Like')),
        DataColumn(label: Text('Comment')),
        DataColumn(label: Text('Tanggal\nPublish')),
        DataColumn(label: Text('Aksi')),
      ],
      rows: data.map((item) {
        return DataRow(
          cells: [
            DataCell(SizedBox(width: 250, child: Text(item.judul))),
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
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => InfossDetailPage(infoss: item),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  if (canWrite) ...[
                    _actionButton(icon: Icons.edit, color: AppColors.primary, tooltip: 'Edit', onPressed: () => _showAddEditDialog(infoss: item, canWrite: true)),
                    const SizedBox(width: 4),
                    _actionButton(icon: Icons.close, color: AppColors.error, tooltip: 'Hapus', onPressed: () async => await provider.deleteInfoss(item.id)),
                    const SizedBox(width: 4),
                  ],
                  _actionButton(icon: Icons.notifications, color: Colors.blue, tooltip: 'Send Notification'),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _actionButton({required IconData icon, required Color color, required String tooltip, VoidCallback? onPressed}) {
    return SizedBox(
      width: 32,
      height: 32,
      child: ElevatedButton(
        onPressed: onPressed ?? () {},
        style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: AppColors.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)), padding: EdgeInsets.zero),
        child: Tooltip(message: tooltip, child: Icon(icon, size: 16)),
      ),
    );
  }
}