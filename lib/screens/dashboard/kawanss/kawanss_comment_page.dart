// lib/screens/dashboard/kawanss/kawanss_comment_page.dart

import 'package:suara_surabaya_admin/core/theme/app_colors.dart';
import 'package:suara_surabaya_admin/models/dashboard/kawanss/kawanss_comment_model.dart';
import 'package:suara_surabaya_admin/providers/dashboard/kawanss/kawanss_post_provider.dart';
import 'package:suara_surabaya_admin/widgets/common/custom_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class KawanssCommentPage extends StatefulWidget {
  const KawanssCommentPage({super.key});

  @override
  State<KawanssCommentPage> createState() => _KawanssCommentPageState();
}

class _KawanssCommentPageState extends State<KawanssCommentPage> {
  final TextEditingController _searchController = TextEditingController();
  final DateFormat _dateFormatter = DateFormat('dd MMM yyyy\nHH:mm');
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
        List<KawanssCommentModel> filteredData;
        final query = _searchController.text.toLowerCase();
        final allData = provider.comments;

        if (query.isEmpty) {
          filteredData = allData;
        } else {
          filteredData = allData.where((item) =>
            item.comment.toLowerCase().contains(query) ||
            item.username.toLowerCase().contains(query)
          ).toList();
        }
        
        final paginatedData = filteredData.take(int.tryParse(_entriesToShow) ?? 10).toList();

        return Column(
          key: const PageStorageKey('kawanssCommentPage'),
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
                      Text("Manajemen Komentar Kawan SS", style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 20),
                      _buildTableControls(),
                      const SizedBox(height: 20),
                      
                      // --- PERBAIKAN LAYOUT TABEL ---
                      if (provider.state == KawanssPostViewState.Busy && provider.comments.isEmpty)
                        const Center(child: CircularProgressIndicator())
                      else if (provider.errorMessage != null)
                        Center(child: Text('Error: ${provider.errorMessage}', style: const TextStyle(color: AppColors.error)))
                      else if (paginatedData.isEmpty)
                        const Center(child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text("Tidak ada komentar ditemukan."),
                        ))
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                child: _buildDataTable(provider, paginatedData),
                              ),
                            );
                          },
                        ),
                      // ------------------------------
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
                border: Border.all(color: AppColors.foreground.withOpacity(0.2)),
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
              labelText: 'Cari Komentar / User',
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDataTable(KawanssPostProvider provider, List<KawanssCommentModel> dataToShow) {
    return DataTable(
      dataRowMinHeight: 32.0, 
      dataRowMaxHeight: 64.0, 
      headingRowColor: const WidgetStatePropertyAll(AppColors.primary),

      columns: const [
        DataColumn(label: Text('User')),
        DataColumn(label: Text('Komentar')),
        DataColumn(label: Text('Tanggal')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Aksi')),
      ],
      rows: dataToShow.map((item) {
        bool isDeleted = item.deleted;

        return DataRow(
          cells: [
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    backgroundImage: (item.photoURL != null && item.photoURL!.isNotEmpty) 
                        ? NetworkImage(item.photoURL!) 
                        : null,
                    child: (item.photoURL == null || item.photoURL!.isEmpty) 
                        ? const Icon(Icons.person, size: 16) 
                        : null,
                    radius: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(item.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            DataCell(
              SizedBox(
                width: 300,
                child: Text(
                  item.comment,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            DataCell(Text(_dateFormatter.format(item.uploadDate))),
            DataCell(
              Chip(
                label: Text(isDeleted ? 'Dihapus' : 'Aktif'),
                backgroundColor: isDeleted ? AppColors.error.withOpacity(0.1) : AppColors.success.withOpacity(0.1),
                labelStyle: TextStyle(color: isDeleted ? AppColors.error : AppColors.success, fontSize: 12),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              ),
            ),
            DataCell(
              Row(
                children: [
                  _actionButton(
                    icon: isDeleted ? Icons.restore_from_trash : Icons.delete_outline,
                    color: isDeleted ? AppColors.success : AppColors.error,
                    tooltip: isDeleted ? 'Pulihkan Komentar' : 'Hapus Komentar (Soft)',
                    onPressed: () async {
                      await provider.toggleCommentStatus(item.id, item.deleted);
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
        style: ElevatedButton.styleFrom(
          backgroundColor: color, 
          foregroundColor: AppColors.surface, 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)), 
          padding: EdgeInsets.zero
        ),
        child: Tooltip(message: tooltip, child: Icon(icon, size: 16)),
      ),
    );
  }
}