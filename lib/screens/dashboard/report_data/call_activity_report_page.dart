import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:suara_surabaya_admin/core/theme/app_colors.dart';
import 'package:suara_surabaya_admin/models/dashboard/report/call_activity_report_model.dart';
import 'package:suara_surabaya_admin/providers/dashboard/report/call_activity_report_provider.dart';
import 'package:suara_surabaya_admin/widgets/common/custom_card.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

class CallActivityReportPage extends StatefulWidget {
  const CallActivityReportPage({super.key});

  @override
  State<CallActivityReportPage> createState() => _CallActivityReportPageState();
}

class _CallActivityReportPageState extends State<CallActivityReportPage> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 6));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CallActivityReportProvider>().generateReport(
        _startDate,
        _endDate,
      );
    });
  }

  void _onSelectionChanged(DateRangePickerSelectionChangedArgs args) {
    if (args.value is PickerDateRange) {
      final PickerDateRange range = args.value;
      if (range.startDate != null && range.endDate != null) {
        setState(() {
          _startDate = range.startDate!;
          _endDate = range.endDate!;
        });
      }
    }
  }

  void _showDateRangePicker() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Pilih Rentang Tanggal'),
            content: SizedBox(
              width: 350,
              height: 350,
              child: SfDateRangePicker(
                onSelectionChanged: _onSelectionChanged,
                selectionMode: DateRangePickerSelectionMode.range,
                initialSelectedRange: PickerDateRange(_startDate, _endDate),
                maxDate: DateTime.now(),
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Batal'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text('Terapkan'),
                onPressed: () {
                  Navigator.of(context).pop();
                  context.read<CallActivityReportProvider>().generateReport(
                    _startDate,
                    _endDate,
                  );
                },
              ),
            ],
          ),
    );
  }

  void _exportToCsv(CallActivityReportProvider provider) {
    final csvData = provider.generateCsvData();
    print("CSV Generated:\n$csvData");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'CSV berhasil digenerate (Implementasi download di web/desktop)',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CallActivityReportProvider>();
    final DateFormat formatter = DateFormat('dd MMM yyyy', 'id');
    final String dateRangeText =
        '${formatter.format(_startDate)} - ${formatter.format(_endDate)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- HEADER ---
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Laporan Aktivitas Panggilan',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Analisis trafik panggilan (Voice & Video) per jam',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextButton.icon(
                  onPressed: _showDateRangePicker,
                  icon: const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    dateRangeText,
                    style: const TextStyle(color: Colors.black87),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // --- SUMMARY CARDS ---
        if (provider.state != ReportViewState.Busy)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: [
                _buildSummaryCard(
                  'Total Panggilan',
                  provider.totalCalls.toString(),
                  Icons.call,
                  Colors.blue,
                ),
                const SizedBox(width: 16),
                _buildSummaryCard(
                  'Voice Call',
                  provider.totalVoice.toString(),
                  Icons.phone_in_talk,
                  Colors.green,
                ),
                const SizedBox(width: 16),
                _buildSummaryCard(
                  'Video Call',
                  provider.totalVideo.toString(),
                  Icons.videocam,
                  Colors.orange,
                ),
                const SizedBox(width: 16),
                _buildSummaryCard(
                  'Jam Tersibuk',
                  provider.busiestHour,
                  Icons.access_time_filled,
                  Colors.purple,
                ),
              ],
            ),
          ),

        const SizedBox(height: 24),

        // --- TABEL DATA ---
        Expanded(
          child: CustomCard(
            margin: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Detail Trafik Per Jam',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _exportToCsv(provider),
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text('Export CSV'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (provider.state == ReportViewState.Busy)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (provider.errorMessage != null)
                  Expanded(
                    child: Center(
                      child: Text(
                        'Error: ${provider.errorMessage}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  )
                else if (provider.reportData.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Tidak ada data panggilan pada rentang tanggal ini.',
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: _buildDataTable(provider.reportData),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable(List<CallHourlyReport> data) {
    // Definisi Kolom: Tanggal, Voice, Video, Total, Jam 00-23
    final List<DataColumn> columns = [
      const DataColumn(
        label: Text('Tanggal', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      const DataColumn(
        label: Text(
          'Voice',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
        ),
      ),
      const DataColumn(
        label: Text(
          'Video',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
        ),
      ),
      const DataColumn(
        label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      ...List.generate(
        24,
        (index) => DataColumn(
          label: Center(
            child: Text(
              '${index.toString().padLeft(2, '0')}:00',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ),
      ),
    ];

    return DataTable(
      headingRowColor: MaterialStateProperty.all(AppColors.primary),
      columns: columns,
      rows:
          data.map((report) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    DateFormat('dd MMM yyyy', 'id').format(report.date),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                DataCell(
                  Text(
                    report.totalVoiceCalls.toString(),
                    style: const TextStyle(color: Colors.green),
                  ),
                ),
                DataCell(
                  Text(
                    report.totalVideoCalls.toString(),
                    style: const TextStyle(color: Colors.orange),
                  ),
                ),
                DataCell(
                  Text(
                    report.dailyTotal.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ...List.generate(24, (hour) {
                  final count = report.hourlyCounts[hour] ?? 0;
                  return DataCell(
                    Center(
                      child: Text(
                        count == 0 ? '-' : count.toString(),
                        style: TextStyle(
                          color:
                              count > 0
                                  ? AppColors.primary
                                  : Colors.grey.shade300,
                          fontWeight:
                              count > 0 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          }).toList(),
    );
  }
}
