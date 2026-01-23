// lib/screens/dashboard/news_page.dart

import 'package:suara_surabaya_admin/core/theme/app_colors.dart';
import 'package:suara_surabaya_admin/models/dashboard/berita/berita_model.dart';
import 'package:suara_surabaya_admin/providers/dashboard/berita/berita_provider.dart';
import 'package:suara_surabaya_admin/widgets/common/custom_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class BeritaPage extends StatefulWidget {
  const BeritaPage({super.key});

  @override
  State<BeritaPage> createState() => _BeritaPageState();
}

class _BeritaPageState extends State<BeritaPage> {
  final TextEditingController _searchController = TextEditingController();
  String _entriesToShow = '10';
  final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd\nHH:mm:ss');

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BeritaProvider>(
      builder: (context, provider, child) {
        final query = _searchController.text.toLowerCase();
        final allData = provider.newsList;

       final List<BeritaModel> filteredData = query.isEmpty
            ? allData
            : allData.where((item) =>
                item.title.toLowerCase().contains(query) ||
                (item.info?.toLowerCase() ?? '').contains(query) ||
                item.category.toLowerCase().contains(query)
              ).toList();
        
        final int entriesCount = int.tryParse(_entriesToShow) ?? filteredData.length;
        final List<BeritaModel> paginatedData = filteredData.take(entriesCount).toList();
        // ---------------------------------------------

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CustomCard(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    _buildTableControls(),
                    const SizedBox(height: 20),
                    if (provider.state == BeritaViewState.Busy && provider.newsList.isEmpty)
                      const Expanded(child: Center(child: CircularProgressIndicator()))
                    else if (provider.errorMessage != null)
                      Expanded(child: Center(child: Text('Error: ${provider.errorMessage}')))
                    else
                      // --- PERBAIKAN UTAMA DI SINI ---
                      Expanded(
                        child: SingleChildScrollView(
                          // Scroll vertikal untuk seluruh tabel jika barisnya banyak
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            // Scroll horizontal untuk tabel jika kolomnya lebar
                            scrollDirection: Axis.horizontal,
                            child: _buildDataTable(paginatedData),
                          ),
                        ),
                      ),
                  ],
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
            const Text('Show'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.foreground.withValues(alpha: 0.2)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _entriesToShow,
                  items: <String>['10', '25', '50', '100', 'All'].map((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value));
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _entriesToShow = newValue!;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text('entries'),
          ],
        ),
        SizedBox(
          width: 250,
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(labelText: 'Search:'),
          ),
        ),
      ],
    );
  }

  Widget _buildDataTable(List<BeritaModel> data) {
    return DataTable(
      dataRowMaxHeight: 80,
      columns: const [
        DataColumn(label: Text('Judul')),
        DataColumn(label: Text('Lead')),
        DataColumn(label: Text('Category')),
        DataColumn(label: Text('Dilihat')),
        DataColumn(label: Text('Like')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Tanggal\nPosting')),
        DataColumn(label: Text('Diposting\nOleh')),
        DataColumn(label: Text('Aksi')),
      ],
      rows: data.map((item) {
        return DataRow(cells: [
          DataCell(SizedBox(width: 200, child: Text(item.title))),
          DataCell(SizedBox(width: 300, child: Text(item.info ?? item.jpg10Desc ?? '-', maxLines: 3, overflow: TextOverflow.ellipsis))),
          DataCell(Text(item.category)),
          DataCell(Text(item.jumlahView.toString())),
          DataCell(Text(item.jumlahLike.toString())),
          const DataCell(Icon(Icons.check_circle, color: AppColors.success)),
          DataCell(Text(item.uploadDate != null ? _dateFormatter.format(item.uploadDate!) : '-')),
          DataCell(Text(item.pengirim ?? '-')),
          DataCell(
            Row(
              children: [
                _actionButton(
                  icon: Icons.search, // Ikon kaca pembesar
                  color: AppColors.primary,
                  tooltip: 'Lihat Detail',
                  onPressed: () {
                    // TODO: Implementasi navigasi ke halaman detail berita
                    print('Lihat detail untuk berita ID: ${item.id}');
                  },
                ),
              ],
            ),
          ),
        ]);
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