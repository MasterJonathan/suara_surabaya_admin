import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:suara_surabaya_admin/core/theme/app_colors.dart';
import 'package:suara_surabaya_admin/models/dashboard/kawanss/kawanss_comment_model.dart';
import 'package:suara_surabaya_admin/providers/dashboard/kawanss/kawanss_post_provider.dart';
import 'package:suara_surabaya_admin/widgets/common/custom_card.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

class KawanssCommentPage extends StatefulWidget {
  const KawanssCommentPage({super.key});

  @override
  State<KawanssCommentPage> createState() => _KawanssCommentPageState();
}

class _KawanssCommentPageState extends State<KawanssCommentPage> {
  final DateFormat _dateFormatter = DateFormat('dd MMM yyyy\nHH:mm');
  int? _sortColumnIndex;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    // Init Load (Manual Mode default)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KawanssPostProvider>().loadInitialComments();
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
    final provider = context.read<KawanssPostProvider>();
    final TextEditingController queryController = TextEditingController();
    String searchField = 'Komentar';
    DateTime startDate = DateTime.now().subtract(const Duration(days: 30));
    DateTime endDate = DateTime.now();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Filter & Cari Komentar'),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Rentang Tanggal Posting",
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
                                  ['Komentar', 'User']
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
    provider.searchComments(
      searchField: field,
      searchQuery: query,
      startDate: start,
      endDate: adjustedEnd,
    );
    Navigator.of(context).pop();
  }

  // --- ACTIONS ---
  Future<void> _handleToggleStatus(
    KawanssPostProvider provider,
    KawanssCommentModel item,
  ) async {
    final success = await provider.toggleCommentStatus(item.id, item.deleted);
    if (success) {
      _showFeedback(
        item.deleted ? "Komentar dipulihkan" : "Komentar dihapus (soft)",
      );
    } else {
      _showFeedback("Gagal mengubah status komentar", isError: true);
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
      child: Consumer<KawanssPostProvider>(
        builder: (context, provider, child) {
          return Column(
            key: const PageStorageKey('kawanssCommentPage'),
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
                          Text(
                            "Manajemen Komentar Kawan SS",
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 20),

                          _buildTableControls(provider),
                          const SizedBox(height: 20),

                          // INFO LIVE MODE
                          if (provider.isCommentLiveMode)
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
                                    "LIVE MONITORING ACTIVE (50 Komentar Terbaru Realtime)",
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // TABLE & CONTENT
                          if (provider.state == KawanssPostViewState.Busy &&
                              provider.comments.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else if (provider.errorMessage != null)
                            Center(
                              child: Text(
                                'Error: ${provider.errorMessage} (Cek Log)',
                                style: const TextStyle(color: AppColors.error),
                              ),
                            )
                          else if (provider.comments.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Text("Tidak ada komentar ditemukan."),
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
                                        child: _buildDataTable(provider),
                                      ),
                                    );
                                  },
                                ),
                                // PAGINATION (Hanya di Manual Mode)
                                if (!provider.isCommentLiveMode) ...[
                                  if (provider.showContinueCommentSearch)
                                    _buildContinueSearchButton(provider)
                                  else if (provider.hasMoreComments &&
                                      provider.comments.isNotEmpty)
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
        // --- LIVE SWITCH ---
        Row(
          children: [
            const Text(
              "Live Mode:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Switch(
              value: provider.isCommentLiveMode,
              activeColor: Colors.red,
              onChanged: (val) => provider.toggleCommentLiveMode(val),
            ),
          ],
        ),

        // --- FILTER (ONLY MANUAL) ---
        if (!provider.isCommentLiveMode)
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
                  onPressed: () => provider.resetCommentSearch(),
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
        onPressed: () => provider.continueCommentSearch(),
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
                onPressed: () => provider.continueCommentSearch(),
                icon: const Icon(Icons.arrow_downward, size: 16),
                label: const Text("Muat Lebih Banyak Data (Load More)"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
    );
  }

  Widget _buildDataTable(KawanssPostProvider provider) {
    // Disable sort di Live Mode
    final List<KawanssCommentModel> sortedData = List.from(provider.comments);
    if (_sortColumnIndex != null && !provider.isCommentLiveMode) {
      sortedData.sort((a, b) {
        int result = 0;
        switch (_sortColumnIndex) {
          case 0:
            result = a.username.compareTo(b.username);
            break;
          case 1:
            result = a.comment.compareTo(b.comment);
            break;
          case 2:
            result = a.uploadDate.compareTo(b.uploadDate);
            break;
          case 3:
            result = (a.deleted ? 1 : 0).compareTo(b.deleted ? 1 : 0);
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
          DataColumn(
            label: const Text('User'),
            onSort: !provider.isCommentLiveMode ? _onSort : null,
          ),
          DataColumn(
            label: const Text('Komentar'),
            onSort: !provider.isCommentLiveMode ? _onSort : null,
          ),
          DataColumn(
            label: const Text('Tanggal'),
            onSort: !provider.isCommentLiveMode ? _onSort : null,
          ),
          DataColumn(
            label: const Text('Status'),
            onSort: !provider.isCommentLiveMode ? _onSort : null,
          ),
          const DataColumn(label: Text('Aksi')),
        ],
        rows:
            sortedData.map((item) {
              bool isDeleted = item.deleted;
              return DataRow(
                cells: [
                  DataCell(
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundImage:
                              (item.photoURL?.isNotEmpty ?? false)
                                  ? NetworkImage(item.photoURL!)
                                  : null,
                          child:
                              (item.photoURL?.isEmpty ?? true)
                                  ? const Icon(Icons.person, size: 16)
                                  : null,
                          radius: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.username,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 300,
                      child: Text(
                        item.comment,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(Text(_dateFormatter.format(item.uploadDate))),
                  DataCell(
                    Chip(
                      label: Text(isDeleted ? 'Dihapus' : 'Aktif'),
                      backgroundColor:
                          isDeleted
                              ? AppColors.error.withOpacity(0.1)
                              : AppColors.success.withOpacity(0.1),
                      labelStyle: TextStyle(
                        color: isDeleted ? AppColors.error : AppColors.success,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      children: [
                        _actionButton(
                          icon:
                              isDeleted
                                  ? Icons.restore_from_trash
                                  : Icons.delete_outline,
                          color:
                              isDeleted ? AppColors.success : AppColors.error,
                          tooltip:
                              isDeleted
                                  ? 'Pulihkan Komentar'
                                  : 'Hapus Komentar (Soft)',
                          onPressed: () => _handleToggleStatus(provider, item),
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
