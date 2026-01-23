// lib/screens/dashboard/report_data/kawanss_post_report_page.dart

import 'package:suara_surabaya_admin/core/theme/app_colors.dart';
import 'package:suara_surabaya_admin/models/dashboard/kawanss/kawanss_model.dart';
import 'package:suara_surabaya_admin/providers/dashboard/report/kawanss_post_report_provider.dart';
import 'package:suara_surabaya_admin/widgets/common/custom_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

class KawanssPostReportPage extends StatefulWidget {
  const KawanssPostReportPage({super.key});

  @override
  State<KawanssPostReportPage> createState() => _KawanssPostReportPageState();
}

class _KawanssPostReportPageState extends State<KawanssPostReportPage> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 6));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KawanssPostReportProvider>().generateReport(
        _startDate,
        _endDate,
      );
    });
  }

  // ... (Fungsi _onSelectionChanged, _showDateRangePicker, _exportToCsv biarkan sama)
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
                  context.read<KawanssPostReportProvider>().generateReport(
                    _startDate,
                    _endDate,
                  );
                },
              ),
            ],
          ),
    );
  }

  void _exportToCsv(KawanssPostReportProvider provider) {
    final csvData = provider.generateCsvData();
    print("CSV Data Generated:\n$csvData");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data CSV berhasil digenerate (Cek Console)'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<KawanssPostReportProvider>();
    final DateFormat formatter = DateFormat('dd MMM yyyy', 'id');
    final String dateRangeText =
        '${formatter.format(_startDate)} - ${formatter.format(_endDate)}';

    return SingleChildScrollView(
      // Agar bisa discroll jika konten panjang
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER & FILTER
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Laporan Kawan SS',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Analisis postingan dan engagement warga',
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

          // SUMMARY CARDS
          if (provider.state != ReportViewState.Busy)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  // Baris Pertama (Atas)
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          'Total Laporan',
                          provider.totalPosts.toString(),
                          Icons.campaign,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryCard(
                          'Total Likes',
                          provider.totalLikes.toString(),
                          Icons.thumb_up,
                          Colors.pink,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 16,
                  ), // Jarak antar baris (Vertical spacing)
                  // Baris Kedua (Bawah)
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          'Total Komentar',
                          provider.totalComments.toString(),
                          Icons.comment,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryCard(
                          'Hari Tersibuk',
                          provider.busiestDay,
                          Icons.local_fire_department,
                          Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // TABEL TOP POSTS
          if (provider.state != ReportViewState.Busy &&
              provider.topPosts.isNotEmpty)
            CustomCard(
              margin: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top 10 Laporan Warga (Berdasarkan Likes)',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: _buildTopPostsTable(provider.topPosts),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // TABEL DATA HARIAN
          CustomCard(
            margin: const EdgeInsets.symmetric(horizontal: 24.0),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Detail Data Harian',
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
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
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
                else if (provider.reportData.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('Tidak ada data pada rentang tanggal ini.'),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: _buildDailyDataTable(provider.reportData),
                  ),
              ],
            ),
          ),
        ],
      ),
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    title,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyDataTable(List<DailyKawanssReport> data) {
    return DataTable(
      headingRowColor: MaterialStateProperty.all(AppColors.primary),
      columns: const [
        DataColumn(
          label: Text('Tanggal', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        DataColumn(
          label: Text(
            'Jumlah Laporan',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        DataColumn(
          label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
      rows:
          data.map((report) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    DateFormat('dd MMMM yyyy', 'id').format(report.date),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                DataCell(
                  Text(
                    report.count.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: report.count > 0 ? AppColors.primary : Colors.grey,
                    ),
                  ),
                ),
                DataCell(
                  report.count > 0
                      ? Chip(
                        label: const Text(
                          'Aktif',
                          style: TextStyle(color: Colors.blue, fontSize: 10),
                        ),
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        padding: EdgeInsets.zero,
                      )
                      : const Text('-'),
                ),
              ],
            );
          }).toList(),
    );
  }

  Widget _buildTopPostsTable(List<KawanssModel> posts) {
    return DataTable(
      headingRowColor: MaterialStateProperty.all(AppColors.primary),
      columns: const [
        DataColumn(
          label: Text(
            'Isi Laporan / Judul',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        DataColumn(
          label: Text('Pelapor', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        DataColumn(
          label: Text('Tanggal', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        DataColumn(
          label: Text('Likes', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        DataColumn(
          label: Text(
            'Komentar',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
      rows:
          posts.map((post) {
            return DataRow(
              cells: [
                DataCell(
                  SizedBox(
                    width: 300,
                    child: Text(
                      post.deskripsi ?? post.title ?? '-',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(Text(post.accountName ?? 'Anonim')),
                DataCell(
                  Text(DateFormat('dd/MM/yy HH:mm').format(post.uploadDate)),
                ),
                DataCell(
                  Text(
                    post.jumlahLike.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.pink,
                    ),
                  ),
                ),
                DataCell(Text(post.jumlahComment.toString())),
              ],
            );
          }).toList(),
    );
  }
}
