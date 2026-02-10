import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:suara_surabaya_admin/core/theme/app_colors.dart';
import 'package:suara_surabaya_admin/models/dashboard/kawanss/kawanss_model.dart';
import 'package:suara_surabaya_admin/providers/auth/authentication_provider.dart';
import 'package:suara_surabaya_admin/providers/dashboard/kawanss/kawanss_post_provider.dart';
import 'package:suara_surabaya_admin/widgets/common/custom_card.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

class KawanssPostPage extends StatefulWidget {
  const KawanssPostPage({super.key});

  @override
  State<KawanssPostPage> createState() => _KawanssPostPageState();
}

class _KawanssPostPageState extends State<KawanssPostPage> {
  final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd\nHH:mm:ss');
  int? _sortColumnIndex;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KawanssPostProvider>().loadInitialData();
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

  Future<void> _handleDelete(KawanssPostProvider provider, String id) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Hapus Postingan'),
            content: const Text(
              'Apakah Anda yakin ingin menghapus postingan Kawan SS ini?',
            ),
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
      final success = await provider.deletePost(id);
      if (success)
        _showFeedback("Postingan berhasil dihapus");
      else
        _showFeedback(
          provider.errorMessage ?? "Gagal menghapus data",
          isError: true,
        );
    }
  }

  Future<void> _showSearchFilterDialog() async {
    final provider = context.read<KawanssPostProvider>();
    final TextEditingController queryController = TextEditingController();
    String searchField = 'Deskripsi';
    DateTime startDate = DateTime.now().subtract(const Duration(days: 30));
    DateTime endDate = DateTime.now();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Filter & Cari Kawan SS'),
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
                        children: [
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: searchField,
                              items:
                                  ['Deskripsi', 'User']
                                      .map(
                                        (label) => DropdownMenuItem(
                                          value: label,
                                          child: Text(label),
                                        ),
                                      )
                                      .toList(),
                              onChanged:
                                  (v) => setDialogState(() => searchField = v!),
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
                  onPressed: () => Navigator.pop(context),
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
    KawanssPostProvider provider,
    String field,
    String query,
    DateTime start,
    DateTime end,
  ) {
    if (query.trim().isEmpty) return;
    final adjustedEnd = DateTime(end.year, end.month, end.day, 23, 59, 59);
    provider.searchPosts(
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
      child: Consumer<KawanssPostProvider>(
        builder: (context, provider, child) {
          return Column(
            key: const PageStorageKey('kawanssPostPage'),
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

                          // Info Live Mode
                          if (provider.isLiveMode)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              color: Colors.red.withOpacity(0.1),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.sensors,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "LIVE MONITORING ACTIVE (Menampilkan 50 data terbaru secara realtime)",
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          if (provider.state == KawanssPostViewState.Busy &&
                              provider.posts.isEmpty)
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
                                style: const TextStyle(color: AppColors.error),
                              ),
                            )
                          else if (provider.posts.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Text("Tidak ada data ditemukan."),
                              ),
                            )
                          else
                            Column(
                              children: [
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    return SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: ConstrainedBox(
                                        // Paksa lebar MINIMAL sama dengan lebar layar yang tersedia
                                        constraints: BoxConstraints(
                                          minWidth: constraints.maxWidth,
                                        ),
                                        // HAPUS SizedBox(width: double.infinity) DI SINI
                                        // Langsung panggil tabelnya
                                        child: _buildDataTable(
                                      provider.posts,
                                      true,
                                      provider,
                                    ),
                                      ),
                                    );
                                  },
                                ),


                                // HANYA TAMPILKAN TOMBOL LOAD MORE JIKA TIDAK LIVE MODE
                                if (!provider.isLiveMode) ...[
                                  if (provider.showContinueSearchButton)
                                    _buildContinueSearchButton(provider)
                                  else if (provider.hasMoreData &&
                                      provider.posts.isNotEmpty)
                                    _buildLoadMoreButton(provider),
                                  const SizedBox(height: 30),
                                ],
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

  Widget _buildTableControls(KawanssPostProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // --- SWITCH LIVE MODE (KIRI) ---
        Row(
          children: [
            const Text(
              "Live Mode:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Switch(
              value: provider.isLiveMode,
              activeColor: Colors.red,
              onChanged: (val) => provider.toggleLiveMode(val),
            ),
          ],
        ),

        // --- FILTER & RESET (KANAN) - HANYA JIKA TIDAK LIVE ---
        if (!provider.isLiveMode)
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
      ],
    );
  }

  Widget _buildContinueSearchButton(KawanssPostProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: OutlinedButton.icon(
        icon: const Icon(Icons.search),
        onPressed: () => provider.continueSearch(),
        label: const Text("Lanjutkan Pencarian (Scan 200 Berikutnya)"),
      ),
    );
  }

  Widget _buildLoadMoreButton(KawanssPostProvider provider) {
    return Container(
      margin: const EdgeInsets.only(top: 20.0),
      width: double.infinity,
      child:
          provider.state == KawanssPostViewState.LoadingMore
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

  Widget _buildDataTable(
    List<KawanssModel> data,
    bool canWrite,
    KawanssPostProvider provider,
  ) {
    // Disable sorting jika Live Mode aktif (agar data tidak lompat2)
    final List<KawanssModel> sortedData = List.from(data);

    if (_sortColumnIndex != null && !provider.isLiveMode) {
      sortedData.sort((a, b) {
        int result = 0;
        switch (_sortColumnIndex) {
          case 0:
            result = (a.deskripsi ?? a.title ?? '').compareTo(
              b.deskripsi ?? b.title ?? '',
            );
            break;
          case 2:
            result = a.jumlahLaporan.compareTo(b.jumlahLaporan);
            break;
          case 3:
            result = a.jumlahLike.compareTo(b.jumlahLike);
            break;
          case 4:
            result = a.jumlahComment.compareTo(b.jumlahComment);
            break;
          case 6:
            result = a.uploadDate.compareTo(b.uploadDate);
            break;
          case 7:
            result = (a.accountName ?? '').compareTo(b.accountName ?? '');
            break;
        }
        return _sortAscending ? result : -result;
      });
    }

    int rowNum = 0;
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
          DataColumn(
            label: const Text('Judul / Deskripsi'),
            onSort: !provider.isLiveMode ? _onSort : null,
          ),
          const DataColumn(label: Text('Gambar')),
          DataColumn(
            label: const Text('Dilihat'),
            numeric: true,
            onSort: !provider.isLiveMode ? _onSort : null,
          ),
          DataColumn(
            label: const Text('Like'),
            numeric: true,
            onSort: !provider.isLiveMode ? _onSort : null,
          ),
          DataColumn(
            label: const Text('Comment'),
            numeric: true,
            onSort: !provider.isLiveMode ? _onSort : null,
          ),
          const DataColumn(label: Text('Status')),
          DataColumn(
            label: const Text('Tanggal\nPosting'),
            onSort: !provider.isLiveMode ? _onSort : null,
          ),
          DataColumn(
            label: const Text('Diposting\nOleh'),
            onSort: !provider.isLiveMode ? _onSort : null,
          ),
          const DataColumn(label: Text('Aksi')),
        ],
        rows:
            sortedData.map((item) {
              rowNum++;
              bool isActive = !item.deleted;
              String jenisStatus = item.deleted ? 'Dihapus' : 'Aktif';

              return DataRow(
                cells: [
                  DataCell(Text(rowNum.toString())),
                  DataCell(
                    SizedBox(
                      width: 250,
                      child: Text(
                        item.deskripsi ?? item.title ?? '-',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ),
                  DataCell(
                    (item.gambar != null && item.gambar!.isNotEmpty)
                        ? Container(
                          width: 80,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: Colors.grey[200],
                          ),
                          child: Image.network(
                            item.gambar!,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (ctx, err, stack) =>
                                    const Icon(Icons.broken_image, size: 20),
                          ),
                        )
                        : const Text('-'),
                  ),
                  DataCell(Text(item.jumlahLaporan.toString())),
                  DataCell(Text(item.jumlahLike.toString())),
                  DataCell(Text(item.jumlahComment.toString())),
                  DataCell(
                    Chip(
                      label: Text(
                        jenisStatus,
                        style: const TextStyle(fontSize: 10),
                      ),
                      backgroundColor:
                          isActive
                              ? AppColors.success.withOpacity(0.1)
                              : AppColors.error.withOpacity(0.1),
                      labelStyle: TextStyle(
                        color: isActive ? AppColors.success : AppColors.error,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                  ),
                  DataCell(Text(_dateFormatter.format(item.uploadDate))),
                  DataCell(
                    Text(
                      item.accountName ?? '-',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataCell(
                    Row(
                      children: [
                        _actionButton(
                          icon: Icons.delete_outline,
                          color: AppColors.error,
                          tooltip: 'Hapus Postingan',
                          onPressed: () => _handleDelete(provider, item.id),
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
        onPressed: onPressed,
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
