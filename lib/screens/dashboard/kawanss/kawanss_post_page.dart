import 'package:suara_surabaya_admin/core/theme/app_colors.dart';
import 'package:suara_surabaya_admin/models/dashboard/kawanss/kawanss_model.dart';
import 'package:suara_surabaya_admin/providers/dashboard/kawanss/kawanss_post_provider.dart';
import 'package:suara_surabaya_admin/widgets/common/custom_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class KawanssPostPage extends StatefulWidget {
  const KawanssPostPage({super.key});

  @override
  State<KawanssPostPage> createState() => _KawanssPostPageState();
}

class _KawanssPostPageState extends State<KawanssPostPage> {
  final TextEditingController _searchController = TextEditingController();
  final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd\nHH:mm:ss');
  String _entriesToShow = '10'; 

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
    return Consumer<KawanssPostProvider>(
      builder: (context, provider, child) {
        List<KawanssModel> filteredData;
        final query = _searchController.text.toLowerCase();
        final allData = provider.posts;

        if (query.isEmpty) {
          filteredData = allData;
        } else {
          filteredData = allData.where((item) =>
            (item.deskripsi?.toLowerCase() ?? '').contains(query) ||
            (item.accountName?.toLowerCase() ?? '').contains(query)
          ).toList();
        }
        
        
        final paginatedData = filteredData.take(int.tryParse(_entriesToShow) ?? 10).toList();

        return Column(
          key: const PageStorageKey('kontributorPostPage'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: CustomCard(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      
                      _buildTableControls(),
                      const SizedBox(height: 20),
                      if (provider.state == KawanssPostViewState.Busy && provider.posts.isEmpty)
                        const Center(child: CircularProgressIndicator())
                      else if (provider.errorMessage != null)
                        Center(child: Text('Error: ${provider.errorMessage}', style: const TextStyle(color: AppColors.error)))
                      else
                        SizedBox(
                          width: double.infinity,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: _buildDataTable(provider, paginatedData), 
                          ),
                        ),
                    ],
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
                  items: <String>['10', '25', '50', '100'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
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
            decoration: const InputDecoration(
              labelText: 'Search',
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ),
      ],
    );
  }
  

  

  

  Widget _buildDataTable(KawanssPostProvider provider, List<KawanssModel> dataToShow) {
    return DataTable(
      
      
      dataRowMinHeight: 16.0, 
      dataRowMaxHeight: 120.0, 
      
      
      columns: const [
        DataColumn(label: Text('Judul')),
        DataColumn(label: Text('Gambar')),
        DataColumn(label: Text('Dilihat')),
        DataColumn(label: Text('Like')),
        DataColumn(label: Text('Comment')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Tanggal\nPosting')),
        DataColumn(label: Text('Diposting\nOleh')),
        DataColumn(label: Text('Aksi')),
      ],
      rows: dataToShow.map((item) {
        bool isActive = !item.deleted;
        String jenisStatus = item.deleted ? 'Dihapus Kontributor' : 'Aktif';

        return DataRow(
          cells: [
            DataCell(
              SizedBox(
                width: 250,
                child: Text(
                  item.deskripsi ?? item.title ?? '-',
                ),
              ),
            ),
            DataCell(
              (item.gambar != null && item.gambar!.isNotEmpty)
                  ? SizedBox(
                    width: 100,
                    height: 50,
                    child: Image.network(
                      item.gambar!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: AppColors.error),
                    ),
                  )
                  : const Text('-'),
            ),
            DataCell(Text(item.jumlahLaporan.toString())),
            DataCell(Text(item.jumlahLike.toString())),
            DataCell(Text(item.jumlahComment.toString())),
            DataCell(
              Chip(
                label: Text(jenisStatus),
                backgroundColor: isActive ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
                labelStyle: TextStyle(color: isActive ? AppColors.success : AppColors.error),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              ),
            ),
            DataCell(Text(_dateFormatter.format(item.uploadDate))),
            DataCell(
              Text(
                item.accountName ?? '-',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500),
              ),
            ),
            DataCell(
              Row(
                children: [
                  _actionButton(
                    icon: Icons.delete_outline,
                    color: AppColors.error,
                    tooltip: 'Hapus Postingan',
                    onPressed: () async {
                      
                    },
                  ),
                  const SizedBox(width: 4),
                  _actionButton(
                    icon: isActive ? Icons.unpublished_outlined : Icons.check_circle_outline,
                    color: isActive ? AppColors.warning : AppColors.success,
                    tooltip: isActive ? 'Nonaktifkan (Hapus)' : 'Aktifkan Kembali',
                    onPressed: () async {
                      
                    },
                  ),
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