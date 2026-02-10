import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:suara_surabaya_admin/core/theme/app_colors.dart';
import 'package:suara_surabaya_admin/models/dashboard/call/call_history_log_model.dart';
import 'package:suara_surabaya_admin/providers/dashboard/call/call_history_provider.dart';
import 'package:suara_surabaya_admin/widgets/common/custom_card.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

class CallHistoryPage extends StatefulWidget {
  const CallHistoryPage({super.key});

  @override
  State<CallHistoryPage> createState() => _CallHistoryPageState();
}

class _CallHistoryPageState extends State<CallHistoryPage> {
  final DateFormat _dateFormatter = DateFormat('dd MMM yyyy, HH:mm');
  final TextEditingController _searchController = TextEditingController();

  // Sort State
  int? _sortColumnIndex;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CallHistoryProvider>().loadInitialData();
    });
  }

  // --- FILTER DIALOG ---
  Future<void> _showFilterDialog() async {
    final provider = context.read<CallHistoryProvider>();
    DateTime startDate = DateTime.now().subtract(const Duration(days: 7));
    DateTime endDate = DateTime.now();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Filter History Panggilan'),
              content: SizedBox(
                width: 450,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        labelText: 'Cari Nama Penelpon',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Rentang Tanggal",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: SfDateRangePicker(
                        selectionMode: DateRangePickerSelectionMode.range,
                        initialSelectedRange: PickerDateRange(
                          startDate,
                          endDate,
                        ),
                        onSelectionChanged: (args) {
                          if (args.value is PickerDateRange) {
                            startDate = args.value.startDate ?? DateTime.now();
                            endDate =
                                args.value.endDate ??
                                args.value.startDate ??
                                DateTime.now();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Tambahkan 1 hari ke endDate agar inklusif (sampai jam 23:59)
                    final adjustedEnd = DateTime(
                      endDate.year,
                      endDate.month,
                      endDate.day,
                      23,
                      59,
                      59,
                    );

                    provider.searchCalls(
                      searchQuery: _searchController.text,
                      startDate: startDate,
                      endDate: adjustedEnd,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Terapkan Filter'),
                ),
              ],
            );
          },
        );
      },
    );
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
      child: Consumer<CallHistoryProvider>(
        builder: (context, provider, child) {
          return Column(
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Riwayat Panggilan",
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.filter_list, size: 16),
                                label: const Text("Filter & Cari"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                ),
                                onPressed: _showFilterDialog,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          if (provider.state == CallHistoryViewState.Busy &&
                              provider.calls.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else if (provider.calls.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Text("Belum ada riwayat panggilan."),
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
                                        constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                        // HAPUS SizedBox(width: double.infinity) DI SINI
                                        // Langsung panggil tabelnya
                                        child: _buildDataTable(provider),
                                      ),
                                    );
                                  },
                                ),

                                if (provider.hasMoreData)
                                  Container(
                                    margin: const EdgeInsets.only(top: 20),
                                    width: double.infinity,
                                    child:
                                        provider.state ==
                                                CallHistoryViewState.LoadingMore
                                            ? const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            )
                                            : OutlinedButton.icon(
                                              onPressed:
                                                  () =>
                                                      provider.continueSearch(),
                                              icon: const Icon(
                                                Icons.arrow_downward,
                                              ),
                                              label: const Text(
                                                "Load More History",
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 16,
                                                    ),
                                              ),
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
      ),
    );
  }

  Widget _buildDataTable(CallHistoryProvider provider) {
    final List<CallHistoryLogModel> sortedData = List.from(provider.calls);

    if (_sortColumnIndex != null) {
      sortedData.sort((a, b) {
        int result = 0;
        switch (_sortColumnIndex) {
          case 0:
            result = a.callerName.compareTo(b.callerName);
            break;
          case 2:
            result = a.status.compareTo(b.status);
            break;
          case 3:
            result = a.createdAt.compareTo(b.createdAt);
            break;
        }
        return _sortAscending ? result : -result;
      });
    }

    return DataTable(
      sortColumnIndex: _sortColumnIndex,
      sortAscending: _sortAscending,
      headingRowColor: MaterialStateColor.resolveWith(
        (states) => AppColors.primary,
      ),
      columns: [
        DataColumn(label: const Text('Penelpon'), onSort: _onSort),
        const DataColumn(label: Text('Tipe')),
        DataColumn(label: const Text('Status'), onSort: _onSort),
        DataColumn(label: const Text('Waktu Panggilan'), onSort: _onSort),
        const DataColumn(label: Text('Durasi')),
        const DataColumn(label: Text('Admin Penerima')),
      ],
      rows:
          sortedData.map((log) {
            return DataRow(
              cells: [
                DataCell(
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundImage:
                            log.callerPhotoURL.isNotEmpty
                                ? NetworkImage(log.callerPhotoURL)
                                : null,
                        child:
                            log.callerPhotoURL.isEmpty
                                ? const Icon(Icons.person, size: 14)
                                : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        log.callerName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                DataCell(
                  Icon(
                    log.isVideoCall ? Icons.videocam : Icons.phone,
                    color: log.isVideoCall ? Colors.purple : Colors.blue,
                    size: 20,
                  ),
                ),
                DataCell(_buildStatusChip(log.status)),
                DataCell(Text(_dateFormatter.format(log.createdAt))),
                DataCell(
                  Text(
                    log.duration.inSeconds > 0
                        ? "${log.duration.inMinutes}:${(log.duration.inSeconds % 60).toString().padLeft(2, '0')}"
                        : "-",
                  ),
                ),
                DataCell(
                  Text(
                    log.adminName ?? '-',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ), // Bisa dikembangkan fetch nama admin by ID
              ],
            );
          }).toList(),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'accepted':
        color = Colors.green;
        label = 'Diterima';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Ditolak Admin';
        break;
      case 'timeout':
        color = Colors.orange;
        label = 'Tak Terjawab';
        break;
      case 'cancelled':
        color = Colors.grey;
        label = 'Dibatalkan User';
        break;
      case 'completed':
        color = Colors.blue;
        label = 'Selesai';
        break;
      case 'missed':
        color = Colors.redAccent;
        label = 'Missed Call';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Chip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 11, color: Colors.white),
      ),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
    );
  }
}
